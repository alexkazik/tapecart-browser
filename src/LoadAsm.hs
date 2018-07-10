module LoadAsm
  ( load
  ) where

import           Asm.C64

import           Tapecart

displayBytes :: Bool
displayBytes = True

load :: Asm
load = $(asmFile "./load.asm")
