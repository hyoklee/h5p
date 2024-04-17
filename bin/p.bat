set PATH="C:\Program Files\Microsoft Visual Studio\2022\Preview\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\";%PATH%
rmdir /q /s build
mkdir build
cd build
REM "c:\Program Files (x86)\Intel\oneAPI\setvars.bat"
cmake -G Ninja -DCMAKE_C_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/icpx.exe" -DBUILD_SHARED_LIBS:BOOL=OFF  -DHDF5_BUILD_FORTRAN:BOOL=ON  -DHDF5_ENABLE_PARALLEL:BOOL=ON  -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -DMPIEXEC_EXECUTABLE:FILEPATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/include" -DCTEST_DROP_SITE_INIT=my.cdash.org -DSITE=win11 -DBUILDNAME="ninja/icx/+f/+p" ..
REM cmake --build . --config Debug
REM ctest -C Debug -VV
REM ctest -R H5DUMP-tfloatsattrs -VV
REM del bin\cmp.h5
ctest -D Experimental -C Release
cd ..


