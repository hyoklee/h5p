#!/bin/bash

set -e  # Exit on error

# Environment variables
export NPROCS=2
export CC=/opt/nvidia/hpc_sdk/Linux_x86_64/25.9/comm_libs/hpcx/bin/mpicc
export LD_LIBRARY_PATH=/opt/nvidia/hpc_sdk/Linux_x86_64/25.9/cuda/13.0/lib64:/opt/nvidia/hpc_sdk/Linux_x86_64/25.9/compilers/lib
export NVHPCSDK=/opt/nvidia/hpc_sdk
export PATH=/opt/nvidia/hpc_sdk/Linux_x86_64/25.9/comm_libs/hpcx/bin:/opt/nvidia/hpc_sdk/Linux_x86_64/25.9/compilers/bin:$PATH

# Create and enter build directory
echo "Setting up build directory..."
mkdir -p nvhpc
cd nvhpc

# Configure with CMake
echo "Configuring HDF5 with CMake..."
cmake \
  -DBUILDNAME="nvhpc-25.9" \
  -DCMAKE_BUILD_TYPE=Release \
  -DHDF5_BUILD_CPP_LIB:BOOL=OFF \
  -DHDF5_BUILD_FORTRAN:BOOL=OFF \
  -DHDF5_BUILD_JAVA:BOOL=OFF \
  -DHDF5_ENABLE_PARALLEL:BOOL=ON \
  -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF \
  -DCTEST_DROP_SITE_INIT:STRING="my.cdash.org" \
  -DSITE:STRING="ubu-24/WSL" \
  -DMPIEXEC_MAX_NUMPROCS:STRING=2 \
  ..

# Run tests
echo "Running CTest Experimental..."
ctest -D Experimental

echo "Build and test complete!"
