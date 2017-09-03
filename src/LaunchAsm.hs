module LaunchAsm where

import           Asm.C64

import           Tapecart

launch :: Asm
launch = $(asmFile "./launch.asm")
