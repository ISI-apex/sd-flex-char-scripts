#!/bin/bash
export APP_NAME="npb-omp-ep.C.x"
APP_BIN=$(which -a ep.C.x 2>/dev/null | grep OMP || echo "ep.C.x")
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE || true
}

function app_post() {
    :
}
