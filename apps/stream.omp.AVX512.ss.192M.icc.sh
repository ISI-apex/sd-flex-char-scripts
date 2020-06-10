#!/bin/bash
export APP_NAME="stream.omp.AVX512.ss.192M.icc"
export APP_CMD=(stream.omp.AVX512.ss.192M.icc)

function app_pre() {
    export OMP_NUM_THREADS=$1
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
