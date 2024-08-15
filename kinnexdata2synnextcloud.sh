#!/bin/bash

# script: kinnexdata2synnextcloud.sh
# transfer data after Kinnex demux copy from SMRTlink to local folder

# Check if exactly two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Error: You must provide exactly two arguments."
    echo "Usage: $0 <expnum> <custstring>"
    echo "eg: 4776, EDumas_PacBio_16S"
    exit 1
fi

expnum=${1} # 4776
custstring=${2} # "EDumas_PacBio_16S"
destdir="/mnt/syn_hdd/SYN_NextCloud/003_PpProjects"

# no edits below this line
sourcedir=$PWD

targetdir="${destdir}/${expnum}_${custstring}"
mkdir -p "${targetdir}"

filelist="${expnum}_file_list.txt"
#collect files to transfer
ls *.csv > ${filelist}
ls *.pdf >> ${filelist}
ls demultiplexing_files/*.hifi_reads.lima.counts >> ${filelist}
ls demultiplexing_files/*.hifi_reads.lima.summary.txt >> ${filelist}
ls demultiplexing_files/*.html >> ${filelist}
find fastx_files -name "*.fastq.gz" >> ${filelist}

# create tar archive
tar -cvf \
  ${expnum}_archive.tar \
  --files-from=${filelist} \
  --transform 's|^|./|'

md5sum ${expnum}_archive.tar > ${expnum}_archive_md5.txt
md5sum -c ${expnum}_archive_md5.txt && \
  mv ${expnum}_archive* ${targetdir}/

# add readme
cp /data/NC_projects/Rmd-report_template/README.txt ${targetdir}/

# create share and add sharing info
create_nextcloud_share.sh \
  -t 003_PpProjects \
  -f ${expnum}_${custstring} \
  -s 30

