module Input
  ( keyTableNoShift
  , keyTableWithShift
  , keyCsrUp
  , keyCsrDwn
  , keyCsrLft
  , keyCsrRgt
  , keyReturn
  , keyF2
  ) where

import           Asm.C64

keyCsrDwn, keyCsrLft, keyCsrRgt, keyCsrUp :: Word8
keyCsrDwn = 8
keyCsrLft = 14
keyCsrRgt = 3
keyCsrUp = 19

keyF1, keyF2, keyF3, keyF4, keyF5, keyF6, keyF7, keyF8 :: Word8
keyF1 = keyReturn
keyF2 = 16
keyF3 = 6
keyF4 = 17
keyF5 = keyCsrUp
keyF6 = keyCsrLft
keyF7 = keyCsrDwn
keyF8 = keyCsrRgt

keyDel, keyIns, keyHome, keyClr, keyStop, keyRun :: Word8
keyDel = 1
keyIns = 13
keyHome = 9
keyClr = 20
keyStop = 12
keyRun = 23

keyCtrl, keyMeta, keyShftCtrl, keyShftMeta :: Word8
keyCtrl = 10
keyMeta = 11
keyShftCtrl = 21
keyShftMeta = 22

keyReturn :: Word8
keyReturn = 2

{-
                               Port B - 0xDC01
              +-----+-----+-----+-----+-----+-----+-----+-----+
              |Bit 7|Bit 6|Bit 5|Bit 4|Bit 3|Bit 2|Bit 1|Bit 0|
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 7| R/S |  Q  |  C= |SPACE|  2  | CTRL|A_LFT|  1  |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 6|  /  | A_UP|  =  | S_R | HOME|  ;  |  *  |POUND|
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 5|  ,  |  @  |  :  |  .  |  -  |  L  |  P  |  +  |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 4|  N  |  O  |  K  |  M  |  0  |  J  |  I  |  9  |
 Port A +-----+-----+-----+-----+-----+-----+-----+-----+-----+
 0xDC00 |Bit 3|  V  |  U  |  H  |  B  |  8  |  G  |  Y  |  7  |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 2|  X  |  T  |  F  |  C  |  6  |  D  |  R  |  5  |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 1| S_L |  E  |  S  |  Z  |  4  |  A  |  W  |  3  |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 0|C_U/D|  F5 |  F3 |  F1 |  F7 |C_L/R|  CR | DEL |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
-}

keyTableNoShift :: [Word8]
keyTableNoShift =
  [ keyDel, keyReturn, keyCsrRgt, keyF7, keyF1, keyF3, keyF5, keyCsrDwn
  , 0x33, 0x57, 0x41, 0x34, 0x5a, 0x53, 0x45, 0    -- no SHIFT
  , 0x35, 0x52, 0x44, 0x36, 0x43, 0x46, 0x54, 0x58
  , 0x37, 0x59, 0x47, 0x38, 0x42, 0x48, 0x55, 0x56
  , 0x39, 0x49, 0x4a, 0x30, 0x4d, 0x4b, 0x4f, 0x4e
  , 0x2b, 0x50, 0x4c, 0x2d, 0x2e, 0x3a, 0x40, 0x2c
  , 0x5c, 0x2a, 0x3b, home, 0,    0x3d, 0x5e, 0x2f -- no SHIFT
  , 0x31, 0x5f, ctl,  0x32, 0x20, mta,  0x51, stop
  ]
  where
    home = keyHome
    ctl = keyCtrl
    mta = keyMeta
    stop = keyStop

keyTableWithShift :: [Word8]
keyTableWithShift =
  [ keyIns, keyReturn, keyCsrLft, keyF8, keyF2, keyF4, keyF6, keyCsrUp -- shifted RETURN = RETURN
  , 0x23, 0x77, 0x61, 0x24, 0x7a, 0x73, 0x65, 0    -- no shifted SHIFT
  , 0x25, 0x72, 0x64, 0x26, 0x63, 0x66, 0x74, 0x78
  , 0x27, 0x79, 0x67, 0x28, 0x62, 0x68, 0x75, 0x76
  , 0x29, 0x69, 0x6a, 0x30, 0x6d, 0x6b, 0x6f, 0x6e
  , 0,    0x70, 0x6c, 0,    0x3e, 0x5b, 0,    0x3c -- no shifted +,-,@
  , 0,    0,    0x5d, clr , 0,    0,    0,    0x3f -- no shifted POUND,*,SHIFT,=,A_UP
  , 0x21, 0,    sCtl, 0x22, 0x20, sMta, 0x71, run  -- no shifted A_LEFT
  ]
  where
    clr = keyClr
    sCtl =keyShftCtrl
    sMta = keyShftMeta
    run = keyRun
