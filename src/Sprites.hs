module Sprites
  ( sprites
  ) where

import qualified Data.Vector.Unboxed as UV

import           Asm.C64

sprites :: [UV.Vector Word8]
sprites =
  let
    allSpr = slicesOf 24 21 $(imageWithUpdate "graphics/sprites.png")
  in
    map (snd . render1BitWidth [(black8, 0xf0 .|. 0)] 1) allSpr
