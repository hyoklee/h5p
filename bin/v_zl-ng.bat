set PATH=C:\Program Files\CMake\bin;c:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64;C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;%PATH%
rmdir /q /s v26
mkdir v26
cd v26
cmake -G "Visual Studio 18 2026"  -DCMAKE_TOOLCHAIN_FILE=C:/src/vcpkg.microsoft/scripts/buildsystems/vcpkg.cmake -DBUILD_SHARED_LIBS:BOOL=OFF  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=ON -DHDF5_USE_ZLIB_NG:BOOL=ON -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF  -DCTEST_DROP_SITE_INIT:STRING="my.cdash.org"  -DSITE="win-11" -DBUILDNAME="vs-26.c/-sh/zl-ng" ..
ctest -C Release -D Experimental
REM ctest -D Continuous
cd ..

