module InputAsm
  ( input
  ) where

import           Asm.C64

import           Input

input :: Asm
input = $(asmFile "./input.asm")
