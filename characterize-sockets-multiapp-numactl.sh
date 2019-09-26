#!/bin/bash

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export PATH=$THIS_DIR:$PATH # to run other scripts

function run_multiapp() {
    local socks=$1
    local logdir=$2
    local cpus=$((IS_PHYS_ONLY ? TOPOLOGY_SOCKET_CORES : TOPOLOGY_SOCKET_CPUS))
    mkdir "$logdir" || return $?
    (
        cd "$logdir"
        echo "Characterize: total socket(s): start: $socks"
        run-multiapp-numactl.sh -a "$APP_SCRIPT_PATH" \
                                -i "$socks" -t $cpus \
                                -s "$socks" -c $cpus
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

function characterize_sockets_multiapp() {
    for s in "$@"; do
        local logdir="sockets_${s}"
        if [ -e "$logdir" ]; then
            echo "WARNING: directory exists: $logdir"
            echo "  skipping..."
            continue
        fi
        run_multiapp "$s" "$logdir" || return $?
    done
}

function usage() {
    local rc=${1:-0}
    echo "Characterize running app instances on different socket counts"
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
    run_multiapp "$TOPOLOGY_SOCKETS" warmup || exit $?
fi

characterize_sockets_multiapp "${SOCKET_COUNTS[@]}"
