#!/bin/bash

# script: gatk_install.sh
# Aim: install gatk from a selected github release
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2018-08-01 v1.0
# now finds the latest release automatically 2020-05-04 v1.1
# 2026-09-05 v1.2 fail safely: report the online release first, refuse an empty
#                 version from the GitHub API, download BEFORE deleting the
#                 working install, guard every cd, use "ln -sfn" so the link is
#                 replaced instead of created inside the old folder, and return
#                 a non-zero exit code on every error
#
# visit our Git: https://github.com/Nucleomics-VIB

set -o pipefail

function latest_git_release() {
# argument is a quoted string like "broadinstitute/gatk"
curl --silent --fail --max-time 30 "https://api.github.com/repos/$1/releases/latest" \
  | grep '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/'
}

######################################
## report the release to install    ##

# take the version from the first argument, otherwise ask GitHub for the latest
mybuild=${1:-$(latest_git_release "broadinstitute/gatk")}

# 2026-09-05: the GitHub API is unauthenticated and rate-limited. When it fails
# mybuild is empty and the URL becomes ".../download//gatk-.zip". The old
# script deleted the installed release before discovering that.
if [ -z "${mybuild}" ]; then
        echo "# could not read the latest GATK release from GitHub."
        echo "# give the version as first argument, eg: $(basename "$0") 4.7.0.0"
        exit 1
fi

# report where the version came from before anything is changed
if [ -n "$1" ]; then
        echo "# GATK release requested : ${mybuild}"
else
        echo "# latest GATK release online : ${mybuild}"
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

######################################
## get the archive                  ##

zipfile="gatk-${mybuild}.zip"

# 2026-09-05: download FIRST, to a .part file. The old order removed
# gatk-${mybuild} and the zip before wget ran, so a failed download left no
# usable GATK at all.
if ! wget -O "${zipfile}.part" \
     "https://github.com/broadinstitute/gatk/releases/download/${mybuild}/${zipfile}"; then
        echo "# The archive for release ${mybuild} was not found online."
        echo "# The existing GATK install was left untouched."
        rm -f "${zipfile}.part"
        exit 1
fi

mv "${zipfile}.part" "${zipfile}" || exit 1

# only now is it safe to replace the previous copy of this same release
rm -rf "gatk-${mybuild}"

if ! unzip -q "${zipfile}"; then
        echo "# The archive could not be decompressed."
        rm -f "${zipfile}"
        exit 1
fi

rm -f "${zipfile}"

######################################
## link the new build               ##

# 2026-09-05: "ln -sfn". Without -n, and with "gatk" already a symlink to a
# directory, ln creates the new link INSIDE the old folder instead of
# replacing it.
ln -sfn "gatk-${mybuild}" gatk || exit 1

cd gatk || exit 1
ln -sfn "gatk-package-${mybuild}-local.jar" gatk.jar || exit 1
cd "${biotools}" || exit 1

# print version
echo
echo "# if all went right, you should see the new GATK version below"
java -jar gatk/gatk.jar HaplotypeCaller --version
