set PATH=C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;%PATH%
REM setvars.bat runs each component's env\vars.bat from its own directory; this must be unset for that to work.
set NoDefaultCurrentDirectoryInExePath=
set SETVARS="c:\Program Files (x86)\Intel\oneAPI\setvars.bat"
call %SETVARS%
rmdir /q /s p
mkdir p
cd p
cmake -G Ninja -DCMAKE_C_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/icpx.exe" -DBUILD_SHARED_LIBS:BOOL=OFF  -DHDF5_BUILD_FORTRAN:BOOL=ON  -DHDF5_ENABLE_PARALLEL:BOOL=ON  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -DMPIEXEC_EXECUTABLE:FILEPATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/include" -DCTEST_DROP_SITE_INIT=my.cdash.org -DSITE=win-11 -DBUILDNAME="ninja/icx/f/p" ..
ctest -D Continuous -C Release
cd ..
