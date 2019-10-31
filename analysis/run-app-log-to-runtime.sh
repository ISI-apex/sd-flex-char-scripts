#!/bin/bash
#
# Expects the run-app log file as $1
#

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export PATH=$THIS_DIR:$PATH # to run other scripts

function compute_runtime() {
    local f=$1
    local s e
    s=$(grep "start:" "$f" | awk '{print $3}')
    e=$(grep "end:" "$f" | awk '{print $3}')
    if [ -z "$s" ] || [ -z "$e" ]; then
        >&2 echo "Failed to parse for start and end times: $f"
        return 1
    fi
    time-diff-sec.py "$s" "$e"
}

compute_runtime "$1"
