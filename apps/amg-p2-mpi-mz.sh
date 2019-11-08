#!/bin/bash
export APP_NAME="amg-p2-mpi-mz"
PX=256
PY=$PX
PZ=$PX
export APP_CMD=(amg -problem 2 -n $PX $PY $PZ)

function app_pre() {
    APP_CMD+=(-P 1 "$1" 1)
    export OMP_NUM_THREADS=$2
    export OMP_PROC_BIND=TRUE
}

function app_post() {
    :
}
