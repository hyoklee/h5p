d:
set VS2022INSTALLDIR=D:\VS\
set SETVARSVC="D:\one\setvars-vcvarsall"
call %SETVARSVC%
set INCLUDE=D:\VS\VC\Tools\MSVC\14.44.35207\include;%INCLUDE%
set LIB=D:\one\compiler\latest\lib;D:\vs\vc\Tools\MSVC\14.44.35207\lib\onecore\x64;%LIB%
set LIBPATH=D:\one\compiler\latest\lib;D:\vs\vc\Tools\MSVC\14.44.35207\lib\onecore\x64;%LIBPATH%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
set PATH=D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;D:\VS\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64;D:\one\compiler\latest\bin;D:\vcpkg\installed\x64-windows\bin;%PATH%
rmdir /q /s ros3
mkdir ros3
cd ros3
D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake -G Ninja -DBUILDNAME="hk/ninja/icx-2025.3/sz/zl/f/p/s3" -DCMAKE_C_COMPILER="D:/one/compiler/latest/bin/icx.exe" -DCMAKE_CXX_COMPILER="D:/one/compiler/latest/bin/icpx.exe" -DCMAKE_TOOLCHAIN_FILE="D:/vcpkg/scripts/buildsystems/vcpkg.cmake" -DMPIEXEC_EXECUTABLE:FILEPATH="D:/one/mpi/latest/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="D:/one/mpi/latest/include" -DVCPKG_TARGET_TRIPLET=x64-windows -DVCPKG_APPLOCAL_DEPS:BOOL=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DHDF5_BUILD_FORTRAN:BOOL=ON -DHDF5_ENABLE_PARALLEL:BOOL=ON -DHDF5_ENABLE_ROS3_VFD:BOOL=ON -DHDF5_ENABLE_ROS3_VFD_DOCKER_PROXY:BOOL=OFF -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=ON -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=ON -DHDF5_ENABLE_SUBFILING_VFD:BOOL=OFF -DCTEST_DROP_SITE_INIT=my.cdash.org -DSITE=win-10 ..
REM D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\ctest -C Release -D Continuous
D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\ctest -C Release -D Experimental
cd ..
