#!/bin/bash
export APP_NAME="mhmxx-synth64d"
APP_BIN=$(which mhmxx) # upcxx-run seems to need the full path
DATASET=/dev/shm/synth64d.fastq
export APP_CMD=()

function app_pre() {
    APP_CMD+=(upcxx-run -shared-heap "5%" -n "$1" --
              "$APP_BIN" -r "$DATASET" -o "mhmxx_out" -i "300:30" -k "21,33,55,77,99" -s "99,33")
}

function app_post() {
    rm -f mhmxx_out/*.fast*
}
