#!/bin/bash
export APP_NAME="stream.omp.AVX512.16M.exe"
export APP_CMD=(stream.omp.AVX512.16M.exe)

function app_pre() {
    export OMP_NUM_THREADS=$1
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE || true
}

function app_post() {
    :
}
