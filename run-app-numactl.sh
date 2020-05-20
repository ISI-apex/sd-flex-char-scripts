#!/bin/bash

function datetime() {
    date --utc +%FT%T.%3NZ
}

function trap_interceptor() {
    echo "$INTERCEPTOR_NAME: TRAP: interceptor_stop"
    interceptor_stop
}

function usage() {
    echo "Run an app using numactl"
    echo "User must pass any CPU and memory binding args through to numactl"
    echo "Writes to stdout.log and stderr.log"
    echo ""
    echo "Usage: $0 -a SH -t N [-i SH] [-l FILE] [-h] -- [numactl args]"
    echo "    -a SH: bash script to source with app launch vars"
    echo "    -t N: number of threads for the app"
    echo "    -i SH: bash script to source with interceptor configurations"
    echo "    -l FILE: log file for start/end timing metrics"
    echo "    -h: print help/usage and exit"
}

while getopts "a:t:i:l:h?" o; do
    case "$o" in
        a)
            APP_SCRIPT=$OPTARG
            ;;
        t)
            NTHREADS=$OPTARG
            ;;
        i)
            INTERCEPTOR_SCRIPT=$OPTARG
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
if [ -z "$APP_SCRIPT" ] || [ ! -f "$APP_SCRIPT" ] || [ -z "$NTHREADS" ]; then
    >&2 usage
    exit 1
fi
if [ -z "$LOG" ]; then
    LOG=/dev/null
fi

source "$APP_SCRIPT" || exit $?
if [ -z "$APP_NAME" ]; then
    APP_NAME="<UNKNOWN>"
fi

if [ -n "$INTERCEPTOR_SCRIPT" ]; then
    source "$INTERCEPTOR_SCRIPT" || exit $?
    if [ -z "$INTERCEPTOR_NAME" ]; then
        INTERCEPTOR_NAME="<UNKNOWN>"
    fi
fi

echo "$APP_NAME: app_pre"
app_pre "$NTHREADS" || exit $?
if [ -n "$INTERCEPTOR_SCRIPT" ]; then
    trap trap_interceptor EXIT
    echo "$INTERCEPTOR_NAME: interceptor_start"
    interceptor_start || exit $?
fi
RUN_CMD=(numactl "$@" -- "${APP_CMD[@]}")
echo "$APP_NAME: start: $(datetime)" | tee "$LOG"
echo "$APP_NAME: run: ${RUN_CMD[*]}" | tee -a "$LOG"
"${RUN_CMD[@]}" > >(tee stdout.log) 2> >(tee stderr.log)
rc=$?
echo "$APP_NAME: end: $(datetime)" | tee -a "$LOG"
if [ -n "$INTERCEPTOR_SCRIPT" ]; then
    echo "$INTERCEPTOR_NAME: interceptor_stop"
    interceptor_stop || rc=$?
    trap - EXIT
fi
echo "$APP_NAME: app_post"
app_post || exit $?
exit $rc
