block load -- @ 0x0200

  var lohi end @zp
  var lohi ptr @zp
  inline byte raster_pos = 60
  var lohi progress @zp

run:
  // load address (lo only)
  ldy ptr.lo
  // clear lo part of ptr
  lda 0
  sta ptr.lo

  lda 0
  sta progress.lo
  lda 220
  sta progress.hi

loop:
  jsr getbyte.run
  sta [ptr], y
  $if displayBytes
  smc_display_bytes:
    lda vic.border_color
  $endif
  lda vic.raster
  cmp.imm @raster_pos
  bpl next_raster
continue_raster:
  iny
  bne __skip
  inc ptr.hi
  lda progress.lo
  sec
  sbc div_var.quot.lo
  sta progress.lo
  lda progress.hi
  sbc div_var.quot.hi
  sta progress.hi
__skip:
  cpy end.lo
  bne loop
  lda ptr.hi
  cmp end.hi
  bne loop

  lda basic.area[0]
  sta launch_kernal.eighthundred[0]
  lda basic.area[1]
  sta launch_kernal.eighthundred[1]
  lda basic.area[2]
  sta launch_kernal.eighthundred[2]
  dec cpu.port
  lda basic.rom
  sta launch_kernal.rom_check
  inc cpu.port

  jmp launch_kernal.run


  // positions: 0 (occur twice, trigger once) 95 (100..220) 225
next_raster:
  lda raster_pos
  beq r0
  cmp 95
  beq r95
  cmp 225
  beq r225

rlevel:
  $if displayBytes
    lda 0x8d
    sta byte(smc_display_bytes)
  $else
    lda $grey4
    sta vic.border_color
  $endif
  lda 225
  bne exit_raster

r225:
  $if displayBytes
    lda 0xad
    sta byte(smc_display_bytes)
  $endif
  lda $black4
  sta vic.border_color
  lda 0
  beq exit_raster

r0:
  lda $black4
  sta vic.border_color
  lda 95
  bne exit_raster

r95:
  lda $darkGrey4
  sta vic.border_color
  lda progress.hi
  -- bne exit_raster

exit_raster:
  sta raster_pos
  jmp continue_raster




  block getbyte -- @ 0x0200

  run:
    $if fakeTapecart
      inline byte p = 0
      const byte[] dat = [[ /* 0x01, 0x08, */ 0x0c, 0x08, 0x0a, 0x00, 0x99, 0x22, 0x41, 0x4c, 0x58, 0x22, 0x00, 0x00, 0x00 ]] @reloc_0200

      ldx.imm @p
      lda dat, x
      inc p

      -- try to emulate the routine time
      var byte nopCrasher @reloc_0200
      inc nopCrasher
      inc nopCrasher
      inc nopCrasher
      inc nopCrasher
      inc nopCrasher
      inc nopCrasher
      inc nopCrasher
      inc nopCrasher
      inc nopCrasher

    $elseif useFastLoader

      const byte[16] nibbletab = [[0x00, 0x10, 0x20, 0x30, 0x40, 0x50, 0x60, 0x70, 0x80, 0x90, 0xa0, 0xb0, 0xc0, 0xd0, 0xe0, 0xf0]] @reloc_0200

      // wait until tapecart is ready (sense high)
      lda 0x10
    rdyloop:
      -- inc vic.border_color
      bit cpu.port
      beq rdyloop

      // (this would be a nice place to check if a badline is coming up)

      // send our own ready signal
      ldx 0x38
      lda 0x27
      stx cpu.port                 // set write high (start signal)
      sta cpu.ddr                 // 3 - switch write to input
      nop                     // 2 - delay

      // receive byte
      lda cpu.port                 // 3 - read bits 5+4
      and 0x18                // 2 - mask
      lsr                     // 2 - shift down
      lsr                     // 2
      eor cpu.port                 // 3 - read bits 7+6 (EOR invertes 5+4!)
      lsr                     // 2
      and 0x0f                // 2 - mask
      tax                     // 2 - remember value

      lda cpu.port                 // 3 - read bits 1+0
      and 0x18                // 2 - mask
      lsr                     // 2 - shift down
      lsr                     // 2
      eor cpu.port                 // 3 - read bits 3+2 (EOR inverts 1+0!)
      lsr                     // 2
      and 0x0f                // 2 - mask
      ora nibbletab,x         // 4 - add upper nibble

      ldx 0x2f                // 2 - switch write to output
      stx cpu.ddr                 // 3
      ldx 0x36                // set write low again
      stx cpu.port

    $else
      var byte result @zp

      // returns byte in A, preserves Y
      // NEW trashes Y

      // wait until AVR is ready (sense high)
      lda 0x10
    rdyloop:
      bit cpu.port
      beq rdyloop

      // send our own ready signal
      lda 0x3f -- 0x3d
      // lda #$37 //   bit4 of $00 set to 1
      sta cpu.port                 // set write high (start signal)
      // sta $00                 // 3 - switch write to output
      // nop                     // 2 - delay

      //now start
      ldx 7
    iloop:

      lda cpu.port
      and 0b1111.0111 // write low
      sta cpu.port

      lda cpu.port
      ora 0b0000.1000 // write high
      sta cpu.port

      lda cpu.port
      // 76543210
      rol
      // 7-6543210c
      rol
      // 6-543210c7
      rol
      // 5-43210c76
      rol //bit in carry (sense)
      // 4-3210c765
      rol result

      dex
      bpl iloop

      lda cpu.port
      and 0b1111.0111 //write low
      sta cpu.port

      lda result
    $endif
    rts
  end

end
