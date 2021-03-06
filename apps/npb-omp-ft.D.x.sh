#!/bin/bash
export APP_NAME="npb-omp-ft.D.x"
APP_BIN=$(which -a ft.D.x 2>/dev/null | grep OMP || echo "ft.D.x")
export APP_CMD=("$APP_BIN")

function app_pre() {
    export OMP_NUM_THREADS=$1
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE || true
}

function app_post() {
    :
}
