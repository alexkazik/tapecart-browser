block launch -- @ prog

run:
  // disable screen
  lda 0
  sta vic.control1
  sta vic.sprite_enable

  // cia2: stop & reset timer A
  lda 0b1100.0000
  sta cia2.controla
  lda 0xff
  sta cia2.timera.lo
  sta cia2.timera.hi

  $if useFastLoader
    // wait until vertical blank
    ldx 14
  wait1:
    cpx vic.raster
    bne wait1
    ldy vic.control1
    bmi wait1
    dex
    cpx 12
    bne wait1
  $endif

  // selected _entry
  local lohi _entry @zp
  lda drawStart
  clc
  adc drawOffset
  tay
  lda dirStartPositionsLo, y
  sta _entry.lo
  lda dirStartPositionsHi, y
  sta _entry.hi
  ldy 25

  // load the specified file
  $if useFastLoader
    lda $tapecartApiReadFlashFast
  $else
    lda $tapecartApiReadFlash
  $endif
  jsr tapecart.putbyte.run

  // start
  lda 0
  jsr tapecart.putbyte.run
  lda [_entry], y
  iny
  jsr tapecart.putbyte.run
  lda [_entry], y
  iny
  jsr tapecart.putbyte.run

  // length
  lda [_entry], y
  iny
  sta load.end.lo
  jsr tapecart.putbyte.run
  lda [_entry], y
  iny
  sta load.end.hi
  sta div_var.src2.lo
  jsr tapecart.putbyte.run
  iny -- skip lengthHihi


  lda [_entry], y
  sta load.ptr.lo
  clc
  adc load.end.lo
  sta load.end.lo
  sta launch_kernal.end_lo
  iny
  lda [_entry], y
  sta load.ptr.hi
  adc load.end.hi
  sta load.end.hi
  sta launch_kernal.end_hi


  lda 4
  sta launch_kernal.keyb_len


  lda 0x52
  sta launch_kernal.keyb[0]
  lda 0x55
  sta launch_kernal.keyb[1]
  lda 0x4e
  sta launch_kernal.keyb[2]
  lda 0x0d
  sta launch_kernal.keyb[3]

  lda 0
  sta basic.area
  sta div_var.src2.hi
  sta div_var.src1.lo
  lda 120
  sta div_var.src1.hi
  jsr div16round.run

  jmp load.run

end


block launch_kernal @reloc_stack

  inline byte restore_chrin_lo
  inline byte restore_chrin_hi

  -- lda 0x37
  -- sta cpu.port
run:
  // do a partial reset
  ldx 0xff
  txs
  lda $blue4
  sta vic.border_color
  jsr kernal.ioinit
  jsr kernal.ramtas
  jsr kernal.restor
  jsr kernal.init

  lda kernal.vector.chrin.lo
  sta restore_chrin_lo
  lda kernal.vector.chrin.hi
  sta restore_chrin_hi

  lda addr(our_chrin) & 0xff
  sta kernal.vector.chrin.lo
  lda addr(our_chrin) >> 8
  sta kernal.vector.chrin.hi

  // set current file (emulate read from drive 8)
  lda 1
  ldx 8
  tay
  jsr kernal.setlfs

  pointer code continue_reset = 0xfcfe
  jmp continue_reset


our_chrin:
  // store X
  sei
  txa
  pha

  ldx 8
l:
  lda keyb, x
  sta kernal.keyboard_buffer, x
  lda byte(eighthundred, -6), x
  sta byte(basic.area, -6), x
  dex
  bpl l
  lda.imm @keyb_len
  sta kernal.keyboard_buffer_len
  lda.imm @rom_check
  sta basic.rom

  lda.imm @end_lo
  sta basic.start_variables.lo
  sta basic.start_arrays.lo
  sta basic.end_arrays.lo
  sta kernal.end_of_program.lo
  lda.imm @end_hi
  sta basic.start_variables.hi
  sta basic.start_arrays.hi
  sta basic.end_arrays.hi
  sta kernal.end_of_program.hi

  lda.imm @restore_chrin_lo
  sta kernal.vector.chrin.lo
  lda.imm @restore_chrin_hi
  sta kernal.vector.chrin.hi

  // restore X
  cli
  pla
  tax

  jmp [kernal.vector.chrin]

  var byte[9] keyb @reloc_stack
  var byte[3] eighthundred @reloc_stack
  inline byte rom_check
  inline byte keyb_len
  inline byte end_lo
  inline byte end_hi
end
