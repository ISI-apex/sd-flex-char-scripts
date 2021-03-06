#!/bin/bash
export APP_NAME="amg-p2-omp"
PX=256
PY=$PX
PZ=$PX
export APP_CMD=(amg -problem 2 -n $PX $PY $PZ -P 1 1 1)

function app_pre() {
    export OMP_NUM_THREADS=$1
    [ -z "$OMP_PROC_BIND" ] && export OMP_PROC_BIND=TRUE || true
}

function app_post() {
    :
}
