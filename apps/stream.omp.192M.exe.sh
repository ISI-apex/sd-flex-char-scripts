#!/bin/bash
export APP_NAME="stream.omp.192M.exe"
export APP_CMD=(stream.omp.192M.exe)

function app_pre() {
    export OMP_NUM_THREADS=$1
}

function app_post() {
    :
}
