#!/bin/bash
export APP_NAME="xsbench-mpi-mz"
export APP_CMD=(XSBench)

function app_pre() {
    export OMP_NUM_THREADS=$2
    export OMP_PROC_BIND=TRUE
    APP_CMD+=(-t "$OMP_NUM_THREADS")
}

function app_post() {
    :
}
