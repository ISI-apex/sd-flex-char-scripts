#!/bin/bash
export APP_NAME="npb-mpi-ep.D.x"
APP_BIN=$(which -a ep.D.x | grep MPI) || echo "ep.D.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
