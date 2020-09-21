#!/bin/bash

# for all .fastq files in the current path
# * find the files
# * compress each file next to the original
# * delete the original if compression command succeeded
# SP@NC - 2019-08-22; v1.0

# work with parallel jobs for speedup
par=8
thr=4

inlist="file_list_for_compression.txt"
donelist="compressed_ok.txt"

# create working list with single quotes because some path have spaces (BAD habbit!)
find . -type f \( -name \*.fq -o -name \*.fastq \) -printf "'%p'\n" > ${inlist}

# compressing with ${par} jobs using each ${thr} threads
cat ${inlist} \
  | xargs -n 1 -P ${par} -I% (pigz -p ${thr} -c % \
  > %.gz \
  && echo % >> ${donelist})

# if all went fine, delete processed fastq
if [ $? -eq 0 ]; then
    # compression completed, now deletiong fastq files
    cat ${donelist} | xargs -n 1 -P ${par} -I% rm %
else
    echo "something went wrong!"
    echo "looking for differences between ${inlist} and ${donelist}"
    echo "to locate failed compressions"
    echo "# the following "$(comm -23 <(sort ${inlist}) \
    <(sort ${donelist}) \
    | wc -l)" fastq out of "$(wc -l ${inlist})" were not compressed"
    comm -23 <(sort ${inlist}) <(sort ${donelist})
    return; # or 'exit 0'?
fi

# look for survivors
echo "# so far so good!"
echo "# now looking for uncompressed fastq files in the path" 
find . -type f \( -name \*.fq -o -name \*.fastq \) -printf "'%p'\n"
