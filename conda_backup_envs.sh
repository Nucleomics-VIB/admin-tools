#!/bin/bash

# conda_backup_envs.sh
# script from https://github.com/conda/conda/issues/5165
# author: https://github.com/DavidMertz
# slightly modified by Stephane PLaisance - VIB Nucleomics Core
# version 1.1; 2022-06-09

# initialize conda (adapt to your own path!)
source /etc/profile.d/conda.sh

# create date-tagged folder
NOW=$(date "+%Y-%m-%d")
destdir=$PWD/conda_env_backups_$NOW
mkdir -p ${destdir}

# list all available conda envs
ENVS=$(conda env list | grep '^\w' | cut -d' ' -f1)

# loop and backup to yaml definition files
for myenv in $ENVS; do
  conda activate ${myenv} || \
    ( echo "# the conda environment ${myenv} was not found on this machine" ;
      echo "# please read the top part of the script!" \
      && exit 1 )
      echo "Exporting ${myenv}"
      conda env export > ${destdir}/${myenv}.yml
done
