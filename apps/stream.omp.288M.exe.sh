#!/bin/bash
export APP_NAME="stream.omp.288M.exe"
export APP_CMD=(stream.omp.288M.exe)

function app_pre() {
    export OMP_NUM_THREADS=$1
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}