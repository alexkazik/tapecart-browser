block tapecart

  block putbyte
    inline byte restx
    local byte _transfer @zp

  run:
    // A is byte to send
    sta _transfer
    stx restx

    // wait until AVR is ready (sense high)
    lda 0x10
  rdyloop:
    bit cpu.port
    beq rdyloop

    // send our own ready signal
    // ldx #$38
    lda 0x3f // bit4 of $00 set to 1
    // stx $01 // set write high (start signal)
    sta cpu.ddr // 3 - switch write to output
    // nop // 2 - delay

    inline byte bitflag

    // now start
    ldx 7
  iloop:
    lda 0
    rol _transfer
    rol // 0
    rol // 1
    rol // 2
    rol // 3
    rol // 4 sense
    sta bitflag

    lda cpu.port
    and 0b1110.1111
    ora.imm @bitflag
    sta cpu.port

    pha
    pla // delay

    lda cpu.port
    ora 0b0000.1000 // write high
    sta cpu.port

    pha
    pla // delay

    lda cpu.port
    and 0b1111.0111 // write low
    sta cpu.port

    dex
    bpl iloop

    lda cpu.port
    ora 0b0001.0000 // sense high
    sta cpu.port

    lda cpu.port
    and 0b1110.1111 // sense low
    sta cpu.port

    //sense input
    lda 0x2f // bit4 of $00 set to 0
    sta cpu.ddr

    ldx.imm @restx
    rts
  end

  block getbyte
  run:
    $if fakeTapecart
      inline byte p = 0
      const byte[] dat = $["000000{{{n2C}}}       " :: String] @prog

      ldy.imm @p
      lda dat, y
      inc p
    $else
      local byte _result @zp

      // returns byte in A, preserves Y
      // NEW trashes Y

      // wait until AVR is ready (sense high)
      lda 0x10
    rdyloop:
      bit cpu.port
      beq rdyloop

      // send our own ready signal
      ldy 0x3f // 0x3d
      // lda #$37 // bit4 of $00 set to 1
      sty cpu.port // set write high (start signal)
      // sta $00 // 3 - switch write to output
      // nop // 2 - delay

      //now start
      ldy 7
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
      rol _result

      dey
      bpl iloop

      lda cpu.port
      and 0b1111.0111 // write low
      sta cpu.port

      lda _result
    $endif
    rts
  end

  block set_commandmode
  run:
    $if not fakeTapecart
    sensechk:
      lda cpu.port
      and 0x10
      bne sensechk // wait for sense = 0

      lda 0xfc
      sta _handshk1

      lda 0xe2
      sta _handshk2

      local byte _handshk1 @zp
      local byte _handshk2 @zp

      // start:
      // handshake needs ~50ms, enough to ensure the screen is blank

      // send handshake
      clc // fill the signature byte with a 0-bit
      ldy 16 // 16 bits
      ldx 0x00
      // stx 0xc6 // clear keyboard buffer

    hskloop:
      lda 0x27 // motor off, write low
      rol _handshk2 // read top bit of signature word
      rol _handshk1 // read top bit of signature word
      bcc hsk_0
      ora 0x08             // set write high
    hsk_0:
      sta cpu.port

    delay1:
      dex // delay loop (motor line is heavily RC-filtered)
      nop
      bne delay1

      and 0xdf // motor on, keep write
      sta cpu.port

    delay2:
      dex
      bne delay2

      dey // check if all bits sent
      bne hskloop

      // turn off motor
      lda 0x37 // motor off, write low
      sta cpu.port

    delay3:
      dex // delay loop (motor line is heavily RC-filtered)
      nop
      bne delay3

      lda cpu.port
      ora 0b0000.1000 // write high
      sta cpu.port

      // wait until sense is high
    sensechk2:
      lda cpu.port
      and 0x10
      beq sensechk2

      // wait until three read pulses have been received
      ldy 0x03
      lda 0x10
    pulseloop:
      bit cia1.icr
      beq pulseloop
      dey
      bne pulseloop

      lda cpu.port
      and 0b1111.0111 // write low
      sta cpu.port
    $endif
    rts
  end

end
