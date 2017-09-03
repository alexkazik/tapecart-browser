module TapecartAsm where

import           Asm.C64

import           Tapecart

tapecart :: Asm
tapecart = $(asmFile "./tapecart.asm")
