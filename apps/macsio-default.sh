#!/bin/bash
export APP_NAME="MACSio-default"
export APP_CMD=(macsio --interface miftmpl --parallel_file_mode MIF 4 --part_size 80000)

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${THIS_DIR}/macsio_common.sh" || exit $?
