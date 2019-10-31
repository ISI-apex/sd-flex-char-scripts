#!/bin/bash
export APP_NAME="npb-mpi-lu.D.x"
APP_BIN=$(which -a lu.D.x | grep MPI) || echo "lu.D.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
