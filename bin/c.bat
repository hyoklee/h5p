set PATH=C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;%PATH%
set SETVARS="c:\Program Files (x86)\Intel\oneAPI\2025.0\oneapi-vars.bat"
call %SETVARS%
cd c:\Users\JoeLee\source\repos\hdf5.HDFGroup
copy c:\Users\JoeLee\source\repos\hdf5\src\CMakeLists.txt src\
copy c:\Users\JoeLee\source\repos\hdf5\CMakeFilters.cmake .
cd c:\Users\JoeLee\source\repos\hdf5.HDFGroup\build
cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=C:/Users/JoeLee/source/repos/vcpkg.microsoft/scripts/buildsystems/vcpkg.cmake -DCMAKE_C_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/icx.exe" -DBUILD_SHARED_LIBS:BOOL=OFF  -DHDF5_BUILD_FORTRAN:BOOL=ON  -DHDF5_ENABLE_PARALLEL:BOOL=ON  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=ON -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=ON -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -DHDF5_TEST_API=ON -DMPIEXEC_EXECUTABLE:FILEPATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="C:/Program Files (x86)/Intel/oneAPI/mpi/latest/include" -DCTEST_DROP_SITE_INIT:STRING="my.cdash.org"  -DSITE="win-11" -DBUILDNAME="ninja/icx/f/+ae+zl/p" ..
ctest  -D Continuous



