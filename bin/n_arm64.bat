set SETVARS="C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
call %SETVARS%
rmdir /q /s n_arm64
mkdir n_arm64
cd n_arm64
cmake -G "Visual Studio 18 2026" -A ARM64 -DBUILD_SHARED_LIBS:BOOL=OFF -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=ON -DCMAKE_C_FLAGS="/fsanitize=address" -DCMAKE_CXX_FLAGS="/fsanitize=address" -DCTEST_DROP_SITE_INIT:STRING="my.cdash.org" -DSITE="poe" -DBUILDNAME="arm/win-11/vs-26.c/-sh/sz/asan" -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=ON -DVCPKG_TARGET_TRIPLET=arm64-windows -DCMAKE_TOOLCHAIN_FILE="C:\vcpkg.ms\scripts\buildsystems\vcpkg.cmake" ..
ctest -D Experimental -j
cd ..
