# h5p

[![linux CMake icc sf](https://github.com/hyoklee/hdf5/actions/workflows/linux-icc-sf.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-icc-sf.yml) [![linux CMake icx sf](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-sf.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-sf.yml) [![linux autotools icx sf debug](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-auto-sf-debug.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-auto-sf-debug.yml)  [![linux CMake nvhpc sf](https://github.com/hyoklee/hdf5/actions/workflows/linux-nvhpc-sf.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-nvhpc-sf.yml)  [![linux autotools nvhpc sf](https://github.com/hyoklee/hdf5/actions/workflows/linux-nvhpc-auto-sf.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-nvhpc-auto-sf.yml)


[![mac-13 CMake clang15 debug gfortran mpich sf ](https://github.com/hyoklee/hdf5/actions/workflows/mac-clang15-cmake.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/mac-clang15-cmake.yml)
[![mac-13 CMake Xcode clang15 debug mpich sf ](https://github.com/hyoklee/hdf5/actions/workflows/mac-clang15-xcode.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/mac-clang15-xcode.yml)
[![mac-13 CMake clang17 debug flang java mpich sf ](https://github.com/hyoklee/hdf5/actions/workflows/mac-cmake-flang-mpich.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/mac-cmake-flang-mpich.yml)
## Goals

* Rewrite HDF5 model and format for parallel processing on distributed systems.
* Optimize HDF5 library & tools for parallel processing on distributed systems.
* Improve security and reliability for parallel processing on distributed systems.

## Problems

The existing HDF5 Parallel Library / MPI-IO has some issues.

* Can't build.
* Can't test.
* Can't scale.

## Solutions

* bin/h.bat: test script for Intel OneAPI on Windows
* bin/d.bat: debugging script for Intel OneAPI on Windows
