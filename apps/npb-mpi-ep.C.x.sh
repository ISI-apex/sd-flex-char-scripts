#!/bin/bash
export APP_NAME="npb-mpi-ep.C.x"
APP_BIN=$(which -a ep.C.x | grep MPI) || echo "ep.C.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
