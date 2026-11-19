<!--
 // author: Stéphane Plaisance, VIB-NC (version 1.3 by TS)
 // script: 'print_custom_labels_slims.php'
 // runs: 'print_custom_labels_slims.sh'
 // version 1.4, 2026-11-19: each field is checked against an allow-list and escaped (#12)
 // needs PHP 8.2.35 or newer (#11)
 // visit our Git: https://github.com/Nucleomics-VIB
-->

<html>
<head>
<title>Print Altec labels</title>
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
// $upload_file is the file built by this page for the type '-F'
function build_cmd ($post, $upload_file = null){
  $size = trim($post["size"] ?? "");
  $type = trim($post["type"] ?? "");
  $copies = trim($post["copies"] ?? "");
  $darkness = trim($post["darkness"] ?? "");
  if (!in_array($size, array("", "-M", "-B"), true)
    || !in_array($type, array("", "-b", "-x", "-F"), true)
    || !preg_match('/^[0-9]{1,2}$/', $copies) || (int)$copies < 1 || (int)$copies > 35
    || !preg_match('/^[0-9]{1,2}$/', $darkness) || (int)$darkness > 15) {
    return null;
  }
  $cmd = "/var/www/cgi-bin/print_custom_labels_slims.sh";
  if ($type == "-F") {
    if ($upload_file === null) {
      return null;
    }
    return $cmd." -c ".escapeshellarg($copies)." -d ".escapeshellarg($darkness)." -F ".escapeshellarg($upload_file);
  }
  if ($size != "") $cmd .= " $size";
  if ($type != "") $cmd .= " $type";
  foreach (textLines($post["text"] ?? "", $size, $type) as $line) {
    $cmd .= " -t ".escapeshellarg($line);
  }
  return $cmd." -c ".escapeshellarg($copies)." -d ".escapeshellarg($darkness);
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
  $upload_file = null;
  if (trim($_POST["type"] ?? "") == "-F") {
    // accept only a csv or text file; this page makes the file name (#12)
    $htmlID = $_FILES["fileToUpload"]["tmp_name"] ?? "";
    $extension = strtolower(pathinfo($_FILES["fileToUpload"]["name"] ?? "", PATHINFO_EXTENSION));
    $file_info = new finfo(FILEINFO_MIME_TYPE);
    $upload_file = 'uploads/print_custom_labels_slims_' . date("ymdHis") . '.' . $extension;
    if ($htmlID == ""
      || !in_array($extension, array("csv", "txt"), true)
      || !in_array($file_info->file($htmlID), array("text/csv", "text/plain"), true)
      || !move_uploaded_file($htmlID, $upload_file)) {
      header('Location: http://10.112.84.39/cgi-bin/print_custom_labels_slims_error.php');
      exit;
    }
  }
  $cmd = build_cmd($_POST, $upload_file);
  if ($cmd === null) {
    echo "<h2>Not printed: a field has a value that is not allowed</h2>";
  } else {
    // run it
    $message = shell_exec("$cmd");
    header("Location: http://10.112.84.39/cgi-bin/print_custom_labels_done_slims.php");
  }
}

?>

<h2>Custom labels on Altec</h2>
<p>Define the number of lines of text, the font size, and even the type of label (text/barcode or numerical BC), and submit</p>
<p><i>(version 1.4 SP, 2026_11_19 - version 1.3 by TS, original from SP)</i></p>

<img src="http://10.112.84.39/pictures/400px-Zebra_labels.png" />

<form method="post" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>" enctype="multipart/form-data">
  <input type="reset" style="font-size:14px";>
  <hr>
  <h4>Text: (max 21 char and 5 lines)</h4>
  <textarea rows="5" cols="21" name="text">edit text</textarea>
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
  <input type="radio" name="type"
  <?php if (isset($type) && startsWith($type, "From")) echo "checked";?>
  value=" -F">From File
  <br>
  <h4>Copies: (max 35 for your own safety :-))</h4>
  <input type="number" name="copies" min="1" max="35" value=1>
  <br>
  <h4>Darkness: (value between 0 and 15)</h4>
  <input type="number" name="darkness" min="0" max="15" value=8>
  <br>
  <h4>Import file:</h4>
  <input type="file" name="fileToUpload" id="fileToUpload"/>
  <br><br>
  <hr>
  <input type="submit" name="submit" value="Submit" style="font-size:14px";>
</form>
</body>
</html>