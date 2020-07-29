#!/bin/bash
#
# Requires RAPLCap - https://github.com/powercap/raplcap
#
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export PATH=$THIS_DIR:$PATH # to run other scripts

RAPL_CONFIGURE=rapl-configure-msr # binary

function rapl_get_all_package_caps() {
    local zones
    zones=$("$RAPL_CONFIGURE" -n) || return $?
    for ((i = 0; i < zones; i++)); do
        sudo "$RAPL_CONFIGURE" -c $i -z PACKAGE | grep watts_short | awk '{print $2}' || return $?
        local rc=${PIPESTATUS[0]}
        if [ "$rc" -ne 0 ]; then
            return "$rc"
        fi
    done
}

function rapl_set_all_package_caps() {
    local CAPS=("$@")
    local zones
    zones=$("$RAPL_CONFIGURE" -n) || return $?
    for ((i = 0; i < zones; i++)); do
        local w="${CAPS[i]}"
        echo "Setting short term power cap: package=${i}, watts=${w}"
        local cmd=(sudo "$RAPL_CONFIGURE" -c $i -z PACKAGE -W "$w")
        echo "${cmd[@]}"
        "${cmd[@]}" || return $?
    done
}

function run_rapl() {
    local p=$1
    local logdir=$2
    # expand powercap value into an array for each PACKAGE zone
    local P_ARR=()
    for ((i = 0; i < "${#POWERCAPS_ORIG[@]}"; i++)); do
        P_ARR+=("$p")
    done
    # set powercaps
    rapl_set_all_package_caps "${P_ARR[@]}" || return $?
    mkdir "$logdir" || return $?
    (
        cd "$logdir"
        echo "Characterize: powercap: start: $p"
        "${COMMAND[@]}"
        local rc=$?
        echo "Characterize: powercap: end: $p"
        return $rc
    )
}

function characterize_rapl() {
    for p in "$@"; do
        local logdir="rapl_${p}"
        if [ -e "$logdir" ]; then
            echo "WARNING: directory exists: $logdir"
            echo "  skipping..."
            continue
        fi
        run_rapl "$p" "$logdir" || return $?
    done
}

function usage() {
    echo "Characterize a command under different RAPL power caps"
    echo "Power caps are applied to each RAPL PACKAGE zone"
    echo ""
    echo "Usage: $0 [-p W]+ [-h] -- command [arguments]..."
    echo "    -p W: a power limit to test, in watts"
    echo "    -h: print help/usage and exit"
}

POWERCAPS=()
while getopts "p:h?" o; do
    case "$o" in
        p)
            POWERCAPS+=($OPTARG)
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
if [ ${#POWERCAPS[@]} -eq 0 ]; then
    2>&1 echo "Must specify at least one power cap"
    2>&1 usage
    exit 1
fi
COMMAND=("$@")

which "$RAPL_CONFIGURE" > /dev/null || {
    2>&1 echo "Required RAPLCap utilities not found"
    exit 1
}

# get original power caps for each PACKAGE
POWERCAPS_ORIG=($(rapl_get_all_package_caps)) || exit $?

characterize_rapl "${POWERCAPS[@]}"
rc=$?

# reset original powercaps
rapl_set_all_package_caps "${POWERCAPS_ORIG[@]}" || exit $?

exit $rc
