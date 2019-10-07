#!/bin/bash
export APP_NAME="npb-omp-is.C.x"
APP_BIN=$(which -a is.C.x | grep OMP) || echo "is.C.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
}

function app_post() {
    :
}