#!/bin/bash
#
# script: create_nextcloud_share.sh
# create a new shared folder on Nextcloud using cloud-dl
# start sharing it for a period of X days (default to 30)
# save the random password and share URL to a file
# adapted from code produced in an older script: NextSeq2000DataDelivery_SP.pl
# requires cloud-dl installed and config file created in user $HOME
# requires openssh to create the password
#
# Stephane Plaisance (VIB-NC) 2024/07/01; v1.0

#####################
# default parameters
#####################

# all of these can be changed using specific arguments

# Default server base URL
default_server_base_url="https://nextnuc.gbiomed.kuleuven.be"

# default mount to root (empty to have access to all NC Nextcloud mounts)
default_mount="NUC_Syn_NextCloud"

# Default sharing duration in days
default_share_duration=30

############
# FUNCTIONS
############

# scroll down to find the executed code

# Function to display usage
display_usage() {
    echo "Usage: $0 [-m <mount name>] [-t <target folder>] [-f <shared folder>] [-s <share_duration>] [-l <list target folder>]"
    echo "Options:"
    echo " -m <mount_name>          Name of the NextCloud mount point"
    echo " -t <target_folder>       Name of the target folder on the NextCloud mount point (of: 001_Runs, 002_RawFastq, 003_PpProject)"
    echo " -f <shared folder_name>  Name of the folder to create on the NextCloud"
    echo " -s <share_duration>      Duration of the sharing in days (default: $share_duration)"
    echo " -l <list target folder>  Show the list of current folders on /mount/target/..."
    echo " -h Display this help message"
}

function get_user_args(){
    while getopts ":b:m:t:f:s:lh" opt; do
        case $opt in
            b)
                opt_base_url=$OPTARG
                ;;
            m)
                opt_mount=$OPTARG
                ;;
            t)
                opt_target=$OPTARG
                ;;
            f)
                opt_folder=$OPTARG
                ;;
            s)
                opt_duration=$OPTARG
                ;;
            l)
                opt_list=TRUE
                ;;
            h)
                display_usage
                exit 0
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                display_usage
                exit 1
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                display_usage
                exit 1
                ;;
        esac
    done
}

# Check if cloud-dl is installed
check_cloud_dl() {
    if ! command -v cloud-dl &> /dev/null; then
        echo "Error: cloud-dl command not found. Please install cloud-dl before running this script."
        exit 1
    fi
}

# Check if openssl is installed
check_openssl() {
    if ! command -v openssl &> /dev/null; then
        echo "Error: openssl command not found. Please install openssl before running this script."
        exit 1
    fi
}

# Function to check for .cloudconf file
check_cloudconf() {
    local home_dir=$1
    local cloudconf_file="$home_dir/.cloudconf"
    
    if [ -f "$cloudconf_file" ]; then
        # Load server base URL from .cloudconf
        server_base_url=$(grep "^host=" "$cloudconf_file" | cut -d'=' -f2)
        webdav_path=$(grep "^path=" "$cloudconf_file" | cut -d'=' -f2)
        nc_share=$(echo "${webdav_path}" | cut -d'/' -f 3)
        echo "${nc_share}"
    else
        echo "Error: .cloudconf file not found in $home_dir"
        exit 1
    fi
}

# Function to validate the mount path
validate_target() {
    local target=${1//\/}
    local valid_folders=( "001_Runs" "002_RawFastq" "003_PpProject" "Test_Nextflow" )
    for folder in "${valid_folders[@]}"; do
        if [ "${target}" == "${folder}" ]; then
            return 0
        fi
    done
    echo "invalid target folder: ${target}, should be of (001_Runs, 002_RawFastq, 003_PpProject)!"
    return 1
}

# Function to check if dest folder already exists
test_dest_folder_exists() {
    local mount=$1
    local target=$2
    local folder=$3
    notfound="[!] Error listing files"
    test=$(cloud-dl -l "${mount}/${target}/${folder}")
    if [[ "${test}" == "${notfound}" ]]; then
        return 0
    else
        return 1
    fi
    # should not come further
    return 1
}


# Function to check for .cloudconf file
list_share() {
    local path_to_list=$1
    cmd="cloud-dl -l ${path_to_list}"
    echo "# ${cmd}"
    eval ${cmd}
}

create_and_share(){
        # start sharing process
        echo "# Nextcloud sharing information:" > /tmp/sharing_info.txt
        # Generate a random password
        password=$(openssl rand -base64 9)
        end_date=$(date -d "+${share_duration} days" +"%Y-%m-%d")
        # create new folder        
        cmd="cloud-dl -k ${mount_path}${target_path}${dest_path}"
        #echo "# ${cmd}"
        create_folder_result=$(eval ${cmd}) || (echo "# something went wrong while creating folder; exit 1)")
        #echo "# folder creation: ${create_folder_result}"
        # Share the new folder with the generated password and duration
        cmd="cloud-dl -S ${mount_path}${target_path}${dest_path} $password $share_duration"
        #echo "# ${cmd}"
        share_result=$(eval ${cmd})
        IFS='|' read -ra parts <<< "${share_result}"
        ( echo "share-URL:${parts[1]}";
        echo "password:${parts[2]}";
        echo "("${parts[3]#"${parts[3]%%[![:space:]]*}"}")") | tee -a /tmp/sharing_info.txt
        cloud-dl -u /tmp/sharing_info.txt ${mount_path}${target_path}${dest_path}/
        echo "New folder created and shared successfully!"
        echo "Credentials saved to 'sharing_info.txt' and copied to the share."
        # cleanup
        rm /tmp/sharing_info.txt
}

#######
# CODE
#######

# check we are a go with cloud-dl
check_cloud_dl
check_cloudconf $HOME

# same for openssl
check_openssl

# get user arguments
get_user_args "$@"

# check if command had arguments
if [ $# -eq 0 ]; then
  display_usage
  exit 0
fi

# Construct the full path
server_base_url="${opt_base_url:-${default_server_base_url}}/"
mount_path="${opt_mount:-${default_mount}}/"
target_path="${opt_target}/"
dest_path="${opt_folder}/"
share_path="${mount_path}${target_path}${dest_path}"
#echo "# share_path: ${share_path}"
full_path="${server_base_url}${share_path}"
#echo "# full_path: ${full_path}"
share_duration="${opt_duration:-${default_share_duration}}"
#echo "# share duration ${share_duration}"

# case list target folder = TRUE
if [ -n "${opt_list}" ]; then
    list_share "${share_path}"
    exit 0
fi

###################################
# create a new folder and share it
###################################

# Check if folder_name is provided
if [ -z "$opt_folder" ]; then
    echo "folder_name is required"
    display_usage
fi

# Validate the mount_path if it's provided
if [ -n "${target_path}" ]; then
    if ! validate_target "${target_path}"; then
        echo "Error: Invalid target path. Please choose one of: 001_Runs, 002_RawFastq, 003_PpProject (Test_Nextflow)."
        exit 1
    fi
fi

# test if share folder already exists
if [ -n "${dest_path}" ]; then
    # check if it folder already exists on the share
    if $(test_dest_folder_exists "${mount_path}" "${target_path}" "${dest_path}"); then
        # start sharing process
        create_and_share
    else
        echo "# folder already exists, quitting"
        exit 1
    fi
fi



