rmdir /q /s intel
mkdir intel
cd intel
REM "C:\Program Files (x86)\Intel\oneAPI\setvars"
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -G Ninja -DBUILDNAME=icx.p.zlib -DCMAKE_C_COMPILER="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/bin/mpicc.bat" -DCMAKE_CXX_COMPILER="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/bin/mpicc.bat" -DHDF5_ENABLE_PARALLEL:BOOL=ON  -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -DMPIEXEC_EXECUTABLE:FILEPATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/include" -DCTEST_DROP_SITE_INIT=my.cdash.org -DSITE=win11 ..
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\ctest" -D Experimental
