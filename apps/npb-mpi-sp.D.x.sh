#!/bin/bash
export APP_NAME="npb-mpi-sp.D.x"
APP_BIN=$(which -a sp.D.x | grep MPI) || echo "sp.D.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
