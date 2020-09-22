#!/usr/bin/env bash

# A script to log the cpu disk_IO% and RAM(GB) usage
# launch in separate window to monitor a job
# scriptname: log_usage.sh
#
# Stephane Plaisance VIB-NC July-22-2018 v1.0
# v1.1: added disk usage in local folder
# requires: lscpu, mpstat, sar, free, and du
# see usagelog2plot.R for plotting
#
# visit our Git: https://github.com/Nucleomics-VIB

version="1.1, 2018-07-27"

usage='# Usage: log_usage.sh
#    -t <log-frequency in sec (default 60sec)>
#    -p <precision for output (decimals, default 2)
#    -h <this help message>
# version: '${version}

while getopts "t:p:h" opt; do
  case $opt in
    t) timeint=${OPTARG} ;;
    p) precision=${OPTARG} ;;
    h | *) echo "${usage}" >&2; exit 0 ;;
  esac
done

# check dependencies
$( hash lscpu 2>/dev/null ) || ( echo "# lscpu not installed or not in PATH"; exit 1 )
$( hash mpstat 2>/dev/null ) || ( echo "# mpstat not installed or not in PATH"; exit 1 )
$( hash sar 2>/dev/null ) || ( echo "# sar not installed or not in PATH"; exit 1 )
$( hash free 2>/dev/null ) || ( echo "# free not installed or not in PATH"; exit 1 )
$( hash du 2>/dev/null ) || ( echo "# du not installed or not in PATH"; exit 1 )

# precision
SCALE=${precision:-2}

# repeat loop every x sec
FREQ=${timeint:-60}

# log file name and header
LOG_FILE=resource_usage_"$(date +%s)".log
echo "logtime,cpu,diskIO,memGB,diskGB" > $LOG_FILE

echo "# logging to $LOG_FILE every $FREQ sec"
echo "# press <Ctrl>-C to stop logging"

# infinite loop will run until ctrl-C is hit
while :; do

# get values
stamp=$(date +%s)
cpu=$(echo "scale=${SCALE}; $(mpstat -u 1 1 | tail -1 | awk '{print $3}') / 1" | bc)
disktps=$(echo "scale=${SCALE}; $(sar -b 1 1 | tail -1 | awk '{print $2}') / 1" | bc)
memgb=$(echo "scale=${SCALE}; $(free | head -2 | tail -1 | awk '{print $3}') / 1000000" | bc)
curpath=$(pwd)
diskusg=$(echo "scale=${SCALE}; $(du -s ${curpath} | cut -f 1) / 1048576" | bc)

# return csv
echo "${stamp},${cpu},${disktps},${memgb},${diskusg}" >> $LOG_FILE
sleep ${FREQ}

done

# when the app closes, no additional line will be added to the log file
