#!/bin/bash

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export PATH=$THIS_DIR:$PATH # to run other scripts

function kill_all_and_die() {
    kill 0
    exit 1
}

function wait_all() {
    local rc=0
    for pid in "$@"; do
        wait "$pid" || rc=$?
    done
    return $rc
}

function launch_app() {
    local cpus=$1
    local logdir="cpus_${cpus}"
    mkdir "$logdir" || kill_all_and_die
    (
        cd "$logdir" &&
        run-app-numactl.sh -a "$APP_SCRIPT_PATH" -C "$cpus" \
                           -t "$N_APP_THREADS_PER_INST" -l run-app.log
    )
}

# Round-robin assignment of app instances to sockets (>=1 instance per socket).
# Allows for sockets and CPUs to remain unassigned, but not shared.
function multiapp_numactl_sockets_share() {
    local pids=()
    for ((i = 0; i < N_APP_INSTANCES; i++)); do
        local sock=$((i % N_SOCKETS))
        local off=$((N_APP_THREADS_PER_INST * (i / N_SOCKETS)))
        if ((off + N_APP_THREADS_PER_INST > N_CPUS_PER_SOCK)); then
            echo "multiapp_numactl_sockets_share: insufficient CPU count!"
            kill_all_and_die
        fi
        local cpus
        cpus=$(topology_sock_to_physcpubind $sock "$N_APP_THREADS_PER_INST" $off)
        launch_app "$cpus" &
        pids+=($!)
    done
    wait_all "${pids[@]}"
}

# Assign sockets to app instances (>=1 socket per instance).
# Allows for sockets to remain unassigned, but not shared.
# App instances may be oversubscribed CPUs (sockets provide N_CPUS_PER_SOCK).
function multiapp_numactl_sockets_own() {
    local nsock_per_inst=$((N_APP_THREADS_PER_INST / N_CPUS_PER_SOCK))
    if ((N_APP_THREADS_PER_INST % N_CPUS_PER_SOCK)); then
        ((nsock_per_inst++)) # app was not a precise fit to socket CPUs
    fi
    local sock=0
    local pids=()
    for ((i = 0; i < N_APP_INSTANCES; i++)); do
        local cpus=""
        for ((s = 0; s < nsock_per_inst; s++, sock++)); do
            if ((sock >= N_SOCKETS)); then
                echo "multiapp_numactl_sockets_own: insufficient socket count!"
                kill_all_and_die
            fi
            if [ -n "$cpus" ]; then
                cpus+=","
            fi
            cpus+=$(topology_sock_to_physcpubind $sock "$N_CPUS_PER_SOCK")
        done
        launch_app "$cpus" &
        pids+=($!)
    done
    wait_all "${pids[@]}"
}

function usage() {
    local rc=${1:-0}
    echo "Run >=1 app instance on >=1 sockets using numactl"
    echo "Creates and writes to directories in the form 'cpus_M-N[,O-P]*'"
    echo ""
    echo "Usage: $0 -a SH [-i N] [-t N] [-s N] [-c N] [-h]"
    echo "    -a SH: bash script to source with app launch vars"
    echo "    -i N: number of app instances (default=1)"
    echo "    -t N: number of threads per app instance (default=1)"
    echo "    -s N: number of sockets (default=1)"
    echo "    -c N: number of CPUs per socket (default=1)"
    echo "    -h: print help/usage and exit"
    exit "$rc"
}

N_APP_INSTANCES=1
N_APP_THREADS_PER_INST=1
N_SOCKETS=1
N_CPUS_PER_SOCK=1
while getopts "a:i:t:s:c:h?" o; do
    case "$o" in
        a)
            APP_SCRIPT=$OPTARG
            ;;
        i)
            N_APP_INSTANCES=$OPTARG
            ;;
        t)
            N_APP_THREADS_PER_INST=$OPTARG
            ;;
        s)
            N_SOCKETS=$OPTARG
            ;;
        c)
            N_CPUS_PER_SOCK=$OPTARG
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
topology_dbg

# enforce that topology is respected
if ((N_CPUS_PER_SOCK > TOPOLOGY_SOCKET_CPUS)); then
    echo "ERROR: CPUs per socket ($N_CPUS_PER_SOCK) >" \
         "TOPOLOGY_SOCKET_CPUS ($TOPOLOGY_SOCKET_CPUS)"
    exit 1
fi
if ((N_CPUS_PER_SOCK > TOPOLOGY_SOCKET_CORES)); then
    echo "NOTE: CPUs per socket ($N_CPUS_PER_SOCK) >" \
         "TOPOLOGY_SOCKET_CORES ($TOPOLOGY_SOCKET_CORES) -->" \
         "will use both physical and virtual CPUs"
fi

# enforce sufficient total resources
TOTAL_APP_THREADS=$((N_APP_INSTANCES * N_APP_THREADS_PER_INST))
TOTAL_CPU_THREADS=$((N_SOCKETS * N_CPUS_PER_SOCK))
if ((TOTAL_APP_THREADS > TOTAL_CPU_THREADS)); then
    echo "ERROR: Total app threads ($TOTAL_APP_THREADS)" \
         "must be <= Total CPUs ($TOTAL_CPU_THREADS)"
    exit 1
fi

if ((N_CPUS_PER_SOCK >= N_APP_THREADS_PER_INST)); then
    # assign instances to sockets (>=1 instance per socket)
    # enforce modular fit --> never run out of CPUs
    if ((N_CPUS_PER_SOCK % N_APP_THREADS_PER_INST)); then
        echo "ERROR: CPUs per socket ($N_CPUS_PER_SOCK) >=" \
             "Threads per app instance ($N_APP_THREADS_PER_INST) -->" \
             "Threads per app instance ($N_APP_THREADS_PER_INST) must be a divisor of" \
             "CPUs per socket ($N_CPUS_PER_SOCK)"
        exit 1
    fi
    # there may still be unused sockets, but that's OK
    multiapp_numactl_sockets_share
else
    # assign sockets to instances (>=1 socket per instance)
    # enforce modular fit --> never run out of sockets or oversubscribe CPUs
    if ((N_APP_THREADS_PER_INST % N_CPUS_PER_SOCK)); then
        echo "ERROR: CPUs per socket ($N_CPUS_PER_SOCK) <" \
             "Threads per app instance ($N_APP_THREADS_PER_INST) -->" \
             "CPUs per socket ($N_CPUS_PER_SOCK) must be a divisor of" \
             "Threads per app instance ($N_APP_THREADS_PER_INST)"
        exit 1
    fi
    # there may still be unused sockets, but that's OK
    multiapp_numactl_sockets_own
fi
