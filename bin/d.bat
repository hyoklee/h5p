rmdir /q /s build
mkdir build
cd build
REM "c:\Program Files (x86)\Intel\oneAPI\setvars.bat"
cmake -G Ninja -DCMAKE_C_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/windows/bin/icx.exe" -DCMAKE_CXX_COMPILER="C:/Program Files (x86)/Intel/oneAPI/compiler/latest/windows/bin/icx.exe" -DHDF5_ENABLE_PARALLEL:BOOL=ON  -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_ENABLE_SUBFILING_VFD:BOOL=ON -DMPIEXEC_EXECUTABLE:FILEPATH="C:/Program Files (x86)/Intel/oneAPI/mpi/2021.9.0/bin/mpiexec.exe" -DMPI_C_HEADER_DIR:PATH="C:/Program Files (x86)/Intel/oneAPI/mpi/2021.9.0/include" -DCMAKE_MPI_CC="C:/Program Files (x86)/Intel/oneAPI/mpi/2021.9.0/bin/mpicc.bat"  ..
cmake --build . --config Debug
ctest -C Debug -VV

