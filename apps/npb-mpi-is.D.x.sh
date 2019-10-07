#!/bin/bash
export APP_NAME="npb-mpi-is.D.x"
APP_BIN=$(which -a is.D.x | grep MPI) || echo "is.D.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
