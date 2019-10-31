#!/bin/bash
export APP_NAME="npb-omp-sp.D.x"
APP_BIN=$(which -a sp.D.x 2>/dev/null | grep OMP || echo "sp.D.x")
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
