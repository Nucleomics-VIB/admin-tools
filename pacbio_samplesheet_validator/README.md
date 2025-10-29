[(Nucleomics-VIB)](https://github.com/Nucleomics-VIB)

## PacBio Samplesheet Cleaner

Cleans and validates PacBio barcode-to-name CSV files via a web interface and shell script.

### Features
* Ensures the file has the expected header row (`Barcode,Bio Sample`).
* Removes extra columns beyond the first two.
* Removes leading/trailing spaces and replaces invalid characters with underscores.
* Converts to Unix line endings and removes empty rows.
* Provides a cleaned CSV file for download via the web interface.

### Usage (Web Interface)
1. Go to the PacBio Samplesheet Cleaner web page.
2. Upload your CSV file.
3. Click Submit.
4. Download the cleaned CSV file using the provided button.

### Usage (Shell Script)
```bash
# usage: pacbio_samplesheet_cleaner.sh -s sampleSheet.csv
```
This will create a cleaned file in the uploads directory with a datetag in the filename.

---

<h4>Please send comments and feedback to <a href="mailto:nucleomics.bioinformatics@vib.be">nucleomics.bioinformatics@vib.be</a></h4>

---

![Creative Commons License](http://i.creativecommons.org/l/by-sa/3.0/88x31.png?raw=true)

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/).
