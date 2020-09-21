#! /bin/bash

# script: create_project_folder_onL.sh
# get Experiment number as argument
# create new Project folder name from google sheet info
# run this code on gbw-s-nuc01 (NCWIKI) in /var/www/cgi-bin
# called from within: create_project_folder_onL.php
#
# Stephane Plaisance (VIB-NC) 2020/07/13; v1.0
# visit our Git: https://github.com/Nucleomics-VIB

version="1.0.0, 2020_07_13"

# single input
number=$1

Lmount="/mnt/nuc-data"
projects="${Lmount}/Projects"
template="${Lmount}/AppData/CreateProjectDirectory/Copy-to-Y-projects/Workflow_Exp0000.docm"

# Google sheet address
shareID=<you access ID obtained from google drive>
gid=<gdrive gid>
url="https://docs.google.com/spreadsheets/d/${shareID}/export?format=tsv&id=${shareID}&gid=${gid}"

# TO BE EDITED AFTER CORRECTING THE GOOGLE SHEET
declare -A types
types=(
  [Unknown]="Unknown"
  [Bioinformatics\ Only]="BioIOnly"
  [Illumina\ MiSeq]="MiSeq"
  [Illumina\ NextSeq]="NextSeq"
  [Illumina\ HiSeq]="HiSeq"
  [Illumina\ NovaSeq]="NovaSeq"
  [PacBio\ Sequel]="PacBio"
  [Oxford\ Nanopore\ GridION]="GridIon"
  [MGI\ DNBSEQ-G400]="DNBSEQ-G400"
  [QC\ Only]="SampleQC"
)

# fetch info in the Google sheet based on the experiment number alone
declare -a data
IFS="," ; data=( $(wget -q -o /dev/null -O - ${url} | gawk -v num="${number}" 'BEGIN{FS="\t"; OFS=","}{if ($1==num) print $1, $4, $8}') )

# extract info and build folder name
exp=${data[0]}

############################
# stop if no Google data
if [ -z ${exp} ]; then
echo "# no data found for ${number} in the Google sheet"
exit 1
fi

############################
# build folder name
IFS=" "; arr=(${data[1]})
first=${arr[0]:0:1}
first=${first^}
last=${arr[1]}
longtype=${data[2]:-"Unknown"}
shorttype=${types[${longtype}]}
foldername=${exp}"_"${first}${last}_${shorttype}

############################
# stop if folder exists
if [ -d "${projects}/${foldername}" ]; then
	echo "# Folder ${foldername} already exists!"
	exit 1
fi

############################
# create folder tree

case "${shorttype}" in
	BioIOnly )
		mkdir -p ${projects}/${foldername}/{Data,RawData,Scripts} ;;
	SampleQC )
		mkdir -p ${projects}/${foldername}/{Data,RawData,WetLab} ;;
	* )
		mkdir -p ${projects}/${foldername}/{Data,RawData,WetLab,Scripts} ;;
esac 

if [ $? -ne 0 ]; then
	echo "# there was a problem while creating the folder"
	exit 1
fi

############################
# copy template
cp ${template} \
	"${projects}/${foldername}/$(basename ${template%_Exp0000.docm})_Exp${exp}.docm"

if [ $? -ne 0 ]; then
	echo "# there was a problem while copying the template"
	exit 1
fi

touch "${projects}/${foldername}/created_$(date +'%d-%m-%Y_%H:%M:%S')"
echo "# ${foldername} created and template copied"
