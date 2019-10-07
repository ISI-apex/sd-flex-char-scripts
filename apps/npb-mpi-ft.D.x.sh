#!/bin/bash
export APP_NAME="npb-mpi-ft.D.x"
APP_BIN=$(which -a ft.D.x | grep MPI) || echo "ft.D.x"
export APP_CMD=("$APP_BIN")

function app_pre() {
    :
}

function app_post() {
    :
}
