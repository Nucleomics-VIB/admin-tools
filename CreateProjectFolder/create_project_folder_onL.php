<!--
 // author: Stéphane Plaisance, VIB-NC, 2020-07-20
 // script: 'create_project_folder_onL.php'
 // runs: 'create_project_folder_onL.sh'
 // links to: 'create_project_folder_onL_done.php'
 // version 1.0.0
 // visit our Git: https://github.com/Nucleomics-VIB
-->

<html>
<head>
</head>
<body>

<?php
session_start();

// define variables and set to empty values
$number = $cmd = $result = "";

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

function str_wrap ($string = '', $char = '"'){
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
  $number = test_input($_POST["number"]);
  // build command
  $cmd = "/var/www/cgi-bin/create_project_folder_onL.sh $number";
  $result = shell_exec("$cmd 2>&1");
  $_SESSION['result'] = $result;
  header("Location: http://10.112.84.39/cgi-bin/create_project_folder_onL_done.php" );
}

?>

<h2>Create Project Folder on L:</h2>
<p>Provide a project Number present in the PROJECTS Goggle Sheet, then click Submit</p>

<!--
action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>"
-->

<hr>
<form method="post" action="" method="post">
  <p>Project Number: (max 4-digits) <input name="number" id="number" /> (eg. '3456')</p>
  </br>
  <input type="submit" name="submit" value="Submit" style="font-size:20px";>
</form>

<hr>

<p><i>(version 1.0 SP, 2020_07_13)</i></p>
</body>
</html>
