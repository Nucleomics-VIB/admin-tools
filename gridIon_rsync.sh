#!/bin/bash

# script: gridion_rsync.sh
# send data to a NAS via ssh + rsync
# requires sshpass, rsync
# !! requires that the target server has been added to known hosts 
# before running this, which can be done by a simple ssh session
#
# Stephane Plaisance (VIB-NC) 2020/04/02; v1.0

read -d '' usage <<- EOF
Usage: gridion_rsync.sh (more will be asked at runtime)
EOF

ts=$(date +%s)

# list current folder
echo "current folder contains:"
ls -lah .
echo "-----------------------------------------------------------------------------------"
echo

# get details from user
echo -n "Enter source path (globbing allowed), eg multiplex_run8_24_pool*') [ENTER]: "
read SOURCE

echo -n "Enter server IP:/<full-path> [ENTER]: "
read SRV_PATH

echo -n "Enter user login [ENTER]: "
read USER

stty -echo
echo -n "Enter user login [ENTER]: "
read PASSWD
stty echo

# transfer archive file
echo
echo "transfering ${SOURCE} files"

sshpass -p ${PASSWD} \
  rsync --progress -avz -e 'ssh ' \
    ${SOURCE} \
    ${USER}@${SRV_PATH} > \
    transfer_log_${ts}.txt 2>&1

