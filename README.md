Superdome Flex Characterization Scripts
=======================================

Scripts to automate characterizing benchmark application behavior.

Contents:

* `apps/` - directory containing application launch configurations
* `interceptors/` - directory containing interceptor configurations
* `env-reference.sh` - reference script for setting up the environment to locate apps
* `topology.sh` - utility script for parsing system topology
* `run-app-numactl.sh` - run an application using `numactl` and capture output
* `run-multiapp-numactl.sh` - run (potentially) multiple instances of an application using `numactl` and capture outputs
* `characterize-sockets-multiapp-numactl.sh` - run multiapp `numactl` applications for different socket counts
* `run-app-openmpi.sh` - run an application using OpenMPI and capture output
* `run-app-openmpi-omp.sh` - thin wrapper around `run-app-openmpi.sh` to map ranks by socket (OpenMP can be used within a socket)
* `characterize-sockets-app-openmpi.sh` - run MPI applications by mapping to different socket counts


Prerequisites
-------------

* numactl
* util-linux
* OpenMPI 4.x - https://www.open-mpi.org/


Applications
------------

* [NAS Parallel Benchmarks](https://www.nas.nasa.gov/publications/npb.html) version 3.4
* [STREAM](http://www.cs.virginia.edu/stream/) version 5.10
* [AMG](https://github.com/LLNL/AMG) version 1.2
* [HPGMG](https://bitbucket.org/hpgmg/hpgmg) version 0.4
* [RSBench](https://github.com/ANL-CESAR/RSBench) version 12
* [XSBench](https://github.com/ANL-CESAR/XSBench) version 19

Applications have at least one script in the `apps` directory which the top-level scripts require to run the application.
At a minimum, an app script requires specifying a user-friendly application name (`APP_NAME=foo`) and the application execution command (`APP_CMD=(foo [params]...)`).

The app scripts may also need to perform additional setup and/or cleanup of the environment.
The setup (`app_pre()`) may include changing the execution command or setting environment variables to configure the application with the correct scaling parameters (e.g., thread counts and/or MPI ranks).
The cleanup (`app_post()`) may include rolling back changes that persist after the application execution completes (e.g., deleting temporary or output files).


Examples: Threading
-------------------

Running a (usually) threaded application is the most basic task.
Threaded applications are executed using `numactl` to control CPU and memory policies.
The script `run-app-numactl.sh` is not topology-aware, so the user is responsible for specifying an appropriate CPU set and memory policy.
For example, to run `ep.D.x` (from the NAS benchmarks) with local memory allocations and 8 threads on logical (not necessarily physical) CPUs 0 through 7:

    ./run-app-numactl.sh -a apps/npb-omp-ep.D.x.sh -t 8 -- -l -C 0-7

The app script `apps/npb-omp-ep.D.x.sh` defines how to run `ep.D.x` including configuring the threading, which in this case sets `OMP_NUM_THREADS` since the application uses OpenMP as its scaling model.

The script `run-multiapp-numactl.sh` wraps `run-app-numactl.sh` and provides some topology awareness.
For example, to run the same `ep.D.x` execution as above (assuming the system has at least 8 CPUs per socket):

    ./run-multiapp-numactl.sh -a apps/npb-omp-ep.D.x.sh -t 8 -c 8 -m local

Or to scale the 8 threads across 2 sockets, using 4 CPUs on each socket:

    ./run-multiapp-numactl.sh -a apps/npb-omp-ep.D.x.sh -t 8 -s 2 -c 4 -m local

As the script name suggests, it's possible to run multiple copies of the application in parallel---a form of weak scaling.
This is more complex and will not be documented here at this time.
See the script internals for additional information.

Log files are stored in directories of the form `cpus_CPUS` where `CPUS` is the CPU set for each execution.

As its name implies, the script `characterize-sockets-multiapp-numactl.sh` wraps `run-multiapp-numactl.sh` and runs an application with different socket counts (and is thus topology-aware).
The total number of threads in each execution is equal to the total number of available CPUs for the requested socket count.
Suggested options include `-p` (using only physical CPUs, no HyperThreads) and `-w` (perform a warmup execution by running in all sockets first before starting the characterization).
The `-m` option supports running multiple application instances (i.e., weak scaling instead of strong scaling).
For example, the following would characterize all socket counts using physical cores and a warmup execution:

    ./characterize-sockets-multiapp-numactl.sh -a apps/npb-omp-ep.D.x.sh -p -w -- -m local

To instead specify the socket counts yourself, add a `-s` parameter for each desired socket count.
For example, to characterize socket counts 1 and 4:

    ./characterize-sockets-multiapp-numactl.sh -a apps/npb-omp-ep.D.x.sh -p -w -s 1 -s 4 -- -m local

Log files are stored in directories of the form `sockets_N` where `N` is the socket count.


Examples: MPI
-------------

Running an application with OpenMPI is also straightforward.
By default, MPI ranks are mapped by physical core and also bound to cores.
The script `run-app-openmpi.sh` is not topology-aware on its own, only via OpenMPI's behavior.
Following from the `numactl` example, to run `ep.D.x` with 8 ranks and binding to physical CPUs 0-7:

    ./run-app-openmpi.sh -a apps/npb-mpi-ep.D.x.sh -n 8

Log files are stored in directories created by OpenMPI of the form `1/rank.N/std{out,err}` for each rank `N`.

As its name implies, the script `characterize-sockets-app-openmpi.sh` wraps `run-app-openmpi.sh` and runs an application with different socket counts (and is thus topology-aware).
The total number of MPI ranks in each execution is equal to the total number of available CPUs for the requested socket count.
The same `-p`, `-w`, and `-s` parameters and behavior apply as with `characterize-sockets-multiapp-numactl.sh`.
For example, to characterize socket counts 1 and 4:

    ./characterize-sockets-app-openmpi.sh -a apps/npb-mpi-ep.D.x.sh -p -w -s 1 -s 4

Log files are stored in directories of the form `sockets_N` where `N` is the socket count.


Examples: MPI + Threading
-------------------------

The script `run-app-openmpi.sh` also supports threading within ranks (e.g., using OpenMP).
For example, to run `bt.D.x` (from the NAS Multi-Zone benchmarks) with 2 MPI ranks and 4 threads each:

    ./run-app-openmpi.sh -a apps/npb-mz-mpi-bt.D.x.sh -n 2 -t 4

The above command still maps ranks by physical cores though.
To instead place each rank on its own socket:

    ./run-app-openmpi.sh -a apps/npb-mz-mpi-bt.D.x.sh -n 2 -t 4 -m socket

Characterize MPI + threading for different socket counts using the script `characterize-sockets-app-openmpi.sh` with the `-t` option.
The total number of MPI ranks in each execution is equal to the requested socket count, and the total number of threads for each MPI rank is equal to the available CPUs per socket.
For example, to characterize socket counts 1 and 4:

    ./characterize-sockets-app-openmpi.sh -a apps/npb-mz-mpi-bt.D.x.sh -t -p -w -s 1 -s 4

Log files are stored in directories as described previously for MPI.
