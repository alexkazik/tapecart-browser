block input

	const byte[] keyTableNoShift = $[keyTableNoShift] ++ $[keyTableWithShift] @data page 256
	alias keyTableWithShift = byte(keyTableNoShift, $(length keyTableNoShift))

	local lohi _ZP_INPUT_KEYTABLE @zp
	local byte _ZP_INPUT_MATRIX @zp
	local byte _ZP_BUFFER @zp

	{
	getin:
	  jsr get_shift
	  beq __is_shift

	  // no shift
	  lda addr(keyTableNoShift) & 0xff
	  sta _ZP_INPUT_KEYTABLE.lo
	  lda addr(keyTableNoShift) >> 8
	  sta _ZP_INPUT_KEYTABLE.hi
	  bne shift_end
	  // whith shift
	__is_shift:
	  lda (addr(keyTableNoShift) + $(length keyTableNoShift)) & 0xff
	  sta _ZP_INPUT_KEYTABLE.lo
	  lda (addr(keyTableNoShift) + $(length keyTableNoShift)) >> 8
	  sta _ZP_INPUT_KEYTABLE.hi
	shift_end:

	  // go trough rows
	  ldy 63 // char in table
	  lda 0x7f
	row_loop:
	  sta _ZP_INPUT_MATRIX
	  sta cia1.porta
	// row-loop
	read_loop:
	  lda cia1.portb
	  cmp cia1.portb
	  bne read_loop
	  ldx 7
	// col-loop
	col_loop:
	  asl
	  bcc a_char
	doch_nicht_a_char:
	  dey
	  bmi __no_char
	  dex
	  bpl col_loop

	// row-loop
	  lda _ZP_INPUT_MATRIX
	  sec
	  ror
	  bne row_loop // branches always

	__no_char:
	  lda 0
	  rts


	a_char:
	  sta _ZP_BUFFER
	    // check weather shift is still the same
	    jsr get_shift
	    beq __skip1
	    lda addr(keyTableNoShift) & 0xff // no shift
	    jmp __skip2
	  __skip1:
	    lda (addr(keyTableNoShift) + $(length keyTableNoShift)) & 0xff // shift
	  __skip2:
	    cmp _ZP_INPUT_KEYTABLE.lo
	    bne getin // if shift state is different: just restart

	  lda [_ZP_INPUT_KEYTABLE], y
	  beq doch_nicht_a_char_l
	  rts

	doch_nicht_a_char_l:
	  lda _ZP_BUFFER
	  bne doch_nicht_a_char

		{
		get_shift:
		  lda 0xbf
		  sta cia1.porta
		loop1:
		  lda cia1.portb
		  cmp cia1.portb
		  bne loop1
		  and 0x10
		  beq __is_shift
		  lda 0xfd
		  sta cia1.porta
		loop2:
		  lda cia1.portb
		  cmp cia1.portb
		  bne loop2
		  and 0x80
		__is_shift:
		  rts
		}
	}

	var byte ZP_INPUT_LAST_CHAR @zp

	{
	init:
    // init
    lda 0
    sta ZP_INPUT_LAST_CHAR

    // init CIA1-data direction
    ldx 0xff
    stx cia1.ddra
    inx
    stx cia1.ddrb

    // alles in CIA2
    // timer A stoppen
    lda 0b1100.0000
    sta cia2.controla
    // timer B stoppen
    lda 0b0100.0000
    sta cia2.controlb
    // latch (zeit eines durchgangs) fuer timer A setzen
    lda 0x08 // 0808 -> 2056 cycles -> ~0.002 sec / ~2/1000 sec
    sta cia2.timera.hi
    sta cia2.timera.lo
    // upper latch fuer timer B auf 0 setzen
    lda 0
    sta cia2.timerb.hi
    // timer A starten
    lda 0b1100.0001
    sta cia2.controla

    rts
	}

	{
	getJoy:
	  lda 0x7f
	  sta cia1.porta
	loop:
    lda cia1.porta
    cmp cia1.porta
    bne loop
    lsr
    bcc up
    lsr
    bcc down
    lsr
    bcc left
    lsr
    bcc right
    lsr
    bcc fire
    lda 0
    rts

  up:
    lda $keyCsrUp
    rts

  down:
    lda $keyCsrDwn
    rts

  left:
    lda $keyCsrLft
    rts

  right:
    lda $keyCsrRgt
    rts

  fire:
    lda $keyReturn
    rts
	}

	{
	getKey:

	  // get from joystick
	  jsr getJoy
	  bne has_joy
	  // if no joystick: get from keyboard
	  jsr getin
	has_joy:

	  // process the key
	  beq __no_char

	  // a key is pressed
	  cmp ZP_INPUT_LAST_CHAR
	  bne use_key // key is different to the last, get it

	  lda cia2.controlb
	  and 0x01
	  bne show_no_char // time is not yet done -> no key

	  // rep-loop is done -> emit a key and use another rep.time
	  lda 48
	  jsr set_timer
	  jmp return_char

	use_key:
	  sta ZP_INPUT_LAST_CHAR
	  lda 200
	  jsr set_timer
	return_char:
	  lda ZP_INPUT_LAST_CHAR
	  rts

	__no_char:
	  sta ZP_INPUT_LAST_CHAR
	  rts

	set_timer:
	  sta cia2.timerb.lo
	  lda 0b0101.1001
	  sta cia2.controlb
	  rts

	show_no_char:
	  lda 0
	return:
	  rts
	}

end
