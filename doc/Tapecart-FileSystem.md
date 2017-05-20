Tapecart FileSystem
===================

From now on referred to as FS.

For the sake if the FS the cart is divided into 4 KiB (4096 Byte) blocks.

The first block contains the FS.

It is assumed that the erase block size is 4 KiB or less.


Structure
---------

The first 2 Byte can be used by the system for any purpose and must not be changed otherwise.
The following 13 Byte must contain "TapcrtFileSys" in ASCII.

Following that are up to 127 entries of 32 Byte each.

All bytes beyond the last used entry must be filled with 0xff.
(This gurantees that the type of the 128th entry, which is only partially in the block, is the EOF marker.)

All data fields are stored in little endian.

Each entry consists of:

- 16 Byte filename
  - lowercase PETSCII (valid characters: 0x20-0x7f, 0xa0-0xbf)
  - padded with NUL (0x00)
- 1 Byte type (see below)
- 2 Byte start address (lower 4 bits must always be 0)
- 3 Byte size (in Byte)
- 2 Byte load address (see type below)
- 2 Byte bundle compatibility (zero if not a bundle)
- 2 Byte bundle main start (zero if not a bundle)
- 2 Byte bundle main length (zero if not a bundle)
- 2 Byte bundle main call address (zero if not a bundle)

The start address is: `0xHHL000` where only 0xL0 and 0xHH are stored in the FS.
The bytes in the last block after the file are not used. And do not need to be saved in case the file is moved, stored or whatever.

### Type

- 0x00 - 0x3f:
  An program which can be loaded into the C64 and executed.

  The load address from the FS is used (not stored in the file!).
  The load address + size must fit into the C64.
  - 0x00: general program
  - 0x01: game
  - 0x02: utility
  - 0x03: multimedia
  - 0x04: demo
  - 0x05: image
  - 0x06: tune
  - 0x38-0x3f: private use area
- 0x40 - 0x7f:
  A bundled file (see below)
  Same types as 0x00-0x3f (just for a bundle and not a prg)
- 0x80 - 0xef:
  Data files may not displayed by a browser.
  - 0x80: general data
  - 0x81: text file (lower PETSCII)
  - 0x82: koala image
  - 0x83: hires image
  - 0x84: fli image (multicolor)
- 0xf0:
  separator - this name should be displayed just as a separator.
  `size` must be 0, all other info data (start, load address) is undefined
- 0xfe:
  System file!
  This file is (part of) the program that launches at power up.

  No other program should ever rename/delete this file or relocate the blocks.
  (The entry within the FS however can be moved around.
   This may cover the FS itself, but it's not required.)
- 0xff:
  Marker for the first free entry.

All types not mentioned above are reserved.



Bundled Files
-------------

This mode is designed for games that need to load further files or store data like high scores or save games.

It also cen be used for subdirectories.

A bundled file is a TCRT image which can be embedded in others.

See [TCRT Format](https://github.com/ikorb/tapecart/blob/master/doc/TCRT%20Format.md) for details.
