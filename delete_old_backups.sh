#!/bin/bash

# delete backups that are not from
# the last 7 days
# the last 4 sundays
# the first sunday of the last 12 months 
# the first sunday of the last 5 years

# Stephane Plaisance - VIB-NC Jan-26-2018 v1.1
# v1.1, autodelete with -a as second argument

# variables
if [ -z "${1}" ]
then
	echo "# provide the backup path as argument"
	echo "# /mnt/nuc-data/Archive/Backup/invoiceplane-general"
	echo "# .../invoiceplane-pacbio"
	echo "# .../wikilix"
	exit 1
else
	backuppath=$1
fi

# delete without confirm
if [ "${2}" == "-a" ]
then
	echo "# deleting old backups automatically"
	export delauto=1
fi

##################################### begin custom functions ##################################

# custom function to produce date array
keepdates ()
{
local -a keep
for i in $(seq 0 6)
do
	(( keep[$(date +%Y%m%d -d "-$i day")]++ ))
done
for i in $(seq 0 3)
do
	(( keep[$(date +%Y%m%d -d "sunday-$((i+1)) week")]++ ))
done
motm=$(date +%Y-%m-15)
for i in $(seq 0 11)
do
	DW=$(( $(date +%-W)-$(date -d $(date -d "$motm -$i month" +%Y-%m-01) +%-W) ))

	for  (( AY=$(date -d "$motm -$i month" +%Y);  $AY < $(date +%Y); AY++ ))
	do
		(( DW+=$(date -d $AY-12-31 +%W) ))
	done
	(( keep[$(date +%Y%m%d -d "sunday-$DW weeks")]++ ))
done
for i in $(seq 0 5)
do
	DW=$(date +%-W)
	EY=$(date +%Y)
	for (( AY=$(( EY-i )); $AY < $EY; AY++ ))
	do
		(( DW+=$(date -d $AY-12-31 +%W) ))
	done
	(( keep[$(date +%Y%m%d -d "sunday-$DW weeks")]++ ))
done
echo ${!keep[@]}
}

# custom function to test if a date is in the list
containsElement () {
	# containsElement "blaha" "${array[@]}"; echo $?
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}

###################################### end custom functions ##################################

# create list in bash array
tokeep=( $(keepdates) )
echo "# kept dates are:"
echo "# ${tokeep[@]}"

# parse folder and keep/delete files based on the date list
# files are expected to be named as YYYYMMDD_* to match valid archive names
# other files will not be processed

list=$( find "${backuppath}" -type f -regex '.*/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_.*' -printf "%P " )
slist=( $(echo ${list[*]}| tr " " "\n" | sort -n) )

for f in "${slist[@]}"
do
	# extract date from name
	date="${f:0:8}"

	# test date
	containsElement "${date}" "${tokeep[@]}"

	if [ $? -eq 0 ]; then
		echo "${f} will be kept"
	else
		if [[ ${delauto} -eq 1 ]]; then
			# delete straight, no confirm
			rm "${backuppath}/${f}" && echo "${f} was deleted"
		else
			# ask user to confirm deletion
			echo "${f} will be deleted"
			read -r -p "Are you sure? [y/N] " response
			if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
				rm "${backuppath}/${f}"
			fi
		fi
	fi
done
# end