#!/bin/bash

# script: SAV2archive.sh
# Aim: create a SAV archive from files present in a Illumina Run folder
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2020-09-21 v1.1
#
# visit our Git: https://github.com/Nucleomics-VIB

usage="## Usage: SAV2archive.sh
# -i <Illumina Run folder> (eg. 190921_7001450_0495_AH5JJ7BCX3 - required)
# -o <path to save the archive> (default to T:/IlluminaSavData)
# -T <if present: add Thumbnail_Images.zip (default OFF)
# -t <thread number for pigz (default 1)
# -v <verbose output during archiving> (default OFF)
# -l <log commands and outputs to file> (default OFF)
# -h <show this help>"

if [[ ! $@ =~ ^\-.+ ]]; then 
  echo "# This command requires arguments"
  echo "${usage}"
  exit 1
fi

while getopts "i:o:t:Tvlh" opt; do
  case $opt in
    i) opt_runfolder=${OPTARG} ;;
    o) opt_savfolder=${OPTARG} ;;
    T) opt_thumb=1 ;;
    v) opt_verbose="v" ;;
    l) opt_log=1 ;;
    t) opt_thr=${OPTARG} ;;
    h) echo "${usage}" >&2; exit 0 ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
    *) echo "# This command requires arguments, try -h" >&2; exit 1 ;;
  esac
done

# check if requirements are present
$( hash tar 2>/dev/null ) || ( echo "# tar not found in PATH"; exit 1 )
$( hash pigz 2>/dev/null ) || ( echo "# pigz not found in PATH"; exit 1 )

# test if minimal arguments were provided
if [ -z "${opt_runfolder}" ]; then
  echo "# no Run folder provided!"
  echo "${usage}"
  exit 1
fi

# check if exists
if [ ! -d "${opt_runfolder}" ]; then
  echo "# Run folder not found, please check!"
  echo "${usage}"
  exit 1
fi

# get run name and parent folder
runname=$(basename ${opt_runfolder%_QC})
parent=$(dirname ${opt_runfolder%_QC})

# set destination
destfolder_default="/mnt/nuc-transfer/0003_Runs/IlluminaSavData"
destfolder=${opt_savfolder:-"${destfolder_default}"}

# check if exists
if [ ! -d "${destfolder}" ]; then
  echo "# destination folder not found, please mount or create it!"
  echo "${usage}"
  exit 1
fi

# count threads present and check -t
thrcnt=$(grep -c processor /proc/cpuinfo)
thr=${opt_thr:-1}

if [ ${thr} -gt ${thrcnt} ]; then
   echo "# only ${thrcnt} on this machine, please adapt your command!"
   echo "${usage}"
   exit 1
fi

# create timestamp
ts=$(date +%s)

# verbosity
v=${opt_verbose:-""}

# capture all to log from here if -l was provided
${opt_log} ] && exec &> >(tee -i SAV2archive_${ts}.log)

######################################

# check if all required SAV files are present
test -f ${opt_runfolder}/RunInfo.xml || ( echo "RunInfo.xml not found!"; exit 1 )
test -f ${opt_runfolder}/[Rr]unParameters.xml || ( echo "RunParameters.xml not found!"; exit 1 )
test -d ${opt_runfolder}/InterOp || ( echo "InterOp not found!"; exit 1 )

# to avoid adding the full path to the data at restore
# we need to cd to the parent of the data folder before running tar
# curdir is where we will come back after the archiving is done
curdir=$(pwd)

# user asks to include Thumbnail_Images ?

if [ -n "${opt_thumb}" ] && [ -d "${opt_runfolder}/Thumbnail_Images" ]; then

  # include Thumbnail_Images as a zip
  cmd="cd ${parent} && tar -c${v}f - ${runname}/Thumbnail_Images \
         | pigz -p ${thr} \
         > ${runname}/Thumbnail_Images.zip && \
    tar -c${v}f - -C ${parent} ${runname}/RunInfo.xml \
      ${runname}/[Rr]unParameters.xml \
      ${runname}/InterOp \
      ${runname}/Thumbnail_Images.zip \
      | pigz -p ${thr} \
        > ${destfolder}/${runname}_SAV-archive+.tgz && \
          touch ${destfolder}/${runname}_SAV-archive_created && \
          rm ${runname}/Thumbnail_Images.zip && \
          cd ${curdir}"

  echo "# ${cmd}"
  eval ${cmd}

else

  # do not include Thumbnail_Images
  cmd="cd ${parent} && tar -c${v}f - ${runname}/RunInfo.xml \
    ${runname}/[Rr]unParameters.xml \
    ${runname}/InterOp \
    | pigz -p ${thr} \
      > ${destfolder}/${runname}_SAV-archive.tgz && \
        touch ${destfolder}/${runname}_SAV-archive_created && \
          cd ${curdir}"

  echo "# ${cmd}"
  eval ${cmd}

fi

exit 0
