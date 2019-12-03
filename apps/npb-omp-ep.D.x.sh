#!/bin/bash
export APP_NAME="npb-omp-ep.D.x"
APP_BIN=$(which -a ep.D.x 2>/dev/null | grep OMP || echo "ep.D.x")
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
