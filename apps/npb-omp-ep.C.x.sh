#!/bin/bash
export APP_NAME="npb-omp-ep.C.x"
APP_BIN=$(which -a ep.C.x | grep OMP) || echo "ep.C.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
}

function app_post() {
    :
}
