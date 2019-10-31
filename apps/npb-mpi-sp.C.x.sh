#!/bin/bash
export APP_NAME="npb-mpi-sp.C.x"
APP_BIN=$(which -a sp.C.x | grep MPI) || echo "sp.C.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
