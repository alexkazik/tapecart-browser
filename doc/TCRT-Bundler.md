TCRT-Bundler
============

This small tool takes a brunch of files and bundles them together with a browser in
a TCRT image.


Usage
-----

`php tcrt_bundler.php <input.txt> <out.tcrt> [<name>]`


`input.txt`: Contains the list of files to include in the image (see below)

`out.tcrt`: The image to create

`name`: The name of the cartridge, defaults to `TAPECART BROWSER` (max 16 chars, ASCII only)


Input format
------------

`filename;displayname[;type[;comment]]`

`filename`: The filename, has to be in the same directory as the txt file (or relaitve to)

`displayname`: the name to be shown in the browser (max. 16 chars, ascii only)

`type`: the type of the entry, "game" if omitted (see TapCrtFs.md for details) can be entered in decimal or hex (with prefixed `0x`)

`comment`: not used at all


Example:

    MR DO.PRG;Mr. Do
    Paradroid_Redux_CE.prg;Paradroid Redux;0x01;could have omitted 0x01 since it's the default
