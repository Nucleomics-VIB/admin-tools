#! /bin/bash

# script: create_project_onL.sh
# get Experiment number as argument
# create new Project folder name from google sheet info
# run this code on gbw-s-nuc01 (NCWIKI) in /var/www/cgi-bin
#
# Stephane Plaisance (VIB-NC) 2020/07/13; v1.0
# visit our Git: https://github.com/Nucleomics-VIB

# version="1.0.0, 2020_07_13"
version="1.1.0, 2023_04_12"

# single input
number=$1

Lmount="/mnt/nuc-data"
projects="${Lmount}/Projects"
template="${Lmount}/AppData/CreateProjectDirectory/Copy-to-Y-projects/Workflow_Exp0000.docm"

# Google sheet address
url="https://docs.google.com/spreadsheets/d/e/2PACX-1vSjnT4BA1TyM8GROH0kUM-CSr0pQD6qnidF68XzB5rUwxwKcSpkrgytXb3Q6BIinvs2xl2tn9ikjPBR/pub?gid=536507405&single=true&output=tsv"

declare -A types
types=(
  [Unknown]="Unknown"
  [BioInformatics]="BioIT"
  [Illumina_MiSeq]="MiSeq"
  [Illumina_NextSeq_2000]="NextSeq2000"
  [Illumina_iSeq_100]="iSeq100"
  [Illumina_NovaSeq_6000]="NovaSeq6000"
  [PacBio_Sequel_IIe]="Sequel2e"
  [ONT_GridION]="GridIon"
  [ONT_P2Solo]="P2"
  [Element_Bio_AVITI]="Aviti"
  [MGI_DNBSEQ-G400]="G400"
  [SampleQC]="QC"
  [Library_Prep]="LibraryPrep"
  [Shearing]="Shearing"
)

# fetch info in the Google sheet based on the experiment number alone
declare -a data
IFS="," ; data=( $(wget -q -o /dev/null -O - ${url} | \
  gawk -v num="${number}" 'BEGIN{FS="\t"; OFS=","}{if ($1==num) print $1, $4, $8}') )

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
	echo "# ${foldername} already exists!"
	exit 1
fi

############################
# create folder tree

case "${shorttype}" in
	BioIT )
		mkdir -p ${projects}/${foldername}/{Data,RawData,Scripts} ;;
	QC )
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