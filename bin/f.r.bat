d:
set VS2022INSTALLDIR=D:\VS\
set SETVARSVC="D:\one\setvars-vcvarsall"
call %SETVARSVC%
set INCLUDE=D:\VS\VC\Tools\MSVC\14.43.34808\include;%INCLUDE%
set LIB=D:\one\compiler\2025.2\lib;D:\vs\vc\Tools\MSVC\14.43.34808\lib\onecore\x64;%LIB%
set LIBPATH=D:\one\mpi\latest\lib;D:\one\compiler\2025.2\lib;D:\vs\vc\Tools\MSVC\14.43.34808\lib\onecore\x64;%LIBPATH%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
set PATH=D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;D:\VS\VC\Tools\MSVC\14.43.34808\bin\Hostx64\x64;%PATH%
cd d:\hdf5.HDFGroup
REM rmdir /q /s build
REM mkdir build
cd build
d:\cmake\bin\cmake -G Ninja -DCMAKE_C_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DCMAKE_Fortran_COMPILER="D:/one/compiler/2025.2/bin/ifx.exe" -DBUILD_SHARED_LIBS:BOOL=ON -DBUILD_STATIC_LIBS:BOOL=ON -DHDF5_BUILD_FORTRAN:BOOL=ON  -DHDF5_BUILD_HL_LIB:BOOL=ON  -DHDF5_ENABLE_PARALLEL:BOOL=OFF  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -D CTEST_DROP_SITE_INIT:STRING="my.cdash.org" -DSITE=win-10 -DBUILDNAME="ninja/icx/+st/f/h/-sz-zl/-p" ..
ctest  -D Continuous
REM ctest  -D Experimental
cd ..
