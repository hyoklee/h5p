set VS2022INSTALLDIR=D:\VS\
set PATH=D:\CMake\bin;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;%PATH%
set LIB=D:\VS\VC\Tools\MSVC\14.41.34120\lib\x64;D:\VS\VC\Tools\MSVC\14.41.34120\lib\x86;%LIB%
set LIBPATH=D:\VS\VC\Tools\MSVC\14.41.34120\lib\x64;D:\VS\VC\Tools\MSVC\14.41.34120\lib\x86;%LIBPATH%
set INCLUDE=D:\VS\VC\Tools\MSVC\14.41.34120\include;%INCLUDE%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
cmake --workflow --preset ci-StdShar-Intel --fresh 
