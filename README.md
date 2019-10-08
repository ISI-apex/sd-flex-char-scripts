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
