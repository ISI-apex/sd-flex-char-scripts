#!/bin/bash
export APP_NAME="npb-mpi-cg.C.x"
APP_BIN=$(which -a cg.C.x | grep MPI) || echo "cg.C.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
