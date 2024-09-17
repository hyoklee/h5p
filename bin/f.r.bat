
set VS2022INSTALLDIR=D:\VS\
set SETVARSVC="D:\one\setvars-vcvarsall"
call %SETVARSVC%
set INCLUDE=D:\VS\VC\Tools\MSVC\14.41.34120\include;%INCLUDE%
set LIB=D:\one\compiler\2024.2\lib;D:\vs\vc\Tools\MSVC\14.41.34120\lib\onecore\x64;%LIB%
set LIBPATH=D:\one\mpi\latest\lib;D:\one\compiler\2024.2\lib;D:\vs\vc\Tools\MSVC\14.41.34120\lib\onecore\x64;%LIBPATH%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
rmdir /q /s build
mkdir build
cd build
set PATH=D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;D:\VS\VC\Tools\MSVC\14.41.34120\bin\Hostx64\x64;%PATH%
d:\cmake\bin\cmake -C../config/cmake/cacheinit.cmake -G Ninja -DCMAKE_C_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DCMAKE_Fortran_COMPILER="D:/one/compiler/2024.2/bin/ifx.exe" -DBUILD_SHARED_LIBS:BOOL=ON  -DHDF5_BUILD_FORTRAN:BOOL=ON  -DHDF5_ENABLE_PARALLEL:BOOL=OFF  -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -D CTEST_DROP_SITE_INIT:STRING="my.cdash.org" ..
REM cmake --build . --config Debug
REM ctest -C Debug -VV
cd ..

