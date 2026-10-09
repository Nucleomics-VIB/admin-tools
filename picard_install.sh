#!/bin/bash

# script: picard_install.sh
# Aim: install picard from a selected github release
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2018-08-01 v1.0
# 2020-05-04 v1.1 now finds the latest release automatically
# 2026-09-05 v1.2 fail safely: keep the working picard.jar when the download
#                 fails, refuse an empty version from the GitHub API, guard
#                 every cd, accept the version as first argument, and return a
#                 non-zero exit code on every error
#
# visit our Git: https://github.com/Nucleomics-VIB

set -o pipefail

######################################
## find the release to install      ##

function latest_git_release() {
# argument is a quoted string like "broadinstitute/picard"
curl --silent "https://api.github.com/repos/$1/releases/latest" \
  | grep '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/'
}

# take the version from the first argument, otherwise ask GitHub for the latest
mybuild=${1:-$(latest_git_release "broadinstitute/picard")}

# 2026-09-05: the GitHub API call is unauthenticated and rate-limited. When it
# failed, mybuild was empty, the URL became ".../download//picard.jar", and the
# script had already removed picard.jar before finding that out.
if [ -z "${mybuild}" ]; then
        echo "# could not read the latest picard release from GitHub."
        echo "# give the version as first argument, eg: $(basename "$0") 3.3.0"
        exit 1
fi

# report where the version came from before anything is changed
if [ -n "$1" ]; then
        echo "# picard release requested : ${mybuild}"
else
        echo "# latest picard release online : ${mybuild}"
fi

######################################
## get destination folder from user ##

echo -n "[ENTER] for '/opt/biotools' or provide a different path: "
read -r mypath
biotools=${mypath:-"/opt/biotools"}

# test if exists and abort
if [ ! -d "${biotools}" ]; then
        echo "# This path was not found, check it and restart this script."
        exit 1
fi

cd "${biotools}" || exit 1

# 2026-09-05: both cd calls are guarded. Without the guard a failed mkdir left
# the jar in ${biotools} instead of ${biotools}/picard.
mkdir -p picard || exit 1
cd picard || exit 1

######################################
## get the jar                      ##

picardlnk="picard.jar"
newjar="picard_${mybuild}.jar"

# 2026-09-05: download to a .part file FIRST. The old order ran
# "unlink picard.jar" before wget, so a failed download left the directory
# without any usable picard.
if ! wget -O "${newjar}.part" \
     "https://github.com/broadinstitute/picard/releases/download/${mybuild}/picard.jar"; then
        echo "# The jar for release ${mybuild} was not found online."
        echo "# The existing ${picardlnk} was left untouched."
        rm -f "${newjar}.part"
        exit 1
fi

mv "${newjar}.part" "${newjar}" || exit 1
ln -sfn "${newjar}" "${picardlnk}" || exit 1

######################################

cd ../ || exit 1

# print version
echo
echo "# if all went right, you should see the new PICARD version below"
java -jar picard/picard.jar ViewSam --version
