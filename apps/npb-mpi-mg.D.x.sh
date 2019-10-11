#!/bin/bash
export APP_NAME="npb-mpi-mg.D.x"
APP_BIN=$(which -a mg.D.x | grep MPI) || echo "mg.D.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
