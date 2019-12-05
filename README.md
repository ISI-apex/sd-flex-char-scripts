Superdome Flex Characterization Scripts
=======================================

Scripts to automate characterizating benchmark application behavior.

Contents:

* `apps/` - directory containing application launch configurations
* `env-reference.sh` - reference script for setting up the environment to locate apps
* `topology.sh` - utility script for parsing system topology
* `run-app-numactl.sh` - run an application using `numactl` and capture output
* `run-multiapp-numactl.sh` - run multiple instances of an application using `numactl` and capture outputs
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
