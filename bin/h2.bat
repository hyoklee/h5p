rmdir /q /s build
mkdir build
cd build
cmake -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF  -DCMAKE_C_COMPILER="C:\Program Files (x86)\Intel\oneAPI\compiler\latest\windows\bin\icx.exe" -DCMAKE_CXX_COMPILER="C:\Program Files (x86)\Intel\oneAPI\compiler\latest\windows\bin\icx.exe" -DHDF5_ENABLE_PARALLEL:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=ON -DMPIEXEC_EXECUTABLE:FILEPATH="C:\Program Files (x86)\Intel\oneAPI\mpi\2021.9.0\bin\mpiexec.exe" ..
cmake --build . --config Release
ctest -C Release -VV

