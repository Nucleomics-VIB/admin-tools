#!/bin/bash

# conda_backup_envs.sh
# script from https://github.com/conda/conda/issues/5165
# author: https://github.com/DavidMertz
# slightly modified by Stephane PLaisance - VIB Nucleomics Core
# version 1.2; 2022-07-01

# initialize conda (adapt to your own path!)

case ${OSTYPE} in
  darwin*)
    source /opt/miniconda3/etc/profile.d/conda.sh ;;
  linux*)
    source /etc/profile.d/conda.sh ;;
  *)
    echo "# unsupported OS"; exit 1 ;;
esac

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
