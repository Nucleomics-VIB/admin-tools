<?php
// author: Stéphane Plaisance, VIB-NC, 2026-11-19
// script: 'php_pages_cases.php' (version 1.0)
// usage: php tests/php_pages_cases.php <page.php>
// load the page as a GET request, then check the command that build_cmd() makes (#12)
// a value that is not allowed must give null; every other value must be escaped
// visit our Git: https://github.com/Nucleomics-VIB

$page = $argv[1];
$_SERVER["REQUEST_METHOD"] = "GET";
ob_start();
include $page;
ob_end_clean();

$fails = 0;
function check ($label, $got, $want) {
  global $fails;
  if ($got === $want) {
    echo "ok   $label\n";
  } else {
    $fails++;
    echo "FAIL $label\n     got:  ".var_export($got, true)."\n     want: ".var_export($want, true)."\n";
  }
}

// the default values of the label forms
function form ($change) {
  return array_merge(array("size" => "", "type" => "", "text" => "edit text", "copies" => "1", "darkness" => "0"), $change);
}

switch (basename($page)) {

case "create_project_folder_onL.php":
  $sh = "/var/www/cgi-bin/create_project_folder_onL.sh";
  check("4 digits", build_cmd(array("number" => "3456")), "$sh '3456'");
  check("1 digit with spaces", build_cmd(array("number" => " 7 ")), "$sh '7'");
  foreach (array("", "12345", "abc", "1;id", "1 2", '$(id)', "`id`", "1\nid") as $bad) {
    check("refuse number ".json_encode($bad), build_cmd(array("number" => $bad)), null);
  }
  check("refuse missing number", build_cmd(array()), null);
  break;

case "print_custom_labels.php":
case "print_custom_labels_slims.php":
  $slims = basename($page) == "print_custom_labels_slims.php";
  $sh = $slims ? "/var/www/cgi-bin/print_custom_labels_slims.sh" : "/var/www/cgi-bin/print_custom_labels.sh";
  $dark = $slims ? "8" : "-3";
  check("two text lines", build_cmd(form(array("text" => "line one\r\nline two"))),
    "$sh -t 'line one' -t 'line two' -c '1' -d '0'");
  check("medium font, first line only", build_cmd(form(array("size" => " -M", "text" => "big text\r\nnot printed", "copies" => "2", "darkness" => $dark))),
    "$sh -M -t 'big_text' -c '2' -d '$dark'");
  check("ASCII barcode keeps \$", build_cmd(form(array("type" => " -x", "text" => 'AB$12'))),
    "$sh -x -t 'AB\$12' -c '1' -d '0'");
  check("quote in text", build_cmd(form(array("text" => "it's"))),
    "$sh -t 'it'\\''s' -c '1' -d '0'");
  check("shell code in text stays text", build_cmd(form(array("text" => "\$(id)\n`id`;id"))),
    "$sh -t '\$(id)' -t '`id`;id' -c '1' -d '0'");
  $max = $slims ? "35" : "10";
  check("copies $max", build_cmd(form(array("copies" => $max))), "$sh -t 'edit text' -c '$max' -d '0'");
  check("darkness 15", build_cmd(form(array("darkness" => "15"))), "$sh -t 'edit text' -c '1' -d '15'");
  $bad = array(
    array("type" => "; id;"), array("type" => " -b; id"), array("type" => "-t"),
    array("size" => "-M -t x"), array("size" => "normal"),
    array("copies" => "0"), array("copies" => $slims ? "36" : "11"), array("copies" => "1;id"), array("copies" => ""),
    array("darkness" => "16"), array("darkness" => "-16"), array("darkness" => "a"), array("darkness" => "0 -c 9"),
  );
  if ($slims) {
    $bad[] = array("darkness" => "-1");
  } else {
    $bad[] = array("type" => " -F");
  }
  foreach ($bad as $change) {
    check("refuse ".json_encode($change), build_cmd(form($change)), null);
  }
  if ($slims) {
    check("from file", build_cmd(form(array("type" => " -F")), "uploads/a.csv"),
      "$sh -c '1' -d '0' -F 'uploads/a.csv'");
    check("refuse from file without a file", build_cmd(form(array("type" => " -F"))), null);
  } else {
    check("darkness -15", build_cmd(form(array("darkness" => "-15"))), "$sh -t 'edit text' -c '1' -d '-15'");
  }
  break;

default:
  echo "no cases for $page\n";
  exit(2);
}

exit($fails == 0 ? 0 : 1);
