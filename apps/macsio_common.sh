#!/bin/bash

function app_pre() {
    # don't want to capture old JSON file list
    rm -f macsio_json_*
}

function app_post() {
    local logdir=macsio_logs
    local filelist=macsio_jsons.log
    # capture JSON file list but cleanup the data
    # macsio_json_[file]_[dump].json
    # macsio_json_root_[dump].json
    ls -l macsio_json_* > "$filelist" || return $?
    rm -f macsio_json_*
    mkdir "$logdir" || return $?
    mv macsio-log.log macsio-timings.log "$filelist" "$logdir"
}
