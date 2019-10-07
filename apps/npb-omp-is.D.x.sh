#!/bin/bash
export APP_NAME="npb-omp-is.D.x"
APP_BIN=$(which -a is.D.x | grep OMP) || echo "is.D.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
}

function app_post() {
    :
}
