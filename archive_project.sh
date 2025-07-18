#!/bin/bash

# ======================================================================
# SCRIPT NAME: archive_project.sh
# PURPOSE: Reads a list of files and folders from a text file, creates a
#          tar.gz archive with the corresponding files and folders recursively,
#          calculates MD5 checksums for each file in parallel, and saves them in a separate file.
# AUTHOR: SP@NC (+AI)
# DATE: 2025-04-04
# VERSION: 1.6.0
# USAGE: archive_project.sh -i file_list.txt -o archive_name.tar.gz -p 4
# NOTES: Ensure all paths in the input file are valid and accessible.
# ======================================================================

# Default values for arguments
input_file="file_list.txt"
output_archive="archive_name.tar.gz"
content_file="archive_content.md5"
parallel_tasks=4  # Default number of parallel tasks
pigzt=4 # threads for pigz

# Parse arguments using getopts
while getopts ":i:o:p:z:h" opt; do
  case $opt in
    i) input_file="$OPTARG" ;;
    o) output_archive="$OPTARG" ;;
    p) parallel_tasks="$OPTARG" ;;
    z) pigzt="$OPTARG" ;;
    h)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -i <file>   Specify input file list (default: file_list.txt)"
      echo "  -o <file>   Specify output archive name (default: archive_name.tar.gz)"
      echo "  -p <int>    Number of parallel tasks (default: 4)"
      echo "  -z <int>    Number of parallel pigz compression (default: 4)"
      echo "  -h          Show this help message and exit"
      exit 0
      ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# Ensure input file exists
if [[ ! -f "${input_file}" ]]; then
    echo "Error: Input file '${input_file}' does not exist (-h for options)."
    exit 1
fi

content_file="${output_archive%.tar.gz}_content.md5"

# Step 1: Find all files from the paths listed in the input file
echo "Finding all files..."
files=$(cat "${input_file}" | xargs -I{} find {} -type f)

if [[ -z "${files}" ]]; then
    echo "Error: No files found in the specified paths."
    exit 1
fi

# Step 2: Calculate MD5 checksums in parallel using background processes
echo "Calculating MD5 checksums with $parallel_tasks parallel tasks..."
(
    echo "${files}" | xargs -P "${parallel_tasks}" -I{} md5sum "{}" >> "${content_file}_tmp"
) &

checksum_pid=$! # Capture the PID of the checksum process

# Step 3: Create tar.gz archive using pigz for multithreaded compression
echo "Creating tar.gz archive..."
echo "${files}" | tar --use-compress-program="pigz -p ${pigzt}" -cf "${output_archive}" --files-from=-

# Step 4: Wait for MD5 checksum process to complete before proceeding
echo "Waiting for MD5 checksum process to complete..."
wait $checksum_pid

# sort ${content_file}
sort -k 2V,2 "${content_file}_tmp" > "${content_file}" \
  && rm "${content_file}_tmp"

# Step 5: Calculate MD5 checksum for the entire archive after all processes are complete
echo "Calculating global MD5 checksum for the archive..."
md5sum "${output_archive}" > "${output_archive}.md5"

echo "Archive created successfully: ${output_archive}"
echo "Content file created successfully: ${content_file}"

