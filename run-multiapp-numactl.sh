#!/bin/bash

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export PATH=$THIS_DIR:$PATH # to run other scripts

function schedule_mem_nodes_interleave() {
    local nsock_per_inst=$((N_CORES_PER_INST / N_CORES_PER_SOCK))
    if ((N_CORES_PER_INST % N_CORES_PER_SOCK)); then
        ((nsock_per_inst++)) # app was not a precise fit to socket CPUs
    fi
    for ((i = 0; i < N_APP_INSTANCES; i++)); do
        local sock_start=$(((i * nsock_per_inst) % N_SOCKETS))
        topology_socks_to_nodes $sock_start $nsock_per_inst
    done
}

# Round-robin assignment of app instances to sockets (>=1 instance per socket).
# Allows for sockets and cores to remain unassigned, but not shared.
function schedule_cpus_sockets_share() {
    for ((i = 0; i < N_APP_INSTANCES; i++)); do
        local sock=$((i % N_SOCKETS))
        local off=$((N_CORES_PER_INST * (i / N_SOCKETS)))
        if ((off + N_CORES_PER_INST > TOPOLOGY_SOCKET_CORES)); then
            >&2 echo "Insufficient core count!"
            return 1
        fi
        topology_sock_to_physcpubind $sock "$N_CORES_PER_INST" $off \
                                     "$N_CPU_THREADS_PER_CORE"
    done
}

# Assign sockets to app instances (>=1 socket per instance).
# Allows for sockets to remain unassigned, but not shared.
# Apps may be oversubscribed cores (sockets have TOPOLOGY_SOCKET_CORES cores).
function schedule_cpus_sockets_own() {
    local nsock_per_inst=$((N_CORES_PER_INST / N_CORES_PER_SOCK))
    if ((N_CORES_PER_INST % N_CORES_PER_SOCK)); then
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
            cpus+=$(topology_sock_to_physcpubind $sock "$N_CORES_PER_SOCK" 0 \
                                                 "$N_CPU_THREADS_PER_CORE")
        done
        echo "$cpus"
    done
}

function trap_cleanup() {
    if [ -n "$INTERCEPTOR_SCRIPT" ]; then
        echo "$INTERCEPTOR_NAME: TRAP: interceptor_stop"
        interceptor_stop
    fi
    kill 0
}

function wait_all() {
    local rc=0
    for pid in "$@"; do
        wait "$pid" || rc=$?
    done
    return $rc
}

function launch_app() {
    local logdir=$1
    shift
    mkdir "$logdir" || return $?
    (
        cd "$logdir" &&
        run-app-numactl.sh -a "$APP_SCRIPT_PATH" -t "$N_APP_THREADS_PER_INST" \
                           -l run-app.log -- "$@"
    ) &
}

function usage() {
    echo "Run >=1 app instance on >=1 sockets using numactl"
    echo "Creates and writes to directories in the form 'cpus_M-N[,O-P]*'"
    echo ""
    echo "Usage: $0 -a SH [-g SH] [-i N] [-t N] [-s N] [-c N] [-m POLICY] [-ph]"
    echo "    -a SH: bash script to source with app launch vars"
    echo "    -g SH: bash script to source with global interceptor configurations"
    echo "    -i N: number of app instances (default=1)"
    echo "    -t N: number of threads per app instance (default=1)"
    echo "    -s N: number of sockets (default=1)"
    echo "    -c N: number of cores per socket (default=1)"
    echo "    -m POLICY: numactl memory policy (default=NONE), one of:"
    echo "       local: use '-l' option"
    echo "       interleave: use '-i' option"
    echo "    -p: use only physical cores"
    echo "    -h: print help/usage and exit"
}

INTERCEPTOR_SCRIPT=
N_APP_INSTANCES=1
N_APP_THREADS_PER_INST=1
N_SOCKETS=1
N_CORES_PER_SOCK=1
IS_USE_HT=1
MEM_POLICY=
while getopts "a:i:t:s:c:m:g:ph?" o; do
    case "$o" in
        a)
            APP_SCRIPT=$OPTARG
            ;;
        g)
            INTERCEPTOR_SCRIPT=$OPTARG
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
            N_CORES_PER_SOCK=$OPTARG
            ;;
        m)
            if [ "$OPTARG" != "local" ] && [ "$OPTARG" != "interleave" ]; then
                >&2 usage
                exit 1
            fi
            MEM_POLICY="$OPTARG"
            ;;
        p)
            IS_USE_HT=0
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

if [ -n "$INTERCEPTOR_SCRIPT" ]; then
    source "$INTERCEPTOR_SCRIPT" || exit $?
    if [ -z "$INTERCEPTOR_NAME" ]; then
        INTERCEPTOR_NAME="<UNKNOWN>"
    fi
fi

source topology.sh
topology_dbg

# Compute how many cores and CPU threads/core we need for each app instance
N_CPU_THREADS_PER_CORE=$((IS_USE_HT ? TOPOLOGY_CORE_CPUS : 1))
N_CORES_PER_INST=$((N_APP_THREADS_PER_INST / N_CPU_THREADS_PER_CORE))
if ((N_APP_THREADS_PER_INST % N_CPU_THREADS_PER_CORE)); then
    # over-allocated on CPUs, e.g., one app thread but one core also has HTs
    ((N_CORES_PER_INST++))
fi

# enforce that topology is respected
if ((N_CORES_PER_SOCK > TOPOLOGY_SOCKET_CORES)); then
    >&2 echo "ERROR: Cores per socket ($N_CORES_PER_SOCK) >" \
             "TOPOLOGY_SOCKET_CORES ($TOPOLOGY_SOCKET_CORES)"
    exit 1
fi

# enforce sufficient total resources
TOTAL_APP_CORES=$((N_APP_INSTANCES * N_CORES_PER_INST))
if ((TOTAL_APP_CORES > TOPOLOGY_CORES)); then
    >&2 echo "ERROR: Total app cores ($TOTAL_APP_CORES)" \
             "must be <= TOPOLOGY_CORES ($TOPOLOGY_CORES)"
    exit 1
fi

CPU_SCHEDULES=()
if ((N_CORES_PER_SOCK >= N_CORES_PER_INST)); then
    # assign instances to sockets (>=1 instance per socket)
    # enforce modular fit --> never run out of CPUs
    if ((N_CORES_PER_SOCK % N_CORES_PER_INST)); then
        >&2 echo "ERROR: Cores per socket ($N_CORES_PER_SOCK) >=" \
                 "Cores per app instance ($N_CORES_PER_INST) -->" \
                 "Cores per app instance ($N_CORES_PER_INST) must be a divisor of" \
                 "Cores per socket ($N_CORES_PER_SOCK)"
        exit 1
    fi
    # there may still be unused sockets, but that's OK
    CPU_SCHEDULES=($(schedule_cpus_sockets_share)) || exit $?
else
    # assign sockets to instances (>=1 socket per instance)
    # enforce modular fit --> never run out of sockets or oversubscribe CPUs
    if ((N_CORES_PER_INST % N_CORES_PER_SOCK)); then
        >&2 echo "ERROR: Cores per socket ($N_CORES_PER_SOCK) <" \
                 "Cores per app instance ($N_CORES_PER_INST) -->" \
                 "Cores per socket ($N_CORES_PER_SOCK) must be a divisor of" \
                 "Cores per app instance ($N_CORES_PER_INST)"
        exit 1
    fi
    # there may still be unused sockets, but that's OK
    CPU_SCHEDULES=($(schedule_cpus_sockets_own)) || exit $?
fi

MEM_SCHEDULES=($(schedule_mem_nodes_interleave))
if [ ${#MEM_SCHEDULES[@]} -ne ${#CPU_SCHEDULES[@]} ]; then
    >&2 echo "BUG: len(MEM_SCHEDULES) != len(CPU_SCHEDULES)"
    exit 1
fi

trap trap_cleanup EXIT

if [ -n "$INTERCEPTOR_SCRIPT" ]; then
    echo "$INTERCEPTOR_NAME: interceptor_start"
    interceptor_start || exit $?
fi

PIDS=()
for ((i=0; i<${#CPU_SCHEDULES[@]}; i++)); do
    NUMACTL_ARGS=()
    if [ "$MEM_POLICY" == "local" ]; then
        NUMACTL_ARGS+=(-l)
    elif [ "$MEM_POLICY" == "interleave" ]; then
        NUMACTL_ARGS+=(-i "${MEM_SCHEDULES[i]}")
    fi
    cpus=${CPU_SCHEDULES[i]}
    NUMACTL_ARGS+=(-C "$cpus")
    launch_app "cpus_${cpus}" "${NUMACTL_ARGS[@]}" || exit $?
    PIDS+=($!)
done
wait_all "${PIDS[@]}"
rc=$?

if [ -n "$INTERCEPTOR_SCRIPT" ]; then
    echo "$INTERCEPTOR_NAME: interceptor_stop"
    interceptor_stop || rc=$?
fi

trap - EXIT

exit $rc
