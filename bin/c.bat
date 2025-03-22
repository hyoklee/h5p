set PATH=C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;%PATH%
set SETVARS="c:\Program Files (x86)\Intel\oneAPI\2025.0\oneapi-vars.bat"
call %SETVARS%
cd c:\Users\JoeLee\source\repos\hdf5.HDFGroup
copy c:\Users\JoeLee\source\repos\hdf5\src\CMakeLists.txt src\
copy c:\Users\JoeLee\source\repos\hdf5\CMakeFilters.cmake .
cd c:\Users\JoeLee\source\repos\hdf5.HDFGroup\build
ctest  -D Continuous



