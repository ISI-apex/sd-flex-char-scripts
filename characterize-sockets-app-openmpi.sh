#!/bin/bash

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export PATH=$THIS_DIR:$PATH # to run other scripts

function run_app() {
    local socks=$1
    local logdir=$2
    local cpus_per_sock=$((IS_PHYS_ONLY ? TOPOLOGY_SOCKET_CORES : TOPOLOGY_SOCKET_CPUS))
    local np=$((cpus_per_sock * socks))
    mkdir "$logdir" || return $?
    (
        cd "$logdir"
        echo "Characterize: total socket(s): start: $socks"
        run-app-openmpi.sh -a "$APP_SCRIPT_PATH" -l run-app.log \
                           -n "$np" -t 1 \
                           -m socket -b core
        local rc=$?
        echo "Characterize: total socket(s): end: $socks"
        return $rc
    )
}

function get_default_socket_counts() {
    local sockets=()
    for ((s = 1; s <= TOPOLOGY_SOCKETS; s++)); do
        local mod=$((TOPOLOGY_SOCKETS % s))
        if [ $mod -eq 0 ]; then
            sockets+=($s) # a balanced configuration
        fi
    done
    echo "${sockets[@]}"
}

function characterize_sockets() {
    for s in "$@"; do
        local logdir="sockets_${s}"
        if [ -e "$logdir" ]; then
            echo "WARNING: directory exists: $logdir"
            echo "  skipping..."
            continue
        fi
        run_app "$s" "$logdir" || return $?
    done
}

function usage() {
    local rc=${1:-0}
    echo "Characterize running a MPI app on different socket counts"
    echo ""
    echo "Usage: $0 -a SH [-s N]+ [-p] [-w] [-h]"
    echo "    -a SH: bash script to source with app launch vars"
    echo "    -s N: a socket count to characterize (default = algorithmically selected)"
    echo "    -p: use only physical cores"
    echo "    -w: perform a warmup execution before characterization"
    echo "    -h: print help/usage and exit"
    exit "$rc"
}

IS_WARMUP=0
IS_PHYS_ONLY=0
SOCKET_COUNTS=()
while getopts "a:s:pwh?" o; do
    case "$o" in
        a)
            APP_SCRIPT=$OPTARG
            ;;
        s)
            SOCKET_COUNTS+=($OPTARG)
            ;;
        p)
            IS_PHYS_ONLY=1
            ;;
        w)
            IS_WARMUP=1
            ;;
        h)
            usage
            ;;
        *)
            echo "Unknown option"
            usage 1
            ;;
    esac
done
shift $((OPTIND-1))
if [ -z "$APP_SCRIPT" ] || [ ! -f "$APP_SCRIPT" ]; then
    usage 1
fi
APP_SCRIPT_PATH=$(readlink -f "$APP_SCRIPT") # b/c we cd later

source topology.sh

if [ ${#SOCKET_COUNTS[@]} -eq 0 ]; then
    SOCKET_COUNTS=($(get_default_socket_counts))
else
    for s in "${SOCKET_COUNTS[@]}"; do
        if [ "$s" -lt 1 ] || [ "$s" -gt "$TOPOLOGY_SOCKETS" ]; then
            echo "Socket count ($s) out of range: [1, $TOPOLOGY_SOCKETS]"
            exit 1
        fi
    done
fi

if [ $IS_WARMUP -gt 0 ]; then
    run_app "$TOPOLOGY_SOCKETS" warmup || exit $?
fi

characterize_sockets "${SOCKET_COUNTS[@]}"
