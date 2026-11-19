#!/bin/bash

# script: php_pages_test.sh
# check that no form field of the PHP pages can run a shell command (#12)
# 1. php -l on each page
# 2. tests/php_pages_cases.php: the command that build_cmd() makes for valid and refused values
# 3. send a hostile POST to each page: the marker file must not appear
# usage: tests/php_pages_test.sh (from any folder; PHP=<path> to use another php)
#
# Stephane Plaisance (VIB-NC) 2026/11/19; v1.0
# visit our Git: https://github.com/Nucleomics-VIB

set -eu
cd "$(dirname "$0")/.."
repo=$PWD
PHP=${PHP:-php}

pages="CreateProjectFolder/create_project_folder_onL.php
PrintCustomLabels/print_custom_labels.php
PrintCustomLabels/print_custom_labels_slims.php"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mark="$tmp/mark"
echo "labels" > "$tmp/labels.txt"
fails=0

echo "# PHP $("$PHP" -r 'echo PHP_VERSION;')"

echo "# 1. syntax"
for page in $pages; do
  if "$PHP" -l "$page" >/dev/null; then
    echo "ok   $page"
  else
    echo "FAIL $page"; fails=$((fails+1))
  fi
done

echo "# 2. commands"
for page in $pages; do
  echo "## $page"
  "$PHP" tests/php_pages_cases.php "$page" || fails=$((fails+1))
done

echo "# 3. hostile POST"
# a POST with a valid value runs the page script; never do that on a host that has it
for script in create_project_folder_onL.sh print_custom_labels.sh print_custom_labels_slims.sh; do
  if [ -e "/var/www/cgi-bin/$script" ]; then
    echo "STOP /var/www/cgi-bin/$script exists: run this test on a host without the pages"
    exit 1
  fi
done

# run in $tmp: a payload that reaches the shell can make other files
probe() {
  rm -f "$mark"
  (cd "$tmp" && FIELD=$2 PAYLOAD=$3 UPLOAD="$tmp/labels.txt" "$PHP" \
    -d auto_prepend_file="$repo/tests/php_post_prepend.php" \
    -d session.save_path="$tmp" "$repo/$1" >/dev/null 2>&1) || true
  if [ -e "$mark" ]; then
    echo "FAIL $1 $2 ran: $3"; fails=$((fails+1))
  else
    echo "ok   $1 $2: $3"
  fi
}

# control: the marker must appear when a payload does reach the shell
rm -f "$mark"
# shellcheck disable=SC2016 # the PHP code must not expand in bash
(cd "$tmp" && "$PHP" -r 'shell_exec("true ".$argv[1]);' "; touch $mark" >/dev/null 2>&1) || true
if [ -e "$mark" ]; then
  echo "ok   control: a payload that reaches the shell makes the marker"
else
  echo "FAIL control: the marker does not appear, so this step proves nothing"; fails=$((fails+1))
fi

payloads="; touch $mark
\`touch $mark\`
\$(touch $mark)"

while IFS= read -r payload; do
  probe CreateProjectFolder/create_project_folder_onL.php number "$payload"
  for page in PrintCustomLabels/print_custom_labels.php PrintCustomLabels/print_custom_labels_slims.php; do
    for field in size type text copies darkness; do
      probe "$page" "$field" "$payload"
    done
  done
  probe PrintCustomLabels/print_custom_labels_slims.php upload_name "a.csv$payload"
done <<< "$payloads"

if [ "$fails" -eq 0 ]; then
  echo "# all checks pass"
else
  echo "# $fails check(s) failed"
  exit 1
fi
