#!/usr/bin/env bash
#
# script: delivery_readme.sh
# Write the customer README.txt for a Nextcloud delivery folder.
#
# The README is the house template in the private repo
#   Nucleomics-VIB-internal/shared-resources
#   standard-files/nextcloud-delivery/README.txt
# The function fetches the current template from GitHub at each call, so a new
# template version reaches the next delivery with no edit here. If the fetch
# fails (no network, no 'gh' login, no version stamp in the answer), it writes
# the copy in assets/README.txt and prints a warning. That copy can be older
# than the template.
#
# usage (source it, then call the function):
#   source "$(dirname "$(readlink -f "$0")")/delivery_readme.sh"
#   get_delivery_readme /path/to/README.txt
# or run it directly:
#   delivery_readme.sh /path/to/README.txt
#
# requires: curl; gh logged in to an account that can read shared-resources
#
# Stephane Plaisance (VIB Nucleomics Core) 2026-10-12; v1.0

DELIVERY_README_API="https://api.github.com/repos/Nucleomics-VIB-internal/shared-resources/contents/standard-files/nextcloud-delivery/README.txt"
DELIVERY_README_STAMP="VIB Nucleomics Core - delivery README v"
DELIVERY_README_FALLBACK="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/assets/README.txt"

get_delivery_readme() {
    local dest="$1" tmp token
    if [ -z "${dest}" ]; then
        echo "get_delivery_readme: give the destination file" >&2
        return 1
    fi
    tmp=$(mktemp) || return 1
    token=$(gh auth token 2>/dev/null)
    if [ -n "${token}" ] \
        && curl -fsS --max-time 20 \
            -H "Authorization: Bearer ${token}" \
            -H "Accept: application/vnd.github.raw" \
            -o "${tmp}" "${DELIVERY_README_API}" \
        && grep -q "${DELIVERY_README_STAMP}" "${tmp}"; then
        cp "${tmp}" "${dest}"
        echo "# README.txt: current template ($(grep "${DELIVERY_README_STAMP}" "${tmp}"))" >&2
    else
        echo "WARNING: could not fetch the current README template from GitHub;" >&2
        echo "         using the local copy ${DELIVERY_README_FALLBACK}, which can be old." >&2
        cp "${DELIVERY_README_FALLBACK}" "${dest}" || { rm -f "${tmp}"; return 1; }
    fi
    rm -f "${tmp}"
}

# run directly: write the README to the file given as $1
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    get_delivery_readme "$1"
fi
