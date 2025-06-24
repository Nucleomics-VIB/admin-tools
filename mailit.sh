#!/usr/bin/env bash

# script name: mailit.sh
# send a system mail after IT task 
# (requires sendmail installed and running)
# Stephane Plaisance (VIB-NC+BITS) 2017/04/21; v1.0
#
# visit our Git: https://github.com/Nucleomics-VIB

# check parameters for your system
version="1.0.1, 2018_11_20"

usage='# Usage: mailit.sh -f <from email> -t <to email> -s <subject> -m <message>
# script version '${version}'
# [optional: -h <this help text>]'

while getopts "F:f:T:t:S:s:M:m:h" opt; do
  case $opt in
    F|f) fromopt=${OPTARG} ;;
    T|t) to=${OPTARG} ;;
    S|s) subject=${OPTARG} ;;
    M|m) message=${OPTARG} ;;
    H|h) echo "${usage}" >&2; exit 0 ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
    *) echo "this command requires arguments, try -h" >&2; exit 1 ;;
  esac
done

# check dependencies
$( hash sendmail 2>/dev/null ) || \
	( echo "# sendmail not installed or not in PATH"; exit 1 )

# check all args provided
# test if minimal arguments were provided
if [ -z "${to}" ] || [ -z "${subject}" ] || [ -z "${message}" ]
then
   echo "# #to, #subject, and #message are required!"
   echo "${usage}"
   exit 1
fi

# when from is not provided, take the local user & machine
from=${fromopt:-"$(echo $(whoami)\@$(hostname))"}

$(which sendmail) ${to} << EOM
From: ${from}
To: $(echo "${to}")
Subject: $(echo "${subject}")
$(printf "${message}" \($(date)\))
EOM
