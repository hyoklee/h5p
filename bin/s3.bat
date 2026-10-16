set PATH=C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;%PATH%
REM setvars.bat runs each component's env\vars.bat from its own directory; this must be unset for that to work.
set NoDefaultCurrentDirectoryInExePath=
set SETVARS="c:\Program Files (x86)\Intel\oneAPI\setvars.bat"
call %SETVARS%
REM ROS3 links vcpkg aws-c-* DLLs; with VCPKG_APPLOCAL_DEPS=OFF the tests find them on PATH (debug: CMAKE_BUILD_TYPE defaults to Debug)
set PATH=C:\src\vcpkg.microsoft\installed\x64-windows\debug\bin;%PATH%
rmdir /q /s ps3
mkdir ps3
cd ps3
cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=C:/src/vcpkg.microsoft/scripts/buildsystems/vcpkg.cmake -DCMAKE_C_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/icpx.exe" -DBUILD_SHARED_LIBS:BOOL=OFF  -DHDF5_BUILD_FORTRAN:BOOL=OFF  -DHDF5_ENABLE_PARALLEL:BOOL=OFF  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -DHDF5_ENABLE_ROS3_VFD:BOOL=ON -DVCPKG_APPLOCAL_DEPS:BOOL=OFF -DMPIEXEC_EXECUTABLE:FILEPATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/include" -DCTEST_DROP_SITE_INIT=my.cdash.org -DSITE=win-11 -DBUILDNAME="hk/ninja/icx-2026.1.1/sh-/s3" ..
REM ctest -D Continuous -C Release
ctest -D Experimental
cd ..
