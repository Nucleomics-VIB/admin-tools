#!/bin/bash

# par_rsync.sh
# https://www.krazyworks.com/making-rsync-faster/
# Stéphane Plaisance - VIB-Nucleomics Core - 2019-12-23 v1.0

if [ $# -lt 2 ]; then
    echo "usage: par_rsync.sh <ori-folder> <dest-folder>"
    echo "       optional: <parallel-jobs (default: 16)> <rsync options (default:rlgoDvx)>"
    exit
fi

# Define source, target, maxdepth and cd to source
source=${1}
target=${2}
maxthreads=${3:-30}
rsyncopts=${4:-"rlgoDvx"}

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
 nohup rsync -${rsyncopts} "${source}/${subfolder}/" "${target}/${subfolder}/" </dev/null >/dev/null 2>&1 &
 fi
done
 
# Find all files above the maxdepth level and rsync them as well
find . -maxdepth ${depth} -type f -print0 | rsync -${rsyncopts} --files-from=- --from0 ./ "${target}/"
