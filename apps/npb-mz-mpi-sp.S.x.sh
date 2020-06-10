#!/bin/bash
export APP_NAME="npb-mz-mpi-sp.S.x"
export APP_CMD=(sp-mz.S.x)

function app_pre() {
    export OMP_NUM_THREADS=$2
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
