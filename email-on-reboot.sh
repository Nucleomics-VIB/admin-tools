#!/bin/bash

###############################################################################
# Script Name   : email-on-reboot.sh
# Description   : Sends an email notification after a successful reboot,
#                 only when SSH (port 22) is available.
# Date          : 2025-07-29
# Author        : SP@NC (+AI)
# Version       : 1.0
###############################################################################

################################################################################
# Instructions to Setup Auto Email on Reboot:
#
# 1. Save this script as /root/email-on-reboot.sh and make it executable:
#      sudo chmod +x /root/email-on-reboot.sh
#
# 2. Create a configuration file named `.email-on-reboot.conf` in the same directory as this script, with the following content:
#      EMAILADDRESS="your@email.address"
#   (Do NOT share this file if you want to keep this value private.)
#
# 3. Create a systemd service file at /etc/systemd/system/email-on-reboot.service
#    with the following content:
#
#    [Unit]
#    Description=Send email after system reboot has completed
#    After=network-online.target
#    Wants=network-online.target
#
#    [Service]
#    Type=oneshot
#    ExecStart=/bin/bash /root/email-on-reboot.sh
#
#    [Install]
#    WantedBy=multi-user.target
#
# 4. Reload systemd to recognize the new service and enable it to run after reboot:
#      sudo systemctl daemon-reload
#      sudo systemctl status email-on-reboot.service
#      sudo systemctl enable email-on-reboot.service
#
# This setup ensures the script runs on every boot after networking is ready,
# waits for SSH (port 22) to be accessible, then sends a notification email.
################################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_FILE="$SCRIPT_DIR/.email-on-reboot.conf"
if [[ -f "$CONF_FILE" ]]; then
    # shellcheck source=/dev/null
    . "$CONF_FILE"
else
    echo "Config file $CONF_FILE not found. Please create it with EMAILADDRESS variable."
    exit 1
fi

HOSTNAME=$(hostname -f 2>/dev/null || hostname)
MAX_ATTEMPTS=5    # Try 5 times
SLEEP_TIME=30     # Seconds to wait between tries
ATTEMPT=1


# Wait until port 22 is reachable, retry 5 times, send mail if failure
while ! nc -z "${HOSTNAME}" 22; do
  echo "Waiting for port 22 on ${HOSTNAME} to become available (attempt ${ATTEMPT})"
  ((ATTEMPT++))
  if [ "${ATTEMPT}" -gt "${MAX_ATTEMPTS}" ]; then
    echo "SSH port 22 not available after $((MAX_ATTEMPTS*SLEEP_TIME)) seconds. Sending failure email."
    echo "Reboot completed: $(date). SSH port 22 NOT reachable on ${HOSTNAME} after $((MAX_ATTEMPTS*SLEEP_TIME)) seconds." \
      | mail -s "[FAILURE] Server $(hostname) rebooted but SSH is NOT UP" "${EMAILADDRESS}"
    exit 1
  fi
  sleep "${SLEEP_TIME}"
done


echo "Reboot completed: $(date). Port 22 reachable." \
  | mail -s "[SUCCESS]Server $(hostname) has rebooted and SSH is UP" "${EMAILADDRESS}"
