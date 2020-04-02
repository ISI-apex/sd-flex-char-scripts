#!/bin/bash
export APP_NAME="stream.omp.AVX512.1024M.exe"
export APP_CMD=(stream.omp.AVX512.1024M.exe)

function app_pre() {
    export OMP_NUM_THREADS=$1
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}