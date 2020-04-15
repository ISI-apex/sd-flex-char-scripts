#!/bin/bash
#
# Generally assumes a homogeneous architecture
#

function topology_export() {
    TOPOLOGY=$(lscpu -p=NODE,SOCKET,CORE,CPU | grep -v "#") || return $?
    # logical NUMA node number
    TOPOLOGY_NODES=$(echo "$TOPOLOGY" | cut -d, -f1 | sort -u | wc -l)
    export TOPOLOGY_NODES
    # logical sockets (may contain multiple cores)
    TOPOLOGY_SOCKETS=$(echo "$TOPOLOGY" | cut -d, -f2 | sort -u | wc -l)
    export TOPOLOGY_SOCKETS
    # logical cores (may contain multiple CPUs)
    TOPOLOGY_CORES=$(echo "$TOPOLOGY" | cut -d, -f3 | sort -u | wc -l)
    export TOPOLOGY_CORES
    # logical CPUs
    TOPOLOGY_CPUS=$(echo "$TOPOLOGY" | cut -d, -f4 | sort -u | wc -l)
    export TOPOLOGY_CPUS

    # the following assume a homogeneous socket configuration
    TOPOLOGY_SOCKET_CORES=$((TOPOLOGY_CORES / TOPOLOGY_SOCKETS))
    export TOPOLOGY_SOCKET_CORES
    TOPOLOGY_SOCKET_CPUS=$((TOPOLOGY_CPUS / TOPOLOGY_SOCKETS))
    export TOPOLOGY_SOCKET_CPUS

    # the following assume a homogeneous core configuration
    TOPOLOGY_CORE_CPUS=$((TOPOLOGY_CPUS / TOPOLOGY_CORES))
    export TOPOLOGY_CORE_CPUS
}

function topology_dbg() {
    echo "TOPOLOGY_NODES: $TOPOLOGY_NODES"
    echo "TOPOLOGY_SOCKETS: $TOPOLOGY_SOCKETS"
    echo "TOPOLOGY_CORES: $TOPOLOGY_CORES"
    echo "TOPOLOGY_CPUS: $TOPOLOGY_CPUS"

    echo "TOPOLOGY_SOCKET_CORES: $TOPOLOGY_SOCKET_CORES"
    echo "TOPOLOGY_SOCKET_CPUS: $TOPOLOGY_SOCKET_CPUS"

    echo "TOPOLOGY_CORE_CPUS: $TOPOLOGY_CORE_CPUS"
}

# Get CPU range for socket $1, for $2 cores, core offset $3, $4 threads/core
# Does not verify that cores/threads remain within the socket!
function topology_sock_to_physcpubind() {
    # See: https://www.kernel.org/doc/Documentation/x86/topology.txt
    # Assumes "Alternative enumeration" of CPU numbering (typical Intel), i.e.,
    # ordered globally by all physical, then all virtual
    # (not interleaved at socket/core granularity, which is also a valid scheme)
    # e.g.:
    # [core 0] -> [thread 0] -> Linux CPU 0 # Physical
    #          -> [thread 1] -> Linux CPU 2 # HyperThread
    #          -> [thread 2] -> Linux CPU 3 # HyperThread
    #          -> [thread 3] -> Linux CPU 4 # HyperThread
    # [core 1] -> [thread 0] -> Linux CPU 1 # Physical
    #          -> [thread 1] -> Linux CPU 5 # HyperThread
    #          -> [thread 2] -> Linux CPU 6 # HyperThread
    #          -> [thread 3] -> Linux CPU 7 # HyperThread
    local sock=$1
    local cores=$2
    local off=$3
    local threads_per_core=$4
    local start_cpu=$(((sock * TOPOLOGY_SOCKET_CORES) + off))
    local end_cpu=$((start_cpu + cores - 1))
    local physcpubind="${start_cpu}-${end_cpu}"
    if [ "$threads_per_core" -gt 1 ]; then
        if [ "$threads_per_core" -eq "$TOPOLOGY_CORE_CPUS" ]; then
            # group the thread CPU range into a single expression
            start_cpu=$(((TOPOLOGY_SOCKETS * TOPOLOGY_SOCKET_CORES) +
                         (sock * (TOPOLOGY_SOCKET_CPUS - TOPOLOGY_SOCKET_CORES)) +
                          ((TOPOLOGY_CORE_CPUS - 1) * off)))
            end_cpu=$((start_cpu + ((threads_per_core - 1) * cores) - 1))
            physcpubind+=",${start_cpu}-${end_cpu}"
        else
            # need a separate CPU range expression for each core's threads
            for ((c=0; c<cores; c++)); do
                start_cpu=$(((TOPOLOGY_SOCKETS * TOPOLOGY_SOCKET_CORES) +
                             (sock * (TOPOLOGY_SOCKET_CPUS - TOPOLOGY_SOCKET_CORES)) +
                              ((TOPOLOGY_CORE_CPUS - 1) * (off + c))))
                end_cpu=$((start_cpu + (threads_per_core - 1) - 1))
                physcpubind+=",${start_cpu}-${end_cpu}"
            done
        fi
    fi
    echo "$physcpubind"
}

# Get node range for socket counts
# Does not verify that socket counts do not overflow
function topology_socks_to_nodes() {
    local sock_start=$1
    local sock_count=$2
    local scale
    local nodes=""
    if [ "$TOPOLOGY_NODES" -le "$TOPOLOGY_SOCKETS" ]; then
        # 1 or more sockets per node
        scale=$((TOPOLOGY_SOCKETS / TOPOLOGY_NODES))
        node_start=$((sock_start / scale))
        node_end=$(((sock_start + sock_count - 1) / scale))
        if [ "$node_start" -eq "$node_end" ]; then
            nodes=$node_start
        else
            nodes="${node_start}-${node_end}"
        fi
    else # [ "$TOPOLOGY_NODES" -gt "$TOPOLOGY_SOCKETS" ]
        # multiple nodes per socket
        # TODO: This may over-allocate when only a partial socket is needed
        #       Add param for cores to compute better node_{start,end}?
        scale=$((TOPOLOGY_NODES / TOPOLOGY_SOCKETS))
        node_start=$((sock_start * scale))
        node_end=$((((sock_start + sock_count - 1) * scale) + (scale - 1)))
        nodes="${node_start}-${node_end}"
    fi
    echo "$nodes"
}

topology_export
