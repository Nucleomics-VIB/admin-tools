#!/bin/bash

# script: picard_install.sh
# Aim: install picard from a selected github release
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2018-08-01 v1.0
# now finds the latest release automatically 2020-05-04 v1.1
#
# visit our Git: https://github.com/Nucleomics-VIB

######################################
## get destination folder from user ##

#echo -n "Enter the build number you wish to install (eg 2.19.0 -> get this info from #https://github.com/broadinstitute/picard/releases) and press [ENTER]: "
#read mybuild

function latest_git_release() {
# argument is a quoted string like  "broadinstitute/picard"
ID=${GITHUB_ID}
TOKEN=${GITHUB_TOKEN}
curl --silent -u ${GITHUB_ID}:${GITHUB_TOKEN} "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

mybuild=$(latest_git_release "broadinstitute/picard")
echo "# Installing the current Picard release : "${mybuild}

echo -n "[ENTER] for '/opt/biotools' or provide a different path: "
read mypath 
biotools=${mypath:-"/opt/biotools"}

# test if exists and abort
if [ ! -d "${biotools}" ]; then
        echo "# This path was not found, check it and restart this script."
        exit 0
fi

# get the zip and decompress it
cd ${biotools}

# check if already there and delete
if [ ! -d "picard" ]; then
        mkdir picard
fi

cd picard

# check for link
picardlnk="picard.jar"

if [ -L "${picardlnk}" ]; then
        unlink "${picardlnk}"
fi

# get fresh
wget https://github.com/broadinstitute/picard/releases/download/${mybuild}/picard.jar -O picard_${mybuild}.jar && \
        ln -s picard_${mybuild}.jar "${picardlnk}"
        
# test for success
if [ $? -ne 0 ] ; then
        echo "# The jar was not found online or could not be linked"
fi

######################################

cd ../

# print version
echo
echo "# if all went right, you should see the new PICARD version below"
java -jar picard/picard.jar ViewSam --version
