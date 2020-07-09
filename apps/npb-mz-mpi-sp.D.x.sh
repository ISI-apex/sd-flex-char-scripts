#!/bin/bash
export APP_NAME="npb-mz-mpi-sp.D.x"
export APP_CMD=(sp-mz.D.x)

function app_pre() {
    export OMP_NUM_THREADS=$2
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE || true
}

function app_post() {
    :
}
