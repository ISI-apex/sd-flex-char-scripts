#!/bin/bash
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${THIS_DIR}/mhmxx-common.sh" || exit $?

export APP_NAME="mhmxx-anqdpht"
export MHMXX_DATASET=/dev/shm/7537.7.76903.ACTTGA.anqdpht.fastq
