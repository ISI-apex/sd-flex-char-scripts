#!/bin/bash
export APP_NAME="npb-mpi-lu.C.x"
APP_BIN=$(which -a lu.C.x | grep MPI) || echo "lu.C.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
