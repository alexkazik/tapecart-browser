<?php

// basic argument check
if ($argc < 3 || $argc > 4) {
  echo('Usage: '.$argv[0].' <input.txt> <out.tcrt> [<name>]'.PHP_EOL);
  exit(1);
}

// arguments
$file = fopen($argv[1], 'r');
$dir = dirname($argv[1]);
$output = $argv[2];
$name = array_key_exists(3, $argv) ? $argv[3] : 'TAPECART BROWSER';

// the browser (reserve 16k so further browsers versions could be updated in place)
$browser = browser_bin();
$browserPadded = $browser.str_repeat("\xff", 16 * 1024 - strlen($browser));

// all files and data in the FS
$files = [];
$files[] = [ // the browser
  'name'        => 'bROWSER-p1x3lNET',
  'type'        => 0xfe,
  'loadaddress' => "\xff\xff",
  'size'        => strlen($browserPadded),
  'data'        => $browserPadded,
];

// loop over all CSV entries
while ($ln = fgetcsv($file, 0, ';')) {
  if (trim(implode('', $ln)) == '') {
    continue;
  }
  if (count($ln) < 2) {
    echo 'Entry too short: '.implode(';', $ln).PHP_EOL;
    exit(1);
  }
  if (count($ln) >= 3) {
    $type = intval($ln[2], 0);
    if ($type < 0 || ($type > 0xc0 && $type != 0xf0)) {
      $type = 1;
    }
  } else {
    $type = 1;
  }
  if ($type == 0xf0) {
    $files[] = [
      'name'        => trim($ln[1]),
      'type'        => $type,
      'loadaddress' => "\0\0",
      'size'        => 0,
      'data'        => '',
    ];
  } else {
    $sourceFile = $dir.DIRECTORY_SEPARATOR.trim($ln[0]);
    if (!file_exists($sourceFile)) {
      echo 'File not found: '.implode(';', $ln).PHP_EOL;
      exit(1);
    }
    $data = file_get_contents($sourceFile);
    if (!is_string($data) || strlen($data) < 3) {
      echo 'File too short (less than 3 bytes): '.implode(';', $ln).PHP_EOL;
      exit(1);
    }
    $files[] = [
      'name'        => trim($ln[1]),
      'type'        => $type,
      'loadaddress' => substr($data, 0, 2),
      'size'        => strlen($data) - 2,
      'data'        => substr($data, 2),
    ];
  }
}

$fs = "\x02\x10TapcrtFileSys";
$data = ''; // no payload so far
$start = 0x1000; // start after filesystem

foreach ($files as $file) {
  $fs .=
    str_pad(toPetscii(substr($file['name'], 0, 16)), 16, "\x00", STR_PAD_RIGHT).
    chr($file['type']).
    pack('v', $start >> 8).
    substr(pack('V', $file['size']), 0, 3).
    $file['loadaddress'].
    str_repeat("\x00", 8);
  $d = padBlock($file['data']);
  $data .= $d;
  $start += strlen($d);
}

if (strlen($fs) > 0x1000) {
  echo 'Too many entries (max. 126)'.PHP_EOL;
  exit(1);
}

if (strlen(padBlock($fs).$data) > 2 * 1024 * 1024) {
  echo 'Too big (max. 2 MiB)'.PHP_EOL;
  exit(1);
}

file_put_contents(
  $output,
  "tapecartImage\x0d\x0a\x1a".
  pack('v', 1).
  pack('v', 0).
  pack('v', 0x1000 + strlen($browser)).
  pack('v', 0x2800).
  str_pad(substr($name, 0, 16), 16, ' ', STR_PAD_RIGHT).
  "\x00".
  str_repeat("\x00", 171).
  pack('V', 0x1000 + strlen($data)).
  padBlock($fs).
  $data
);

function toPetscii($t) {
  for ($i = 0; $i < strlen($t); $i++) {
    $c = ord($t[$i]);
    if ($c >= 0x41 && $c <= 0x5a) {
      $t[$i] = chr($c + 0x20);
    } elseif ($c >= 0x61 && $c <= 0x7a) {
      $t[$i] = chr($c - 0x20);
    }
  }
  return $t;
}

function padBlock($b) {
  $l = strlen($b) & 0xfff;
  if ($l == 0) {
    return $b;
  } else {
    return $b.str_repeat("\xff", 0x1000 - $l);
  }
}
