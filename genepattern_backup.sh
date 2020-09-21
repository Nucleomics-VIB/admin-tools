#!/bin/bash

# script: genepattern_backup.sh
# Aim:
# compress and archive GenePatternServer to the mounted L: drive
# compress and archive GenePatternUploads to the mounted L: drive

### REQUIREMENTS
# become genepattern in order to run the script
# stop the server before proceeding
# edit the names and path's below before executing the script
## pigz installed for gzip speedup

# SP@NC, 2017_09_28, v 1.0

usage='## Usage: genepattern_backup.sh
# -s <backup GenePatternServer folder (default off)>
# -u <backup GenePatternUploads folder (default off)>
# -h <show this help>'

if [[ ! $@ =~ ^\-.+ ]]; then echo "# This command requires arguments"; echo "${usage}"; exit 1; fi

while getopts "suh" opt; do
  case $opt in
    s) archiveServer=true ;;
    u) archiveUploads=true ;;
    h) echo "${usage}" >&2; exit 0 ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
    *) echo "# This command requires arguments, try -h" >&2; exit 1 ;;
  esac
done

timestamp=$(date '+%Y%m%d_%H%M')

########## variables, edit here ##########################################
# server
thehost="MAF-SRV-04"
gpuser="genepattern"
theprocess="StartGenePatternServer.lax"

# GenePatternServer
serverpath=/opt/tools
serverfolder=GenePatternServer
serverarchive=${serverfolder}_${timestamp}.tgz

# GenePatternUploads
uploadpath=/data
uploadfolder=GenePatternUploads
uploadarchive=${uploadfolder}_${timestamp}.tgz

# archive destination
outfolder=/mnt/nuc-data/GBW-0011_NUC/Archive/Backup/GenePatternServer
############ no edit necessary below this limit ##########################

### test various things ####

# check running as ${gpuser}
if [ ! "$(whoami)" == "${gpuser}" ]; then
  echo "# You are now on \"$(whoami)\" but should run this script as \"${gpuser}\" as defined in this script header"
  exit 1
fi

# check current host
if [ ! "$(hostname)" == "${thehost}" ]; then
  echo "# You are now on \"$(hostname)\" but should run this script from \"${thehost}\" as defined in this script header"
  exit 1
fi

# check if server is running
ps -aux | grep [^]]"${theprocess}"
if [ $? -eq 0 ]; then
  echo "# GenePatternServer is running, stop it before runnning this script"
  exit 1
fi

# check destination folder exists
cd ${outfolder}

# test for success
if [ $? -ne 0 ] ; then
  echo "# could not change dir to ${outfolder}, check that L: is mounted as defined in this script header" 
  exit 1
fi

#############################
# archive GenePatternServer #
#############################

if [ "${archiveServer}" = true ]; then

# check for the GenePatternServer folder
if [ ! -d "${serverpath}/${serverfolder}" ]; then
  echo "# The GenePatternServer is not found as defined in this script header"
  exit 1
fi

echo
echo "# archiving the GenePatternServer folder \"${serverpath}/${serverfolder}\" to \"${outfolder}\""
cd ${serverpath} && tar --use-compress-program="pigz -p8" -cf ${outfolder}/${serverarchive} ${serverfolder}

# test for success
if [ $? -ne 0 ] ; then
  echo "# the ${serverfolder} archive creation failed, check the folder path in this script header"
  exit 1
fi

cd ${outfolder}
ls -lah "${serverarchive}"

# end archive GenePatternServer
fi

##############################
# archive GenePatternUploads #
##############################

if [ "${archiveUploads}" = true ]; then

echo
echo "# archiving the GenePatternUploads folder \"${uploadpath}/${uploadfolder}\" to \"${outfolder}\""
cd ${uploadpath} && tar --use-compress-program="pigz -p8" -cf ${outfolder}/${uploadarchive} ${uploadfolder}

# test for success
if [ $? -ne 0 ] ; then
  echo "# the ${uploadfolder} archive creation failed, check the folder path in this script header"
  exit 1
fi

cd ${outfolder}
ls -lah "${uploadarchive}"

# end archive GenePatternUploads
fi
