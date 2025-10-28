#!/bin/bash

# pacbio_samplesheet_validator.sh 
# Usage: pacbio_samplesheet_validator.sh -s <csv_file>
# Validates PacBio barcode to names samplesheet
# Looks for duplicate barcodes or sample names as well as invalid characters
# Ensure there is no more than a single line-feed at the end of the file
# Author: SP@NC (+AI)
# Date: 2025-10-28
# Version: 1.2

# Function to display usage
usage() {
    echo "Usage: $0 -s <csv_file>"
    exit 1
}

# Parse command line options
while getopts ":s:" opt; do
    case $opt in
        s) csv_file="$OPTARG" ;;
        \?) echo "Invalid option -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument" >&2; usage ;;
    esac
done

# Check if CSV file is provided
if [ -z "$csv_file" ]; then
    usage
fi

# Check if file exists
if [ ! -f "$csv_file" ]; then
    echo "Error: File '$csv_file' does not exist."
    exit 1
fi

# Validate header
header=$(head -n 1 "$csv_file" | tr -d '\r\n')
if [ "$header" != "Barcode,Bio Sample" ]; then
    echo "Error: Invalid header. Expected 'Barcode,Bio Sample', but got '$header'"
    exit 1
fi

# Initialize counters for total and invalid rows
total_rows=0
invalid_rows=0

# Validate data and count rows
awk -v total_rows_ref="$total_rows" -v invalid_rows_ref="$invalid_rows" '
BEGIN {
    FS=",";
    OFS=",";
    invalid_rows = 0;
}
NR==1 {next}
{
    gsub(/\r$/, "");
    total_rows++;
    invalid = 0;
    if (NF != 2) {
        print "Error: Invalid number of columns in row " NR ": " $0;
        invalid = 1;
    }
    if ($1 in barcode) {
        print "Error: Duplicate Barcode value in row " NR ": " $1;
        invalid = 1;
    }
    if ($2 in biosample) {
        print "Error: Duplicate Bio Sample value in row " NR ": " $2;
        invalid = 1;
    }
    if ($2 !~ /^[A-Za-z0-9_-.]+$/) {
        print "Error: Invalid characters in Bio Sample value in row " NR ": " $2;
        invalid = 1;
    }
    barcode[$1]++;
    biosample[$2]++;
    if (invalid) {
        invalid_rows++;
    }
}
END {
    print "\nValidation Summary:";
    print "Total Rows (excluding header):" total_rows;
    print "Invalid Rows:" invalid_rows;
}' "$csv_file"

# === Check for multiple line feeds at the end ===
# Counts consecutive blank lines at file end (including extra newlines)
end_blank_lines=$(awk '{if(length($0)==0){blank++} else {blank=0}} END{print blank}' "$csv_file")
if [ "$end_blank_lines" -gt 0 ]; then
    echo "Error: File ends with $end_blank_lines blank line(s). Only a single line feed is allowed at end of file."
    exit 1
fi
