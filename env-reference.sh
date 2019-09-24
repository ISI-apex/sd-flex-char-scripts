#!/bin/bash
#
# A default system configuration
#

# Configure LD_LIBRARY_PATH, e.g., for libgfortran
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH

# Configure NAS Parallel Benchmarks binary location
NPB_VER=3.4
NPB_DIR=${HOME}/NPB${NPB_VER}
NPB_OMP_DIR=${NPB_DIR}/NPB${NPB_VER}-OMP
NPB_MPI_DIR=${NPB_DIR}/NPB${NPB_VER}-MPI
export PATH=${NPB_OMP_DIR}/bin:${NPB_MPI_DIR}/bin:$PATH
