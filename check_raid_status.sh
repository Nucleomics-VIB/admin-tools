#!/bin/bash
# check_raid_status.sh
# Checks RAID status for all disks by ID, analyzes results, and emails status
# Created: 2025-07-28



# CONFIGURATION (defaults, can be overridden by args)
MAIL_TO="stephane.plaisance@vib.be"
# Set MAIL_FROM to use the system's short hostname
MAIL_FROM="check_raid_status@$(hostname -s 2>/dev/null || hostname)"
MAIL_SUBJECT=""
RAID_BUS="/dev/bus/0"
LOGFILE=""
HOSTNAME=$(hostname)
SHOW_HELP=0

# Usage info
usage() {
    echo "Usage: $0 -t <to_email> [-f <from_email>] [-s <subject>] [-b <raid_bus>] [-l <logfile>] [-h]"
    echo "  -t <to_email>      Email address to send results to (required)"
    echo "  -f <from_email>    Email address to send from (optional)"
    echo "  -s <subject>       Email subject (optional, auto-set by script if not provided)"
    echo "  -b <raid_bus>      RAID bus device (default: /dev/bus/0)"
    echo "  -l <logfile>       Log file name (default: raid_log-<timestamp>.txt)"
    echo "  -h                 Show this help message"
}

# Parse options
while getopts ":t:f:s:b:l:h" opt; do
  case $opt in
    t) MAIL_TO="$OPTARG" ;;
    f) MAIL_FROM="$OPTARG" ;;
    s) MAIL_SUBJECT="$OPTARG" ;;
    b) RAID_BUS="$OPTARG" ;;
    l) LOGFILE="$OPTARG" ;;
    h) SHOW_HELP=1 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done

if [[ $SHOW_HELP -eq 1 ]]; then
    usage
    exit 0
fi

if [[ -z "$MAIL_TO" ]]; then
    echo "Error: -t <to_email> is required." >&2
    usage
    exit 1
fi

# Set log file if not provided
if [[ -z "$LOGFILE" ]]; then
    LOGFILE="raid_log-$(date +%s).txt"
fi



# RAID check function (writes full output to a temp file, then writes summary or full log as needed)
checkraid() {
    local tmpfile
    tmpfile=$(mktemp)

    echo "disks present now:" > "$tmpfile"
    smartctl --scan >> "$tmpfile"
    echo >> "$tmpfile"

    # build array of disk IDs (safe splitting)
    mapfile -t idlist < <(smartctl --scan | gawk 'BEGIN{FS=" "; OFS="\t"}{if ($3 ~/megaraid/) split($3,v,","); print v[2]}' | grep -v '^$')

    for i in "${idlist[@]}"; do
        echo "####################################################" >> "$tmpfile"
        echo "checking disk: ${i}" >> "$tmpfile"
        echo "####################################################" >> "$tmpfile"
        smartctl -a "$RAID_BUS" -d megaraid,${i} \
            >> "$tmpfile"
    done
    echo >> "$tmpfile"
    echo "#the  full test output was stored to $tmpfile" >> "$tmpfile"

    # Analyze the log for RAID health
    if grep -qiE 'FAILED|FAIL|SMART overall-health.*FAILED' "$tmpfile"; then
        STATUS="RAID CHECK FAILED on $HOSTNAME"
        RESULT_TYPE="fail"
    elif grep -qiE 'PASSED|OK|SMART overall-health.*PASSED' "$tmpfile"; then
        STATUS="RAID CHECK PASSED on $HOSTNAME"
        RESULT_TYPE="ok"
    else
        STATUS="RAID CHECK WARNING/UNKNOWN on $HOSTNAME"
        RESULT_TYPE="unknown"
    fi

    # Write log file for mail: summary if OK, full output if not
    if [[ "$RESULT_TYPE" == "ok" ]]; then
        {
            echo "RAID result: $STATUS"
            echo
            echo "All disks passed RAID check."
        } > "$LOGFILE"
    else
        {
            echo "RAID result: $STATUS"
            for i in {1..10}; do echo; done
            cat "$tmpfile"
        } > "$LOGFILE"
    fi

    rm -f "$tmpfile"
}



# Run the check (status is set inside checkraid)
checkraid

# Set subject if not provided
if [[ -z "$MAIL_SUBJECT" ]]; then
    MAIL_SUBJECT="$STATUS"
fi



# Function to send mail using sendmail (based on mailit.sh)
mailit() {
    local fromopt="$1"
    local to="$2"
    local subject="$3"
    local messagefile="$4"

    # check sendmail
    if ! hash sendmail 2>/dev/null; then
        echo "# sendmail not installed or not in PATH" >&2
        return 1
    fi

    # check required args
    if [[ -z "$to" || -z "$subject" || -z "$messagefile" ]]; then
        echo "# to, subject, and message file are required!" >&2
        return 1
    fi

    local from
    if [[ -z "$fromopt" ]]; then
        from="$(whoami)@$(hostname)"
    else
        from="$fromopt"
    fi

    sendmail -f "$from" "$to" << EOM
From: $from
To: $to
Subject: $subject

$(cat "$messagefile")
EOM
}

# Send the log by mail using mailit
mailit "$MAIL_FROM" "$MAIL_TO" "$MAIL_SUBJECT" "$LOGFILE"

echo "RAID check complete. Status: $STATUS. Log sent to $MAIL_TO."
