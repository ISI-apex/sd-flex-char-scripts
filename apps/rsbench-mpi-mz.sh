#!/bin/bash
export APP_NAME="rsbench-mpi-mz"
export APP_CMD=(rsbench)

function app_pre() {
    export OMP_NUM_THREADS=$2
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE
    APP_CMD+=(-t "$OMP_NUM_THREADS")
}

function app_post() {
    :
}
