#!/bin/bash
export APP_NAME="npb-mz-mpi-bt.S.x"
export APP_CMD=(bt-mz.S.x)

function app_pre() {
    export OMP_NUM_THREADS=$2
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE || true
}

function app_post() {
    :
}
