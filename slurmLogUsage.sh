#!/bin/bash

# script         :slurmLogUsage.sh
# description    :Script to monitor and log SLURM job resource usage
# author         :SP@NC (AI)
# date           :2025-02-05
# version        :1.0
# usage          :./slurmLogUsage.sh [-i interval] [-o output_path]
# notes          :Monitors CPU, RAM, and GPU usage for SLURM jobs

# Default values
INTERVAL=10
OUTPUT_PATH="."

# Parse command line options
while getopts ":i:o:" opt; do
  case $opt in
    i) INTERVAL="$OPTARG"
    ;;
    o) OUTPUT_PATH="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# Ensure we're in a SLURM job
if [ -z "$SLURM_JOB_ID" ]; then
    echo "Error: This script must be run within a SLURM job."
    exit 1
fi

# Set the output file name using SLURM_JOB_ID
OUTPUT_FILE="${OUTPUT_PATH}/job_${SLURM_JOB_ID}_metrics.txt"

# Print header
echo "Timestamp,UnixTimestamp,CPU_Usage(cores),RAM_Usage(GB),GPU_Usage(%),GPU_Memory(GB)" > "$OUTPUT_FILE"

# Main monitoring loop (end with Ctrl-C)
while true; do
    UNIX_TIMESTAMP=$(date +%s)
    TIMESTAMP=$(date -d @$UNIX_TIMESTAMP +"%Y-%m-%d %H:%M:%S")
    
    # Get SLURM stats
    STATS=$(sstat --noheader --parsable2 --format=AveCPU,AveRSS,AveGPUUtil,AveGPUMem -j $SLURM_JOB_ID)
    
    # Parse stats
    IFS='|' read -r CPU_USAGE RAM_USAGE GPU_USAGE GPU_MEM <<< "$STATS"
    
    # Convert CPU usage from HH:MM:SS to cores
    CPU_CORES=$(echo $CPU_USAGE | awk -F':' '{print ($1 * 3600 + $2 * 60 + $3) / 3600}')
    
    # Convert RAM from KB to GB
    RAM_GB=$(echo "scale=2; $RAM_USAGE / 1024 / 1024" | bc)
    
    # Convert GPU memory from MB to GB
    GPU_MEM_GB=$(echo "scale=2; $GPU_MEM / 1024" | bc)
    
    echo "${TIMESTAMP},${UNIX_TIMESTAMP},${CPU_CORES},${RAM_GB},${GPU_USAGE},${GPU_MEM_GB}" >> "$OUTPUT_FILE"

    sleep $INTERVAL
done
