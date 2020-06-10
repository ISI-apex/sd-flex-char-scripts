#!/bin/bash
export APP_NAME="npb-mz-mpi-lu.S.x"
export APP_CMD=(lu-mz.S.x)

function app_pre() {
    export OMP_NUM_THREADS=$2
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
