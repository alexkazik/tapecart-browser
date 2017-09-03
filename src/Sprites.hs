module Sprites where

import           Asm.C64

sprites :: [[Word8]]
sprites =
  let
    allSpr = slicesOf 24 21 $(imageWithUpdate "graphics/sprites.png")
  in
    map (renderHiresBg 0) allSpr
