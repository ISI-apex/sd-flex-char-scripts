#!/bin/bash
export APP_NAME="npb-omp-cg.D.x"
APP_BIN=$(which -a cg.D.x 2>/dev/null | grep OMP || echo "cg.D.x")
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
