#!/bin/bash
export APP_NAME="hpgmg-fv-omp"
export APP_CMD=(hpgmg-fv 7 8)

function app_pre() {
    export OMP_NUM_THREADS=$1
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
