<?php
// create the email content to send to a customer with a HiFi data delivery
// Author: Stephane Plaisance - VIB Nucleomics Core
// Date: 2026-03-28
// Version: 1.1
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create the mail content for a Nextcloud HiFi data delivery</title>
    <link rel="stylesheet" type="text/css" href="/style_template.css">
    <style>
        .output-container {
            max-width: 1000px;
            margin: 20px auto;
            padding: 0 20px;
        }
        .preview-container {
            background-color: white !important;
            color: black !important;
            border: 2px solid #ccc;
            border-radius: 8px;
            padding: 20px;
            max-width: 900px;
            margin: 0 auto 20px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        .preview-header {
            font-family: Arial, sans-serif;
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 10px;
            color: #333;
        }
        .preview-body {
            font-family: Arial, sans-serif;
            font-size: 14px;
            line-height: 1.4;
            margin-bottom: 15px;
        }
        .preview-bold {
            font-weight: bold;
            color: #000;
        }
        form .field {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 6px;
        }
        form .field label {
            width: 160px;
            flex-shrink: 0;
            font-weight: bold;
            font-size: 13px;
        }
        form .field input, form .field textarea {
            font-size: 13px;
        }
        .copy-btn {
            float: right;
            padding: 8px 16px;
            background: #28a745;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 13px;
            margin-bottom: 10px;
        }
        .copy-btn:hover {
            background: #218838;
        }
        .output-actions {
            text-align: center;
            max-width: 900px;
            margin: 0 auto;
        }
        .output-actions button, .output-actions a {
            display: inline-block;
            margin: 0 10px;
            padding: 12px 24px;
            background: #007cba;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            border: none;
            cursor: pointer;
            font-size: 14px;
        }
        .output-actions button:hover, .output-actions a:hover {
            background: #005a87;
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

        // HTML template with proper bold styling
        $htmlTemplate = "
<div class=\"preview-header\">Subject: VIB Nucleomics Core | project <span class=\"preview-bold\">{$projectNumber}</span> data delivery</div>
<div class=\"preview-body\">Dear <span class=\"preview-bold\">{$customerName}</span>,<br>
Your <span class=\"preview-bold\">{$applicationTitle}</span> was done by <span class=\"preview-bold\">{$technicianName}</span> and the resulting data is available for one month on our share using the following credentials.<br>
<span class=\"preview-bold\">https://nextnuc.gbiomed.kuleuven.be/index.php/s/{$shareIDString}</span><br>
<span class=\"preview-bold\">{$sharePassword}</span><br>
(shared on <span class=\"preview-bold\">{$shareDate}</span>)<br>
Please copy all the data to your own storage as we will not keep it for more than 3 months on our server.<br>
You will find there the HiFi reads of the demultiplexed samples in Fastq (and optionally bam) format, as well as a Run QC report. When present, a barcoding QC info can also be found under <span class=\"preview-bold\">barcode_QC_v11.html</span>.<br>
The barcode-pair to sample-name relation can be obtained from <span class=\"preview-bold\">Exp{$projectNumber}_SMRTlink_barcodefile.csv</span><br>
<span class=\"preview-bold\">{$remark}</span><br>
Let us know if you encounter issues with this data.<br>
Best regards,</div>
        ";

        // Plain text for copying (email-safe)
        $plainText = "Subject: VIB Nucleomics Core | project {$projectNumber} data delivery

Dear {$customerName},

Your {$applicationTitle} was done by {$technicianName} and the resulting data is available for one month on our share using the following credentials.

https://nextnuc.gbiomed.kuleuven.be/index.php/s/{$shareIDString}
{$sharePassword}

(shared on {$shareDate})

Please copy all the data to your own storage as we will not keep it for more than 3 months on our server.

You will find there the HiFi reads of the demultiplexed samples in Fastq (and optionally bam) format, as well as a Run QC report. When present, a barcoding QC info can also be found under barcode_QC_v11.html.

The barcode-pair to sample-name relation can be obtained from Exp{$projectNumber}_SMRTlink_barcodefile.csv

{$remark}

Let us know if you encounter issues with this data.

Best regards,";

        echo '<div class="output-container">';
        echo '<textarea id="plain-text-content" style="display:none;">' . htmlspecialchars($plainText) . '</textarea>';
        echo '<div class="preview-container">';
        echo '<button class="copy-btn" onclick="copyPlainText()">Copy Email Text</button>';
        echo $htmlTemplate;
        echo '</div>';
        echo '<div class="output-actions">';
        echo '<button onclick="window.location.href=window.location.pathname;">New Text</button>';
        echo '<a href="/webtools/Workflow.htm">Return to Webtools</a>';
        echo '</div>';
        echo '</div>';

        echo '
        <script>
        function copyPlainText() {
            const ta = document.getElementById("plain-text-content");
            ta.style.display = "block";
            ta.select();
            ta.setSelectionRange(0, 99999);
            document.execCommand("copy");
            ta.style.display = "none";
            const btn = document.querySelector(".copy-btn");
            const originalText = btn.textContent;
            btn.textContent = "Copied!";
            btn.style.background = "#17a2b8";
            setTimeout(() => {
                btn.textContent = originalText;
                btn.style.background = "#28a745";
            }, 2000);
        }
        </script>';
    } else {
    ?>
        <div class="container">
            <h1>Create the mail content for a Nextcloud HiFi data delivery <small style="font-size: 0.45em; font-weight: normal; color: #666;">(SP@NC 2026-03-28)</small></h1>
            <form method="post" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>">
                <div class="field"><label for="projectnumber">Project Number:</label><input type="text" id="projectnumber" name="projectnumber" required style="width: 120px;"></div>
                <div class="field"><label for="customername">Customer Name:</label><input type="text" id="customername" name="customername" required style="width: 300px;"></div>
                <div class="field"><label for="applicationtitle">Application Title:</label><input type="text" id="applicationtitle" name="applicationtitle" required style="width: 400px;"></div>
                <div class="field"><label for="technicianname">Technician Name:</label><input type="text" id="technicianname" name="technicianname" required style="width: 300px;"></div>
                <div class="field"><label for="shareidstring">Share ID String:</label><input type="text" id="shareidstring" name="shareidstring" required style="width: 400px;"></div>
                <div class="field"><label for="sharepassword">Share Password:</label><input type="text" id="sharepassword" name="sharepassword" required style="width: 200px;"></div>
                <div class="field"><label for="sharedate">Share Date:</label><input type="date" id="sharedate" name="sharedate" required style="width: 200px;"></div>
                <div class="field"><label for="remark">Remark:</label><textarea id="remark" name="remark" rows="3" style="width: 500px;" required>We also processed a negative sample (buffer) and a positive one from the D6305_zymobiomics_microbial_community_standards (PDF added)</textarea></div>
                <div style="margin-top: 8px;"><input type="submit" value="Generate Custom Text" style="padding: 8px 18px; font-size: 14px;"></div>
            </form>
            <p style="margin-top: 20px;"><a href="/webtools/Workflow.htm" style="color: #007cba; font-weight: bold;">&lt;&lt; Return to Webtools</a></p>
        </div>
    <?php
    }
    ?>
</body>
</html>