module DirConverterAsm where

import           Asm.C64

import           Macros

dirConverter :: Asm
dirConverter = $(asmFile "./dir-converter.asm")
