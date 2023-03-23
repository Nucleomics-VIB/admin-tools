#!/bin/bash

# script: yq_install.sh
# Aim: install yq from a selected github release
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2021-05-25 v1.0
#
# visit our Git: https://github.com/Nucleomics-VIB

# get fresh
if [ $(uname) == "Darwin" ]; then
package=yq_darwin_amd64
elif [ $(uname) == "Linux" ]; then
package=yq_linux_amd64
else
echo "OS $(uname) is not supported by this script (Darwin|Linux)"
exit 0
fi

######################################
## get destination folder from user ##

function latest_git_release() {
# argument is a quoted string like  "mikefarah/yq"
ID=${GITHUB_ID}
TOKEN=${GITHUB_TOKEN}
curl --silent -u ${GITHUB_ID}:${GITHUB_TOKEN} "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

mybuild=$(latest_git_release "mikefarah/yq")
echo "# Installing the current YQ release : "${mybuild}

echo -n "[ENTER] for '/opt/biotools' or provide a different path: "
read mypath 
biotools=${mypath:-"/opt/biotools"}

# test if exists and abort
if [ ! -d "${biotools}" ]; then
        echo "# This path was not found, check it and restart this script."
        exit 0
fi

# get the archive and decompress it
cd ${biotools}

# check if folder already there and delete
if [ -d "yq_${mybuild}" ]; then
        rm -rf "yq_${mybuild}"
        unlink yq
fi

# create folder
mkdir -p yq_${mybuild} && cd yq_${mybuild}

# get archive and deploy
wget https://github.com/mikefarah/yq/releases/download/${mybuild}/${package}.tar.gz
tar -xzvf ${package}.tar.gz && rm ${package}.tar.gz
./install-man-page.sh

# test for success
if [ $? -ne 0 ] ; then
        echo "# The archive was not found online or could not be decompressed"
fi

ln -s "${package}" yq

# test for success
if [ $? -ne 0 ] ; then
        echo "# The link to the new file could not be created"
fi

cd ../

# create new link to folder
yqlnk="yq"

if [ -L "${yqlnk}" ]; then
        unlink ${yqlnk}
fi

ln -s yq_${mybuild} ${yqlnk}

# test for success
if [ $? -ne 0 ] ; then
        echo "# The link to the new build folder could not be created"
fi

# print version
echo
echo "# if all went right, you should see the new YQ version below"
yq --version
