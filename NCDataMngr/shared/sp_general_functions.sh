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


function parse_yaml {
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


function process_config {
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


function listactions {
  parse_yaml allowed_actions.yaml > .tmp
  while read l; do
    echo "${l}"
    echo "${l}" | sed 's/^\(.*\)_usage=("\(.*\)")$/\1_\2/)'
  done < .tmp && rm .tmp
}


#--------------------------------------------------------------------------------------
# join array elements with separator given as $1
#  usage_1 join_by ',' ${array[@]}
#  rem: do not quote ${array[@]}
#  usage_2 join_by '|' one two "three four" 5 "a {more} : (complex) = \example"


function join_by {
  sep=$1
  shift
  # join the remaining elements and remove leading ${sep}
  printf "${sep}%s" "${@}" | sed s"/^${sep}//"
}


#--------------------------------------------------------------------------------------
# split string into array 
# default separator is '|'
# usage: res=( $(split2array "var=124" "=") )
# echo $res[0] => var
# echo $res[1] => 124


function split2array {
  input=$1
  sep=${2:-"|"}
  IFS="${sep}" read -r -a result <<< "${input}"
  echo "${result[@]}"
}


#--------------------------------------------------------------------------------------
# split a list of pairs into two arrays 
# default list separator is ' '
# default pair separator is '='
# usage: local IFS="|" read keys values <<< $(pairlist2arrays "key1=val1 key2=val2 key3=3")
# echo $keys[@] => key1 key2 key3
# echo $val[@] => val1 val2 3
# echo $keys[0] => key1
# echo $val[0] => val1


function pairlist2arrays {
  input=$1
  outsep=$2
  # convert argument $1 to array
  listofpairs=( $(echo $input) ); # a space delimited list of key=value pairs
  # convert row into two arrays, one for keys and one for values
  local keyarray=()
  local valarray=()
  for kv_pair in "${listofpairs[@]}"; do
    # split one pair to the two arrays
    spl=( $(split2array "${kv_pair}" "=") )
    # add to both arrays
    keyarray+=( "${spl[0]}" )
    valarray+=( "${spl[1]}" )
  done
  # return results as a '|' separated string
  echo "${keyarray[@]}|${valarray[@]}"
  }


#--------------------------------------------------------------------------------------
# test if element ($1) is in array ($@) 
# pass the array like -p varname='element1 element2 element3'

# usage:
# inArray "${query}" "${array[@]}" || { echo "# ${query} is not a valid element"; exit 1; }


function inArray {
  q=$1
  shift
  # debug: echo "# looking for $q in $@"
  while [ $# -gt 0 ]; do
    [[ "$q" == "$1" ]] && return 0; # found
    shift
  done
  # not found
  return 1
}


#--------------------------------------------------------------------------------------
# test if an input file or folder exists or die
# usage:


# file_exists <some path> || { echo "# <some path> not found"; exit 1 ; }
function file_exists {
  [[ -f "$1" ]] || return 1;
}


# folder_exists <some path> || { echo "# <some path> not found"; exit 1 ; }
function folder_exists {
  [[ -d "$1" ]] || return 1;
}


#--------------------------------------------------------------------------------------
# check if last command succeeded or die with message
function cmdOK () {
  if [ $? -ne 0 ]
  then
    echo "!! something went wrong, quitting."
    exit 1
  fi
}
