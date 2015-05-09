import Data.Formula

import Test.Tasty
import Test.Tasty.SmallCheck as SC
import Test.Tasty.QuickCheck as QC
import Test.Tasty.HUnit

import Control.Monad (liftM, liftM2)
-- import Text.Show.Functions

-- main = defaultMain tests
main = defaultMain $ testGroup "tests"
    [ formulaFunctorLaws
    , atomsTests
    , domainTests
    , modelsTests
    , cnfTests
    ]


-- ----------------------------------------------------------------------------
formulaFunctorLaws = testGroup "Formula Functor laws tests"
    [ QC.testProperty "Formula Functor Law 1"
        ((\fm -> fmap id fm == id fm ) :: Formula Int -> Bool)
    , QC.testProperty "Formula Functor Law 2"
        ((\ p q fm -> fmap (p . q) fm == fmap p (fmap q fm)) :: (Int -> Int) -> (Int -> Int) -> Formula Int -> Bool)
    ]


-- ----------------------------------------------------------------------------
atomsTests = testGroup "atoms tests"
    [ testCase "atomsAtom1" $   [1]   @=? atoms (Atom 1)
    , testCase "atomsNot1" $    [1]   @=? atoms (Not (Atom 1))
    , testCase "atomsAnd1" $    [1,2] @=? atoms (And (Atom 1) (Atom 2))
    , testCase "atomsAnd2" $    [1]   @=? atoms (And (Atom 1) (Atom 1))
    , testCase "atomsOr1" $     [1,2] @=? atoms (Or (Atom 1) (Atom 2))
    , testCase "AtomsOr2" $     [1]   @=? atoms (Or (Atom 1) (Atom 1))
    , testCase "atomsImp1" $    [1,2] @=? atoms (Imp (Atom 1) (Atom 2))
    , testCase "AtomsImp2" $    [1]   @=? atoms (Imp (Atom 1) (Atom 1))
    , testCase "atomsIff1" $    [1,2] @=? atoms (Iff (Atom 1) (Atom 2))
    , testCase "AtomsIff2" $    [1]   @=? atoms (Iff (Atom 1) (Atom 1))
    ]

domainTests = testGroup "domain test"
    [ testCase "domain1" $  2 @=? length (domain (Atom 1))
    , testCase "domain2" $  2 @=? length (domain (And (Atom 1) (Atom 1)))
    , testCase "domain2" $  4 @=? length (domain (And (Atom 1) (Atom 2)))
    ]

modelsTests = testGroup "models test"
    [ testCase "modelsAtom1" $  1 @=? length (models (Atom 1))
--    , testCase "modelsAtom2" $  [[(1,True)]] @=? (fmap fromList (models (Atom 1)))
    ]



cnfTests = testGroup "cnf test"
    [ QC.testProperty "semantic equality"
        ((\fm -> domain fm == domain (cnf fm)) :: (Formula Int) -> Bool)
    ]


-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- QuickCheck Test Preparation

-- create a new wrapper for variable values for better control
-- of the distrubution intervall
newtype TInt = TInt  Int deriving (Eq, Read, Show)

-- make id type and formula instance of class arbitrary for data generation
instance Arbitrary TInt where
    arbitrary = sized tint'
      where
        tint' n = do
            x <- choose (0,n)
            return . TInt $ x

instance Arbitrary a => Arbitrary (Formula a) where
    arbitrary = sized formula'
      where
        formula' 0 = fmap Atom arbitrary
        formula' n | n>0 =
            let subf = subformula n
            in  oneof [ formula' 0
                      , liftM Not  subf
                      , liftM2 And subf subf
                      , liftM2 Or  subf subf
                      , liftM2 Imp subf subf
                      , liftM2 Iff subf subf
                      ]
        subformula n = formula' (n `div` 2)

-- to get the impression of the produced data:
-- sample ((arbitrary) :: Gen (Formula Int))

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
