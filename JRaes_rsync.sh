#!/bin/bash

# script: JRaes_rsync.sh
# send data to JRaes share @PSB
# requires sshpass, rsync
#
# Stephane Plaisance (VIB-NC) 2019/03/12; v1.0

read -d '' usage <<- EOF
Usage: JRaes_rsync.sh <password> (more will be asked at runtime)
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
echo -n "Enter archive name to transfer [ENTER]: "
read archive

echo -n "Enter EXP_NB [ENTER]: "
read EXP_NB

echo -n "Enter LIB_ID [ENTER]: "
read LIB_ID

# transfer archive file
echo "transfering archive file"
sshpass -p ${password} \
  rsync --progress -avz -e 'ssh -p 7788' \
    ${archive} \
    nucleomics-core@zeus.psb.ugent.be:/metagenomes/nucleomics-core/exp${EXP_NB}_${LIB_ID}

# transfer md5sum file too if present
if [ -f "${archive}_md5*.txt" ]; then
echo "transfering MD5sum file"
sshpass -p ${password} \
  rsync --progress -avz -e 'ssh -p 7788' \
    ${archive}_md5*.txt \
    nucleomics-core@zeus.psb.ugent.be:/metagenomes/nucleomics-core/exp${EXP_NB}_${LIB_ID}
fi
