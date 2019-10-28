#!/bin/bash
export APP_NAME="npb-mz-mpi-lu.C.x"
export APP_CMD=(lu-mz.C.x)

function app_pre() {
    export OMP_NUM_THREADS=$2
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
