#!/bin/bash

# script name: check_mount.sh
# check that L: and T: are valid mount points
# Stephane Plaisance - VIB-NC Nov-20-2018 v1.0
# added on gbw-s-nuc01 server:
# /etc/cron.d/check_mounts-cron
# 0 */6 * * *	root	/root/check_mounts.sh /mnt/nuc-data
# 1 */6 * * *	root	/root/check_mounts.sh /mnt/nuc-transfer

# variables
if [ -z "${1}" ]
then
	echo "# provide a valid mount point as argument"
	echo "# eg: /mnt/nuc-data"
	exit 1
else
	mountpoint=$1
fi

# vars
currdate=$(date '+%Y-%m-%d %H:%M:%S')
curhost=$(hostname)

# mail for status, edit for your use
mailit='/opt/biotools/scripts/mailit.sh'
mailfrom="$(basename $0)"
mailto="stephane.plaisance@vib.be"
mailcontent="bye!"

###### no edit below this line #######

######################################
# check that the mountpoint is valid #
######################################

if mountpoint -q "${mountpoint}"; then
    echo "${mountpoint} is a mountpoint"
    # ${mailit} -f ${mailfrom} -t ${mailto} -s "OK!: ${mountpoint} is mounted on ${curhost}" -m "* ${mailcontent}\n\n${currdate}";
else
    echo "${mountpoint} is not a mountpoint"
    ${mailit} -f ${mailfrom} -t ${mailto} -s "ERROR!: ${mountpoint} is not mounted on ${curhost}, please check it" -m "* ${mailcontent}\n\n${currdate}";
  exit 1;
fi
