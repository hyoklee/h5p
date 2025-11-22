call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
rmdir /q /s n
mkdir n
cd n
cmake -G Ninja -DBUILD_SHARED_LIBS:BOOL=OFF -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF  -DCTEST_DROP_SITE_INIT:STRING="my.cdash.org"  -DSITE="win-11" -DBUILDNAME="n/vs-26.c/-sh" ..
ctest -D Experimental -j
cd ..
