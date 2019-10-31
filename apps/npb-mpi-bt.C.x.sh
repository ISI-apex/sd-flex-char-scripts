#!/bin/bash
export APP_NAME="npb-mpi-bt.C.x"
APP_BIN=$(which -a bt.C.x | grep MPI) || echo "bt.C.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
