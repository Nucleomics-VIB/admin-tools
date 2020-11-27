<html>
<head>
</head>
<body>

<?php
// define variables and set to empty values
$cmd = $message = $text = $size = $type = $copies = "";

function test_input ($data) {
  // $data = trim($data);
  //$data = stripslashes($data);
  $data = htmlspecialchars($data);
  //$data = str_replace(' ', '_', $data);
  return $data;
}

function startsWith ($string, $startString){
    $len = strlen($startString);
    return (substr($string, 0, $len) === $startString);
}

function str_wrap ($string = '', $char = '"')
{
    return str_pad($string, strlen($string) + 2, $char, STR_PAD_BOTH);
}

function concatText ($input){
  $result = '';
  $arr = explode("\n", $input);
  if (($_POST["type"] == '') && ($_POST["size"] == '')) {
    foreach ($arr as &$text) {
      $result .= ' -t '.str_wrap(trim($text));
      }
    } else {
    $result .= ' -t '.str_wrap(str_replace(' ', '_', trim($arr[0])));
  }
  unset($text);
  return $result;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
  $size = test_input($_POST["size"]);
  $type = $_POST["type"];
  $text = concatText($_POST["text"]);
  $copies = test_input($_POST["copies"]);
  $darkness = test_input($_POST["darkness"]);
  // print it
  $cmd = "/var/www/cgi-bin/print_custom_labels.sh $size $type $text -c $copies -d $darkness";
  // run it
  $message = shell_exec("$cmd");
  header("Location: http://10.112.84.39/cgi-bin/print_custom_labels_done.php");
  // echo "<h2>$message</h2>";
}

?>

<h2>Custom labels on Zebra</h2>
<p>Define the number of lines of text, the font size, and even the type of label (text/barcode or numerical BC), and submit</p>
<p><i>(version 1.1 SP, 2020_11_23)</i></p>

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
