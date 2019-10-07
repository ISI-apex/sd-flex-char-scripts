#!/bin/bash
export APP_NAME="npb-mpi-ft.C.x"
APP_BIN=$(which -a ft.C.x | grep MPI) || echo "ft.C.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
