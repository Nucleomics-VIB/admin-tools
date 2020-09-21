#!/bin/bash

# script: get_blast_db.sh
# Aim: download the blast nt database to the local folder using parallel threads
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2018-11-21 v1.0
#
# visit our Git: https://github.com/Nucleomics-VIB

usage="## Usage: get_blast_db.sh
# -u <base URL (eg: ftp://ftp.ncbi.nlm.nih.gov/blast/db/nt ; required)>
# -m <current highest value for the nt archive parts (eg nt_66.tar.gz => 66 ; required)>
# -p <number of parallel wget jobs (default: 8)>
# -h <show this help>"

if [[ ! $@ =~ ^\-.+ ]]; then echo "# This command requires arguments"; echo "${usage}"; exit 1; fi

while getopts "u:m:p:h" opt; do
  case $opt in
    u) opt_url=${OPTARG} ;;
	m) opt_max=${OPTARG} ;;
    p) opt_para=${OPTARG} ;;
    h) echo "${usage}" >&2; exit 0 ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
    *) echo "# This command requires arguments, try -h" >&2; exit 1 ;;
  esac
done

# test if minimal arguments were provided
if [ -z "${opt_url}" ]
then
   echo "# provide the base URL here (eg: ftp://ftp.ncbi.nlm.nih.gov/blast/db/nt)"
   echo "${usage}"
   exit 1
fi

if [ -z "${opt_max}" ]
then
   echo "# highest value for the archive parts (eg nt_66.tar.gz => 66)"
   echo "${usage}"
   exit 1
fi

# 'para' the number of parallel downloads
para=${opt_para:-8}
dig=${#opt_max}

echo "# getting archives"

# get archives
printf %0${dig}d\\n $(seq 0 ${opt_max}) \
    | xargs -n 1 -P ${para} -I{} wget ${opt_url}."{}".tar.gz
echo
echo "# getting md5sums"

# get checksums
printf %0${dig}d\\n $(seq 0 ${opt_max}) \
    | xargs -n 1 -P ${para} -I{} wget ${opt_url}."{}".tar.gz.md5

echo
echo "# checking md5sums"
 
# check all locally
printf %0${dig}d\\n $(seq 0 ${opt_max}) \
    | xargs -n 1 -P ${para} -I{} md5sum -c nt."{}".tar.gz.md5 \
    | grep -v "OK" | tee -a errors.txt

if [ -s "errors.txt" ]
then
   echo "# errors were found "
   cat errors.txt
else
   echo
   echo "# no error found "
   # expand and cleanup
   cat *.tar.gz | tar -zxf - -i \
     && mkdir tgz_files \
     && mv *.tar.gz *.md5 tgz_files/
fi
