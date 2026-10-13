d:
set VS2022INSTALLDIR=D:\VS\
set SETVARSVC="D:\one\setvars-vcvarsall"
call %SETVARSVC%
set INCLUDE=D:\VS\VC\Tools\MSVC\14.44.35207\include;%INCLUDE%
set LIB=D:\one\compiler\2025.2\lib;D:\vs\vc\Tools\MSVC\14.44.35207\lib\onecore\x64;%LIB%
set LIBPATH=D:\one\mpi\latest\lib;D:\one\compiler\2025.3\lib;D:\vs\vc\Tools\MSVC\14.44.35207\lib\onecore\x64;%LIBPATH%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
set PATH=D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;D:\VS\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64;%PATH%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
rmdir /q /s intel
mkdir intel
cd intel
D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake -G Ninja -DBUILDNAME="hk/ninja/icx/p" -DCMAKE_C_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="D:/one/compiler/latest/bin/icpx.exe" -DHDF5_BUILD_FORTRAN:BOOL=OFF  -DHDF5_ENABLE_PARALLEL:BOOL=ON  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -DMPIEXEC_EXECUTABLE:FILEPATH="D:/one/mpi/latest/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="D:/one/mpi/latest/include" -DCTEST_DROP_SITE_INIT=my.cdash.org -DSITE=win10 ..
D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\ctest -C Release -D Continuous -E ".*t_pflush.*"
cd ..
