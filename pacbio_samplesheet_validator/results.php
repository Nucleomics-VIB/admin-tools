<?php
    $output_string = "";
    $cleaned_file = "";
    $error_message = "";
    // Use absolute path for uploads directory
    $uploads_dir = "/var/www/html/uploads/";
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
      $excelfile = rtrim($_FILES['data']['name']['indexfile']);   
      $target_file = $uploads_dir . $excelfile;
      if (move_uploaded_file($_FILES['data']['tmp_name']['indexfile'], $target_file)){ 
        $command = "scripts/pacbio_samplesheet_cleaner.sh -s $target_file";
        exec($command, $output, $return);
        if ($return == 0){
          // Find cleaned file path in output
          foreach($output as $line) {
            if (strpos($line, "Cleaned file saved as") !== false) {
              $cleaned_file = trim(str_replace("Cleaned file saved as", "", $line));
              // Only use if it ends with .csv
              if (substr($cleaned_file, -4) !== '.csv') {
                $cleaned_file = '';
              }
            }
            if (strpos($line, "Error: Cleaned file could not be saved") !== false) {
              $error_message = $line;
            }
          }
        } else {
          $error_message = "An error occured during cleaning.";
        }
      } else {
        $error_message = "Error: Could not move uploaded file.";
      }
    }
?>    

<html>
 <head>
  <title>PacBio Samplesheet Cleaner</title>
  <link rel="stylesheet" type="text/css" href="http://gbw-s-nuc04.luna.kuleuven.be:8080/style_template.css">
  <img class="logo" src="http://gbw-s-nuc04.luna.kuleuven.be:8080/images/logo.png" alt="logo">
</head>
<body>
<div class="container">
<h1>PacBio Samplesheet Cleaner</h1>
<?php if ($error_message) { ?>
  <div style="color:red;"><b><?php echo $error_message; ?></b></div>
<?php } ?>
<?php if ($cleaned_file && file_exists($cleaned_file)) { ?>
  <?php $cleaned_file_url = '/uploads/' . basename($cleaned_file); ?>
  <div><b>Cleaned file:</b> <?php echo basename($cleaned_file); ?></div>
  <br><a href="<?php echo $cleaned_file_url; ?>" download><button>Download Cleaned File</button></a>
<?php } ?>
<br></br>
<p><a href=<?php echo("http://".$_SERVER["HTTP_HOST"]."/cgi-bin/pacbio_samplesheet_validator/index.php")?>><< Submit Other</a></p>
<p><a href=<?php echo("http://".$_SERVER["HTTP_HOST"]."/webtools/pacbio_samplesheet_validator/index.php")?>><< Main</a></p>
<p><a href=http://gbw-s-nuc04.luna.kuleuven.be:8080/webtools/Workflow.htm><< Return to Webtools</a></p>
</div>
</body>
</html>
