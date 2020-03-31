#!/bin/bash

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export PATH=$THIS_DIR:$PATH # to run other scripts

function run_multiapp() {
    local socks=$1
    local logdir=$2
    local cpus=$((IS_PHYS_ONLY ? TOPOLOGY_SOCKET_CORES : TOPOLOGY_SOCKET_CPUS))
    local insts=$((IS_MULTIPLE ? socks : 1))
    local threads=$((IS_MULTIPLE ? cpus : cpus * socks))
    local OPTIONAL_PARAMS=()
    if [ "$IS_PHYS_ONLY" -ne 0 ]; then
        OPTIONAL_PARAMS+=(-p)
    fi
    mkdir "$logdir" || return $?
    (
        cd "$logdir"
        echo "Characterize: total socket(s): start: $socks"
        run-multiapp-numactl.sh -a "$APP_SCRIPT_PATH" \
                                -i "$insts" -t $threads \
                                -s "$socks" -c "$TOPOLOGY_SOCKET_CORES" \
                                "${OPTIONAL_PARAMS[@]}"
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
    echo "Characterize running app instance(s) on different socket counts"
    echo ""
    echo "Usage: $0 -a SH [-s N]+ [-p] [-u | -m] [-w] [-h]"
    echo "    -a SH: bash script to source with app launch vars"
    echo "    -s N: a socket count to characterize (default = algorithmically selected)"
    echo "    -p: use only physical cores"
    echo "    -u: unified execution - one app instance only (default, overrides -m)"
    echo "    -m: multiple executions - one app instance per socket (overrides -u)"
    echo "    -w: perform a warmup execution before characterization"
    echo "    -h: print help/usage and exit"
}

IS_MULTIPLE=0
IS_WARMUP=0
IS_PHYS_ONLY=0
SOCKET_COUNTS=()
while getopts "a:s:pumwh?" o; do
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
        u)
            IS_MULTIPLE=0
            ;;
        m)
            IS_MULTIPLE=1
            ;;
        w)
            IS_WARMUP=1
            ;;
        h)
            usage
            exit
            ;;
        *)
            >&2 usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))
if [ -z "$APP_SCRIPT" ] || [ ! -f "$APP_SCRIPT" ]; then
    >&2 usage
    exit 1
fi
APP_SCRIPT_PATH=$(readlink -f "$APP_SCRIPT") # b/c we cd later

source topology.sh

if [ ${#SOCKET_COUNTS[@]} -eq 0 ]; then
    SOCKET_COUNTS=($(get_default_socket_counts))
else
    for s in "${SOCKET_COUNTS[@]}"; do
        if [ "$s" -lt 1 ] || [ "$s" -gt "$TOPOLOGY_SOCKETS" ]; then
            >&2 echo "Socket count ($s) out of range: [1, $TOPOLOGY_SOCKETS]"
            exit 1
        fi
    done
fi

if [ $IS_WARMUP -gt 0 ]; then
    run_multiapp "$TOPOLOGY_SOCKETS" warmup || exit $?
fi

characterize_sockets_multiapp "${SOCKET_COUNTS[@]}"
