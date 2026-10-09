#!/bin/bash

# script: cromwell_install.sh
# Aim: install cromwell version X in one GO
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2019-09-20 v1.0
# now finds the latest release automatically 2020-05-04 v1.1
# 2026-09-05 v1.2 fail safely: report the online release first, refuse an empty
#                 version from the GitHub API, download BEFORE deleting the
#                 working jars, guard every cd, return a non-zero exit code on
#                 every error, and fix the message that said "Picard"
#
# visit our Git: https://github.com/Nucleomics-VIB

set -o pipefail

function latest_git_release() {
# argument is a quoted string like "broadinstitute/cromwell"
curl --silent --fail --max-time 30 "https://api.github.com/repos/$1/releases/latest" \
  | grep '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/'
}

######################################
## report the release to install    ##

# take the version from the first argument, otherwise ask GitHub for the latest
mybuild=${1:-$(latest_git_release "broadinstitute/cromwell")}

if [ -z "${mybuild}" ]; then
        echo "# could not read the latest Cromwell release from GitHub."
        echo "# give the version as first argument, eg: $(basename "$0") 92"
        exit 1
fi

# 2026-09-05: this line used to say "Installing the current Picard release".
# report where the version came from before anything is changed
if [ -n "$1" ]; then
        echo "# Cromwell release requested : ${mybuild}"
else
        echo "# latest Cromwell release online : ${mybuild}"
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

cromwell=${biotools}/cromwell
mkdir -p "${cromwell}" || exit 1
cd "${cromwell}" || exit 1

######################################
## get the two jars                 ##

# https://github.com/broadinstitute/cromwell/releases/download/46/cromwell-46.jar
# https://github.com/broadinstitute/cromwell/releases/download/46/womtool-46.jar

# 2026-09-05: download each jar to a .part file FIRST. The old order deleted
# cromwell-${mybuild}.jar and womtool-${mybuild}.jar before wget ran, so a
# failed download left no usable jar at all.
baseurl="https://github.com/broadinstitute/cromwell/releases/download/${mybuild}"

for tool in cromwell womtool; do
        jar="${tool}-${mybuild}.jar"

        if ! wget -O "${jar}.part" "${baseurl}/${jar}"; then
                echo "# ${jar} was not found online."
                echo "# The existing ${tool}.jar was left untouched."
                rm -f "${jar}.part"
                exit 1
        fi

        mv "${jar}.part" "${jar}" || exit 1
        ln -sfn "${jar}" "${tool}.jar" || exit 1
done

cd "${biotools}" || exit 1

# print version
echo
echo "# if all went right, you should see the new Cromwell and womtool versions below"
java -jar "${cromwell}/cromwell.jar" --version
java -jar "${cromwell}/womtool.jar" --version
