#!/bin/bash
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${THIS_DIR}/mhmxx-common.sh" || exit $?

export APP_NAME="mhmxx-synth64d"
export MHMXX_DATASET=/dev/shm/synth64d.fastq
