#!/bin/bash
export INTERCEPTOR_NAME=pcm-numa

PCM_BIN=pcm-numa.x
PCM_PATH=$(which "${PCM_BIN}") || return $? # PATH not preserved by sudo, so get full path
PCM_INTERVAL_SEC=1.0
PCM_CSV=pcm-numa.csv
PCM_CMD=("${PCM_PATH}" -csv="${PCM_CSV}" "${PCM_INTERVAL_SEC}")

PCM_PID=

function interceptor_start() {
    echo "${INTERCEPTOR_NAME}: ${PCM_CMD[*]}"
    sudo -n "${PCM_CMD[@]}" &
    PCM_PID=$!
    # TODO: This is dirty and probably unreliable
    sleep 1 # let PCM initialize, and if it fails, hopefully it fails fast
    ps -p $PCM_PID > /dev/null # returns 0 if PID is still running
}

function interceptor_stop() {
    echo "${INTERCEPTOR_NAME}: kill $PCM_PID"
    # sudo -n kill $PCM_PID || return $? # TODO: kill isn't working (silent failure)?
    sudo -n pkill -u root "${PCM_BIN}" || return $?
    # wait for PCM to clean up and finish writing output file
    sudo -n wait $PCM_PID 2>/dev/null
    local rc=$?
    # rc=127 --> non-existent process or job (it's already exited)
    if [ $rc -eq 127 ] || [ $rc -eq 0 ]; then
        rc=0
    fi
    return $rc
}
