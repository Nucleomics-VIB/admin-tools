#!/bin/bash

# A script to log all output to a file and report the total run time
# scriptname: runandlog.sh
# usage: runandlog <command> <parameters>
# Stephane Plaisance VIB-BITS June-1-2014 v1.0

# send copy of all outputs to logfile
timeinit=$(date +%s)
exec > >(tee logfile-${timeinit}.txt)

# also capture stderr
exec 2>&1

function timerun() {
# report total run duration
endtime=$(date +%s)
echo
echo "# run started at: "$(echo ${timeinit} | awk '{print strftime("%Y-%m-%d %T",$1)}')
echo "# run ended at: "$(date +%F" "%T)
dur=$(( ${endtime}-${timeinit} ))
echo "# run total duration: "$( echo - | awk -v "S=${dur}" '{printf "%dd:%dh:%dm:%ds",S/60/60%24,S/(60*60),S%(60*60)/60,S%60}' )
echo
}

# execute command from $@ (array of command and parameters)
cmd=$@
echo "# Your command was: ${cmd}"

# execute the command and report time if success
eval "${cmd}" && timerun

# test returned code
RESULT=$?

if [ $RESULT -eq 0 ]; then
  echo -n "# the command succeeded in: " 
  timerun
else
  echo "# the command failed"
fi
