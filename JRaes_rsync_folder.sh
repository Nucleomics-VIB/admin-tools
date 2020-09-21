#!/bin/bash

# script: JRaes_rsync_folder.sh
# send data to JRaes share @PSB
# requires sshpass, rsync
#
# Stephane Plaisance (VIB-NC) 2019/03/12; v1.0

read -d '' usage <<- EOF
Usage: JRaes_rsync_folder.sh <password> (more will be asked at runtime)
EOF

password=${1}

# test minimal argument
if [ -z "${password}" ]; then
   echo "# no password provided!"
   echo -e "${usage}" >&2
   exit 1
fi

# list current folder
echo "current folder contains:"
ls -lah .
echo "-----------------------------------------------------------------------------------"
echo

# get details from user

echo -n "Local Folder to transfer [ENTER]: "
read BASE

# transfer files
echo "transfering folder and content"
sshpass -p ${password} \
  rsync --progress -avzr -e 'ssh -p 7788' \
    ${BASE}/* \
    nucleomics-core@zeus.psb.ugent.be:/metagenomes/nucleomics-core/${BASE}
