<!--
 // author: Stéphane Plaisance, VIB-NC
 // script: 'print_custom_labels.php'
 // runs: 'print_custom_labels.sh'
 // version 1.2, 2026-11-19: each field is checked against an allow-list and escaped (#12)
 // needs PHP 8.2.35 or newer (#11)
 // visit our Git: https://github.com/Nucleomics-VIB
-->

<html>
<head>
<title>Print Zebra labels</title>
</head>
<body>

<?php
// define variables and set to empty values
$cmd = $message = $text = $size = $type = $copies = "";

function startsWith ($string, $startString){
    $len = strlen($startString);
    return (substr($string, 0, $len) === $startString);
}

// all lines for a normal text label, else only the first line with '_' for spaces
function textLines ($input, $size, $type){
  $arr = explode("\n", $input);
  if (($type == '') && ($size == '')) {
    return array_map('trim', $arr);
  }
  return array(str_replace(' ', '_', trim($arr[0])));
}

// check each field against an allow-list and escape each value (#12)
// return the command, or null when a field is not valid
function build_cmd ($post){
  $size = trim($post["size"] ?? "");
  $type = trim($post["type"] ?? "");
  $copies = trim($post["copies"] ?? "");
  $darkness = trim($post["darkness"] ?? "");
  if (!in_array($size, array("", "-M", "-B"), true)
    || !in_array($type, array("", "-b", "-x"), true)
    || !preg_match('/^[0-9]{1,2}$/', $copies) || (int)$copies < 1 || (int)$copies > 10
    || !preg_match('/^-?[0-9]{1,2}$/', $darkness) || (int)$darkness < -15 || (int)$darkness > 15) {
    return null;
  }
  $cmd = "/var/www/cgi-bin/print_custom_labels.sh";
  if ($size != "") $cmd .= " $size";
  if ($type != "") $cmd .= " $type";
  foreach (textLines($post["text"] ?? "", $size, $type) as $line) {
    $cmd .= " -t ".escapeshellarg($line);
  }
  return $cmd." -c ".escapeshellarg($copies)." -d ".escapeshellarg($darkness);
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
  $cmd = build_cmd($_POST);
  if ($cmd === null) {
    echo "<h2>Not printed: a field has a value that is not allowed</h2>";
  } else {
    // run it
    $message = shell_exec("$cmd");
    header("Location: http://10.112.84.39/cgi-bin/print_custom_labels_done.php");
    // echo "<h2>$message</h2>";
  }
}

?>

<h2>Custom labels on Zebra</h2>
<p>Define the number of lines of text, the font size, and even the type of label (text/barcode or numerical BC), and submit</p>
<p><i>(version 1.2 SP, 2026_11_19)</i></p>

<form method="post" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>">
  <input type="reset" style="font-size:20px";>
  <hr>
  <h4>Text: (max 12 char and 5 lines)</h4>
  <textarea rows="5" cols="" name="text">edit text</textarea>
  <br>
  <h4>Size: (only first line is printed for Medium and Large)</h4>
  <input type="radio" name="size" checked="checked"
  <?php if (isset($size) && $size=="normal") echo "checked";?>
  value="">Normal
  <input type="radio" name="size"
  <?php if (isset($size) && $size=="medium") echo "checked";?>
  value=" -M">Medium
  <input type="radio" name="size"
  <?php if (isset($size) && $size=="large") echo "checked";?>
  value=" -B">Large
  <br>
  <h4>Type: (only first line is printed for barcode types)</h4>
  <input type="radio" name="type" checked="checked"
  <?php if (isset($type) && startsWith($type, "Text")) echo "checked";?>
  value="">Text label
  <input type="radio" name="type"
  <?php if (isset($type) && startsWith($type, "numeric")) echo "checked";?>
  value=" -b">numeric barcode
  <input type="radio" name="type"
  <?php if (isset($type) && startsWith($type, "ASCCI")) echo "checked";?>
  value=" -x">ASCCI ([0-9][A-Z]-.$/+% ) barcode
  <br>
  <h4>Copies: (max 10 for your own safety :-))</h4>
  <input type="number" name="copies" min="1" max="10" value=1>
  <br>
  <h4>Darkness: (value between -15 and 15)</h4>
  <input type="number" name="darkness" min="-15" max="15" value=0>
  <br><br>
  <hr>
  <input type="submit" name="submit" value="Submit" style="font-size:20px";>
</form>
</body>
</html>
