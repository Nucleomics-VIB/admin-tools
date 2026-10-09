#!/bin/bash

# script: bedtools_install.sh
# Aim: install bedtools version 2.X in one GO
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2017-09-27 v1.0
# now finds the latest release automatically 2020-05-04 v1.1
# 2026-09-05 v1.2 fail safely: report the online release first, refuse an empty
#                 version from the GitHub API, stop on a failed download, build
#                 or install instead of carrying on, and guard every cd
#
# visit our Git: https://github.com/Nucleomics-VIB

set -o pipefail

function latest_git_release() {
# argument is a quoted string like "arq5x/bedtools2"
curl --silent --fail --max-time 30 "https://api.github.com/repos/$1/releases/latest" \
  | grep '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/'
}

######################################
## report the release to install    ##

# take the version from the first argument, otherwise ask GitHub for the latest
mybuild=${1:-$(latest_git_release "arq5x/bedtools2")}

# remove leading 'v'
mybuild=${mybuild#v}

if [ -z "${mybuild}" ]; then
        echo "# could not read the latest Bedtools release from GitHub."
        echo "# give the version as first argument, eg: $(basename "$0") 2.31.1"
        exit 1
fi

# report where the version came from before anything is changed
if [ -n "$1" ]; then
        echo "# Bedtools release requested : ${mybuild}"
else
        echo "# latest Bedtools release online : ${mybuild}"
fi

######################################
## get destination folder from user ##

echo -n "[ENTER] for '/opt/biotools/bedtools2-${mybuild}' or provide a different path: "
read -r mypath
myprefix=${mypath:-"/opt/biotools/bedtools2-${mybuild}"}

# test if exists and abort
if [ -d "${myprefix}" ]; then
        echo "# This folder already exists, change its name or move it then restart this script."
        exit 1
fi

# create destination folder
# 2026-09-05: this used to only print on failure, then carry on regardless.
mkdir -p "${myprefix}/src" || {
        echo "# You were not allowed to create this path"
        exit 1
}

######################################

# move to the place where to download and build
# work in a folder => easy to clean afterwards
cd "${myprefix}/src" || exit 1

# capture all to log from here
exec &> >(tee -i "bedtools_install_${mybuild}.log")

# get source (note the added 'v' in front of mybuild)
myurl="https://github.com/arq5x/bedtools2/releases/download/v${mybuild}/bedtools-${mybuild}.tar.gz"

if ! wget "${myurl}"; then
        echo "# The source archive for release ${mybuild} was not found online."
        exit 1
fi

package=${myurl##*/}

if ! tar -xzf "${package}"; then
        echo "# The source archive could not be decompressed."
        exit 1
fi

# build and install
cd "${package%-*}2" || exit 1

if ! make; then
        echo "# The build failed, see the log above."
        exit 1
fi

if ! make install prefix="${myprefix}"; then
        echo "# The install step failed, see the log above."
        exit 1
fi

cd "${myprefix}" || exit 1

# move relevant folders out of src
for folder in data docs genomes scripts tutorial; do
        if [ -d "${myprefix}/src/bedtools2/${folder}" ]; then
                mv "${myprefix}/src/bedtools2/${folder}" "${myprefix}/"
        fi
done

# copy man pages
mkdir -p "${myprefix}/share/man/man1"
find "${myprefix}/src/bedtools2" -type f -name "*.1" \
     -exec cp {} "${myprefix}/share/man/man1/" \;

# post install steps
echo
echo -e "# Full Bedtools install finished, check for error messages in \"bedtools_install_${mybuild}.log\""

# print version
echo
echo "# if all went right, you should see the new Bedtools2 version below"
"${myprefix}/bin/bedtools" --version
echo
echo -e "# add: \"export PATH=\$PATH:${myprefix}/bin\" to your /etc/profile"
echo
echo -e "# you may also delete the build folder \"${myprefix}/src\""
