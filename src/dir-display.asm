block dirDisplay

  local byte _line @zp

run:
  // ADAPT screen start/offset (when > 23 entries)

// check for correct values

  lda numEntries
  cmp 24
  bcs multi_page

  // we're always on page 0 (single page mode)
  lda 0
  sta drawStart

  {
    lda drawOffset
    bpl __else
    // offset < 0 -> make 0 (first entry)
    lda 0
    sta drawOffset
    beq __endif
  __else:
    // offset >= 0
    cmp numEntries
    bcc __endif

    // offset >= max
    ldx numEntries
    dex
    stx drawOffset
  __endif:
  }

  jmp _end_check


multi_page:

  // move start up while offset is < 0
  {
  __while:
    // while P_DRAW_OFFSET < 0
    lda drawOffset
    bpl __end_while
    // P_DRAW_OFFSET+=23
    clc
    adc $constPageScroll
    sta drawOffset
    // P_DRAW_START-=23
    lda drawStart
    sec
    sbc $constPageScroll
    sta drawStart
    bcs __while
    // if P_DRAW_START < 0
    lda 0
    sta drawStart
    sta drawOffset
  __end_while:
  }

  // move start down while offset is out of screen
  {
  __while:
    // while P_DRAW_OFFSET >= 23
    lda drawOffset
    cmp 23
    bcc __end_while
    // P_DRAW_OFFSET-=23
    sec
    sbc $constPageScroll
    sta drawOffset
    // P_DRAW_START+=23
    lda drawStart
    clc
    adc $constPageScroll
    sta drawStart
    bcc __while
    // if P_DRAW_START > 255
    lda drawStartLast
    sta drawStart
    lda 22
    sta drawOffset
  __end_while:
  }

  {
    // if P_DRAW_START > last start
    lda drawStartLast
    cmp drawStart
    bcs __endif
    lda drawStartLast
    sec
    sbc drawStart
    sta drawStart
    lda drawOffset
    sec
    sbc drawStart
    cmp 23
    bcc __skip
    lda 22
  __skip:
    sta drawOffset
    lda drawStartLast
    sta drawStart
  __endif:
  }

  {
  __while:
    lda drawOffset
    cmp $constKeepClear
    bcs __end_while
    lda drawStart
    beq __end_while
    inc drawOffset
    dec drawStart
    jmp __while
  __end_while:
  }

  {
  __while:
    lda drawOffset
    cmp 23 - $constKeepClear
    bcc __end_while
    lda drawStart
    cmp drawStartLast
    beq __end_while
    dec drawOffset
    inc drawStart
    jmp __while
  __end_while:
  }

_end_check:

  lda 0
  sta _line

  local lohi _display @zp
  local lohi _directory @zp

  lda (0x0400 + 1*40 + 1) & 0xff
  sta _display.lo
  lda (0x0400 + 1*40 + 1) >> 8
  sta _display.hi

  ldx drawStart
  lda dirStartPositionsLo, x
  sta _directory.lo
  lda dirStartPositionsHi, x
  sta _directory.hi

big_loop:
  lda _line
  cmp drawOffset
  beq do_invert
do_normal:
  // copy a _line
  {
    ldy 24-1
  __loop:
    lda [_directory], y
    sta [_display], y
    dey
    bpl __loop
  }
  bmi do_done
do_invert:
  // copy a _line
  {
    ldy 24-1
  __loop:
    lda [_directory], y
    eor 0x80
    sta [_display], y
    dey
    bpl __loop
  }

do_done:

  // next dir.entry
  $(macroAddConstToLoHi "_directory" 40)

  // end of _display?
  inc _line
  lda _line
  cmp 23
  beq exit
  // last _line displayed?
  cmp numEntries
  beq exit

  // next _line
  $(macroAddConstToLoHi "_display" 40)

  jmp big_loop

exit:
  jmp drawSlider.run


  block drawSlider

    /*
    ** SLIDER!
    */

    local byte _before_slider @zp
    local byte _after_slider @zp

    // use _display for screen and _directory for colmem

  run:
    // init ptr to screen+colmem
    lda (0x0400 + 40 + 25) & 0xff
    sta dirDisplay._display.lo
    lda (0x0400 + 40 + 25) >> 8
    sta dirDisplay._display.hi
    lda (0xd800 + 40 + 25) & 0xff
    sta dirDisplay._directory.lo
    lda (0xd800 + 40 + 25) >> 8
    sta dirDisplay._directory.hi

    // check wether to draw a slider
    lda sliderSize
    bne has_slider

    // no slider!
    lda 23
    sta _after_slider
    ldy 0
    jmp last_part

  has_slider:

    // calc position of slider
    local lohi _src1 @zp
    local byte _src2 @zp

    lda sliderPositionIncrease.lo
    sta _src1.lo
    lda sliderPositionIncrease.hi
    sta _src1.hi

    lda drawStart
    sta _src2

    $(macroMul168 "_src1" "_src2" "_src1")

    ldx _src1.hi
    lda _src1.lo
    bpl skip
    inx
  skip:
    stx _before_slider
    // middle = size
    lda 23
    sec
    sbc sliderSize
    sbc _before_slider
    sta _after_slider

    ldy 0

    // draw '_before_slider'

    ldx _before_slider
    beq middle_part

  before_loop:
    lda $charSliderBefore
    sta [dirDisplay._display], y
    lda $colorSliderOff
    sta [dirDisplay._directory], y
    jsr f_next_line
    dex
    bne before_loop

  middle_part:

    // draw top thing
    lda $charSliderTop
    sta [dirDisplay._display], y
    lda $colorSliderOn
    sta [dirDisplay._directory], y
    jsr f_next_line

    // draw middle thing (if needed)
    ldx sliderSize
    dex
    dex
    beq skip_middle_inner
  middle_loop:
    lda $charSliderMiddle
    sta [dirDisplay._display], y
    lda $colorSliderOn
    sta [dirDisplay._directory], y
    jsr f_next_line
    dex
    bne middle_loop
  skip_middle_inner:
    // draw bottom thing
    lda $charSliderBottom
    sta [dirDisplay._display], y
    lda $colorSliderOn
    sta [dirDisplay._directory], y
    jsr f_next_line

  last_part:

    // draw '_after_slider'
    ldx _after_slider
    beq return

  last_loop:
    lda $charSliderAfter
    sta [dirDisplay._display], y
    lda $colorSliderOff
    sta [dirDisplay._directory], y
    jsr f_next_line
    dex
    bne last_loop


  return:
    rts

  f_next_line:
    $(macroAddConstToLoHi "dirDisplay._display" 40)
    $(macroAddConstToLoHi "dirDisplay._directory" 40)
    rts

  end

  block title
    local byte[22] _buffer @zp
    -- var byte[6+16] _buffer @zp

    do:

      jsr tapecart.set_commandmode.run
      lda $tapecartApiReadLoadInfo
      jsr tapecart.putbyte.run
      ldx 0
    __loop:
      jsr tapecart.getbyte.run
      cmp 0x20
      bcc __bad
      cmp 0x7a
      bcc __store
    __bad:
      lda 0x60
    __store:
      sta _buffer, x
      inx
      cpx 22
      bne __loop

      // find last used char
      ldx 16
    __loop1:
      dex
      bmi __skip_title
      lda _buffer[6], x
      and (~0x40) & 0xff
      cmp 0x20
      beq __loop1

      inline byte last

      inx
      lda 0x20
      sta _buffer[6], x
      inx
      stx last

      // find first
      ldx 0xff
    __loop2:
      inx
      lda _buffer[6], x
      and (~0x40) & 0xff
      cmp 0x20
      beq __loop2

      // copy to screen
      ldy 0
    __loop3:
      lda _buffer[6], x
      ora 0x80
      cmp 0xc0
      bcc __skip3
      cmp 0xe0
      ora 0x20
      bcc __skip3
      lda 0xe0
    __skip3:
      sta screen[2], y
      iny
      inx
      cpx.imm @last
      bne __loop3

  __skip_title:
    rts
  end

end
