#!/bin/bash

# compress and archive invoiceplane-pacbio to L:
# Stephane Plaisance - VIB-NC Jan-26-2018 v1.0
# added to /etc/cron.d/web_backups-cron

# run as root from /root
home=$HOME

# Set default file permissions
umask 177

timestamp=$(date '+%Y%m%d_%H%M')

# destination folder on L:
servername="invoiceplane-pacbio"
outfolder=/mnt/nuc-data/Archive/Backup/${servername}

# mail for status
mailOK="stephane.plaisance@vib.be" 
mailFAIL="stephane.plaisance@vib.be" 

mailcontent=""

#######################
# archive html folder
#######################

serverpath=/var/lib/invoiceplane-1.5.5-pacbio
tarfile=${timestamp}_${servername}_folder.tgz
tar -czf $HOME/${tarfile} ${serverpath}

# check if mounted or use R710
if [ -d "${outfolder}" ]; then
  echo "copying html folder tgz archive to the mounted L:";
  cp $HOME/${tarfile} ${outfolder} && \
  	rm ${tarfile};
else
  echo "copying html folder tgz archive through R710"
  sshpass -f /root/.backup scp $HOME/${tarfile} splaisan@10.33.113.7:${outfolder} && \
  	rm ${tarfile}
fi

# send a mail
if [ $? -eq 0 ]; then
  mailcontent="${servername} tgz copied to L:";
else
  /root/mail_it "ERROR!: ${servername} automatic backup part 1 failed" "${mailFAIL}" "${servername} tgz NOT copied to L:";
  exit 1;
fi

#################
# dump SQL data
#################

# Server Database credentials
user="nuc-invoiceplane"
password="mysql4IP"
host="localhost"
db_name="pacbio_invoiceplane"
dumpbase=${timestamp}_${db_name}"_dump"

# Dump database into SQL file
mysqldump --user=$user --password=$password --host=$host $db_name > $HOME/${dumpbase}.sql

# check if mounted or use R710
if [ -d "${outfolder}" ]; then
  echo "copying mysqldump to the mounted L:";
  (gzip $HOME/${dumpbase}.sql && cp $HOME/${dumpbase}.sql.gz ${outfolder}) && \
  	rm $HOME/${dumpbase}.sql.gz;
else
  echo "copying mysqldump through R710";
  (gzip $HOME/${dumpbase}.sql && sshpass -f /root/.backup scp $HOME/${dumpbase}.sql.gz splaisan@10.33.113.7:${outfolder}) && \
  	rm $HOME/${dumpbase}.sql.gz;
fi

# send a mail
if [ $? -eq 0 ]; then
  currdate=$(date '+%Y-%m-%d %H:%M:%S')
  /root/mail_it "${servername} automatic backup succedeed" "${mailOK}" "* ${mailcontent}\n* ${db_name} mysql dump copied to L:\n\n${currdate}";
else
  /root/mail_it "${servername} automatic backup part 2 failed" "${mailFAIL}" "${db_name} mysql dump NOT copied to L:";
  exit 1;
fi

