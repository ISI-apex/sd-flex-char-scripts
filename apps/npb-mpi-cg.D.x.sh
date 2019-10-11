#!/bin/bash
export APP_NAME="npb-mpi-cg.D.x"
APP_BIN=$(which -a cg.D.x | grep MPI) || echo "cg.D.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
