#!/bin/bash
export APP_NAME="npb-mpi-ep.E.x"
APP_BIN=$(which -a ep.E.x | grep MPI) || echo "ep.E.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
