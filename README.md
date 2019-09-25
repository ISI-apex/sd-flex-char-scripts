Superdome Flex Characterization Scripts
=======================================

Scripts to automate characterizating benchmark application behavior.

Contents:

* `apps/` - directory containing application launch configurations
* `env-reference.sh` - reference script for setting up the environment to locate apps
* `topology.sh` - utility script for parsing system topology
* `run-app-numactl.sh` - run an application using `numactl` and capture output
* `run-multiapp-numactl.sh` - run multiple instances of an application using `numactl` and capture outputs


Prerequisites
-------------

* numactl
* util-linux


Applications
------------

* [NAS Parallel Benchmarks](https://www.nas.nasa.gov/publications/npb.html) version 3.4
