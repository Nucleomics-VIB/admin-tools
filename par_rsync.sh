#!/bin/bash

# script: par_rsync.sh
# run rsync in several parallel jobs for speedup
# the list of all source folders up to depth 2 is split in $j jobs and processed
# 
# from: https://www.krazyworks.com/making-rsync-faster/
# Stéphane Plaisance - VIB-Nucleomics Core - 2019-12-23 v1.0

# v1.01: add optargs
# visit our Git: https://github.com/Nucleomics-VIB

version="1.01, 2023_03_24"

usage='# Usage: par_rsync.sh
# -s <path to run folder (in the current path)> 
# -t <path to output folder (in the current path)>
# optional -j <number of parallel rsync jobs (default: 4)>
# optional -o <overwrite rsync options (default: rlgoDvx)>
# note: parallel jobs are not normalized, some may take longer!
# script version '${version}'
# [-h for this help]'

while getopts "s:t:j:o:h" opt; do
  case $opt in
    s) opt_source=${OPTARG} ;;
    t) opt_target=${OPTARG} ;;
    j) opt_jobs=${OPTARG} ;;
    o) opt_args=${OPTARG} ;;
    h) echo "${usage}" >&2; exit 0 ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
    *) echo "this command requires arguments, try -h" >&2; exit 1 ;;
  esac
done

# check if required arguments were provided
if [ -z "${opt_source+x}" ] || [ -z "${opt_target+x}" ]
then
   echo "# please provide mandatory arguments -s and -t!"
   echo "${usage}"
   exit 1
fi

# Define source, target, maxdepth and cd to source
source=${opt_source}
target=${opt_target}
maxthreads=${opt_jobs:-4}
rsyncopts=${opt_args:-"rlgoDvx"}

# Find all folders in the source directory within the maxdepth level
depth=2

# How long to wait before checking the number of rsync threads again
sleeptime=5

# move to source folder
cd "${source}"

find . -maxdepth ${depth} -type d | while read dir;
do
 # Make sure to ignore the parent folder
 if [ $(echo "${dir}" | awk -F'/' '{print NF}') -gt ${depth} ];
 then
 # Strip leading dot slash
 subfolder=$(echo "${dir}" | sed 's@^./@@g')
 if [ ! -d "${target}/${subfolder}" ];
 then
 # Create destination folder and set ownership and permissions to match source
 mkdir -p "${target}/${subfolder}"
 chown --reference="${source}/${subfolder}" "${target}/${subfolder}"
 chmod --reference="${source}/${subfolder}" "${target}/${subfolder}"
 fi
 # Make sure the number of rsync threads running is below the threshold
 while [ $(ps -ef | grep -c [r]sync) -gt ${maxthreads} ];
 do
 echo "Sleeping ${sleeptime} seconds"
 sleep ${sleeptime}
 done
 # Run rsync in background for the current subfolder and move one to the next one
 nohup rsync -${rsyncopts} "${source}/${subfolder}/" "${target}/${subfolder}/" \
   </dev/null \
   >/dev/null 2>&1 &
 fi
done
 
# Find all files above the maxdepth level and rsync them as well
find . -maxdepth ${depth} -type f -print0 | \
  rsync -${rsyncopts} --files-from=- --from0 ./ "${target}/"
