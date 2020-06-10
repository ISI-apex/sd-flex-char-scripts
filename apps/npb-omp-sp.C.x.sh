#!/bin/bash
export APP_NAME="npb-omp-sp.C.x"
APP_BIN=$(which -a sp.C.x 2>/dev/null | grep OMP || echo "sp.C.x")
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
