#!/bin/bash

# script: samtools_install.sh
# Aim: install samtools, bcftools and htslib version 1.X in one GO
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2017-09-27 v1.2
# update to samtools 1.6 2017-10-26
# updated to any new build 2018-02-12
# allow different build version for each of the three 2019-12-30 v1.3
# now finds the latest releases automatically 2020-05-04 v1.4
# 2026-09-05 v1.5 fail safely: report the three online releases first, refuse
#                 an empty version from the GitHub API, stop on a failed
#                 download or build instead of carrying on, and guard every cd
#
# visit our Git: https://github.com/Nucleomics-VIB

set -o pipefail

function latest_git_release() {
# argument is a quoted string like "samtools/samtools"
curl --silent --fail --max-time 30 "https://api.github.com/repos/$1/releases/latest" \
  | grep '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/'
}

############################################################
## report the releases to install                         ##

# one shared version can be given as first argument, otherwise ask GitHub
mybuild_st=${1:-$(latest_git_release "samtools/samtools")}
mybuild_bc=${1:-$(latest_git_release "samtools/bcftools")}
mybuild_ht=${1:-$(latest_git_release "samtools/htslib")}

# 2026-09-05: the GitHub API is unauthenticated and rate-limited. When it
# fails a version is empty, the URL becomes ".../download//samtools-.tar.bz2",
# and the build ran on in the wrong directory.
for v in "${mybuild_st}" "${mybuild_bc}" "${mybuild_ht}"; do
        if [ -z "${v}" ]; then
                echo "# could not read the latest samtools releases from GitHub."
                echo "# give the version as first argument, eg: $(basename "$0") 1.24"
                exit 1
        fi
done

# report where the versions came from before anything is changed
if [ -n "$1" ]; then
        echo "# release requested for all three : ${mybuild_st}"
else
        echo "# latest samtools release online : ${mybuild_st}"
        echo "# latest bcftools release online : ${mybuild_bc}"
        echo "# latest htslib   release online : ${mybuild_ht}"
fi

######################################
## get destination folder from user ##

echo -n "# Provide a path OR type [ENTER] for '/opt/biotools/samtools-${mybuild_st}': "
read -r mypath
myprefix=${mypath:-"/opt/biotools/samtools-${mybuild_st}"}

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
exec &> >(tee -i "samtools_install_${mybuild_st}.log")

# process three packages
cat <<EOL |
https://github.com/samtools/samtools/releases/download/${mybuild_st}/samtools-${mybuild_st}.tar.bz2
https://github.com/samtools/bcftools/releases/download/${mybuild_bc}/bcftools-${mybuild_bc}.tar.bz2
https://github.com/samtools/htslib/releases/download/${mybuild_ht}/htslib-${mybuild_ht}.tar.bz2
EOL

# loop through the list
while read -r myurl; do

        cd "${myprefix}/src" || exit 1

        # get source
        if ! wget "${myurl}"; then
                echo "# ${myurl} was not found online."
                exit 1
        fi

        package=${myurl##*/}

        if ! tar -xjf "${package}"; then
                echo "# ${package} could not be decompressed."
                exit 1
        fi

        # build and install
        cd "${package%.tar.bz2}" || exit 1

        ./configure CPPFLAGS='-I /opt/local/include' --prefix="${myprefix}" || exit 1
        make || exit 1
        make install || exit 1

# end loop
done

cd "${myprefix}" || exit 1

# post install steps
echo
echo -e "# Full Samtools install finished, check for error messages in \"samtools_install_${mybuild_st}.log\""
echo
echo -e "# samtools version is: $("${myprefix}/bin/samtools" --version | head -1)"
echo -e "# bcftools version is: $("${myprefix}/bin/bcftools" --version | head -1)"
echo -e "# htsfile version is: $("${myprefix}/bin/htsfile" --version | head -1)"
echo
echo -e "# add: \"export PATH=\$PATH:${myprefix}/bin\" to your /etc/profile"
echo -e "# add: \"export MANPATH=${myprefix}/share/man:\$MANPATH\" to your /etc/profile"
echo
echo -e "# you may also delete the build folder \"${myprefix}/src\""
