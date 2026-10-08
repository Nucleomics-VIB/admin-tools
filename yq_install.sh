#!/bin/bash

# script: yq_install.sh
# Aim: install yq from a selected github release
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2021-05-25 v1.0
# 2024-06-07 v1.1 : adding arch to Darwin to support Mx chips
# 2026-09-05 v1.2 fail safely: drop the broken "curl -u" call, report the
#                 online release first, refuse an empty version from the
#                 GitHub API, download BEFORE deleting the working install,
#                 guard every cd, use "ln -sfn", and return a non-zero exit
#                 code on every error
#
# visit our Git: https://github.com/Nucleomics-VIB

set -o pipefail

######################################
## pick the build for this OS       ##

if [ "$(uname)" == "Darwin" ]; then
        arch=$(uname -m)
        package=yq_darwin_${arch}
elif [ "$(uname)" == "Linux" ]; then
        package=yq_linux_amd64
else
        echo "OS $(uname) is not supported by this script (Darwin|Linux)"
        exit 1
fi

function latest_git_release() {
# argument is a quoted string like "mikefarah/yq"
# 2026-09-05: this used to send "curl -u ${GITHUB_ID}:${GITHUB_TOKEN}".
# GITHUB_TOKEN is no longer set, so that sent "splaisan:" and GitHub answered
# 401, which made mybuild empty and then unlinked the working yq.
# Unauthenticated access is enough for a public repository.
curl --silent --fail --max-time 30 "https://api.github.com/repos/$1/releases/latest" \
  | grep '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/'
}

######################################
## report the release to install    ##

# take the version from the first argument, otherwise ask GitHub for the latest
mybuild=${1:-$(latest_git_release "mikefarah/yq")}

if [ -z "${mybuild}" ]; then
        echo "# could not read the latest yq release from GitHub."
        echo "# give the version as first argument, eg: $(basename "$0") v4.53.6"
        exit 1
fi

# report where the version came from before anything is changed
if [ -n "$1" ]; then
        echo "# yq release requested : ${mybuild}"
else
        echo "# latest yq release online : ${mybuild}"
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

tarball="${package}.tar.gz"

# 2026-09-05: download FIRST. The old order ran "rm -rf yq_${mybuild}" and
# "unlink yq" before wget, so a failed download left no usable yq at all.
if ! wget -O "${tarball}.part" \
     "https://github.com/mikefarah/yq/releases/download/${mybuild}/${tarball}"; then
        echo "# The archive for release ${mybuild} was not found online."
        echo "# The existing yq install was left untouched."
        rm -f "${tarball}.part"
        exit 1
fi

mv "${tarball}.part" "${tarball}" || exit 1

# only now is it safe to replace the previous copy of this same release
rm -rf "yq_${mybuild}"
mkdir -p "yq_${mybuild}" || exit 1

if ! tar -xzf "${tarball}" -C "yq_${mybuild}"; then
        echo "# The archive could not be decompressed."
        rm -f "${tarball}"
        exit 1
fi

rm -f "${tarball}"

cd "yq_${mybuild}" || exit 1

# the man page installer is not in every release
if [ -x ./install-man-page.sh ]; then
        ./install-man-page.sh
fi

# name the binary plainly inside its version folder
ln -sfn "${package}" yq || exit 1

cd "${biotools}" || exit 1

######################################
## link the new build               ##

# 2026-09-05: "ln -sfn". Without -n, and with "yq" already a symlink to a
# directory, ln creates the new link INSIDE the old folder instead of
# replacing it.
ln -sfn "yq_${mybuild}" yq || exit 1

# print version
echo
echo "# if all went right, you should see the new YQ version below"
"${biotools}/yq/yq" --version
