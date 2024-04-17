rmdir /q /s vs17arm64
mkdir vs17arm64
cd vs17arm64
cmake -G "Visual Studio 17 2022" -A ARM -DBUILDNAME:STRING="vs17.arm64.d"  -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -D CTEST_DROP_SITE_INIT:STRING="my.cdash.org" -DSITE:STRING=win11 ..
REM ctest -C Debug -D Experimental
ctest -C Debug -D Continuous
