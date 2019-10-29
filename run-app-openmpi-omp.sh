#!/bin/bash

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export PATH=$THIS_DIR:$PATH # to run other scripts

function usage() {
    echo "Run an app using OpenMPI + OpenMP"
    echo "Assumes MPI process map-by=socket instead of map-by=core"
    echo ""
    echo "Usage: $0 [-h] -- [run-app-openmpi.sh args]"
    echo "    -h: print help/usage and exit"
}

while getopts "h?" o; do
    case "$o" in
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

run-app-openmpi.sh -m socket "$@"
