#!/bin/bash

function datetime() {
    date --utc +%FT%T.%3NZ
}

function usage() {
    echo "Run an app using numactl"
    echo "Writes to stdout.log and stderr.log"
    echo ""
    echo "Usage: $0 -a SH -t N -C CPUS [-l FILE] [-h]"
    echo "    -a SH: bash script to source with app launch vars"
    echo "    -t N: number of threads for the app"
    echo "    -C CPUS: numactl physcpubind"
    echo "    -l FILE: log file for start/end timing metrics"
    echo "    -h: print help/usage and exit"
}

while getopts "a:t:C:l:h?" o; do
    case "$o" in
        a)
            APP_SCRIPT=$OPTARG
            ;;
        t)
            NTHREADS=$OPTARG
            ;;
        C)
            CPUS=$OPTARG
            ;;
        l)
            LOG=$OPTARG
            ;;
        h)
            usage
            exit
            ;;
        *)
            >&2 usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))
if [ -z "$APP_SCRIPT" ] || [ ! -f "$APP_SCRIPT" ] ||
   [ -z "$CPUS" ] || [ -z "$NTHREADS" ]; then
    >&2 usage
    exit 1
fi
if [ -z "$LOG" ]; then
    LOG=/dev/null
fi

source "$APP_SCRIPT" || exit 1
if [ ${#APP_CMD[@]} -eq 0 ]; then
    >&2 echo "APP not set --> bad app config script?"
    exit 1
fi
if [ -z "$APP_NAME" ]; then
    APP_NAME="<UNKNOWN>"
fi

RUN_CMD=(numactl -l -C "$CPUS" -- "${APP_CMD[@]}")

echo "$APP_NAME: app_pre"
app_pre "$NTHREADS" || exit $?
echo "$APP_NAME: start: $(datetime)" | tee "$LOG"
echo "$APP_NAME: run: ${RUN_CMD[*]}" | tee -a "$LOG"
"${RUN_CMD[@]}" > >(tee stdout.log) 2> >(tee stderr.log)
rc=$?
echo "$APP_NAME: end: $(datetime)" | tee -a "$LOG"
echo "$APP_NAME: app_post"
app_post || exit $?
exit $rc
