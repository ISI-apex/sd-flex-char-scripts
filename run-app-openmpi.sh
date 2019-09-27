#!/bin/bash

function datetime() {
    date --utc +%FT%T.%3NZ
}

function usage() {
    local rc=${1:-0}
    echo "Run an app using OpenMPI"
    echo "Writes to '1/rank.{0..\$N-1}/std{out,err}'"
    echo ""
    echo "Usage: $0 -a SH -n N [-t N] [-m FOO] [-b FOO] [-l FILE] [-h] -- [MPI_OPTION]..."
    echo "    -a SH: bash script to source with app launch vars"
    echo "    -n N: number of MPI processes; see OpenMPI -np"
    echo "    -t N: number of threads for each process; see OpenMPI PE=n (default=1)"
    echo "    -m FOO: map processes by FOO; see OpenMPI --map-by (default=core)"
    echo "    -b FOO: bind processes to FOO; see OpenMPI --bind-to (default=core)"
    echo "    -l FILE: log file for start/end timing metrics"
    echo "    -h: print help/usage and exit"
    echo "    MPI_OPTION: additional parameters passed to mpirun"
    exit "$rc"
}

NTHREADS=1
MAP_BY=core
BIND_TO=core
while getopts "a:n:t:m:b:l:h?" o; do
    case "$o" in
        a)
            APP_SCRIPT=$OPTARG
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
        l)
            LOG=$OPTARG
            ;;
        h)
            usage
            ;;
        *)
            echo "Unknown option"
            usage 1
            ;;
    esac
done
shift $((OPTIND-1))
if [ -z "$APP_SCRIPT" ] || [ ! -f "$APP_SCRIPT" ] || [ -z "$NPROCS" ]; then
    usage 1
fi
if [ -z "$LOG" ]; then
    LOG=/dev/null
fi

source "$APP_SCRIPT" || exit 1
if [ ${#APP_CMD[@]} -eq 0 ]; then
    echo "APP not set --> bad app config script?"
    exit 1
fi
if [ -z "$APP_NAME" ]; then
    APP_NAME="<UNKNOWN>"
fi

RUN_CMD=(mpirun -np "$NPROCS"
                --map-by "${MAP_BY}":PE="$NTHREADS"
                --bind-to "${BIND_TO}"
                --output-filename .
                "$@"
                -- "${APP_CMD[@]}")

echo "$APP_NAME: app_pre"
app_pre "$NPROCS" "$NTHREADS" || exit $?
echo "$APP_NAME: start: $(datetime)" | tee "$LOG"
echo "$APP_NAME: run: ${RUN_CMD[*]}" | tee -a "$LOG"
"${RUN_CMD[@]}"
rc=$?
echo "$APP_NAME: end: $(datetime)" | tee -a "$LOG"
echo "$APP_NAME: app_post"
app_post || exit $?
exit $rc
