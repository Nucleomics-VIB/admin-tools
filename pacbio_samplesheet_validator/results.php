<?php
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
      $excelfile = rtrim($_FILES['data']['name']['indexfile']);   
      $target_dir = "uploads/";
      $target_file = $target_dir . $excelfile;
      if (move_uploaded_file($_FILES['data']['tmp_name']['indexfile'], $target_file)){ 
        $command = "scripts/pacbio_samplesheet_validator.sh -s $target_file";
        exec($command, $output, $return);
        $command_string = "Command used is: " . $command . "</br></br>";
        if ($return == 0){
          $output_string = $command_string . "<h2>Validation results:</h2>";
          foreach($output as $line) { $output_string .= $line . "</br>"; }
        } else {
          $output_string = $command_string . "An error occured during validation: </br>";
          foreach($output as $line) { $output_string .= $line . "</br>";} 
        }
      } 
    }
?>    

<html>
 <head>
  <title>PacBio Samplesheet Validator</title>
  <link rel="stylesheet" type="text/css" href="http://gbw-s-nuc04.luna.kuleuven.be:8080/style_template.css">
  <img class="logo" src="http://gbw-s-nuc04.luna.kuleuven.be:8080/images/logo.png" alt="logo">
</head>
<body>
<div class="container">
<h1>PacBio Samplesheet Validator</h1>
<p><?php
  print($output_string);
  ?></p>
<br></br>
<p><a href=<?php echo("http://".$_SERVER["HTTP_HOST"]."/webtools/pacbio_samplesheet_validator/index.php")?>><< Main</a></p>
<p><a href=http://gbw-s-nuc04.luna.kuleuven.be:8080/webtools/Workflow.htm><< Return to Webtools</a></p>
</div>
</body>
</html>
