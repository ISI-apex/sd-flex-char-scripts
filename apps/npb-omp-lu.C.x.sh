#!/bin/bash
export APP_NAME="npb-omp-lu.C.x"
APP_BIN=$(which -a lu.C.x 2>/dev/null | grep OMP || echo "lu.C.x")
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
