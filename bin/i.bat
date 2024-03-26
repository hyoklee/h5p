set VS2022INSTALLDIR=D:\VS\
set PATH=D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;%PATH%
rmdir /q /s intel
mkdir intel
cd intel
D:\one\setvars
D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake -G Ninja -DBUILDNAME=icx.p -DCMAKE_C_COMPILER="D:/one/mpi/latest/bin/mpicc.bat" -DCMAKE_CXX_COMPILER="D:/one/mpi/latest/bin/mpicc.bat" -DHDF5_ENABLE_PARALLEL:BOOL=ON  -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -DMPIEXEC_EXECUTABLE:FILEPATH="D:/one/mpi/latest/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="D:/one/mpi/latest/include" -DCTEST_DROP_SITE_INIT=my.cdash.org -DSITE=win10 ..
D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\ctest -D Experimental
