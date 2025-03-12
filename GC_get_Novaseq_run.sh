#!/bin/bash

# scripts: GC_get_Novaseq_run.sh
# download run files from bucket
# Stephane Plaisance (VIB-NC) 2025/03/12; v1.0
#
# visit our Git: https://github.com/Nucleomics-VIB

version="1.0, 2025-03-12"

# default values
destdir="/mnt/nuc-transfer/0003_Runs/Novaseq6000"
rundir="runs"

usage='# Usage: GC_get_Novaseq_run.sh <args>
# -d <destination folder (default : '${destdir}')
# -R <runs_dir (obtained from "gsutil ls gs://gcpi-rvvnc/": default '${rundir}')>
# -r <run_id (obtained from "gsutil ls gs://gcpi-rvvnc/<runs_dir>", this folder will not be synched but its content will be!)>
# -l <show the list of runs_dir currently present on the server (specify -r to get subfolders)>]
# -h <this help>
# script version '${version}'
# [-h for this help]'

while getopts "d:R:r:lh" opt; do
  case $opt in
    d) destdir=${OPTARG} ;;
    R) rundir=${OPTARG} ;;
    r) runid=${OPTARG} ;;
    l) echo "# Runs data currently available on the bucket";
    		gsutil ls gs://gcpi-rvvnc/${rundir:-""}/${runid:-""};
			exit 0 ;;
    h) echo "${usage}" >&2; exit 0 ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
    *) echo "this command requires arguments, try -h" >&2; exit 1 ;;
  esac
done

# test if minimal arguments were provided
if [ -z "${rundir}" ]
then
   echo "# no run folder name provided!"
   echo "${usage}"
   exit 1
fi

if [ -z "${runid}" ]
then
   echo "# no runID folder name provided!"
   echo "${usage}"
   exit 1
fi

# get target folder name
runfolder=$(gsutil ls gs://gcpi-rvvnc/${rundir}/${runid})
destid=$(basename ${runfolder})

# create local folder
mkdir -p ${destdir}/${destid} 

# get run folder
echo -e "\n# getting run data as ${destid}"

cmd="gsutil -m rsync -r -x '^.*Thumbnail_Images.*$' gs://gcpi-rvvnc/${rundir}/${runid}/${destid} ${destdir}/${destid}"

echo "# cmd: ${cmd}"

eval ${cmd} && echo -e "\n\n# copy done"
