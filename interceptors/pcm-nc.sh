#!/bin/bash
THIS_DIR=""
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/pcm.sh" || return $?

export INTERCEPTOR_NAME=pcm-nc
PCM_CMD+=(-nc)
