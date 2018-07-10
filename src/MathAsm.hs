module MathAsm
  ( math
  ) where

import           Asm.C64

math :: Asm
math = [asm|
  var struct { lohi src1; lohi src2; lohi quot; lohi rem; byte tmp} div_var @zp

  block div16round
  run:
    lda 0
    sta div_var.rem.lo
    sta div_var.rem.hi

    // actual division
    ldx 16
  __loop:
    asl div_var.src1.lo
    rol div_var.src1.hi
    rol div_var.rem.lo
    rol div_var.rem.hi

    lda div_var.rem.lo
    sta div_var.tmp
    sec
    sbc div_var.src2.lo
    sta div_var.rem.lo
    lda div_var.rem.hi
    tay
    sbc div_var.src2.hi
    sta div_var.rem.hi
    bcs __next

    sty div_var.rem.hi
    lda div_var.tmp
    sta div_var.rem.lo
    clc
  __next:
    rol div_var.quot.lo
    rol div_var.quot.hi
    dex
    bne __loop

    // round up
    lda div_var.rem.lo
    asl
    rol div_var.rem.hi
    cmp div_var.src2.lo
    lda div_var.rem.hi
    sbc div_var.src2.hi
    bcc _no_round
    inc div_var.quot.lo
    bne _no_round
    inc div_var.quot.hi
  _no_round:
    rts
  end
|]
