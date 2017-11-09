{-# LANGUAGE FlexibleContexts #-}

module Main where

import           Codec.Compression.BZip
import           Control.Monad
import qualified Data.ByteString.Base64.Lazy as B64
import qualified Data.ByteString.Lazy        as BL
import qualified Data.Text                   as T
import qualified Data.Text.Lazy.IO           as TLIO
import qualified Data.Vector                 as V
import           System.Directory

import           Asm.C64

import           Dir
import           DirConverterAsm
import           DirDisplayAsm
import           Font
import           Input
import           InputAsm
import           LaunchAsm
import           LoadAsm
import           MathAsm
import           Sprites
import           TapecartAsm

vicInit :: [(T.Text, Expr)]
vicInit =
  [ ("sprite", $array
      [ sprPos  sprX         sprY
      , sprPos (sprX+24)     sprY
      , sprPos (sprX+2*24)   sprY
      , sprPos  sprX        (sprY+21)
      , sprPos (sprX+24)    (sprY+21)
      , sprPos (sprX+2*24)  (sprY+21)
      , sprPos (sprX+12)    (sprY+21)
      , sprPos (sprX+12+24) (sprY+21)
      ]
    )
  , ("sprite_x_msb", 0b11110110)
  , ("control1", 0x9b)
  , ("sprite_enable", 0xff)
  , ("control2", 0x08)
  , ("sprite_ydouble", 0x00)
  , ("memory", 0x18)
  , ("sprite_prio", 0xff)
  , ("sprite_mc", 0x00)
  , ("sprite_xdouble", 0x00)
  , ("border_color", $byte black4)
  , ("background_color", $byte black4)
  , ("sprite_color", $array
      [ $byte cyan4
      , $byte cyan4
      , $byte cyan4
      , $byte grey4
      , $byte grey4
      , $byte grey4
      , $byte cyan4
      , $byte cyan4
      ]
    )
  ]
  where
  sprPos :: Int -> Int -> Expr
  sprPos x y = $struct [("x", $byte (x .&. 0xff)), ("y", $byte y)]
  sprX :: Int
  sprX = 24+28*8
  sprY :: Int
  sprY = 50+2*8-1

someConst :: ToArray e => String -> Int -> LabelName -> Int -> [e] -> Asm
someConst labelBase start pool align list =
  concat $ flip map (zip [start..] list) $ \(i, element) ->
    [asm|const byte[] $(labelBase ++ show i) = $[element] @$pool align $align|]

code :: Asm
code = [asm|
  set meta.cpu = #6502
  pool out[font,start,prog,data] = 0x2000
  pool zp = virtual 0x0002
  pool reloc_stack = 0x0110
  pool reloc_0200 = 0x0200

  // place pool reloc_0200 inside the pool data, accessible by the name reloc_0200_data
  const pool reloc_0200_data = reloc_0200 @data
  const pool reloc_stack_data = reloc_stack @data

  $(c64include)

  $block (dirConverter) @prog
  $block (dirDisplay) @prog
  $block (input) @prog
  $block (math) @prog
  $block (tapecart) @prog
  $block (launch) @prog
  $block (load) @reloc_0200

  type struct {
    byte lo;
    byte hi;
  } lohi

  var byte numEntries @zp
  var byte sliderSize @zp
  var byte drawStartLast @zp
  var byte drawStart @zp
  var byte drawOffset @zp
  var lohi sliderPosition @zp
  var lohi sliderPositionIncrease @zp

  const byte[] dirStartPositionsLo = $[dirStartPositionsLo] @data page 256
  const byte[] dirStartPositionsHi = $[dirStartPositionsHi] @data page 256
  const byte[] screenSource = ($[screen] ++ [[unused,unused,unused,unused,unused,unused,unused,unused,unused,unused,unused,unused,unused,unused,unused,unused]] ++ [[addr(sprite0)>>6,addr(sprite1)>>6,addr(sprite2)>>6,addr(sprite3)>>6,addr(sprite4)>>6,addr(sprite5)>>6,addr(sprite6)>>6,addr(sprite7)>>6]]) @data
  const byte[] colorSource = $[colors] @data
  $(someConst "sprite" 0 "data" 64 sprites)
  pointer byte[1024] screen = 0x0400
  const vicType vicInit = fill(${vicInit}, unused) @data

  block @start
    sei
    ldx 255
    txs

    lda 0x37
    sta cpu.port // motor off

    {
    ldx 0
  __loop:
    lda byte(reloc_stack_data, -0x10), x
    sta byte(reloc_stack, -0x10), x
    for i = 0 < size(reloc_0200) += 0x100
      lda byte(reloc_0200_data, i), x
      sta byte(reloc_0200, i), x
    end
    lda byte(screenSource, 0), x
    sta byte(screen, 0), x
    lda byte(screenSource, 0x100), x
    sta byte(screen, 0x100), x
    lda byte(screenSource, 0x200), x
    sta byte(screen, 0x200), x
    lda byte(screenSource, 0x300), x
    sta byte(screen, 0x300), x
    lda byte(colorSource, 0), x
    sta byte(color_memory, 0), x
    lda byte(colorSource, 0x100), x
    sta byte(color_memory, 0x100), x
    lda byte(colorSource, 0x200), x
    sta byte(color_memory, 0x200), x
    lda byte(colorSource, 0x300), x
    sta byte(color_memory, 0x300), x
    inx
    bne __loop
    }

    ldx size(vicInit) - 1
  vi:
    lda vicInit, x
    sta vic, x
    dex
    bpl vi

    jsr dirDisplay.title.do
    jsr dirConverter.run
    jsr dirDisplay.run
    jsr input.init
    jmp main.run
  end

  block main @prog
  run:
    jsr input.getKey
    beq run

    cmp $keyF2
    beq goBasic

    // if no enties -> don't move
    ldx numEntries
    beq run

    cmp $keyCsrUp
    beq moveUp
    cmp $keyCsrDwn
    beq moveDown
    cmp $keyCsrLft
    beq pageUp
    cmp $keyCsrRgt
    beq pageDown
    cmp $keyReturn
    bne run
    jmp launch.run

  moveUp:
    dec drawOffset
    jmp draw_screen

  moveDown:
    inc drawOffset
    jmp draw_screen

  pageUp:
    lda drawOffset
    sec
    sbc 23
    sta drawOffset
    jmp draw_screen

  pageDown:
    lda drawOffset
    clc
    adc 23
    sta drawOffset
    //  jmp draw_screen

  draw_screen:
    jsr dirDisplay.run
    jmp run

  goBasic:
    jmp [cpu.vector.reset]
  end

  var byte[] typeToIcon = $[typeToIcon] @data align 256

  const byte[] __font = $[font] @font
|]

main :: IO ()
main = do
  let
    cr = compile code
  createDirectoryIfMissing False $(getRelativeFilePath "build")
  TLIO.writeFile $(getRelativeFilePath "build/browser.vs") (generateViceSybols cr)
  TLIO.writeFile $(getRelativeFilePath "build/browser.status") (crDumpState cr)
  print (crPoolsStats cr)
  forM_ (lookup "out" (crPoolsWithData cr)) $ \(_start,poolData) -> do
    let
      browser_bin = BL.pack $ V.toList (fmap (final 0xff) poolData)
    BL.writeFile
      $(getRelativeFilePath "build/browser.bin")
      browser_bin
    BL.writeFile
      $(getRelativeFilePath "build/tcrt-bundler.php")
      (
        BL.fromStrict $(embedFile "./tcrt-bundler_src.php") `BL.append`
        "\nfunction browser_bin(){ return bzdecompress(base64_decode('" `BL.append`
        B64.encode (compress browser_bin) `BL.append`
        "')); }\n"
      )
