#!/bin/bash
#
# A default system configuration
#

# Configure PATH for tools, e.g., for OpenMPI installation
export PATH=$PATH

# Configure LD_LIBRARY_PATH for tools, e.g., for libgfortran
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH

# Configure NAS Parallel Benchmarks binary location
NPB_VER=3.4
NPB_DIR=${HOME}/NPB${NPB_VER}
NPB_OMP_DIR=${NPB_DIR}/NPB${NPB_VER}-OMP
NPB_MPI_DIR=${NPB_DIR}/NPB${NPB_VER}-MPI
export PATH=${NPB_OMP_DIR}/bin:${NPB_MPI_DIR}/bin:$PATH

# Configure NAS Parallel Benchmarks Multi-Zone binary location
NPB_MZ_VER=3.4
NPB_MZ_DIR=${HOME}/NPB${NPB_MZ_VER}-MZ
NPB_MZ_MPI_DIR=${NPB_MZ_DIR}/NPB${NPB_MZ_VER}-MZ-MPI
export PATH=${NPB_MZ_MPI_DIR}/bin:$PATH

# Configure STREAM location
STREAM_DIR=${HOME}/stream
export PATH=${STREAM_DIR}:$PATH

AMG_DIR=${HOME}/AMG
export PATH=${AMG_DIR}/test:$PATH

# Configure HPGMG location
HPGMG_DIR=${HOME}/hpgmg
export PATH=${HPGMG_DIR}/build/bin:$PATH
