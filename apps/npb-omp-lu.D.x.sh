#!/bin/bash
export APP_NAME="npb-omp-lu.D.x"
APP_BIN=$(which -a lu.D.x 2>/dev/null | grep OMP || echo "lu.D.x")
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
