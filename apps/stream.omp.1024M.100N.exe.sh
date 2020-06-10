#!/bin/bash
export APP_NAME="stream.omp.1024M.100N.exe"
export APP_CMD=(stream.omp.1024M.100N.exe)

function app_pre() {
    export OMP_NUM_THREADS=$1
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
