#!/bin/env bash

# Runs a script, saves STDOUT and STDERR to a log file,
#   and collect usage information with log_usage.sh
# when the command end successfully, stops the usage collection from its stored PID#
# all outputs are saved in the local folder
# scriptname: log_usage_wrapper.sh
#
# Stephane Plaisance VIB-NC July-22-2018 v1.0
# requires: lscpu, mpstat, sar & free
#
# visit our Git: https://github.com/Nucleomics-VIB

usage='# Usage: log_usage_wrapper.sh
#    -s <script to execute (required)>
#    -l <name for the run log file (required)
#    -t <usage log time interval (default 60)>
#    -p <usage log decimal precision (default 2)>
#    -h <display this help'

while getopts "s:l:t:p:h" opt; do
 case $opt in
    s) opt_script=${OPTARG} ;;
    l) opt_logfile=${OPTARG} ;;
    t) opt_timeint=${OPTARG} ;;
    p) opt_precision=${OPTARG} ;;
    h) echo "${usage}" >&2; exit 0 ;;
    *) echo "${usage}" >&2; exit 0 ;;
  esac
done

# check if log_usage.sh is in PATH
hash log_usage.sh 2>/dev/null || ( echo "# log_usage.sh not found in PATH"; exit 1 )

# check log_usage.sh dependencies
hash lscpu 2>/dev/null || ( echo "# lscpu not installed or not in PATH"; exit 1 )
hash mpstat 2>/dev/null || ( echo "# mpstat not installed or not in PATH"; exit 1 )
hash sar 2>/dev/null || ( echo "# sar not installed or not in PATH"; exit 1 )
hash free 2>/dev/null || ( echo "# free not installed or not in PATH"; exit 1 )

if [ -z "${opt_script}" ]
then
   echo "# no script provided for monitoring!"
   echo "${usage}"
   exit 1
fi

if [ -z "${opt_logfile}" ]
then
   echo "# no name provided for the command log file!"
   echo "${usage}"
   exit 1
fi

startts=$(date +%s)

# start monitoring in background
log_usage.sh -t "${opt_timeint:-60}" -p "${opt_precision:-2}" -l "${opt_logfile:-"log.txt"}" &
MONITOR_PID=$!

echo "# executing: ${opt_script} (${MONITOR_PID})"
"${opt_script}" 2>&1  | tee -a "${opt_logfile}"

endts=$(date +%s)
dur=$(echo "${endts}-${startts}" | bc)

echo "Done in ${dur} sec" | tee -a "${opt_logfile}"

# stop monitoring
kill "$MONITOR_PID"
