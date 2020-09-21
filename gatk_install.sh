#!/bin/bash

# script: gatk_install.sh
# Aim: install gatk from a selected github release
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2018-08-01 v1.0
# now finds the latest release automatically 2020-05-04 v1.1
#
# visit our Git: https://github.com/Nucleomics-VIB

######################################
## get destination folder from user ##

function latest_git_release() {
# argument is a quoted string like  "broadinstitute/gatk"
curl --silent "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

mybuild=$(latest_git_release "broadinstitute/gatk")
echo "# Installing the current GATK release : "${mybuild}

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
if [ -f "gatk-${mybuild}.zip" ]; then
        rm "gatk-${mybuild}.zip"
fi

if [ -d "gatk-${mybuild}" ]; then
        rm -rf "gatk-${mybuild}"
fi

# get fresh
wget https://github.com/broadinstitute/gatk/releases/download/${mybuild}/gatk-${mybuild}.zip && \
        unzip gatk-${mybuild}.zip &&
        rm gatk-${mybuild}.zip

# test for success
if [ $? -ne 0 ] ; then
        echo "# The archive was not found online or could not be decompressed"
fi

######################################

# create new link
gatklnk="gatk"

if [ -L "${gatklnk}" ]; then
        unlink ${gatklnk}
fi

ln -s gatk-${mybuild} ${gatklnk}

# test for success
if [ $? -ne 0 ] ; then
        echo "# The link to the new build folder could not be created"
fi

# create link in the build folder
cd gatk && \
        ln -s "gatk-package-${mybuild}-local.jar" gatk.jar

# test for success
if [ $? -ne 0 ] ; then
        echo "# The link to the new jar file could not be created"
fi

cd ../

# print version
echo
echo "# if all went right, you should see the new GATK version below"
java -jar gatk/gatk.jar HaplotypeCaller --version
