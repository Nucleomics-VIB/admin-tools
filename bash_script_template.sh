#!/bin/bash

# ------------
# Script Name:   script_name.sh
# Author:        Your Name
# Version:       1.0
# Date:          2024-06-13

# Optargs
# -------
# -h:   Display help message
# -I:   Input file path
# -o:   Output file path
# --long-option:   Long option description

# Check for required arguments
if [ $# -eq 0 ]; then
    echo "Error: No arguments provided."
    echo "Usage: $0 [-h] [-I <file_path>] [-o <file_path>] [--long-option]"
    exit 1
fi

# Process the input options
while getopts ":hi:o:" opt; do
    case $opt in
        h) # Display help message
            echo "Usage: $0 [-h] [-I <file_path>] [-o <file_path>] [--long-option]"
            exit 0
            ;;
        I) # Input file path
            INPUT_FILE=$OPTARG
            ;;
        o) # Output file path
            OUTPUT_FILE=$OPTARG
            ;;
        :) # Option requires an argument
            echo "Error: Option -$OPTARG requires an argument."
            echo "Usage: $0 [-h] [-I <file_path>] [-o <file_path>] [--long-option]"
            exit 1
            ;;
        \?) # Invalid option
            echo "Error: Invalid option -$OPTARG."
            echo "Usage: $0 [-h] [-I <file_path>] [-o <file_path>] [--long-option]"
            exit 1
            ;;
    esac
done

# Check for input file
if [ -z "$INPUT_FILE" ]; then
    echo "Error: No input file provided."
    echo "Usage: $0 [-h] [-I <file_path>] [-o <file_path>] [--long-option]"
    exit 1
fi

# Check for output file
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="output.txt"
fi

# Check for long options
if [[ $1 == *"--"* ]]; then
    if [[ $1 == *"--long-option"* ]]; then
        LONG_OPTION=$1
        shift
    fi
fi

# Perform script operations
# ...