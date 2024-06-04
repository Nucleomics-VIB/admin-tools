<?php
// create the email content to send to a customer with a 16S data delivery
// Author: Stephane Plaisance - VIB Nucleomics Core
// Date: 2024-06-14
// Version: 1.0
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create the mail content for a Nextcloud HiFi data delivery</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f9f9f9;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #ffffff;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #333333;
        }
        label {
            font-weight: bold;
            display: block;
            margin-top: 10px;
            margin-bottom: 5px;
        }
        input[type="text"],
        input[type="email"],
        input[type="date"],
        textarea {
            width: 100%;
            padding: 10px;
            margin-bottom: 15px;
            border: 1px solid #ccc;
            border-radius: 3px;
            font-size: 12px;
        }
        input[type="submit"] {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 3px;
            cursor: pointer;
            font-size: 14px;
            margin-top: 10px;
        }
        input[type="submit"]:hover {
            background-color: #0056b3;
        }
        .bold {
            font-weight: bold;
        }
    </style>
</head>
<body>
    <?php
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        $projectNumber = $_POST['projectnumber'];
        $customerName = $_POST['customername'];
        $applicationTitle = $_POST['applicationtitle'];
        $technicianName = $_POST['technicianname'];
        $shareIDString = $_POST['shareidstring'];
        $sharePassword = $_POST['sharepassword'];
        $shareDate = $_POST['sharedate'];
        $remark = $_POST['remark'];

        $template = "
        Subject: VIB Nucleomics Core | project <span class=\"bold\">$projectNumber</span> data delivery

        Dear <span class=\"bold\">$customerName</span>,

        Your <span class=\"bold\">$applicationTitle</span> was done by <span class=\"bold\">$technicianName</span> and the resulting data is available for one month on our share using the following credentials.

        <span class=\"bold\">https://nextnuc.gbiomed.kuleuven.be/index.php/s/$shareIDString</span>
        <span class=\"bold\">$sharePassword</span>

        (shared on <span class=\"bold\">$shareDate</span>)

        Please copy all the data to your own storage as we will not keep it for more than 3 months on our server.

        You will find there the HiFi reads of the demultiplexed samples in Fastq (and optionally bam) format, as well as a Run QC report. When present, a barcoding QC info can also be found under <span class=\"bold\">barcode_QC_v11.html</span>.

        The barcode-pair to sample-name relation can be obtained from <span class=\"bold\">Exp{$projectNumber}_SMRTlink_barcodefile.csv</span>

        <span class=\"bold\">$remark</span>

        Let us know if you encounter issues with this data.

        Best regards,
        ";

        echo nl2br($template);
    } else {
    ?>
        <div class="container">
            <h1>Create the mail content for a Nextcloud HiFi data delivery</h1
            <br>
            <h3>(SP@NC 2024-05-31)</h3>
            <br>
            <form method="post" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>">
                <label for="projectnumber">Project Number:</label>
                <input type="text" id="projectnumber" name="projectnumber" required><br>

                <label for="customername">Customer Name:</label>
                <input type="text" id="customername" name="customername" required><br>

                <label for="applicationtitle">Application Title:</label>
                <input type="text" id="applicationtitle" name="applicationtitle" required><br>

                <label for="technicianname">Technician Name:</label>
                <input type="text" id="technicianname" name="technicianname" required><br>

                <label for="shareidstring">Share ID String:</label>
                <input type="text" id="shareidstring" name="shareidstring" required><br>

                <label for="sharepassword">Share Password:</label>
                <input type="text" id="sharepassword" name="sharepassword" required><br>

                <label for="sharedate">Share Date:</label>
                <input type="date" id="sharedate" name="sharedate" required><br>

                <label for="remark">Remark:</label>
                <textarea id="remark" name="remark" required>We also processed a negative sample (buffer) and a positive one from the D6305_zymobiomics_microbial_community_standards (PDF added)</textarea><br>

                <input type="submit" value="Generate Custom Text">
            </form>
        </div>
    <?php
    }
    ?>
</body>
</html>