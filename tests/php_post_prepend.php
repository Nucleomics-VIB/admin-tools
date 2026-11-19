<?php
// author: Stéphane Plaisance, VIB-NC, 2026-11-19
// script: 'php_post_prepend.php' (version 1.0)
// used by php_pages_test.sh as auto_prepend_file: make the page see a POST request (#12)
// FIELD names the form field that gets PAYLOAD; every other field keeps a valid value
// UPLOAD is a local file that stands for the uploaded file
// visit our Git: https://github.com/Nucleomics-VIB

$_SERVER["REQUEST_METHOD"] = "POST";
$_POST = array("number" => "1234", "size" => "", "type" => "", "text" => "edit text", "copies" => "1", "darkness" => "0");
$_FILES = array("fileToUpload" => array("name" => "labels.txt", "tmp_name" => getenv("UPLOAD")));
if (getenv("FIELD") == "upload_name") {
  $_POST["type"] = " -F";
  $_FILES["fileToUpload"]["name"] = getenv("PAYLOAD");
} else {
  $_POST[getenv("FIELD")] = getenv("PAYLOAD");
}
