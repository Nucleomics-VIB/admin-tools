#!/bin/bash

# script: md5sum_recursive.sh
# create md5sum for all files in provided path
#
# Stephane Plaisance (VIB-NC) 2019/03/12; v1.0

path=${1}
title=${2:-"$(basename ${1})_md5sum.txt"}

read -d '' usage <<- EOF
Usage: md5sum_recursive.sh <path> <prefix>
# <path> to checksum for all files recursively
# <prefix> for the md5sum.txt output (or '<basename of path>_md5sum.txt' as default)
EOF

# test minimal argument
if [ -z "${path}" ]; then
   echo "# no input path provided!"
   echo -e "${usage}" >&2
   exit 1
fi

echo "# creating md5 checksums for all files in ${path}"
find ${path} -type f -exec md5sum '{}' \; > ${title}

echo "# performing a md5 check against the original"
md5sum --quiet -c ${title}

echo "# if no output above, all when well!"
