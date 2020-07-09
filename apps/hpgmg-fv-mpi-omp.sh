#!/bin/bash
export APP_NAME="hpgmg-fv-mpi-omp"
export APP_CMD=(hpgmg-fv 7 8)

function app_pre() {
    export OMP_NUM_THREADS=$2
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE || true
}

function app_post() {
    :
}
