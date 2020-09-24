# shared functions for NCDataMngr
# Stéphane Plaisance - VIB-Nucleomics Core - 2019-12-23 v1.0
#
# commented echo can be used to debug
# please add inline documentation to explain your code
# also add example ActionScript usage in your comments


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
  q="'"
  d='"'
  
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
  cmd="sqlite3 ${d}${CONF_database_path}/${CONF_database_name}${d} ${q}${sqlq}${q};"
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
  q="'"
  d='"'
  
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
  cmd="sqlite3 ${d}${CONF_database_path}/${CONF_database_name}${d} ${q}${sqlq}${q};"
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
