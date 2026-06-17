d:
set VS2022INSTALLDIR=D:\VS\
set SETVARSVC="D:\one\setvars-vcvarsall"
call %SETVARSVC%
set INCLUDE=D:\VS\VC\Tools\MSVC\14.44.35207\include;%INCLUDE%
set LIB=D:\one\compiler\latest\lib\clang\21\lib\windows;D:\one\compiler\latest\opt\compiler\lib;D:\one\compiler\latest\lib;D:\vs\vc\Tools\MSVC\14.44.35207\lib\onecore\x64;%LIB%
set LIBPATH=D:\one\mpi\latest\lib;D:\one\compiler\latest\lib;D:\vs\vc\Tools\MSVC\14.44.35207\lib\onecore\x64;%LIBPATH%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
set PATH=D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;D:\VS\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64;%PATH%
cd d:\clio-core
rmdir /q /s build
mkdir build
cd build
d:\cmake\bin\cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=D:/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_C_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DSITE="win-10" -DBUILDNAME="ninja/icx-2025.3.0" -DCMAKE_BUILD_TYPE=Debug -DCLIO_CORE_ENABLE_RUNTIME=ON -DCLIO_CORE_ENABLE_CTE=ON -DCLIO_CORE_ENABLE_CAE=ON -DCLIO_CORE_ENABLE_CEE=OFF -DCLIO_CORE_ENABLE_TESTS=ON -DCLIO_CORE_ENABLE_PYTHON=OFF -DCLIO_CORE_ENABLE_ZMQ=ON -DCLIO_CORE_ENABLE_CEREAL=ON -DCLIO_CORE_ENABLE_CONDA=OFF -DCLIO_CORE_ENABLE_ELF=OFF -DCLIO_CORE_ENABLE_RPATH=OFF -DCLIO_CTE_ENABLE_VFD=OFF -DCLIO_CTE_ENABLE_HDF5_VOL=OFF -DCLIO_CORE_ENABLE_BENCHMARKS=OFF -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCLIO_CTP_LOG_LEVEL=0 ..
ctest  -D Continuous
REM ctest  -D Experimental
cd ..
