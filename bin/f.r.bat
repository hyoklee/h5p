d:
REM setvars.bat does "pushd <component>\env & call vars.bat"; that fails when this is set.
set NoDefaultCurrentDirectoryInExePath=
set VS2022INSTALLDIR=D:\VS\
set SETVARSVC="D:\one\setvars-vcvarsall"
call %SETVARSVC%
set INCLUDE=D:\VS\VC\Tools\MSVC\14.44.35207\include;%INCLUDE%
set LIB=D:\one\compiler\2025.3\lib;D:\vs\vc\Tools\MSVC\14.44.35207\lib\onecore\x64;%LIB%
set LIBPATH=D:\one\mpi\latest\lib;D:\one\compiler\2025.3\lib;D:\vs\vc\Tools\MSVC\14.44.35207\lib\onecore\x64;%LIBPATH%
set SETVARS="D:\one\setvars.bat"
if not defined SETVARS_COMPLETED call %SETVARS%
set PATH=D:\one\compiler\2025.3\bin;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;D:\VS\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64;%PATH%
cd /d d:\hdf5.HDFGroup
if exist build rmdir /q /s build
mkdir build
cd build
set CMAKE_EXE=D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe
%CMAKE_EXE% -G Ninja -DCMAKE_TOOLCHAIN_FILE=D:/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_C_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DCMAKE_Fortran_COMPILER="D:/one/compiler/2025.3/bin/ifx.exe" -DBUILD_SHARED_LIBS:BOOL=ON -DBUILD_STATIC_LIBS:BOOL=ON -DHDF5_BUILD_FORTRAN:BOOL=ON  -DHDF5_BUILD_HL_LIB:BOOL=ON  -DHDF5_ENABLE_PARALLEL:BOOL=OFF  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=ON -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=ON -DHDF5_ENABLE_SUBFILING_VFD:BOOL=ON -DHDF5_ENABLE_ALL_WARNINGS=ON -DHDF5_ENABLE_DEBUG_APIS:BOOL=ON -DHDF5_ENABLE_DEV_WARNINGS=ON -D CTEST_DROP_SITE_INIT:STRING="my.cdash.org" -DSITE="raven" -DBUILDNAME="x86_64/win-10/icx-2025.3.0/ifx-2025.3.0/st/h/zl/sz/aw/da/dw/vfd" ..
if errorlevel 1 (
  echo CMake configure failed, skipping ctest.
  cd ..
  exit /b 1
)
D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\ctest.exe -D Continuous
REM ctest  -D Experimental
cd ..
