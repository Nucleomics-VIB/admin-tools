[(Nucleomics-VIB)](https://github.com/Nucleomics-VIB)

## PacBio Samplesheet Validator & Cleaner

Validates and cleans PacBio barcode-to-sample CSV files via a web interface and shell script.

> **Note:** This code is specific to the **nuc4 server** environment. Some hardcoded URLs and paths may need adjustment for other deployment environments.

## Features

* Validates file has the expected header row (`Barcode,Bio Sample`).
* Detects **barcode duplicates** (critical error - stops processing).
* Detects and reports sample name duplicates (auto-fixed with integer suffixes: `_1`, `_2`, etc.).
* Removes extra columns beyond the first two.
* Removes leading/trailing spaces and replaces invalid characters with underscores.
* Converts to Unix line endings and removes empty rows.
* Detailed validation and cleaning report with categorized errors, warnings, and success messages.
* Provides a cleaned CSV file for download via the web interface.
* Secure file download handler with directory traversal protection.

## Usage (Web Interface)

1. Go to the PacBio Samplesheet Validator & Cleaner web page.
2. Upload your CSV file.
3. Click Submit.
4. Review the validation and cleaning report.
5. Download the cleaned CSV file using the provided button.

## Usage (Shell Script)

```bash
# usage: pacbio_samplesheet_validate_and_clean.sh -s sampleSheet.csv
```

This will validate the file, report any issues, auto-fix non-critical issues, and create a cleaned file in the uploads directory with a datetag in the filename.

---

### Contact

Please send comments and feedback to [nucleomics.bioinformatics@vib.be](mailto:nucleomics.bioinformatics@vib.be)

---

![Creative Commons License](http://i.creativecommons.org/l/by-sa/3.0/88x31.png?raw=true)

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/).
