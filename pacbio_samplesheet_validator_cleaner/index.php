<html>
<META NAME="description" CONTENT="Validates and Cleans a PacBio Samplesheet v2.0 11/03/2025">
<META NAME="author" CONTENT="Thomas Standaert thomas.standaert@vib.be">
<META NAME="author" CONTENT="Stephane Plaisance stephane.plaisance@vib.be">
<META NAME="robots" CONTENT="NOFOLLOW,NOINDEX">
<head>
  <title>PacBio Samplesheet Validator & Cleaner</title>
  <link rel="stylesheet" type="text/css" href="http://gbw-s-nuc04.luna.kuleuven.be:8080/style_template.css">
  <img class="logo" src="http://gbw-s-nuc04.luna.kuleuven.be:8080/images/logo.png" alt="logo">
</head>
<body>
<div class="container">
  <h1>PacBio Samplesheet Validator & Cleaner</h1>
  <p style="font-size: 0.85em; color: #666;">Version 2.0 | Released 2025-11-03</p>

  <!-- Application description -->
  <p><b>Validates and cleans PacBio barcode to name CSV files.</b></p>
  
  <h3>Validation Checks:</h3>
  <ul>
    <li>Verifies the expected header row format (Barcode,Bio Sample)</li>
    <li><b style="color:red;">Detects barcode duplicates and stops processing (cannot be auto-fixed)</b></li>
    <li>Detects duplicate sample names and auto-fixes by adding integer suffixes</li>
  </ul>
  
  <h3>Cleaning Operations:</h3>
  <ul>
    <li>Removes extra columns beyond the first two</li>
    <li>Trims leading/trailing spaces from barcode and sample names</li>
    <li>Replaces invalid characters (non-alphanumeric, underscore, dot, hyphen) with underscores</li>
    <li>Converts DOS/Windows line endings to Unix format (LF)</li>
    <li>Removes empty rows</li>
    <li>Ensures proper file formatting (single newline at end)</li>
  </ul>

  <h3>Output:</h3>
  <ul>
    <li>Detailed validation report with all warnings and errors</li>
    <li>Cleaned and validated CSV file ready for use</li>
  </ul>

  <h3>Upload CSV File:</h3>
  <form method="post" action="results.php" enctype="multipart/form-data">
    <label>PacBio CSV File:</label><input type="file" name="data[indexfile]" id="indexfile" accept=".csv"><br><br>
    <input type="submit" name="submit" value="Validate & Clean">
  </form>

    <p><a href=http://gbw-s-nuc04.luna.kuleuven.be:8080/webtools/Workflow.htm><< Return to Webtools</a></p>
</div>
</body>
</html>
