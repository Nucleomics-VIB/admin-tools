#!/bin/sh

# shared functions for NCDataMngr
# StŽphane Plaisance - VIB-Nucleomics Core - 2019-12-23 v1.0
#
# commented echo can be used to debug
# please add inline documentation to explain your code
# also add example ActionScript usage in your comments

#--------------------------------------------------------------------------------------
# GENERAL FUNCTIONS
#--------------------------------------------------------------------------------------


#--------------------------------------------------------------------------------------
# parse yaml config file and create variables with prefix
# usage in terminal: parse_yaml sample.yml "CONF_"
# usage in script: eval $(parse_yaml sample.yml "CONF_")
# from: https://www.thetopsites.net/article/50350760.shtml


function parse_yaml() # parse yaml config file and create variables with prefix
{
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\):|\1|" \
    -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
    -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
  awk -F$fs '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
      vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
      printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
    }'
}


# --------------------------------------------------------------------------------------
# parse run_config.yaml and declare corresponding variables
# required: parse_yaml


function process_config() # parse run_config.yaml and declare corresponding variables
{
  config=$1
  if [[ -f "${config}" ]]; then
    set -a
    # create tmp file and source it to populate the variables
    parse_yaml ${config} "CONF_" > .tmp && \
    . .tmp
    # echo "# ${run_config} was sourced"
    rm .tmp
    set +a
  else
    echo "${config} not found"
    exit 1
  fi
}


# --------------------------------------------------------------------------------------
# list available Actions from allowed_actions.yaml
# required: parse_yaml


function listactions() # list available Actions from allowed_actions.yaml
{
  parse_yaml allowed_actions.yaml > .tmp
  while read l; do
    echo "${l}"
    echo "${l}" | sed 's/^\(.*\)_usage=("\(.*\)")$/\1_\2/)'
  done < .tmp && rm .tmp
}


# --------------------------------------------------------------------------------------
# checks if a string congtains a substring
# from: https://stackoverflow.com/questions/
#       229551/how-to-check-if-a-string-contains-a-substring-in-bash
# usage:
#    stringContains "MN[0-9]*" ${position} && { 
#      platform="Minion"
#      deviceid=${position}
#      position="na"; }
# ==> do not forget space after '{' and '; ' before '}'

function stringContains() # checks if a string congtains a substring
{
  reqsubstr="$1"
  shift
  string="$@"
  if [ -z "${string##*$reqsubstr*}" ] ;then
    # echo "String '$string' contain substring: '$reqsubstr'.";
    return 0
  else
    # echo "String '$string' does not contain substring: '$reqsubstr'."
    return 1
  fi
}


#--------------------------------------------------------------------------------------
# test if an input file or folder exists or die
# usage:


# file_exists <some path> || { echo "# <some path> not found"; exit 1 ; }
function file_exists() # check if file exists
{
  [[ -f "$1" ]] || return 1;
}


# folder_exists <some path> || { echo "# <some path> not found"; exit 1 ; }
function folder_exists() # check if folder exists
{
  [[ -d "$1" ]] || return 1;
}


#--------------------------------------------------------------------------------------
# check if last command succeeded or die with message
function cmdOK() # check if last command succeeded
{
  if [ $? -ne 0 ]
  then
    echo "!! something went wrong, quitting."
    exit 1
  fi
}
