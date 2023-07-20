rmdir /q /s build
mkdir build
cd build
cmake -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF  -DCMAKE_C_COMPILER="C:\Program Files (x86)\Intel\oneAPI\compiler\latest\windows\bin\icx.exe" -DCMAKE_CXX_COMPILER="C:\Program Files (x86)\Intel\oneAPI\compiler\latest\windows\bin\icx.exe" -DHDF5_ENABLE_PARALLEL:BOOL=ON ..
cmake --build . --config Release
ctest -C Release -VV

