#!/bin/bash

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export PATH=$THIS_DIR:$PATH # to run other scripts

# Round-robin assignment of app instances to sockets (>=1 instance per socket).
# Allows for sockets and CPUs to remain unassigned, but not shared.
function schedule_cpus_sockets_share() {
    for ((i = 0; i < N_APP_INSTANCES; i++)); do
        local sock=$((i % N_SOCKETS))
        local off=$((N_APP_THREADS_PER_INST * (i / N_SOCKETS)))
        if ((off + N_APP_THREADS_PER_INST > N_CPUS_PER_SOCK)); then
            >&2 echo "Insufficient CPU count!"
            return 1
        fi
        topology_sock_to_physcpubind $sock "$N_APP_THREADS_PER_INST" $off
    done
}

# Assign sockets to app instances (>=1 socket per instance).
# Allows for sockets to remain unassigned, but not shared.
# App instances may be oversubscribed CPUs (sockets provide N_CPUS_PER_SOCK).
function schedule_cpus_sockets_own() {
    local nsock_per_inst=$((N_APP_THREADS_PER_INST / N_CPUS_PER_SOCK))
    if ((N_APP_THREADS_PER_INST % N_CPUS_PER_SOCK)); then
        ((nsock_per_inst++)) # app was not a precise fit to socket CPUs
    fi
    local sock=0
    for ((i = 0; i < N_APP_INSTANCES; i++)); do
        local cpus=""
        for ((s = 0; s < nsock_per_inst; s++, sock++)); do
            if ((sock >= N_SOCKETS)); then
                >&2 echo "Insufficient socket count!"
                return 1
            fi
            if [ -n "$cpus" ]; then
                cpus+=","
            fi
            cpus+=$(topology_sock_to_physcpubind $sock "$N_CPUS_PER_SOCK")
        done
        echo "$cpus"
    done
}

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
    local logdir=$2
    mkdir "$logdir" || return $?
    (
        cd "$logdir" &&
        run-app-numactl.sh -a "$APP_SCRIPT_PATH" -C "$cpus" \
                           -t "$N_APP_THREADS_PER_INST" -l run-app.log
    ) &
}

function usage() {
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
topology_dbg

# enforce that topology is respected
if ((N_CPUS_PER_SOCK > TOPOLOGY_SOCKET_CPUS)); then
    >&2 echo "ERROR: CPUs per socket ($N_CPUS_PER_SOCK) >" \
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
    >&2 echo "ERROR: Total app threads ($TOTAL_APP_THREADS)" \
             "must be <= Total CPUs ($TOTAL_CPU_THREADS)"
    exit 1
fi

CPU_SCHEDULES=()
if ((N_CPUS_PER_SOCK >= N_APP_THREADS_PER_INST)); then
    # assign instances to sockets (>=1 instance per socket)
    # enforce modular fit --> never run out of CPUs
    if ((N_CPUS_PER_SOCK % N_APP_THREADS_PER_INST)); then
        >&2 echo "ERROR: CPUs per socket ($N_CPUS_PER_SOCK) >=" \
                 "Threads per app instance ($N_APP_THREADS_PER_INST) -->" \
                 "Threads per app instance ($N_APP_THREADS_PER_INST) must be a divisor of" \
                 "CPUs per socket ($N_CPUS_PER_SOCK)"
        exit 1
    fi
    # there may still be unused sockets, but that's OK
    CPU_SCHEDULES=($(schedule_cpus_sockets_share)) || exit $?
else
    # assign sockets to instances (>=1 socket per instance)
    # enforce modular fit --> never run out of sockets or oversubscribe CPUs
    if ((N_APP_THREADS_PER_INST % N_CPUS_PER_SOCK)); then
        >&2 echo "ERROR: CPUs per socket ($N_CPUS_PER_SOCK) <" \
                 "Threads per app instance ($N_APP_THREADS_PER_INST) -->" \
                 "CPUs per socket ($N_CPUS_PER_SOCK) must be a divisor of" \
                 "Threads per app instance ($N_APP_THREADS_PER_INST)"
        exit 1
    fi
    # there may still be unused sockets, but that's OK
    CPU_SCHEDULES=($(schedule_cpus_sockets_own)) || exit $?
fi

PIDS=()
for cpus in "${CPU_SCHEDULES[@]}"; do
    launch_app "$cpus" "cpus_${cpus}" || kill_all_and_die
    PIDS+=($!)
done
wait_all "${PIDS[@]}"
