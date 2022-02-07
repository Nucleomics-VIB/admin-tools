# shared functions for NCDataMngr
# Stphane Plaisance - VIB-Nucleomics Core - 2019-12-23 v0.1
#


#--------------------------------------------------------------------------------------
# Array FUNCTIONS
#--------------------------------------------------------------------------------------


#--------------------------------------------------------------------------------------
# join array elements with separator given as $1
#  usage_1 join_by ',' ${array[@]}
#  rem: do not quote ${array[@]}
#  usage_2 join_by '|' one two "three four" 5 "a {more} : (complex) = \example"


function join_by() # join array elements with separator given as $1
{
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


function split2array() # split string into array
{
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


function pairlist2arrays() # split a list of pairs into two arrays
{
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
# test if element '$1' is in array '$@' 
# pass the array like -p varname='element1 element2 element3'

# usage:
# inArray "${query}" "${array[@]}" || { echo "# ${query} is not a valid element"; exit 1; }


function inArray() # test if element '$1' is in array '$@'
{
  # ex: inArray ${folder_status} ${CONF_folder_status[@]} (no quotes around variables!)
  local query=$1
  shift
  # debug: echo "# looking for $q in $@"
  while [ $# -gt 0 ]; do
    [[ "$query" == "$1" ]] && return 0; # found
    shift
  done
  # not found
  return 1
}


# test if variable is Array eg. is_arr a (no leading '$' unless a dynamic name)
# inspired by ludvikjerabek, code from: https://stackoverflow.com/questions/
#  14525296/how-do-i-check-if-variable-is-an-array


function is_arr() # test if a variable is an array
{
  [[ ! "$1" =~ ^\$?[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  # the leading '$' is only used if the array is dynamic
  eval declare -p $1 2> /dev/null | grep -q '^declare \-a'; # && echo "yes" || echo "no"
}

#--------------------------------------------------------------------------------------
# More Array FUNCTIONS and dynamic arrays
#--------------------------------------------------------------------------------------
# from: http://www.ludvikjerabek.com/2015/08/24/getting-bashed-by-dynamic-arrays/


# Dynamically create an array by name
function arr() # Dynamically create an array by name
{
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  # The following line can be replaced with 'declare -ag $1=\(\)'
  # Note: For some reason when using 'declare -ag $1' without the parentheses will make 'declare -p' fail
  eval $1=\(\)
}

# Insert element at the end of array eg. array+=(data)
function arr_insert() # Insert element at the end of array
{
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  declare -p "$1" > /dev/null 2>&1
  [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
  eval $1[\$\(\(\${#${1}[@]}\)\)]=\$2
}

# Update an index at position
function arr_set() # replace array element by index
{
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  declare -p "$1" > /dev/null 2>&1
  [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
  eval ${1}[${2}]=\${3}
}

# Get the array content ${array[@]}
function arr_get() # get an array content
{
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  declare -p "$1" > /dev/null 2>&1
  [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
  eval echo \${${1}[@]}
}

# Get the value stored at a specific index eg. ${array[0]}
function arr_at() # Get array element at specific index
{
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  declare -p "$1" > /dev/null 2>&1
  [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
  [[ ! "$2" =~ ^(0|[-]?[1-9]+[0-9]*)$ ]] && { echo "Array index must be a number" 1>&2 ; return 1 ; }
  local v=$1
  local i=$2
  local max=$(eval echo \${\#${1}[@]})
  # Array has items and index is in range
  if [[ $max -gt 0 && $i -ge 0 && $i -lt $max ]]
  then 
  eval echo \${$v[$i]}
  fi
}

# Get array length eg. ${#array[@]}
function arr_count() # get array length
{
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable " 1>&2 ; return 1 ; }
  declare -p "$1" > /dev/null 2>&1
  [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
  local v=${1}
  eval echo \${\#${1}[@]}
}
