set VS2022INSTALLDIR=D:\VS\
D:\VS\VC\Auxiliary\Build\vcvarsall.bat x64
set PATH=D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;%PATH%
set LIB=D:\VS\VC\Tools\MSVC\14.41.34120\lib\x64;D:\VS\VC\Tools\MSVC\14.41.34120\lib\x86;%LIB%
set LIBPATH=D:\VS\VC\Tools\MSVC\14.41.34120\lib\x64;D:\VS\VC\Tools\MSVC\14.41.34120\lib\x86;%LIBPATH%
set INCLUDE=D:\VS\VC\Tools\MSVC\14.41.34120\include;%INCLUDE%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
rmdir /q /s intel
mkdir intel
cd intel
D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake -G Ninja -DBUILDNAME="ninja/icx/+p" -DCMAKE_C_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="D:/one/compiler/latest/bin/icpx.exe" -DCMAKE_Fortran_COMPILER="D:/one/compiler/latest/bin/ifx.exe" -DCMAKE_CXX_COMPILER="D:/one/compiler/latest/bin/icpx.exe"  -DHDF5_BUILD_FORTRAN:BOOL=OFF  -DHDF5_ENABLE_PARALLEL:BOOL=ON  -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -DMPIEXEC_EXECUTABLE:FILEPATH="D:/one/mpi/latest/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="D:/one/mpi/latest/include" -DCTEST_DROP_SITE_INIT=my.cdash.org -DSITE=win10 ..
D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\ctest -C Release -D Continuous -E ".*t_pflush.*"
cd ..
