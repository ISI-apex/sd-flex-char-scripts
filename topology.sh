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
}

function topology_dbg() {
    echo "TOPOLOGY_NODES: $TOPOLOGY_NODES"
    echo "TOPOLOGY_SOCKETS: $TOPOLOGY_SOCKETS"
    echo "TOPOLOGY_CORES: $TOPOLOGY_CORES"
    echo "TOPOLOGY_CPUS: $TOPOLOGY_CPUS"

    echo "TOPOLOGY_SOCKET_CORES: $TOPOLOGY_SOCKET_CORES"
    echo "TOPOLOGY_SOCKET_CPUS: $TOPOLOGY_SOCKET_CPUS"
}

# Get a bitbask for $1 cpus
function topology_cpus_to_bitmask() {
    local n=$1
    local mask=0
    for ((i = 0; i < n; i++)); do
        mask=$((mask << 1 | 1))
    done
    printf "%x\n" $mask
}

# The taskset for socket $1, for $2 cpus, at optional offset $3
# Does not verify that cpus or offset remain within socket!
function topology_sock_to_taskset() {
    # assumes CPU numbers are ordered globally by all physical, then all virtual
    # (not interleaved at socket/core granularity, which is also a valid scheme)
    local sock=$1
    local cpus=$2
    local off=$3
    [ -z "$off" ] && off=0
    local ts
    ts=$(topology_cpus_to_bitmask "$cpus")
    ts=$((ts << (sock * TOPOLOGY_SOCKET_CORES)))
    ts=$((ts << off))
    printf "%x\n" "$ts"
}

# Get CPU range for socket $1, for $2 cpus, at optional offset $3
# Does not verify that cpus or offset remain within socket!
function topology_sock_to_physcpubind() {
    # assumes CPU numbers are ordered globally by all physical, then all virtual
    # (not interleaved at socket/core granularity, which is also a valid scheme)
    local sock=$1
    local cpus=$2
    local off=$3
    [ -z "$off" ] && off=0
    local start=$(((sock * TOPOLOGY_SOCKET_CORES) + off))
    local end=$((start + cpus - 1))
    echo "${start}-${end}"
}

topology_export
