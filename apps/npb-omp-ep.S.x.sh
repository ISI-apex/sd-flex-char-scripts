#!/bin/bash
export APP_NAME="npb-omp-ep.S.x"
APP_BIN=$(which -a ep.S.x | grep OMP) || echo "ep.S.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
}

function app_post() {
    :
}
