#!/bin/bash

function datetime() {
    date --utc +%FT%T.%3NZ
}

function usage() {
    echo "Run an app using OpenMPI"
    echo "Writes to '1/rank.{0..\$N-1}/std{out,err}'"
    echo ""
    echo "Usage: $0 -a SH [-i SH] [-n N] [-t N] [-m FOO] [-b FOO] [-r FILE] [-l FILE] [-h] -- [MPI_OPTION]..."
    echo "    -a SH: bash script to source with app launch vars"
    echo "    -i SH: bash script to source with interceptor configurations"
    echo "    -n N: number of MPI processes; see OpenMPI -np (default=1)"
    echo "    -t N: number of threads for each process; see OpenMPI PE=n (default=1)"
    echo "    -m FOO: map processes by FOO; see OpenMPI --map-by (default=core)"
    echo "    -b FOO: bind processes to FOO; see OpenMPI --bind-to (default=core)"
    echo "    -r FILE: Use a rank file; see OpenMPI -rf (default=<none>)"
    echo "             If set, takes precedence over -n, -t, -m, -b options"
    echo "    -l FILE: log file for start/end timing metrics"
    echo "    -h: print help/usage and exit"
    echo "    MPI_OPTION: additional parameters passed to mpirun"
}

NPROCS=1
NTHREADS=1
MAP_BY=core
BIND_TO=core
RANK_FILE=
while getopts "a:i:n:t:m:b:r:l:h?" o; do
    case "$o" in
        a)
            APP_SCRIPT=$OPTARG
            ;;
        i)
            INTERCEPTOR_SCRIPT=$OPTARG
            ;;
        n)
            NPROCS=$OPTARG
            ;;
        t)
            NTHREADS=$OPTARG
            ;;
        m)
            MAP_BY=$OPTARG
            ;;
        b)
            BIND_TO=$OPTARG
            ;;
        r)
            RANK_FILE=$OPTARG
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
if [ -z "$APP_SCRIPT" ] || [ ! -f "$APP_SCRIPT" ]; then
    >&2 usage
    exit 1
fi
if [ -z "$LOG" ]; then
    LOG=/dev/null
fi

source "$APP_SCRIPT" || exit 1
if [ -z "$APP_NAME" ]; then
    APP_NAME="<UNKNOWN>"
fi

if [ -n "$INTERCEPTOR_SCRIPT" ]; then
    source "$INTERCEPTOR_SCRIPT" || exit $?
    if [ -z "$INTERCEPTOR_NAME" ]; then
        INTERCEPTOR_NAME="<UNKNOWN>"
    fi
fi

RUN_CMD=(mpirun)
if [ -n "$RANK_FILE" ]; then
    RUN_CMD+=(-rf "$RANK_FILE")
else
    RUN_CMD+=(-np "$NPROCS"
              --map-by "${MAP_BY}":PE="$NTHREADS"
              --bind-to "${BIND_TO}")
fi
RUN_CMD+=(--report-bindings --output-filename . "$@" --)

echo "$APP_NAME: app_pre"
app_pre "$NPROCS" "$NTHREADS" || exit $?
if [ -n "$INTERCEPTOR_SCRIPT" ]; then
    trap trap_interceptor EXIT
    echo "$INTERCEPTOR_NAME: interceptor_start"
    interceptor_start || exit $?
fi
RUN_CMD+=("${APP_CMD[@]}")
echo "$APP_NAME: start: $(datetime)" | tee "$LOG"
echo "$APP_NAME: run: ${RUN_CMD[*]}" | tee -a "$LOG"
"${RUN_CMD[@]}"
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
