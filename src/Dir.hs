module Dir
  ( typeToIcon
  , constPageScroll
  , constKeepClear
  , dirStartPositionsLo
  , dirStartPositionsHi
  ) where

import           Asm.C64

typeToIcon :: [TInt64]
typeToIcon = [124, 126, 124, 30, 30, 30, 30] ++ replicate (64-7) 124 ++ replicate (64+128-1) (0x80 *& 0x80) ++ [0]

constPageScroll :: Int
constPageScroll = 15

constKeepClear :: Int
constKeepClear = 3

dirStartPositionsLo :: [Int]
dirStartPositionsLo = map (\x -> (x*40 + 0x0800) .&. 0xff) [0..127-22]

dirStartPositionsHi :: [Int]
dirStartPositionsHi = map (\x -> (x*40 + 0x0800) `shiftR` 8) [0..127-22]
