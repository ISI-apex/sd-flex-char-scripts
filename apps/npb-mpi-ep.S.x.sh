#!/bin/bash
export APP_NAME="npb-mpi-ep.S.x"
APP_BIN=$(which -a ep.S.x | grep MPI) || echo "ep.S.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
