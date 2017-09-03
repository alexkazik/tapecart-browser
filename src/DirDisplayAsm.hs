module DirDisplayAsm where

import           Asm.C64

import           Dir
import           Font
import           Macros
import           Tapecart

dirDisplay :: Asm
dirDisplay = $(asmFile "./dir-display.asm")
