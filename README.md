# h5p

[![linux CMake icx sf](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-sf.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-sf.yml)

[![linux autotools icx sf debug](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-auto-sf-debug.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/linux-icx-auto-sf-debug.yml)

[![windows ninja icx ifx parallel sf](https://github.com/hyoklee/hdf5/actions/workflows/win-ninja-icx-f-p-sf.yml/badge.svg)](https://github.com/hyoklee/hdf5/actions/workflows/win-ninja-icx-f-p-sf.yml)

## Goals

* Rewrite HDF5 model and format for parallel processing on distributed systems.
* Optimize HDF5 library & tools for parallel processing on distributed systems.
* Improve security and reliability for parallel processing on distributed systems.

## Problems

The existing HDF5 Parallel Library / MPI-IO has some issues.

* Can't build.
* Can't test.
* Can't scale.

## Backgrounds

pnetcdf can't create NetcDF-4/HDF5, only NetCDF-3.
You need to use NetCDF-3 to NetCDF-4 conversion tool.

Parquet is great for distributed system.
You need to use Pandas to convert parquet to HDF5.

## Solutions

Hide MPI/Dask/Spark calls.

```c
#include <h5p.h>

h5p_use("mpi"); /*  replace mpi with dask or spark */
H5P_FILE* fp = h5p_open("s3://test.h5p", "w");
h5p_write(fp, "/g/d", data);
h5p_close(fp);

H5P_FILE* fp = h5p_open("s3://test.h5p", "r");
data = h5p_read(fp, "/g/d");
h5p_close(fp);
```

## Experiments

* bin/h.bat: test script for Intel OneAPI on Windows
* bin/d.bat: debugging script for Intel OneAPI on Windows
