#!/bin/bash
export APP_NAME="npb-mpi-bt.D.x"
APP_BIN=$(which -a bt.D.x | grep MPI) || echo "bt.D.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
