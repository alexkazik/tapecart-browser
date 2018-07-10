module Dir
  ( typeToIcon
  , constPageScroll
  , constKeepClear
  , dirStartPositionsLo
  , dirStartPositionsHi
  ) where

import           Control.Arrow ((&&&))

import           Asm.C64

typeToIcon :: [TInt64]
typeToIcon = section1 ++ section2 ++ section3 ++ section4
  where
    section1 = [124, 126, 124, 30, 30, 30, 30] ++ replicate (64-7) 124
    section2 = replicate 64 (0x80 *& 0x80)
    section3 = replicate 112 (0x80 *& 0x80)
    section4 = replicate 15 (0x80 *& 0x80) ++ [0]

constPageScroll :: Int
constPageScroll = 15

constKeepClear :: Int
constKeepClear = 3

dirStartPositionsLo :: [Int]
dirStartPositionsHi :: [Int]
(dirStartPositionsLo, dirStartPositionsHi) =
  unzip (map ((.&. 0xff) &&& (`shiftR` 8)) pos)
  where
    pos = map (\x -> x * 40 + 0x0800) [0..127-22]
