# Get DUC size via SSH NUC01 via a given path

function ts_get_folder_size_nuc1() # get folder size from DUC from NUC1 (via ssh)
{
    sshhost="gbw-s-nuc01.luna.kuleuven.be"
    ducdb="${1}"
    mountpoint="${2}"
    # >&2 echo "${mountpoint}/${folderpath}"
    DUC_SIZE=$(ssh -i /home/thomas/.ssh/ubuntuwsl u0130210@${sshhost} '/opt/tools/duc/duc4 ls -D -b -d '${ducdb} ${mountpoint} 2>&1)
    # handle not found in DUC
    [[ ${DUC_SIZE} == *'Requested path not found'* ]] && DUC_SIZE="NULL" || DUC_SIZE=$(echo ${DUC_SIZE} | cut -d " " -f 1)
}
