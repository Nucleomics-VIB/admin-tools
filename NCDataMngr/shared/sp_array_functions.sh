# shared functions for NCDataMngr
# StŽphane Plaisance - VIB-Nucleomics Core - 2019-12-23 v1.0
#
# from: http://www.ludvikjerabek.com/2015/08/24/getting-bashed-by-dynamic-arrays/


#--------------------------------------------------------------------------------------
# Array FUNCTIONS
#--------------------------------------------------------------------------------------

# test if variable is Array eg; is_arr a (no leading '$' unless a dynamic name)
function is_arr() {
  [[ ! "$1" =~ ^\$?[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  # the leading '$' is only used if the array is dynamic
  eval declare -p $1 2> /dev/null | grep -q '^declare \-a'; # && echo "yes" || echo "no"
}

# Dynamically create an array by name
function arr() {
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  # The following line can be replaced with 'declare -ag $1=\(\)'
  # Note: For some reason when using 'declare -ag $1' without the parentheses will make 'declare -p' fail
  eval $1=\(\)
}

# Insert incrementing by incrementing index eg. array+=(data)
function arr_insert() {
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  declare -p "$1" > /dev/null 2>&1
  [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
  eval $1[\$\(\(\${#${1}[@]}\)\)]=\$2
}

# Update an index by position
function arr_set() {
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  declare -p "$1" > /dev/null 2>&1
  [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
  eval ${1}[${2}]=\${3}
}

# Get the array content ${array[@]}
function arr_get() {
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
  declare -p "$1" > /dev/null 2>&1
  [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
  eval echo \${${1}[@]}
}

# Get the value stored at a specific index eg. ${array[0]}
function arr_at() {
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
function arr_count() {
  [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable " 1>&2 ; return 1 ; }
  declare -p "$1" > /dev/null 2>&1
  [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
  local v=${1}
  eval echo \${\#${1}[@]}
}
