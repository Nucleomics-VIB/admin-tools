#!/bin/bash

# script         :logUsageGPU.sh
# description    :Script to monitor and log system resource usage
# author         :SP@NC (AI)
# date           :2025-02-05
# version        :1.1
# usage          :./logUsage.sh [-i interval] [-o output_path]
# notes          :Monitors RAM, CPU, and GPU usage during SLURM or local jobs

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

# set to SLURM job if exists otherwise to 'local'
: ${SLURM_JOB_ID:=local}

# Set the output file name using SLURM_JOB_ID
OUTPUT_FILE="${OUTPUT_PATH}/job_${SLURM_JOB_ID}_metrics.txt"

# Print header
echo "Timestamp,UnixTimestamp,CPU_Usage(cores),RAM_Usage(GB),GPU_Usage(%),GPU_Memory(GB)" > "$OUTPUT_FILE"

# Function to get CPU usage in cores
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | awk '{printf "%.2f", $1 * '"$(nproc)"' / 100}'
}

# Function to get RAM usage in GB
get_ram_usage() {
    free -b | awk '/Mem:/ {printf "%.2f", $3 / (1024*1024*1024)}'
}

get_gpu_metrics() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits | awk -F',' '{
            sum_util += $1
            sum_mem += $2
        } END {
            printf "%.2f,%.2f", sum_util/NR, sum_mem/(NR*1024)
        }'
    else
        echo "0,0"
    fi
}

# Main monitoring loop (end with Ctrl-C)
while true; do
    UNIX_TIMESTAMP=$(date +%s)
    TIMESTAMP=$(date -d @$UNIX_TIMESTAMP +"%Y-%m-%d %H:%M:%S")
    CPU=$(get_cpu_usage)
    RAM=$(get_ram_usage)
    GPU_METRICS=$(get_gpu_metrics)

    echo "${TIMESTAMP},${UNIX_TIMESTAMP},${CPU},${RAM},${GPU_METRICS}" >> "$OUTPUT_FILE"

    sleep $INTERVAL
done
