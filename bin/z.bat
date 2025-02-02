set PATH=C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;%PATH%
set SETVARS="c:\Program Files (x86)\Intel\oneAPI\2024.2\oneapi-vars.bat"
call %SETVARS%
copy CMakeFilters.cmake CMakeFilters.cmake.bak
copy CMakeFilters.cmake_  CMakeFilters.cmake
rmdir /q /s build_z
mkdir build_z
cd build_z
cmake -G Ninja -DCMAKE_C_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/icx.exe" -DBUILD_SHARED_LIBS:BOOL=OFF  -DHDF5_BUILD_FORTRAN:BOOL=ON  -DHDF5_ENABLE_PARALLEL:BOOL=ON  -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=ON -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -DMPIEXEC_EXECUTABLE:FILEPATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/include" -D CTEST_DROP_SITE_INIT:STRING="my.cdash.org"  -DSITE=win11 -DBUILDNAME="ninja/icx/f/sz+zl/p" -DCMAKE_TOOLCHAIN_FILE=C:/Users/JoeLee/source/repos/vcpkg/scripts/buildsystems/vcpkg.cmake -DLIBAEC_PACKAGE_NAME:STRING=szip ..
ctest  -D Experimental
cd ..
copy CMakeFilters.cmake.bak CMakeFilters.cmake
