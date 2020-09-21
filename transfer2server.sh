#!/bin/bash

# script: transfer2server.sh
# Aim: transfer data to a SSH server (with available account)
# used to share data with the group of Stein Aerts

### REQUIREMENTS
## SSH access to the KUL server
## rsync installed
# based on Rekin's Janky's command

# SP@NC, 2018_06_04, v 1.0

# defaults matching Stein Aert's server
default_user="u0002316"
default_server="gbw-s-seq07.luna.kuleuven.be"
default_destpath="/media/gbw_shares4/lcb/share/"

usage="## Usage: transfer2server.sh (repeat the command until no extra transfer occurs)
# -i <source file/folder to sync (required)>
# -o <name for the destination folder (required)>
# -u <userID to use for ssh access (default to "${default_user}")>
# -s <destination server address (default to "${default_server}")>
# -p <destination path in which to create the destination folder (default to "${default_destpath}")> 
# -h <show this help>"

if [[ ! $@ =~ ^\-.+ ]]; then echo "# This command requires arguments"; echo "${usage}"; exit 1; fi

while getopts "i:o:u:s:p:h" opt; do
  case $opt in
    i) opt_sourcefolder=${OPTARG} ;;
	o) opt_destfolder=${OPTARG} ;;
    u) opt_user=${OPTARG} ;;
	s) opt_server=${OPTARG} ;;
	p) opt_destpath=${OPTARG} ;;
    h) echo "${usage}" >&2; exit 0 ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
    *) echo "# This command requires arguments, try -h" >&2; exit 1 ;;
  esac
done

# check if requirements are present
$( hash rsync 2>/dev/null ) || ( echo "# rsync not found in PATH"; exit 1 )

# test if minimal arguments were provided
if [ -z "${opt_sourcefolder}" ]
then
   echo "# no source folder provided or folder not existing!"
   echo "${usage}"
   exit 1
fi

if [ -z "${opt_destfolder}" ]
then
   echo "# no destination folder provided!"
   echo "${usage}"
   exit 1
fi

# or defaults
sshuser=${opt_user:-"${default_user}"}
destserver=${opt_server:-"${default_server}"}
destpath=${opt_destpath:-"${default_destpath}"}

cmd="rsync -avz --rsync-path=\"mkdir -p ${destpath%/}/${opt_destfolder} && rsync \" \
	${opt_sourcefolder} \
	${sshuser}@${destserver}:${destpath%/}/${opt_destfolder%/}/"
	
echo "# command: ${cmd}"
eval ${cmd}
