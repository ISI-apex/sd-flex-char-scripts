#!/bin/bash
export APP_NAME="npb-mpi-is.C.x"
APP_BIN=$(which -a is.C.x | grep MPI) || echo "is.C.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
