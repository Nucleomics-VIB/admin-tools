#!/usr/bin/bash

# script taxid2lineages.sh
# create taxid to lineage database from ncbi dumps
# from: https://github.com/zyxue/ncbitax2lin
# SP@NC 2023-08-30; v1.0
#
# visit our Git: https://github.com/Nucleomics-VIB

echo "# get the current taxdump.tar.gz from ncbi"

wget -N ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz

if [ ! -f "taxdump.tar.gz" ]; then
    echo "Error: taxdump.tar.gz not found. Download the file first."
    exit 1
fi

echo "# decompress the ncbi archive"

mkdir -p taxdump && tar zxf taxdump.tar.gz -C ./taxdump

if [ ! -d "taxdump" ]; then
    echo "Error: taxdump directory not found. Extract taxdump.tar.gz first."
    exit 1
fi

# Check if the conda environment is available
myenv=biopython
source /etc/profile.d/conda.sh
conda activate ${myenv} || \
  ( echo "# the conda environment ${myenv} was not found on this machine" ;
    echo "# please read the top part of the script!" \
    && exit 1 )

# Check if the required files exist
if [ ! -f "taxdump/nodes.dmp" ] || [ ! -f "taxdump/names.dmp" ]; then
    echo "Error: Required files (nodes.dmp and names.dmp) not found in taxdump directory."
    exit 1
fi

echo "# parse the dump data and create new lineage file"

ncbitax2lin --nodes-file taxdump/nodes.dmp --names-file taxdump/names.dmp && \
 rm -rf taxdump taxdump.tar.gz

# the resulting gzipped file is named ncbi_lineages_[date_of_utcnow].csv.gz
# it can be converted to a sqlite3 database using python

conda deactivate
