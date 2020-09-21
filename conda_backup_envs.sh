#!/bin/bash

# conda_backup_envs.sh
# script from https://github.com/conda/conda/issues/5165
# author: https://github.com/DavidMertz

NOW=$(date "+%Y-%m-%d")
destdir=$HOME/conda_backups/envs-$NOW
mkdir -p ${destdir}
ENVS=$(conda env list | grep '^\w' | cut -d' ' -f1)
for env in $ENVS; do
    source activate $env
    conda env export > ${destdir}/$env.yml
    echo "Exporting $env"
done