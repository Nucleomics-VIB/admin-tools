#!/bin/bash

# script: bedtools_install.sh
# Aim: install bedtools version 2.X in one GO
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2017-09-27 v1.2
# update to samtools 1.6 2017-10-26
# updated to any new build 2018-02-12
# now finds the latest release automatically 2020-05-04 v1.1
#
# visit our Git: https://github.com/Nucleomics-VIB

######################################
## get destination folder from user ##

function latest_git_release() {
# argument is a quoted string like "arq5x/bedtools2"
ID=${GITHUB_ID}
TOKEN=${GITHUB_TOKEN}
curl --silent -u ${GITHUB_ID}:${GITHUB_TOKEN} "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

mybuild=$(latest_git_release "arq5x/bedtools2")
# remove leading 'v'
mybuild=${mybuild#v}
echo "# Installing the current Bedtools release : "${mybuild}

echo -n "[ENTER] for '/opt/biotools/bedtools2-${mybuild}' or provide a different path: "
read mypath 
myprefix=${mypath:-"/opt/biotools/bedtools2-${mybuild}"}

# test if exists and abort
if [ -d "${myprefix}" ]; then
        echo "# This folder already exists, change its name or move it then restart this script."
        exit 0
fi

# create destination folder
mkdir -p "${myprefix}/src"

# test for success
if [ $? -ne 0 ] ; then
        echo "# You were not allowed to create this path"
fi

######################################

# move to the place where to download and build
# work in a folder => easy to clean afterwards
cd "${myprefix}/src"

# capture all to log from here
exec &> >(tee -i bedtools_install_${mybuild}.log)

# get source (note the added 'v' in front of mybuild)
myurl="https://github.com/arq5x/bedtools2/releases/download/v${mybuild}/bedtools-${mybuild}.tar.gz"

wget "${myurl}"
package=${myurl##*/}
tar -xzvf ${package}

# build and install
cd "${package%-*}2"
make && make install prefix="${myprefix}" && cd ${myprefix}

# move relevant folders out of src
for folder in data docs genomes scripts tutorial; do
mv ${myprefix}/src/bedtools2/${folder} ${myprefix}/
done

# copy man pages
mkdir -p ${myprefix}/share/man/man1
find ${myprefix}/src/bedtools2 -type f -name "*.1" -exec cp {} ${myprefix}/share/man/man1/ \;

# post install steps
echo
echo -e "# Full Bedtools install finished, check for error messages in \"bedtools_install_${mybuild}.log\""

# print version
echo
echo "# if all went right, you should see the new Bedtools2 version below"
${myprefix}/bin/bedtools --version
echo
echo -e "# add: \"export PATH=\$PATH:${myprefix}/bin\" to your /etc/profile"
echo
echo -e "# you may also delete the build folder with rm -rf \"${myprefix}/src\""
