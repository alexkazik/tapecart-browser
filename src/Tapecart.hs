module Tapecart where

import           Asm.C64

fakeTapecart :: Bool
fakeTapecart = False

useFastLoader :: Bool
useFastLoader = True

tapecartApiReadFlash :: Word8
tapecartApiReadFlash = 0x10

tapecartApiReadFlashFast :: Word8
tapecartApiReadFlashFast = 0x11

tapecartApiReadLoadInfo :: Word8
tapecartApiReadLoadInfo = 0x21
