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


#--------------------------------------------------------------------------------------
# SQLITE3 FUNCTIONS
#--------------------------------------------------------------------------------------

# add to actions relying on relation at each sqlite3 call 'PRAGMA foreign_keys = ON'

#--------------------------------------------------------------------------------------
# get the version of the current DB

function DBversion {
  cmd="sqlite3 ${d}${CONF_database_path}/${CONF_database_name}${d} 'SELECT * FROM version;'"
  eval "${cmd}"
}


#--------------------------------------------------------------------------------------
# get the list of fields in a sqlite table
# required by (addRow2Folders, addRow2Actions)

function listfields {
  table=$1
  cmd="sqlite3 ${d}${CONF_database_path}/${CONF_database_name}${d} 'PRAGMA table_info("${table}");'"
  eval "${cmd}" | tr "\r" "\n"
}


#--------------------------------------------------------------------------------------
# get the list of fields in a sqlite table and return csv or custom delimited-list
# specific to csv


function csfields {
  table=$1
  fields=()
  fieldlist=($(listfields ${table}))
  for f in ${fieldlist[@]}; do
    a=($(split2array ${f}))
    fields=(${fields[@]} ${a[1]})
  done
  echo $(local IFS=',' echo "${fields[*]}")
}


# more generic version of above but with csv as default
# list of fields with chosen separator (or ',' as default)

function delimited_fields {
  table=$1
  delim=${2:-","}
  fields=()
  fieldlist=($(listfields ${table}))
  for f in ${fieldlist[@]}; do
    a=($(split2array ${f}))
    fields=(${fields[@]} ${a[1]})
  done
  echo $(IFS="${delim}" echo "${fields[*]}")
}


#--------------------------------------------------------------------------------------
# create a new record in Folders
# in dev not working yet
# requires split2array


function validDBFields {
  table=$1
  row=( $(echo $2) ); # an array of value pairs field=value to build a table row

  # fetch the current table fields into a new array
  existing_fields=( $(delimited_fields "${table}" " ") )
  # echo "# existing fields are: ${existing_fields[@]}"

  # check keys in all pairs 
  for pair in "${row[@]}"; do
    # convert row into two arrays, one for fields and one for values
    declare -a k=()
    declare -a v=()

    # transpose row into a new array
    res=$(pairlist2arrays "${pair}")
    # echo "res has content: ${res[@]}"
    IFS='|' read -a ar <<< "${res}"
    # echo "keys are: ${ar[O]}";     # => FolderID Creator BAD

    # check if all keys are valid
    for k in "${ar[O]}"; do
      inArray "${k}" "${existing_fields[@]}" || { echo "# ${k} is not a valid '"${table}"' field"; }
    done
  done
  
  # echo "# all fields are valid"
  return 0
}


#--------------------------------------------------------------------------------------
# send a query on a table + fields and return the row count
# several field=value pairs can be provided to build a specific query
# example arguments: Folders FolderPath=<...> FolderName=<...>
# obviously the fields should exist in that table
# the function returns the number of matching rows
# 0 means that the row does not exist

function Querytable2Count {
  table=$1
  shift
  query=( $@ ); # an array of value pairs field=value to build a table row

  # build base sqlite SELECT call
  sqlq="SELECT COUNT(*) FROM ${table} WHERE "

  # add WHERE clause(s)
  wherec=""
  for kv_pair in ${query[@]}; do
    # split one pair to the two arrays
    spl=( $(split2array "${kv_pair}" "=") )
    # add to both arrays
    wherec="${wherec} AND ${spl[0]}=${d}${spl[1]}${d}"
  done

  # concatenate run and return count
  sqlq=${sqlq}${wherec# AND }
  cmd="sqlite3 ${d}${CONF_database_path}/${CONF_database_name}${d} ${s}${sqlq}${s};"
  # echo "# ${cmd}"
  eval "${cmd}"
}


#--------------------------------------------------------------------------------------
# send a query on a table + fields and return the filtered rows
# several field=value pairs can be provided to build a specific query
# example arguments: Folders FolderPath=<...> FolderName=<...>
# obviously the fields should exist in that table
# the function returns the full rows with | separators

function Querytable2Data {
  table=$1
  shift
  query=( $@ ); # an array of value pairs field=value to build a table row

  # build base sqlite SELECT call
  sqlq="SELECT * FROM ${table} WHERE "

  # add WHERE clause(s)
  wherec=""
  for kv_pair in ${query[@]}; do
    # split one pair to the two arrays
    spl=( $(split2array "${kv_pair}" "=") )
    # add to both arrays
    wherec="${wherec} AND ${spl[0]}=${d}${spl[1]}${d}"
  done

  # concatenate run and return count
  sqlq=${sqlq}${wherec# AND }
  cmd="sqlite3 ${d}${CONF_database_path}/${CONF_database_name}${d} ${s}${sqlq}${s};"
  # echo "# ${cmd}"
  eval "${cmd}"
}

#--------------------------------------------------------------------------------------
# add rows to table
# a second version will take care of batch import from a file

# in dev not working yet

function addRow2Table {
  table=$1
  row=$2
  # parse all pairs 
  for pair in "${row[@]}"; do
    # convert row into two arrays, one for fields and one for values
    declare -a k=()
    declare -a v=()
    # transpose row into a new array
    res=$(pairlist2arrays "${pair}")
    # echo "res has content: ${res[@]}"
    IFS='|' read -a ar <<< "${res}"
    #echo "keys are: ${ar[O]}";     # => FolderID Creator BAD
    #echo "values are: ${ar[1]}";     # => FolderID Creator BAD

    # fetch the current table fields into a new array
    existing_fields=( $(delimited_fields "${table}" " ") )

    # check if all keys are valid
    for k in "${ar[O]}"; do
    inArray "${k}" "${existing_fields[@]}" \
      || { echo "# ${k} is not a valid '"${table}"' field"; }
    done
  done
}


#--------------------------------------------------------------------------------------
# to be deleted


#function leftover {
#   echo "# joining the results with comma"
#   # do not quote the array!
#   echo "$( join_by ',' ${ar[O]} )";   # => FolderID,Creator,BAD
#   echo "$( join_by ',' ${ar[1]} )";   # => 100,Me,1
# 
# 
#   for pair in "${row[@]}"; do
#     # split one pair to the two arrays
#     spl=( $(split2array ${pair} "=") )
#     # add to both arrays
#     k+=( ${spl[0]} )
#     v+=( ${spl[1]} )
#   done
# 
#   # debug
#   echo "fields are ${k[@]}"
#   echo "values are ${v[@]}"
# 
# 
# 
# 
#   
# 
# exit 0
# 
# 
#   # validate each user field name against the array above and stop if no match
# 
#   # add the row if absent based on unique fields (FolderName)
# 
# fieldarray="<cs-list of fields>"
# 
#   sqlite3 "${databasepath}/${databasename}" "INSERT INTO Folders 
#     (
#     Creator, 
#     CreatorVersion, 
#     DBAddDate, 
#     FolderPath, 
#     FolderName, 
#     FolderSize, 
#     Protection, 
#     DeviceModel, 
#     StartDate, 
#     DeviceID, 
#     RunNr, 
#     FlowCellID, 
#     ProjectNR, 
#     DeliveryDate, 
#     Comment
#     ) 
#   VALUES (
#     \"${creator}\", 
#     \"${creatorversion}\", 
#     \"${actiondate}\", 
#     \"${folderpath}\", 
#     \"${foldername}\", 
#     \"${foldersize}\", 
#     \"${protection}\", 
#     \"${platform}\", 
#     \"${rdate}\", 
#     \"${deviceid}\", 
#     \"${runnum}\", 
#     \"${flowcellid}\", 
#     \"${projnum}\", 
#     \"${deliverydate}\", 
#     \"${comment}\"
#     );"
#     
#   # fetch the FolderID of the newly added row
# 
#   # add action to table:Actions when this is succesfull and based on the FolderID
#   # build actionrow as an array
#   actionrow=()
#   addRow2Actions Actions ${lastfolderid} ${actionrow[@]}
# 
#   return 0
#}


#--------------------------------------------------------------------------------------
# create record in Actions
# required by addRow2Folders
# a second version will take care of batch import from a file

# in dev not working yet

function addRow2Actions {
table="Actions"
folderid=$1; # the fetched last FolderID
row=$2; # an array of value pairs field=value

# fetch the current table fields into a new array
existing_fields=($(delimited_fields "Folders" " "))

# validate each user field name against the array above and stop if no match

return 0
}


#--------------------------------------------------------------------------------------
# DUC REALATED FUNCTIONS
#--------------------------------------------------------------------------------------

# query DUC on gbw-s-nuc04.luna.kuleuven.be via SSH and get folder size
# !! requires that a public key for the user exists on the host
# wil be replaced by local query later on
# example command: ssh gbw-s-nuc04 'duc ls -D -d /var/www/html/ducDB/nuc_transfer.db \
#  /mnt/nuc-transfer/0003_Runs/HiSeq2500/190807_7001450_0488_AH3HVFBCX3_exp3209/'

# get folder size from DUC accessed as described in run_config.yaml
# can be local, via ssh from nuc1, or via ssh from nuc4


#--------------------------------------------------------------------------------------
# test that you can access the DUC server via ssh (from the KUL or from home with Pulse)


function test_duc_ssh {
  case ${CONF_duc_access} in
    nuc1local)
      return 0
      ;;
    nuc1ssh)
      host="gbw-s-nuc01.luna.kuleuven.be"
      ;;
    nuc4ssh)
      host="gbw-s-nuc04.luna.kuleuven.be"
      ;;
    *)
      echo "invalid CONF_duc_access options: ${CONF_duc_access} in run_config.yaml"
      return 1
  esac
  status=$(ssh -o BatchMode=yes -o ConnectTimeout=5 $(whoami)@${host} echo ok 2>&1)
  if [[ $status == ok ]] ; then
    return 0
  elif [[ $status == "Permission denied"* ]] ; then
    echo "ssh returned no_auth"
    return 1
  else
    echo "ssh error, please check your ssh connection"
    return 1
  fi
}


#--------------------------------------------------------------------------------------
# get folder size from DUC on the local machine (Nuc1)


function get_folder_size_local {
  mountpoint="/mnt/nuc-transfer"
  folderpath=${1}
  size=$(duc ls -D -b \
    -d "${CONF_duc_nuc1db}" "${CONF_duc_nuc1mnt}/${CONF_mount_path}/${folderpath}" \
    | cut -d " " -f 1)
  echo ${size:-0} 
}


#--------------------------------------------------------------------------------------
# get folder size from DUC from Nuc1 via ssh


function get_folder_size_nuc1 {
  sshhost="gbw-s-nuc01.luna.kuleuven.be"
  ducdb="/opt/tools/duc/nuc_transfer.db"
  mountpoint="/mnt/nuc-transfer"
  folderpath=${1}
  # echo "${mountpoint}/${folderpath}"
  size=$(ssh ${sshhost} '/opt/tools/duc/duc4 ls -D -b -d '${ducdb} ${mountpoint}/${folderpath}' | \
    cut -d " " -f 1')
  echo ${size:-0} 
}


#--------------------------------------------------------------------------------------
# get folder size from DUC from Nuc4 via ssh (obsolete)


function get_folder_size_nuc4 {
  sshhost="gbw-s-nuc04.luna.kuleuven.be"
  ducdb="/var/www/html/ducDB/nuc_transfer.db"
  mountpoint="/mnt/nuc-transfer"
  folderpath=${1}
  # echo "${mountpoint}/${folderpath}"
  size=$(ssh ${sshhost} 'duc ls -D -b -d '${ducdb} ${mountpoint}/${folderpath}' | \
    cut -d " " -f 1')
  echo ${size:-0} 
}


#--------------------------------------------------------------------------------------
# get folder size from DUC from Nuc1 via ssh
# get the date and time of the last DUC update
# can be local or via ssh from nuc1


function duc_last_update_local {
  lastupdt=$('/opt/tools/duc/duc4 info -d' ${ducdb} | tail -1 | awk '{print $1,$2}')
  echo ${lastupdt:-"na"}
}


function duc_last_update_nuc1 {
  sshhost="gbw-s-nuc01.luna.kuleuven.be"
  ducdb="/opt/tools/duc/nuc_transfer.db"
  mountpoint="/mnt/nuc-transfer"
  lastupdt=$(ssh ${sshhost} '/opt/tools/duc/duc4 info -d '${ducdb} | tail -1 | awk '{print $1,$2})')
  echo ${lastupdt:-"na"}
}





# END
return
echo "you should never be here"
#--------------------------------------------------------------------------------------


#--------------------------------------------------------------------------------------
# UNUSED FUNCTIONS
#--------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------
# function present in bash4 to map command multiple outputs to an array
# in bash4: mapfile -t my_array < <( my_command )
# here: mapfile my_array <my_command line>
# echo ${<my_array>[@]} will list the array items
# echo ${<my_array>[0]} will list the 1st array item
# from https://stackoverflow.com/questions/
#   11426529/reading-output-of-a-command-into-an-array-in-bash

function mapfile {
my_array=${1}
shift
my_command=\'${@}\'
echo ${my_command}
eval $(IFS=$'\n' read -r -d '' -a "${my_array}" < <( "${my_command}" && printf '\0' ))
}

#--------------------------------------------------------------------------------------
# check executables are in PATH
# or terminate with error
# run with: 
# declare -a arr=( "exe1" "exe2" )
# checkdeps $arr
function checkdeps {
for prog in "${arr[@]}"; do
  $( hash ${prog} 2>/dev/null ) \
    || ( echo "# required ${prog} not found in PATH"; exit 1 )
done
}
