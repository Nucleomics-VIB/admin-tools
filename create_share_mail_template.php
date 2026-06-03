<?php
// create the email content to send to a customer for a Nextcloud data delivery
// supports two data types: "16S Kinnex" and "HiFi"
// Author: Stephane Plaisance - VIB Nucleomics Core
// Date: 2026-06-03
// Version: 2.0
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create the mail content for a Nextcloud data delivery (16S Kinnex / HiFi)</title>
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
        form .field input, form .field textarea, form .field select {
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
    // default remark prefilled for 16S Kinnex deliveries (editable / optional)
    $default16SRemark = "We also processed a negative sample (buffer) and a positive one from the D6305_zymobiomics_microbial_community_standards (PDF added)";

    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        // --- collect input ---
        $projectNumber = $_POST['projectnumber'];
        $dataType      = isset($_POST['datatype']) ? $_POST['datatype'] : '16S Kinnex'; // "16S Kinnex" | "HiFi"
        $dataWord      = ($dataType === 'HiFi') ? 'HiFi' : '16S';   // the single word that differs in the body
        $customerName  = $_POST['customername'];
        $shareURL      = $_POST['shareurl'];
        $sharePassword = $_POST['sharepassword'];
        $shareLimit    = $_POST['sharelimit'];
        $remark        = trim($_POST['remark']);

        // --- escaped copies for the HTML preview (avoid breaking markup / XSS) ---
        $eProject  = htmlspecialchars($projectNumber);
        $eType     = htmlspecialchars($dataType);
        $eWord     = htmlspecialchars($dataWord);
        $eCustomer = htmlspecialchars($customerName);
        $eURL      = htmlspecialchars($shareURL);
        $ePW       = htmlspecialchars($sharePassword);
        $eLimit    = htmlspecialchars($shareLimit);
        $eRemark   = htmlspecialchars($remark);

        // --- optional remark block (only shown when filled) ---
        $htmlRemark = ($remark !== '') ? "<span class=\"preview-bold\">{$eRemark}</span><br><br>" : "";
        $textRemark = ($remark !== '') ? "{$remark}\n\n" : "";

        // HTML template with proper bold styling
        $htmlTemplate = "
<div class=\"preview-header\">Subject: VIB Nucleomics Core | project <span class=\"preview-bold\">{$eProject}</span> {$eType} data delivery</div>
<div class=\"preview-body\">Dear <span class=\"preview-bold\">{$eCustomer}</span>,<br><br>
Your <span class=\"preview-bold\">{$eWord}</span> data is now available for download on our Nextcloud server. Please download this data asap and check it against the md5sum file for integrity.<br><br>
You can access it at the following address: <span class=\"preview-bold\">{$eURL}</span><br><br>
Please use the following password to access the page and follow the instructions in the README.txt if downloading from your browser is not working<br>
PW: <span class=\"preview-bold\">{$ePW}</span><br><br>
Each fastq.gz file contains the demultiplexed reads for the corresponding sample and a html QC file gives you the respective size of each dataset.<br>
The share is open until <span class=\"preview-bold\">{$eLimit}</span> and we will only keep the corresponding data for max 3 months.<br><br>
{$htmlRemark}Do not hesitate to contact us if you need any additional information<br><br>
Best regards</div>
        ";

        // Plain text for copying (email-safe)
        $plainText = "Subject: VIB Nucleomics Core | project {$projectNumber} {$dataType} data delivery

Dear {$customerName},

Your {$dataWord} data is now available for download on our Nextcloud server. Please download this data asap and check it against the md5sum file for integrity.

You can access it at the following address: {$shareURL}

Please use the following password to access the page and follow the instructions in the README.txt if downloading from your browser is not working
PW: {$sharePassword}

Each fastq.gz file contains the demultiplexed reads for the corresponding sample and a html QC file gives you the respective size of each dataset.
The share is open until {$shareLimit} and we will only keep the corresponding data for max 3 months.

{$textRemark}Do not hesitate to contact us if you need any additional information

Best regards";

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
            <h1>Create the mail content for a Nextcloud data delivery <small style="font-size: 0.45em; font-weight: normal; color: #666;">(16S Kinnex / HiFi &mdash; SP@NC 2026-06-03)</small></h1>
            <form method="post" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>">
                <div class="field"><label for="projectnumber">Project Number:</label><input type="text" id="projectnumber" name="projectnumber" required style="width: 120px;"></div>
                <div class="field"><label for="datatype">Data Type:</label><select id="datatype" name="datatype" required style="width: 200px;"><option value="16S Kinnex" selected>16S Kinnex</option><option value="HiFi">HiFi</option></select></div>
                <div class="field"><label for="customername">User (recipient):</label><input type="text" id="customername" name="customername" required style="width: 300px;"></div>
                <div class="field"><label for="shareurl">Share URL:</label><input type="text" id="shareurl" name="shareurl" required style="width: 500px;" value="https://nextnuc.gbiomed.kuleuven.be/index.php/s/"></div>
                <div class="field"><label for="sharepassword">Password (PW):</label><input type="text" id="sharepassword" name="sharepassword" required style="width: 200px;"></div>
                <div class="field"><label for="sharelimit">Open until (limit):</label><input type="date" id="sharelimit" name="sharelimit" required style="width: 200px;"></div>
                <div class="field"><label for="remark">Remark (optional):</label><textarea id="remark" name="remark" rows="3" style="width: 500px;"><?php echo htmlspecialchars($default16SRemark); ?></textarea></div>
                <div style="margin-top: 8px;"><input type="submit" value="Generate Custom Text" style="padding: 8px 18px; font-size: 14px;"></div>
            </form>
            <p style="margin-top: 20px;"><a href="/webtools/Workflow.htm" style="color: #007cba; font-weight: bold;">&lt;&lt; Return to Webtools</a></p>
        </div>
        <script>
        // Swap the default remark when the data type changes, without clobbering user edits.
        (function () {
            var default16S = <?php echo json_encode($default16SRemark); ?>;
            var dt = document.getElementById('datatype');
            var rm = document.getElementById('remark');
            if (!dt || !rm) return;
            dt.addEventListener('change', function () {
                if (this.value === 'HiFi') {
                    // clear the 16S boilerplate when switching to HiFi (keep custom text)
                    if (rm.value.trim() === default16S.trim()) rm.value = '';
                } else {
                    // restore the 16S boilerplate only if the field is empty
                    if (rm.value.trim() === '') rm.value = default16S;
                }
            });
        })();
        </script>
    <?php
    }
    ?>
</body>
</html>
