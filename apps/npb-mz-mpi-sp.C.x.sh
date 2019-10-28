#!/bin/bash
export APP_NAME="npb-mz-mpi-sp.C.x"
export APP_CMD=(sp-mz.C.x)

function app_pre() {
    export OMP_NUM_THREADS=$2
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
