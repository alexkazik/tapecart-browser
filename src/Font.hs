module Font
  ( font
  , screen
  , colors
  , charSliderTop
  , charSliderBefore
  , charSliderMiddle
  , charSliderAfter
  , charSliderBottom
  , colorSliderOff
  , colorSliderOn
  ) where

import           Data.Bool              (bool)
import           Data.Char              (chr, isAsciiLower, isAsciiUpper, ord)
import           Data.Traversable       (mapAccumL)
import qualified Data.Vector.Unboxed    as UV
import           Data.Version           (versionBranch)
import           Text.Heredoc           (here)

import           Asm.C64

import qualified Paths_tapecart_browser as CabalInfo
import           Tapecart

font :: UV.Vector Word8
font = withSlicesOf 8 8 (snd . render1BitWidth [(black8, 0xf0 .|. 1)] 0) $(imageWithUpdate "graphics/font.png")

colorSliderOff, colorSliderOn :: TInt64
colorSliderOff = green4
colorSliderOn = lightGreen4

charSliderBefore, charSliderTop, charSliderMiddle, charSliderBottom, charSliderAfter :: Word8
charSliderBefore = 128+3
charSliderTop = 128+0
charSliderMiddle = 128+1
charSliderBottom = 128+2
charSliderAfter = 128+3

convertChar :: Bool -> Char -> (Bool, Word8)
convertChar isIverted char

  {- Top row
  -}

  | char == '┌' = (True, 0) -- window
  | char == '╶' = (True, 1)
  | char == '┐' = (True, 2)
  | char == '╵' = (False, 3)
  | char == '│' = (False, 4)
  | char == '└' = (True, 5)
  | char == '─' = (True, 6)
  | char == '┘' = (True, 7)
  | char == '╯' = (True, 8)

  | char == '[' = (True, 9) -- F1
  | char == ']' = (True, 10)
  | char == '↓' = (True, 11) -- arrows
  | char == '↑' = (True, 12)
  | char == '←' = (True, 13)
  | char == '→' = (True, 14)
  | char == '<' = (True, 15) -- start/end inversion
  | char == '=' = (True, 16)
  | char == '>' = (False, 17)

  {- Bottom row
  -}

  -- slider is missing here since it's not used in the screen
  | char == '╷' = (False, 128 + 3) -- no slider here

  | char == '╔' = (False, 128 + 4) -- logo border
  | char == '╗' = (False, 128 + 5)
  | char == '╚' = (False, 128 + 6)
  | char == '═' = (False, 128 + 7)
  | char == '╝' = (False, 128 + 8)
  | char == 'ä' = (False, 128 + 9) -- logo anti alias
  | char == 'Ä' = (False, 128 + 10)

  | char >= '🄰' && char <= '🄵' = (False, fromIntegral $ 128 + 11 + ord char - ord '🄰') -- PXL.NET

  {- Other chars
  -}

  -- joystick icon
  | char == '{' = (False, 126)
  | char == '}' = (False, 127)

  -- all letters and other ascii chars
  | isAsciiUpper char || isAsciiLower char
    = (isIverted, fromIntegral $ bool 0 128 isIverted + (ord char `xor` 0x20))
  | otherwise = (isIverted, fromIntegral $ bool 0 128 isIverted + ord char)

version :: String
version = case versionBranch CabalInfo.version of
  []      -> ['?', delm, '?', ' ']
  [a]     -> [v a, delm, '?', ' ']
  [a,b]   -> [v a, delm, v b, ' ']
  [_,_,0] -> "BETA"
  [a,b,c] -> [v a, delm, v b, v' c]
  (a:b:_) -> [v a, delm, v b, '?']
  where
    v n
      | n >= 0 && n <= 9 = chr (0x30 + n)
      | n >= 10 && n <= 10+25 = chr (0x41 + n - 10)
      | otherwise = '?'
    v' n
      | n >= 1 && n <= 4 = chr (0x12 + n - 1)
      | n >= 5 && n <= 9 = chr (0x91 + n - 5)
      | otherwise = '?'
    delm = bool '.' ',' fakeTapecart

screen :: [Word8]
screen = snd $ mapAccumL convertChar False $ showVersion $ filter (/= '\n') screenSource
  where
    showVersion sc =
      let
        (a,b) = splitAt (1000-85) sc
      in
        a ++ version ++ drop 4 b
    screenSource =
      [here|
┌ ╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶┐ Info ╶╶╶╶╶╶╶┐
╵                        ╷             │
╵                        ╷  ╔───────╗  │
╵                        ╷  │  ä    ╵  │
╵                        ╷  │       ╵  │
╵                        ╷  │  Ä    ╵  │
╵                        ╷  │       ╵  │
╵                        ╷  ╚═══════╝  │
╵                        ╷             │
╵                        ╷ Line scroll │
╵                        ╷ CRSR/{}<↓=↑>│
╵                        ╷ or<F5=F7>   │
╵                        ╷             │
╵                        ╷ Page scroll │
╵                        ╷ CRSR/{}<←=→>│
╵                        ╷ or<F6=F8>   │
╵                        ╷             │
╵                        ╷ Run program │
╵                        ╷ []=RET=FIRE>│
╵                        ╷             │
╵                        ╷ Quit<F2>    │
╵                        ╷             │
╵                        ╷ Browser X.YZ│
╵                        ╷ by 🄰🄱🄲🄳🄴🄵   │
└────────────────────────╯─────────────┘
|]


colors :: [TInt64]
colors =
     colorTopBot
  ++ concat (replicate 2 colorLogo1)
  ++ concat (replicate 2 colorLogo2)
  ++ concat (replicate 2 colorLogo3)
  ++ concat (replicate 1 colorLogo1)
  ++ concat (replicate 3 (concat (replicate 2 colorHelpCyan ++ replicate 2 colorHelpLightBlue)))
  ++ colorHelpCyanLightBlue
  ++ colorHelpCyan
  ++ colorHelpLightBlue
  ++ colorHelpLightBlueCyan
  ++ colorTopBot
  where
    colorTopBot = replicate 26 green4 ++ replicate 14 blue4
    colorLogo1 = [green4] ++ colorList ++ [green4] ++ replicate 13 purple4 ++ [blue4]
    colorLogo2 = [green4] ++ colorList ++ [green4] ++ replicate 3 purple4 ++ replicate 7 blue4 ++ replicate 3 purple4 ++ [blue4]
    colorLogo3 = [green4] ++ colorList ++ [green4] ++ replicate 3 purple4 ++ replicate 7 darkGrey4 ++ replicate 3 purple4 ++ [blue4]
    colorHelpLightBlue = [green4] ++ colorList ++ [green4] ++ replicate 13 lightBlue4 ++ [blue4]
    colorHelpCyan = [green4] ++ colorList ++ [green4] ++ replicate 13 cyan4 ++ [blue4]
    colorHelpCyanLightBlue = [green4] ++ colorList ++ [green4] ++ replicate 5 cyan4 ++ replicate 8 lightBlue4 ++ [blue4]
    colorHelpLightBlueCyan = [green4] ++ colorList ++ [green4] ++ replicate 4 lightBlue4 ++ replicate 9 cyan4 ++ [blue4]
    colorList = [cyan4, cyan4] ++ replicate 17 lightGreen4 ++ [cyan4, cyan4, cyan4, cyan4, cyan4]
