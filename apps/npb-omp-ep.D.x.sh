#!/bin/bash
export APP_NAME="npb-omp-ep.D.x"
export APP_CMD=(ep.D.x)

function app_pre() {
    export OMP_NUM_THREADS=$1
}

function app_post() {
    :
}
