module Main (
  main
) where

import qualified Data.Text as Text
import Lib
import Prelude
import Test.Hspec

main :: IO ()
main = hspec $ do
  describe "hello" $ do
    it "begins with \"Hello\"" $ do
      Text.isPrefixOf "Hello" hello `shouldBe` True