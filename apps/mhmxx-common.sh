#!/bin/bash
export APP_NAME="mhmxx-common"
export APP_CMD=(mhmxx.py)

# Must set this before app_pre is called
export MHMXX_DATASET

# Since we rm this dir, don't let user arbitrarily set it
# It can still be overridden by child app scripts though
# By default, work out of a tmpfs
export MHMXX_OUTDIR=/run/user/${UID}/mhmxx_out

function mhmxx_clean_data() {
    if [ -z "$MHMXX_CLEAN_DATA" ] || [ "$MHMXX_CLEAN_DATA" -ne 0 ]; then
        rm -f "${MHMXX_OUTDIR}"/*.fast* "${MHMXX_OUTDIR}"/*contigs*
    fi
}

function mhmxx_clean_dir() {
    if [ -z "$MHMXX_CLEAN_OUTDIR" ] || [ "$MHMXX_CLEAN_OUTDIR" -ne 0 ]; then
        rm -rf "$MHMXX_OUTDIR"
    fi
}

function app_pre() {
    # Configure dataset
    if [ -z "$MHMXX_DATASET" ]; then
        2>&1 echo "mhmxx-common: Must set MHMXX_DATASET"
        return 1
    fi
    APP_CMD+=(-r "$MHMXX_DATASET")
    # Configure pinning
    if [ -z "$MHMXX_PIN" ]; then
        echo "WARNING: MHMXX_PIN={none,cpu,core,numa} not set, defaulting to 'cpu'"
        export MHMXX_PIN=cpu
    fi
    APP_CMD+=(--pin="$MHMXX_PIN")
    # Configure output dir
    APP_CMD+=(-o "$MHMXX_OUTDIR")
    # Configure process count
    APP_CMD+=(--procs "$1")
    # Clean up any old material
    mhmxx_clean_data || return $?
    mhmxx_clean_dir
}

function app_post() {
    mhmxx_clean_data || return $?
    cp -r "$MHMXX_OUTDIR" . || return $?
    mhmxx_clean_dir
}
