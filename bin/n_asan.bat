set SETVARS="C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
call %SETVARS%
rmdir /q /s n
mkdir n
cd n
cmake -G Ninja -DBUILD_SHARED_LIBS:BOOL=OFF -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=OFF  -DCMAKE_C_FLAGS="/fsanitize=address" -DCMAKE_CXX_FLAGS="/fsanitize=address" -DCTEST_DROP_SITE_INIT:STRING="my.cdash.org" -DSITE="poe" -DBUILDNAME="x86_64/win-11/vs-26.c/-sh/sz/asan" -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=ON -DCMAKE_TOOLCHAIN_FILE="C:\vcpkg.ms\scripts\buildsystems\vcpkg.cmake" ..
ctest -D Experimental -j
cd ..
