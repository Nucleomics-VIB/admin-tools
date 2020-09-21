#! /bin/bash

# script: gdriveadmin.sh
# add and or remove an old version of a google drive file
# Stéphane Plaisance - VIB-NC June-06-2018 v1.0
# visit our Git: https://github.com/Nucleomics-VIB
# correct typos 2018/08/18; v1.1.1
# add retry 2019/04/02; v1.2

# requirements:
# gdrive https://github.com/prasmussen/gdrive 
# gdrive about => connection established 

#version="1.1.2, 2019_01_23"
version="1.2, 2019_04_02"

# custom functions to retry and fail after 5 retries
function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=5
  local delay=15
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

# list all files on drive
echo "# the current files on your drive are:"
retry gdrive list
echo

# ask which file to rollout
read -p "Paste one of the UUID for processing " uuid
echo

echo "# ${uuid} has the following revisions:"
retry gdrive revision list ${uuid}
echo

# add new version
read -p "Do you have a new revision to upload (y/n)? " answer
echo
case ${answer:0:1} in
    y|Y )
    	read -p "path to the new file: " path
        retry gdrive update ${uuid} ${path}
        echo
        retry gdrive revision list ${uuid}
    ;;
    * )
        echo Ok
    ;;
esac
echo

# remove old version
read -p "Do you wish to delete a revision (y/n)? " answer
echo
case ${answer:0:1} in
    y|Y )
    	read -p "uuid of the version to delete: " deluuid
        retry gdrive revision delete ${uuid} ${deluuid}
        echo
        retry gdrive revision list ${uuid}
    ;;
    * )
        echo Ok
    ;;
esac
echo

# add a new file
read -p "Do you wish to add a file (y/n)? " answer
echo
case ${answer:0:1} in
    y|Y )
    	read -p "path to the new file: " path
        retry gdrive upload ${path}
        echo
    ;;
    * )
        echo Ok
    ;;
esac