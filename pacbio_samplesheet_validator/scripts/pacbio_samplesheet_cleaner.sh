#!/bin/bash

# pacbio_samplesheet_cleaner.sh
# Usage: pacbio_samplesheet_cleaner.sh -s <csv_file>
# Cleans and validates PacBio barcode to names samplesheet
# Performs all checks from validator and corrects issues:
# - Removes empty rows at end of CSV
# - Saves as Unix text with LF line endings
# - Replaces all non 'a-zA-Z0-9.-_' characters by '_'
# Author: SP@NC (+AI)
# Date: 2025-10-29
# Version: 1.0

usage() {
    echo "Usage: $0 -s <csv_file>"
    exit 1
}

while getopts ":s:" opt; do
    case $opt in
        s) csv_file="$OPTARG" ;;
        \?) echo "Invalid option -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument" >&2; usage ;;
    esac
done

if [ -z "$csv_file" ]; then
    usage
fi

if [ ! -f "$csv_file" ]; then
    echo "Error: File '$csv_file' does not exist."
    exit 1
fi

echo "Cleaned file saved as $cleaned_file"


# Output cleaned file name in uploads/ with datetag
datetag=$(date +%Y%m%d_%H%M%S)
basefile=$(basename "$csv_file" .csv)

# Always use the main uploads directory (relative to script location)
script_dir="$(cd "$(dirname "$0")/.." && pwd)"
uploads_dir="$script_dir/uploads"
mkdir -p "$uploads_dir"
cleaned_file="$uploads_dir/${basefile}_cleaned_${datetag}.csv"

# Convert to Unix line endings
sed 's/\r$//' "$csv_file" > tmp_unix.csv

# Force correct header
echo "Barcode,Bio Sample" > tmp_cleaned.csv

echo "Cleaning $csv_file ..."

# Clean and validate
awk '
BEGIN {
    FS=","; OFS=",";
}
NR==1 {
    next;  # Skip original header
}
{
    # Remove empty lines
    if ($0 ~ /^\s*$/) next;
    # Keep only first two columns
    if (NF >= 1) {
        $1 = gensub(/^ +/, "", "g", $1);  # Remove leading spaces
        $1 = gensub(/ +$/, "", "g", $1);  # Remove trailing spaces
        $1 = gensub(/[^A-Za-z0-9_.-]/, "_", "g", $1);  # Replace invalid chars
    }
    if (NF >= 2) {
        $2 = gensub(/^ +/, "", "g", $2);  # Remove leading spaces
        $2 = gensub(/ +$/, "", "g", $2);  # Remove trailing spaces
        $2 = gensub(/[^A-Za-z0-9_.-]/, "_", "g", $2);  # Replace invalid chars
    }
    print $1, $2 >> "tmp_cleaned.csv";
}
' tmp_unix.csv

# Remove empty rows at end, ensure Unix LF, single final newline

awk 'NF' tmp_cleaned.csv | sed 's/[ \t]*$//' > "$cleaned_file"

# Ensure single final newline
printf '\n' >> "$cleaned_file"

rm tmp_cleaned.csv tmp_unix.csv


if [ -f "$cleaned_file" ]; then
    echo "Cleaned file saved as $cleaned_file"
else
    echo "Error: Cleaned file could not be saved to $cleaned_file"
fi
