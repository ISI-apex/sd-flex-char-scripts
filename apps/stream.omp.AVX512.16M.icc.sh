#!/bin/bash
export APP_NAME="stream.omp.AVX512.16M.icc"
export APP_CMD=(stream.omp.AVX512.16M.icc)

function app_pre() {
    export OMP_NUM_THREADS=$1
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
