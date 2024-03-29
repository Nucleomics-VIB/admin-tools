# shared functions for NCDataMngr
# St�phane Plaisance - VIB-Nucleomics Core - 2019-12-23 v0.1
#
# Update 2021-03-16: variables from config.yaml
#
# commented echo can be used to debug
# please add inline documentation to explain your code
# also add example ActionScript usage in your comments


#--------------------------------------------------------------------------------------
# DUC RELATED FUNCTIONS
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


function test_duc_ssh() # test DUC access (nuc1local|nuc1ssh|nuc4ssh)
{
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
  status=$(ssh -i ${CONF_duc_sshkey} -o BatchMode=yes -o ConnectTimeout=5 ${CONF_duc_sshusr}@${host} echo ok 2>&1)
  if [[ $status == ok ]] ; then
    return 0
  elif [[ $status == "Permission denied"* ]] ; then
    echo "ssh returned no_auth"
    return 1
  else
    echo "ssh error, please check your ssh connection to ${CONF_duc_access}"
    return 1
  fi
}


#--------------------------------------------------------------------------------------
# get folder size from DUC on the local machine (Nuc1)


function get_folder_size_local() # get folder size from DUC on Nuc1 (local)
{
  folderpath=${1}
  size=$(${CONF_duc_nuc1exe} ls -D -b -d "${CONF_duc_nuc1db}" "${CONF_duc_nuc1mnt}/${folderpath}"  2>&1)
  # handle not found in DUC
  [[ ${size} == *'Requested path not found'* ]] && { echo "NULL"; } \
    || { echo ${size} | cut -d " " -f 1; }
}


#--------------------------------------------------------------------------------------
# get folder size from DUC from Nuc1 via ssh


function get_folder_size_nuc1() # get folder size from DUC from Nuc1 (via ssh)
{
  folderpath=${1}
  # >&2 echo "${CONF_mount_transfer_point}/${folderpath}"
  size=$(ssh -i ${CONF_duc_sshkey} ${CONF_duc_sshusr}@${CONF_duc_nuc1addr} ${CONF_duc_nuc1exe} ls -D -b -d ${CONF_duc_nuc1db} ${CONF_duc_nuc1mnt}/${folderpath} 2>&1)
  # handle not found in DUC
  [[ ${size} == *'Requested path not found'* ]] && { echo "NULL"; } \
    || { echo ${size} | cut -d " " -f 1; }
}


#--------------------------------------------------------------------------------------
# get folder size from DUC from Nuc4 via ssh (obsolete)


function get_folder_size_nuc4() # get folder size from DUC from Nuc4 via ssh (obsolete)
{
  folderpath=${1}
  # >&2 echo "${CONF_mount_transfer_point}/${folderpath}"
  size=$(ssh -i ${CONF_duc_sshkey} ${CONF_duc_sshusr}@${CONF_duc_nuc4addr} ${CONF_duc_nuc4exe} ls -D -b -d ${CONF_duc_nuc4db} ${CONF_duc_nuc4mnt}/${folderpath} 2>&1)
  # handle not found in DUC
  [[ ${size} == *'Requested path not found'* ]] && { echo "NULL"; } \
    || { echo ${size} | cut -d " " -f 1; }
}


#--------------------------------------------------------------------------------------
# get folder size from DUC from Nuc1 via ssh
# get the date and time of the last DUC update
# can be local or via ssh from nuc1


function duc_last_update_local() # get folder size, last DUC update from Nuc1 (local)
{
  lastupdt=$(${CONF_duc_nuc1exe} info -d ${ducdb} | tail -1 | awk '{print $1,$2}')
  echo ${lastupdt:-"na"}
}


function duc_last_update_nuc1() # get last DUC update from Nuc1 (via ssh)
{
  lastupdt=$(ssh -i ${CONF_duc_sshkey} ${CONF_duc_sshusr}@${CONF_duc_nuc1addr} ${CONF_duc_nuc1exe} info -d ${CONF_duc_nuc1db} | tail -1 | awk '{print $1,$2}')
  echo ${lastupdt:-"na"}
}
