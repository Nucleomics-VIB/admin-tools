#!/bin/bash

# script         :logUsageGPU.sh
# description    :Script to monitor and log system resource usage
# author         :SP@NC (AI)
# date           :2025-02-05
# version        :1.0
# usage          :./logUsage.sh
# notes          :Monitors RAM, CPU, and GPU usage during SLURM or local jobs

# Set the interval in seconds
N=10

# set to SLURM job if exists otherwise to 'local'
${SLURM_JOB_ID:=local}

# Set the output file name using SLURM_JOB_ID
OUTPUT_FILE="job_${SLURM_JOB_ID}_metrics.txt"

# Print header
echo "Timestamp,UnixTimestamp,CPU_Usage(cores),RAM_Usage(GB),GPU_Usage(%),GPU_Memory(GB)" > $OUTPUT_FILE

# Function to get CPU usage in cores
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | awk '{printf "%.2f", $1 * '"$(nproc)"' / 100}'
}

# Function to get RAM usage in GB
get_ram_usage() {
    free -b | awk '/Mem:/ {printf "%.2f", $3 / (1024*1024*1024)}'
}

# Function to check GPU existence and get GPU usage in percentage and memory in GB
get_gpu_metrics() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits | awk -F',' '{printf "%.2f,%.2f", $1, $2/1024}'
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

    echo "${TIMESTAMP},${UNIX_TIMESTAMP},${CPU},${RAM},${GPU_METRICS}" >> $OUTPUT_FILE

    sleep $N
done
