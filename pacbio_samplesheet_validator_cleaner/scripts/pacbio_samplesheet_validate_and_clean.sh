#!/bin/bash

# pacbio_samplesheet_validate_and_clean.sh
# Usage: pacbio_samplesheet_validate_and_clean.sh -s <csv_file> [-o <output_file>]
# Validates and cleans PacBio barcode to names samplesheet
# Features:
# - Validates header format
# - Checks for DOS/Windows line endings
# - Removes trailing whitespace
# - Cleans invalid characters in barcode and sample names
# - Detects and reports barcode duplicates (STOPS if found)
# - Detects sample name duplicates and adds integer suffixes to make them unique
# - Removes empty rows
# - Ensures Unix LF line endings and single final newline
# Author: SP@NC (+AI)
# Date: 2025-11-03
# Version: 1.0

# Initialize variables
csv_file=""
output_file=""
errors=()
warnings=()

# Function to display usage
usage() {
    echo "Usage: $0 -s <csv_file> [-o <output_file>]"
    echo "  -s: Input CSV file (required)"
    echo "  -o: Output file (optional, defaults to <basename>_cleaned_<timestamp>.csv)"
    exit 1
}

# Parse command line options
while getopts ":s:o:" opt; do
    case $opt in
        s) csv_file="$OPTARG" ;;
        o) output_file="$OPTARG" ;;
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
    errors+=("Error: File '$csv_file' does not exist.")
    echo "${errors[@]}"
    exit 1
fi

# === STEP 1: CHECK AND FIX HEADER ===
header=$(head -n 1 "$csv_file" | tr -d '\r\n')
header_cols=$(echo "$header" | awk -F',' '{print NF}')
if [ "$header" != "Barcode,Bio Sample" ]; then
    if [ "$header_cols" -gt 2 ]; then
        warnings+=("Warning: Header has $header_cols columns instead of 2. Extra columns will be removed.")
    elif [ "$header_cols" -lt 2 ]; then
        errors+=("Error: Header has fewer than 2 columns. Expected 'Barcode,Bio Sample', but got '$header'")
    else
        # Check if column names are just in different order or have extra spaces
        first_col=$(echo "$header" | awk -F',' '{print $1}' | xargs)
        second_col=$(echo "$header" | awk -F',' '{print $2}' | xargs)
        if [ "$first_col" != "Barcode" ] || [ "$second_col" != "Bio Sample" ]; then
            warnings+=("Warning: Header is not standard format: '$header'. Will be corrected to 'Barcode,Bio Sample'")
        fi
    fi
fi

# === STEP 2: CHECK FOR DOS/WINDOWS LINE ENDINGS ===
if grep -q $'\r' "$csv_file"; then
    warnings+=("Warning: DOS/Windows-style line endings (CRLF) detected. Converting to Unix-style LF.")
fi

# === STEP 3: PRELIMINARY CHECK FOR BARCODE DUPLICATES (ONLY CRITICAL ERROR) ===
barcode_duplicates=$(awk -F',' '
NR>1 {
    gsub(/\r$/, "");
    if (NF >= 1 && $1 ~ /^[A-Za-z0-9_.-]+$/) {
        if ($1 in barcodes) {
            barcodes[$1]++;
        } else {
            barcodes[$1] = 1;
        }
    }
}
END {
    for (bc in barcodes) {
        if (barcodes[bc] > 1) {
            print bc;
        }
    }
}' "$csv_file")

if [ -n "$barcode_duplicates" ]; then
    errors+=("Error: Duplicate barcodes found (cannot be fixed, stopping process):")
    while IFS= read -r bc; do
        errors+=("  - $bc")
    done <<< "$barcode_duplicates"
fi

# Only barcode duplicates are critical - check for errors before proceeding
if [ ${#errors[@]} -gt 0 ]; then
    echo "=== VALIDATION FAILED ==="
    for error in "${errors[@]}"; do
        echo "$error"
    done
    exit 1
fi

# === STEP 4: CONVERT TO UNIX LINE ENDINGS ===
sed 's/\r$//' "$csv_file" > tmp_unix_$$.csv

# === STEP 5: CLEAN AND PROCESS DATA ===
# Create temporary files for processing
tmp_cleaned="tmp_cleaned_$$.csv"
tmp_with_duplicates="tmp_with_duplicates_$$.csv"

# Start with cleaned header
echo "Barcode,Bio Sample" > "$tmp_cleaned"

# Clean data: remove empty lines, trim spaces, replace invalid characters, handle extra columns
awk -F',' '
BEGIN {
    OFS=",";
    extra_columns_found = 0;
}
NR==1 {
    next;  # Skip original header
}
{
    # Remove empty lines
    if ($0 ~ /^\s*$/) next;

    # Check for extra columns
    if (NF > 2) {
        extra_columns_found = 1;
        print "warning: Row " NR " has " NF " columns (expected 2). Extra columns will be removed." > "/dev/stderr";
    }

    # Keep only first two columns
    barcode = $1;
    sample = $2;

    # Trim leading/trailing spaces from barcode
    gsub(/^ +/, "", barcode);
    gsub(/ +$/, "", barcode);

    # Trim leading/trailing spaces from sample
    gsub(/^ +/, "", sample);
    gsub(/ +$/, "", sample);

    # Replace invalid characters with underscore
    # Valid: a-z, A-Z, 0-9, _, ., -
    # Using gsub in a loop for compatibility (gensub not available in all awk versions)
    while (match(barcode, /[^A-Za-z0-9_.-]/)) {
        barcode = substr(barcode, 1, RSTART-1) "_" substr(barcode, RSTART+RLENGTH);
    }
    while (match(sample, /[^A-Za-z0-9_.-]/)) {
        sample = substr(sample, 1, RSTART-1) "_" substr(sample, RSTART+RLENGTH);
    }

    # Skip if barcode or sample is empty after cleaning
    if (length(barcode) == 0 || length(sample) == 0) {
        print "warning: Skipping row " NR " (empty barcode or sample after cleaning)" > "/dev/stderr";
        next;
    }

    print barcode, sample >> "'"$tmp_cleaned"'";
}
END {
    if (extra_columns_found) {
        print "warning: Some rows had extra columns. All have been removed." > "/dev/stderr";
    }
}' tmp_unix_$$.csv 2>/tmp/clean_warnings_$$.log

# Capture any warnings from cleaning
if [ -f /tmp/clean_warnings_$$.log ]; then
    while IFS= read -r warning; do
        warnings+=("$warning")
    done < /tmp/clean_warnings_$$.log
    rm /tmp/clean_warnings_$$.log
fi

# === STEP 6: DETECT AND FIX SAMPLE NAME DUPLICATES ===
# Read the cleaned file and identify duplicate sample names
awk -F',' '
NR > 1 {
    sample = $2;
    if (sample in count) {
        count[sample]++;
    } else {
        count[sample] = 1;
    }
}
END {
    for (s in count) {
        if (count[s] > 1) {
            print s;
        }
    }
}' "$tmp_cleaned" | sort | uniq > "$tmp_with_duplicates"

# Process the file again to add suffixes to duplicates
if [ -s "$tmp_with_duplicates" ]; then
    awk -F',' -v tmpfile="$tmp_with_duplicates" '
    BEGIN {
        OFS=",";
        # Load list of duplicates
        while ((getline dup < tmpfile) > 0) {
            duplicates[dup] = 1;
        }
        close(tmpfile);
    }
    NR==1 {
        print;
        next;
    }
    {
        barcode = $1;
        sample = $2;
        if (sample in duplicates) {
            if (sample in counter) {
                counter[sample]++;
            } else {
                counter[sample] = 1;
            }
            sample = sample "_" counter[sample];
        }
        print barcode, sample;
    }' "$tmp_cleaned" > "${tmp_cleaned}.tmp"

    mv "${tmp_cleaned}.tmp" "$tmp_cleaned"

    # Add warning for duplicates found and fixed
    warnings+=("Warning: Sample name duplicates detected and fixed by adding integer suffixes:")
    while IFS= read -r dup_sample; do
        warnings+=("  - $dup_sample")
    done < "$tmp_with_duplicates"
fi

# === STEP 7: PREPARE OUTPUT FILE ===
if [ -z "$output_file" ]; then
    script_dir="$(cd "$(dirname "$0")/.." && pwd)"
    uploads_dir="$script_dir/uploads"
    mkdir -p "$uploads_dir"
    datetag=$(date +%Y%m%d_%H%M%S)
    basefile=$(basename "$csv_file" .csv)
    output_file="$uploads_dir/${basefile}_cleaned_${datetag}.csv"
fi

# Remove empty rows, trim trailing whitespace, ensure single final newline
awk 'NF' "$tmp_cleaned" | sed 's/[ \t]*$//' > "$output_file"
printf '\n' >> "$output_file"

# === STEP 8: FINAL VALIDATION OF OUTPUT ===
output_lines=$(tail -n +2 "$output_file" | wc -l)

if [ "$output_lines" -eq 0 ]; then
    warnings+=("Warning: Output file contains no data rows after cleaning")
fi

# === STEP 9: CLEANUP ===
rm -f tmp_unix_$$.csv "$tmp_with_duplicates" 2>/dev/null

# === STEP 10: REPORT RESULTS ===
echo "=== VALIDATION AND CLEANING REPORT ==="
echo ""

if [ ${#warnings[@]} -gt 0 ]; then
    echo "WARNINGS:"
    for warning in "${warnings[@]}"; do
        echo "  $warning"
    done
    echo ""
fi

echo "✓ Validation and cleaning completed successfully!"
echo "  Data rows:    $output_lines"
echo ""
echo "OUTPUT_FILE_PATH: $output_file"

exit 0