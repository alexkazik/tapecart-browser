type struct {
  byte [16] name;
  byte type;
  lohi address;
  byte[3] size;
  lohi loadaddress;
  byte[8] bundleData;
} _FSEntry
type struct {
  byte[2] system_data;
  byte[13] id;
  _FSEntry[127] entries;
  byte [17] eof;
} _TapCrtFS

pointer _TapCrtFS TapCrtFS = 0x1000
pointer byte[] DisplayFS = 0x0800

block dirConverter

  local lohi _src @ zp
  local lohi _dst @ zp
  local _FSEntry _tmpEntry @ zp


calc_slider:
  // calc size

  // a == numEntries
  sta div_var.src2.lo
  lda 0
  sta div_var.src2.hi
  lda (23*23) & 0xff
  sta div_var.src1.lo
  lda (23*23) >> 8
  sta div_var.src1.hi
  jsr div16round.run

  // basic checks: size should be 2-22
  lda div_var.quot.lo
  cmp 2
  bcs _min_ok
  lda 2
  bne _set
_min_ok:
  cmp 22
  bcc _max_ok
  lda 22
_max_ok:
_set:
  sta sliderSize

  // calc step size
  lda 0
  sta div_var.src1.lo
  lda 23
  sec
  sbc sliderSize
  sta div_var.src1.hi

  // drawStartLast = P_NUM_DIR_ENTRIES-23
  lda numEntries
  sec
  sbc 23
  sta drawStartLast

  sta div_var.src2.lo
  lda 0
  sta div_var.src2.hi

  jsr div16round.run
  lda div_var.quot.lo
  sta sliderPositionIncrease.lo
  lda div_var.quot.hi
  sta sliderPositionIncrease.hi

  rts

exit:
  // skip the 1st entry if it's a separator
  {
    lda DisplayFS[24]
    cmp 0xf0
    bne __skip
    inc drawOffset
  __skip:
  }
  // calculate slider increase
  lda numEntries
  cmp 23+1
  bcs calc_slider

  // no slider
  lda 0
  sta sliderSize
  // never move screen offset down
  sta drawStartLast

  rts

add_separator:
  // add begin
  lda 25
  sta [_dst], y
  iny

  // copy filename
  {
    ldx 0
  __loop:
    lda _tmpEntry.name, x
    // check for valid char
    beq __end_filename
    cmp 0x20
    bcc __invalid
    cmp 0x7b
    bcc __ok
  __invalid:
    lda 0x60
  __ok:
    ora 0x80
    sta [_dst], y
    inx
    iny
    cpx 15 // max length (the 16th is required for the "end" symbol)
    bne __loop
  __end_filename:
  }
  {
    lda 26
    sta [_dst], y
    iny
    lda 29
  __loop:
    sta [_dst], y
    iny
    cpy 23
    bne __loop
  }
  lda 27
  sta [_dst], y
  iny
  jmp copy_file_info

run:
  sei
  lda addr(TapCrtFS.entries) & 0xff
  sta _src.lo
  lda addr(TapCrtFS.entries) >> 8
  sta _src.hi
  lda addr(DisplayFS) & 0xff
  sta _dst.lo
  if (addr(DisplayFS) & 0xff) != 0
    lda 0
  endif
  sta drawStart
  sta drawOffset
  sta numEntries
  sta sliderPosition.lo
  sta sliderPosition.hi
  lda addr(DisplayFS) >> 8
  sta _dst.hi

big_loop:
  {
    ldy size(_FSEntry)-1
  __loop:
    lda [_src], y
    sta _tmpEntry, y
    dey
    bpl __loop
  }

  $(macroAddConstToLoHi "_src" 32)

  // output pointer
  ldy 0

  // check for a valid filetype (and store icon)
  ldx _tmpEntry.type
  lda typeToIcon, x
  bmi big_loop // unsupported type
  {
    bne __skip
    jmp exit
  __skip:
  }

  sta [_dst], y
  iny
  ora 1
  sta [_dst], y
  iny

  cpx 0xf0
  beq add_separator
  // check load address for 0x0801
  lda _tmpEntry.loadaddress.lo
  cmp 0x01
  bne big_loop
  lda _tmpEntry.loadaddress.hi
  cmp 0x08
  bne big_loop

  // check for load address + size < 0xd000
  lda _tmpEntry.loadaddress.lo
  clc
  adc _tmpEntry.size[0]
  lda _tmpEntry.loadaddress.hi
  adc _tmpEntry.size[1]
  tax
  lda 0
  adc _tmpEntry.size[2]
  bne big_loop // la+s > 0xffff
  cpx 0xd0
  bcs big_loop // la+s > 0xcfff

  // copy filename
  {
    ldx 0
  __loop:
    lda _tmpEntry.name, x
    // check for valid char
    beq __do_space
    cmp 0x20
    bcc __invalid
    cmp 0x7b
    bcc __ok
  __invalid:
    lda 0x60
    bne __ok
  __do_space:
    lda 0x20
  __ok:
    sta [_dst], y
    inx
    iny
    cpx 16 // size(_tmpEntry.name)
    bne __loop
  }

  // add space
  lda 0x20
  sta [_dst], y
  iny

  // add size
  lda _tmpEntry.size[1]
  cmp (1000*1024 >> 8) & 0xff
  lda _tmpEntry.size[2]
  sbc (1000*1024 >> 16) & 0xff
  bcc _show_kib
_show_mib:
  // add mb
  lda _tmpEntry.size[1]
  sta div_var.src1.lo
  lda _tmpEntry.size[2]
  sta div_var.src1.hi
  lda (100*1024 >> 8) & 0xff
  sta div_var.src2.lo
  lda (100*1024 >> 16) & 0xff
  sta div_var.src2.hi
  jsr div16round.run
  ldy 19 -- restore y (killed by div16round)

  // 1s
  ldx 0
mib_1:
  lda div_var.quot.lo
  sec
  sbc 10
  bcc mib_1_x
  sta div_var.quot.lo
  inx
  bpl mib_1
mib_1_x:
  txa
  ora 0x30
  sta [_dst], y
  iny

  // dot
  lda 0x2e
  sta [_dst], y
  iny

  // 1/10th
mib_10:
  lda div_var.quot.lo
  ora 0x30
  sta [_dst], y
  iny

  // add m
  lda 0x6d // 'M'
  sta [_dst], y
  iny

  bne _done_size

_show_kib:

  local byte[3] _kib_show @zp

  // init 0
  lda 0
  -- sta _kib_show[0] -- 1
  sta _kib_show[1] -- 10
  sta _kib_show[2] -- 100

  // tmp space: div_var.rem.lo / div_var.rem.hi for _tmpEntry.size[1] / [2]
  lda _tmpEntry.size[2]
  sta div_var.rem.hi

  // div 1024, round up if required
  lda _tmpEntry.size[1]
  lsr div_var.rem.hi
  ror
  lsr div_var.rem.hi
  ror
  adc 0
  sta div_var.rem.lo
  bcc no_round
  inc div_var.rem.hi
no_round:

  // 100s
kib_100:
  lda div_var.rem.lo
  sec
  sbc 100
  tax
  lda div_var.rem.hi
  sbc (100 >> 8) & 0xff
  bcc kib_10
  stx div_var.rem.lo
  sta div_var.rem.hi
  inc _kib_show[2]
  bpl kib_100

  // 10s
kib_10:
  lda div_var.rem.lo
  sec
  sbc 10
  bcc kib_1
  sta div_var.rem.lo
  inc _kib_show[1]
  bpl kib_10

kib_1:
  lda div_var.rem.lo
  sta _kib_show[0]

  ldx 2
kib_loop:
  lda _kib_show, x
  bne kib_loop_show
  cpx 0
  beq kib_loop_show
kib_loop_space:
  lda 0x20 ^ 0x30
kib_loop_show:
  eor 0x30
  sta [_dst], y
  iny
  dex
  bpl kib_loop

  // add k
  lda 0x4b // 'k'
  sta [_dst], y
  iny

_done_size:
  // add end of line marker
  lda 123
  sta [_dst], y
  iny

copy_file_info:

  // copy file-info
  {
    ldx 0
  __loop:
    lda _tmpEntry.type, x
    sta [_dst], y
    inx
    iny
    cpx 16
    bne __loop
  }

  // increase output pointer
  $(macroAddConstToLoHi "_dst" 40)

  // added a file
  inc numEntries

  jmp big_loop

end
