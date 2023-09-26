# h5p

[![linux CMake icc sf](https://github.com/hyoklee/hdf5/actions/workflows/linux-icc-sf.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-icc-sf.yml) [![linux CMake icx sf](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-sf.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-sf.yml) [![linux autotools icx sf debug](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-auto-sf-debug.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-auto-sf-debug.yml)  [![linux CMake nvhpc sf](https://github.com/hyoklee/hdf5/actions/workflows/linux-nvhpc-sf.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-nvhpc-sf.yml)  [![linux autotools nvhpc sf](https://github.com/hyoklee/hdf5/actions/workflows/linux-nvhpc-auto-sf.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-nvhpc-auto-sf.yml)

## Goals

* Rewrite HDF5 model and file format specification for parallel processing.
* Optimize HDF5 library & tools for parallel processing.
* Improve security and reliability.

## Problems

The existing HDF5 Parallel Library has some issues.

* Can't build.
* Can't test.
* Can't scale.

## Source

* h.bat: test script for Intel OneAPI on Windows
