#!/bin/bash
export APP_NAME="amg-p2-omp"
PX=256
PY=$PX
PZ=$PX
export APP_CMD=(amg -problem 2 -n $PX $PY $PZ -P 1 1 1)

function app_pre() {
    export OMP_NUM_THREADS=$1
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
