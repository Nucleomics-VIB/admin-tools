#!/bin/bash

# script: create_transfer_archive.sh
# prepare data transfer tar archive
# from a list of files and folders in the current path
#
# SP@NC; version 1.0;  2025-02-20

# take arg or default list file as input
list=${1:-"transfer_list.txt"}

# create archive from the prepared list
tar cf - -C $(dirname $(realpath $list)) \
  -T <(sed 's|^./||' ${list}) \
  --transform 's|^|analysis_data/|' \
  | tee >(md5sum > analysis_data_checksum.md5) | gzip -c > analysis_data.tar.gz