#!/bin/bash
export APP_NAME="xsbench-omp"
export APP_CMD=(XSBench)

function app_pre() {
    export OMP_NUM_THREADS=$1
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE || true
}

function app_post() {
    :
}
