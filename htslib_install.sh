#!/bin/bash

# script: htslib_install.sh
# Aim: install htslib version 1.X on its own
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2017-09-27 v1.2
# updated to any new build 2018-02-12
# 2026-09-05 v1.3 fail safely: this file still carried the samtools_install.sh
#                 header, log name and closing text. It now names htslib
#                 throughout, finds the latest release automatically like its
#                 sibling scripts, refuses an empty version, stops on a failed
#                 download or build, and guards every cd
#
# visit our Git: https://github.com/Nucleomics-VIB

set -o pipefail

function latest_git_release() {
# argument is a quoted string like "samtools/htslib"
curl --silent --fail --max-time 30 "https://api.github.com/repos/$1/releases/latest" \
  | grep '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/'
}

######################################
## report the release to install    ##

# take the version from the first argument, otherwise ask GitHub for the latest
mybuild=${1:-$(latest_git_release "samtools/htslib")}

if [ -z "${mybuild}" ]; then
        echo "# could not read the latest htslib release from GitHub."
        echo "# give the version as first argument, eg: $(basename "$0") 1.24"
        exit 1
fi

# report where the version came from before anything is changed
if [ -n "$1" ]; then
        echo "# htslib release requested : ${mybuild}"
else
        echo "# latest htslib release online : ${mybuild}"
fi

######################################
## get destination folder from user ##

echo -n "# Provide a path OR type [ENTER] for '/opt/biotools/htslib-${mybuild}': "
read -r mypath
myprefix=${mypath:-"/opt/biotools/htslib-${mybuild}"}

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
exec &> >(tee -i "htslib_install_${mybuild}.log")

myurl="https://github.com/samtools/htslib/releases/download/${mybuild}/htslib-${mybuild}.tar.bz2"

# get source
if ! wget "${myurl}"; then
        echo "# The source archive for release ${mybuild} was not found online."
        exit 1
fi

package=${myurl##*/}

if ! tar -xjf "${package}"; then
        echo "# The source archive could not be decompressed."
        exit 1
fi

# build and install
cd "${package%.tar.bz2}" || exit 1

./configure CPPFLAGS='-I /opt/local/include' --prefix="${myprefix}" || exit 1
make || exit 1
make install || exit 1

cd "${myprefix}" || exit 1

# post install steps
echo
echo -e "# Full htslib install finished, check for error messages in \"htslib_install_${mybuild}.log\""
echo
echo -e "# htsfile version is: $("${myprefix}/bin/htsfile" --version | head -1)"
echo
echo -e "# add: \"export PATH=\$PATH:${myprefix}/bin\" to your /etc/profile"
echo -e "# add: \"export MANPATH=${myprefix}/share/man:\$MANPATH\" to your /etc/profile"
echo
echo -e "# you may also delete the build folder \"${myprefix}/src\""
