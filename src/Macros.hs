module Macros
  ( macroAddConstToLoHi
  , macroMul168
  ) where

import           Asm.C64

macroAddConstToLoHi :: LabelName -> Int64 -> Asm
macroAddConstToLoHi var num =
  if num .&. 0xffff < 256
    then
      [asm|
        lda $var.lo
        clc
        adc $num
        sta $var.lo
        bcc __skip
        inc $var.hi
      __skip:
      |]
    else
      [asm|
        lda $var.lo
        clc
        adc $num & 0xff
        sta $var.lo
        lda $var.hi
        adc ($num >> 8) & 0xff
        sta $var.hi
      |]

macroMul168 :: LabelName -> LabelName -> LabelName -> Asm
macroMul168 src1 src2 dst =
  [asm|
    lda 0
    tay
    beq __enterLoop

  __doAdd:
    clc
    adc $src1.lo
    tax

    tya
    adc $src1.hi
    tay
    txa

  __loop:
    asl $src1.lo
    rol $src1.hi
  __enterLoop:
    lsr $src2
    bcs __doAdd
    bne __loop

    sta $dst.lo
    sty $dst.hi
  |]
