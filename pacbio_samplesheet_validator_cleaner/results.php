<?php
    // Handle file download requests
    if (isset($_GET['download'])) {
        $filename = basename($_GET['download']); // Sanitize filename
        $script_dir = dirname(__FILE__);
        $uploads_dir = $script_dir . "/uploads/";
        $filepath = $uploads_dir . $filename;

        // Security check: ensure file is in uploads directory and exists
        if (realpath($filepath) && strpos(realpath($filepath), realpath($uploads_dir)) === 0 && file_exists($filepath)) {
            header('Content-Type: application/csv');
            header('Content-Disposition: attachment; filename="' . $filename . '"');
            header('Content-Length: ' . filesize($filepath));
            header('Pragma: public');
            header('Cache-Control: public, must-revalidate');
            readfile($filepath);
            exit;
        } else {
            http_response_code(404);
            echo "Error: File not found or access denied.";
            exit;
        }
    }

    $output_string = "";
    $cleaned_file = "";
    $error_messages = array();
    $warning_messages = array();
    $success_message = "";
    $report_lines = array();

    // Use absolute path for uploads directory (in the app folder, not HTML folder)
    $script_dir = dirname(__FILE__);
    $uploads_dir = $script_dir . "/uploads/";

    if ($_SERVER["REQUEST_METHOD"] == "POST") {
      // Validate file upload
      if (!isset($_FILES['data']['tmp_name']['indexfile']) || empty($_FILES['data']['tmp_name']['indexfile'])) {
        $error_messages[] = "Error: No file was uploaded.";
      } else {
        $excelfile = rtrim($_FILES['data']['name']['indexfile']);

        // Validate file extension
        if (substr($excelfile, -4) !== '.csv') {
          $error_messages[] = "Error: File must be a CSV file (.csv extension required).";
        } else {
          $target_file = $uploads_dir . $excelfile;

          // Move uploaded file
          if (move_uploaded_file($_FILES['data']['tmp_name']['indexfile'], $target_file)) {
            // Execute the validation and cleaning script
            $command = "scripts/pacbio_samplesheet_validate_and_clean.sh -s $target_file";
            exec($command, $output, $return);

            // Parse script output
            $in_errors = false;
            $in_warnings = false;
            $in_data = false;

            foreach($output as $line) {
              $line = trim($line);

              // Skip hidden marker line
              if (strpos($line, "OUTPUT_FILE_PATH:") !== false) {
                continue;
              }

              // Check for section headers
              if (strpos($line, "=== VALIDATION FAILED ===") !== false) {
                $in_errors = true;
                $in_warnings = false;
                continue;
              }

              if (strpos($line, "=== VALIDATION AND CLEANING REPORT ===") !== false) {
                $in_errors = false;
                $in_warnings = false;
                $in_data = true;
                continue;
              }

              // Parse errors section
              if (strpos($line, "ERRORS:") !== false) {
                $in_errors = true;
                $in_warnings = false;
                continue;
              }

              // Parse warnings section
              if (strpos($line, "WARNINGS:") !== false) {
                $in_warnings = true;
                $in_errors = false;
                continue;
              }

              // Skip empty lines
              if (empty($line)) {
                continue;
              }

              // Categorize output lines
              if ($in_errors && !empty($line)) {
                $error_messages[] = $line;
              } elseif ($in_warnings && !empty($line)) {
                $warning_messages[] = $line;
              } elseif ($in_data && !empty($line)) {
                if (strpos($line, "✓") !== false || strpos($line, "successfully") !== false) {
                  $success_message = $line;
                } elseif (strpos($line, "OUTPUT_FILE_PATH:") !== false) {
                  // Skip the hidden marker line from display
                  continue;
                } elseif (!empty($line)) {
                  $report_lines[] = $line;
                }
              }
            }

            // Check return code
            if ($return != 0) {
              if (empty($error_messages)) {
                $error_messages[] = "Validation and cleaning process failed. Please check your file and try again.";
              }
            } else {
              // Find cleaned file path from hidden marker line
              foreach($output as $raw_line) {
                if (strpos($raw_line, "OUTPUT_FILE_PATH:") !== false) {
                  $cleaned_file = trim(str_replace("OUTPUT_FILE_PATH:", "", $raw_line));
                  // Verify file exists
                  if (!file_exists($cleaned_file)) {
                    $cleaned_file = "";
                    $error_messages[] = "Error: Cleaned file could not be found.";
                  }
                  break;
                }
              }
            }
          } else {
            $error_messages[] = "Error: Could not move uploaded file. Please check server permissions.";
          }
        }
      }
    }
?>

<html>
 <head>
  <title>PacBio Samplesheet Validator & Cleaner - Results</title>
  <link rel="stylesheet" type="text/css" href="http://gbw-s-nuc04.luna.kuleuven.be:8080/style_template.css">
  <img class="logo" src="http://gbw-s-nuc04.luna.kuleuven.be:8080/images/logo.png" alt="logo">
  <style>
    .error-box { background-color: #ffcccc; border: 2px solid #cc0000; color: #cc0000; padding: 10px; margin: 10px 0; border-radius: 5px; }
    .warning-box { background-color: #ffffcc; border: 2px solid #ffcc00; color: #ff8800; padding: 10px; margin: 10px 0; border-radius: 5px; }
    .success-box { background-color: #ccffcc; border: 2px solid #00cc00; color: #00aa00; padding: 10px; margin: 10px 0; border-radius: 5px; }
    .report-box { background-color: #f0f0f0; border: 1px solid #cccccc; padding: 10px; margin: 10px 0; border-radius: 5px; font-family: monospace; }
    .report-line { margin: 5px 0; }
  </style>
</head>
<body>
<div class="container">
<h1>PacBio Samplesheet Validator & Cleaner - Results</h1>

<?php if (!empty($error_messages)) { ?>
  <div class="error-box">
    <b>❌ Validation Failed</b><br>
    <?php foreach($error_messages as $error) { ?>
      <div class="report-line"><?php echo htmlspecialchars($error); ?></div>
    <?php } ?>
  </div>
<?php } ?>

<?php if (!empty($warning_messages)) { ?>
  <div class="warning-box">
    <b>⚠️ Warnings</b><br>
    <?php foreach($warning_messages as $warning) { ?>
      <div class="report-line"><?php echo htmlspecialchars($warning); ?></div>
    <?php } ?>
  </div>
<?php } ?>

<?php if (!empty($success_message)) { ?>
  <div class="success-box">
    <b><?php echo htmlspecialchars($success_message); ?></b>
  </div>
<?php } ?>

<?php if (!empty($report_lines)) { ?>
  <div class="report-box">
    <b>Processing Report:</b><br>
    <?php foreach($report_lines as $line) { ?>
      <div class="report-line"><?php echo htmlspecialchars($line); ?></div>
    <?php } ?>
  </div>
<?php } ?>

<?php if ($cleaned_file && file_exists($cleaned_file)) { ?>
  <br>
  <div style="background-color: #e8f5e9; border: 1px solid #4caf50; padding: 10px; border-radius: 5px;">
    <b style="color: #2e7d32;">✓ Cleaned File Ready:</b> <?php echo basename($cleaned_file); ?><br>
    <a href="?download=<?php echo urlencode(basename($cleaned_file)); ?>"><button style="background-color: #4caf50; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; margin-top: 5px;">📥 Download Cleaned File</button></a>
  </div>
<?php } ?>

<br><br>
<p><a href="index.php">⬅️ Validate Another File</a></p>
<p><a href=<?php echo("http://".$_SERVER["HTTP_HOST"]."/webtools/Workflow.htm")?>>⬅️ Return to Webtools</a></p>
</div>
</body>
</html>
