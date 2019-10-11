#!/bin/bash
export APP_NAME="npb-mpi-mg.C.x"
APP_BIN=$(which -a mg.C.x | grep MPI) || echo "mg.C.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
