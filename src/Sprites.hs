module Sprites where

import           Asm.C64

import qualified Data.Vector.Unboxed as UV

sprites :: [UV.Vector Word8]
sprites =
  let
    allSpr = slicesOf 24 21 $(imageWithUpdate "graphics/sprites.png")
  in
    map (snd . render1BitWidth [(black8, 0xf0 .|. 0)] 1) allSpr
