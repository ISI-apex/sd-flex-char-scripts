#!/bin/bash
export APP_NAME="mhmxx-gut5x"
APP_BIN=$(which mhmxx) # upcxx-run seems to need the full path
DATASET=/dev/shm/gut-5x.fastq
export APP_CMD=()

function app_pre() {
    # NOTE: cores-per-node is platform-specific!
    APP_CMD+=(upcxx-run -shared-heap "5%" -n "$1" --
              "$APP_BIN" --cores-per-node 24 -r "$DATASET" -i 300:30 -k 21,33,55,77,99 -s 99,33)
}

function app_post() {
    rm -f *.fast*
}
