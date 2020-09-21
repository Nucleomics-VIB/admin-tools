#!/bin/bash

# script: cromwell_install.sh
# Aim: install cromwell version X in one GO
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2019-09-20 v1.0
# now finds the latest release automatically 2020-05-04 v1.1
#
# visit our Git: https://github.com/Nucleomics-VIB

######################################
## get destination folder from user ##

function latest_git_release() {
# argument is a quoted string like  "broadinstitute/cromwell"
curl --silent "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

mybuild=$(latest_git_release "broadinstitute/cromwell")
echo "# Installing the current Cromwell release : "${mybuild}

echo -n "[ENTER] for '/opt/biotools' or provide a different path: "
read mypath 
biotools=${mypath:-"/opt/biotools"}

# test if exists and abort
if [ ! -d "${biotools}" ]; then
        echo "# This path was not found, check it and restart this script."
        exit 0
fi

# get the jar
cromwell=${biotools}/cromwell
mkdir -p ${cromwell} && cd ${cromwell}

# https://github.com/broadinstitute/cromwell/releases/download/46/cromwell-46.jar
# https://github.com/broadinstitute/cromwell/releases/download/46/womtool-46.jar

# check if already there and delete
if [ -f "cromwell-${mybuild}.jar" ]; then
        rm "cromwell-${mybuild}.jar"
fi

if [ -f "womtool-${mybuild}.jar" ]; then
        rm "womtool-${mybuild}.jar"
fi

# get fresh
wget https://github.com/broadinstitute/cromwell/releases/download/${mybuild}/cromwell-${mybuild}.jar && \
ln -f -s cromwell-${mybuild}.jar cromwell.jar

# test for success
if [ $? -ne 0 ] ; then
        echo "# cromwell.jar was not found online"
fi

wget https://github.com/broadinstitute/cromwell/releases/download/${mybuild}/womtool-${mybuild}.jar && \
ln -f -s womtool-${mybuild}.jar womtool.jar

# test for success
if [ $? -ne 0 ] ; then
        echo "# womtool.jar was not found online"
fi

cd ../

# print version
echo
echo "# if all went right, you should see the new Cromwell and womtool versions below"
java -jar ${cromwell}/cromwell.jar --version
java -jar ${cromwell}/womtool.jar --version