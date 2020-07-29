#!/bin/bash
#
# Requires RAPLCap - https://github.com/powercap/raplcap
#
RAPL_CONFIGURE=rapl-configure-msr # binary
RAPLCAP_CONSTRAINT_SHORT_W=246

function raplcap_reset() {
    local zones
    zones=$("$RAPL_CONFIGURE" -n) || return $?
    for ((i = 0; i < zones; i++)); do
        echo "Setting short term power cap: package=${i}, watts=${RAPLCAP_CONSTRAINT_SHORT_W}"
        "$RAPL_CONFIGURE" -c $i -z PACKAGE -W "$RAPLCAP_CONSTRAINT_SHORT_W" || return $?
    done
}

raplcap_reset
