#!/bin/bash

# script: NCDataMngr.sh
#
# aim: manage a number of axction scripts to create, modify and add to the NC Share database

# all dependencies absent from a standard linux OS 
# are listed in dependencies.yaml for future workflow developments

# Stéphane Plaisance - VIB-Nucleomics Core - 2020-09-08 v1.0

######################
# initialisation
######################

scriptname=$(basename "$0")
scriptversion='1.0_2020-09-10'

usage='# Usage: '${scriptname}' -a <action> -p <action parameter array>
#
# script version '${scriptversion}'
# [optional: -c <path to run_config.yaml (default to run_config.yaml in current folder)>]
# [optional: -l to list the available actions]
# [optional: -h <this help text>]'

# handle getops
while getopts "a:p:c:lh" opt; do
	case $opt in
		a) opt_action=${OPTARG};;
		p) opt_actparams+=("${OPTARG}");; # READ 'ABOUT' BELOW !
		c) opt_config=${OPTARG};;
		l) opt_listactions=1;;
		h) echo "${usage}" >&2; exit 0;;
		\?) echo "# Invalid option: -${OPTARG}" >&2; exit 1;;
		*) echo "# this command requires arguments, try -h" >&2; exit 1;;
	esac
done
shift $(( OPTIND - 1 ))

# ABOUT: opt_actparams is an array of parameters needed by the action
# you can pass as many -p <variable>=<value> pairs as needed with format:
# * no spaces or = in var names
# * use single quotes around multiword values
# * no special characters 
# in your action scripts, the variables will be ready for use
#  see ==> ActionDemo

# the quote symbols can be nice to have in complex calls
# use them as ${q} and ${d} where needed (hint: sqlite queries)
q="'"
d='"'

# create backups folder for DB copies
mkdir -p backups

# source shared functions from the shared subfolder
[[ -n $(find shared -maxdepth 1 -type f -name '*_functions.sh') ]] \
	&& { for f in shared/*_functions.sh; do . $f; done; } \
	|| { echo "# *_functions.sh not found in shared/"; exit 1; }

# read yaml configuration and process it
run_config=${opt_config:-"run_config.yaml"}
process_config ${run_config}

# check if mount is present or die
folder_exists ${CONF_mount_point}/${CONF_mount_path} || { echo "# Storage not found, please check the 'run_config.yaml' settings and mounted drives"; exit 1; }

# check duc ssh access
test_duc_ssh || { echo "check your ssh connection to the DUC server"; exit 1;}

# list allowed actions
if [ -n "${opt_listactions}" ]
then
	echo "#-----------------------------------------------------------------------------"
	echo "# List of current Actions:"
	echo "#-----------------------------------------------------------------------------"
	parse_yaml allowed_actions.yaml | \
	  sort |
	  sed -e $'s/_usage=/\\\n  /g'
	echo "#-----------------------------------------------------------------------------"
	exit 0
fi

# was action provided?
if [ -z "${opt_action}" ]
then
	echo "# no action provided"
	echo "${usage}"
	exit 1
fi

# check if provided action is valid (present in allowed_actions.yaml)
if ! grep -wq "${opt_action}" allowed_actions.yaml; then
    echo "# action '${opt_action}' was not found, please check your spelling"
    exit 1
fi

# REM: when present the array ${opt_actparams} is parsed and 
#      extracted variables are passed to the subscript 

if [ ! -z "${opt_actparams}" ]
then

  # extract and declare variables
  for var in "${opt_actparams[@]}"; do
    # extract variable name and value
    read name value <<< $(echo ${var} | awk -F= '{print $1, $2}')
    my_vars=( ${my_vars[@]} "${name}" )
    # handle several times the same variable name
    if [ -z ${!name} ]; then
      # new variable, gets unique value
      declare "${var}"
    else
      # variable already exists, add new value in it as array
      arr_insert ${name} ${value}
    fi
  done

  # retain unique variable names when duplicates are present
  my_vars=( $(printf "%s\n" "${my_vars[@]}" | sort -u) )

fi

# source the named ActionScript (do it!)
. tools/${opt_action} 

exit 0
