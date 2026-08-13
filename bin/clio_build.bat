@echo off
REM Incremental rebuild of the CLIO Core runtime + ChiMod DLLs needed to run a
REM node, in the d:\clio-core-dev build tree. Ninja/CMake reconfigure
REM automatically when the source (e.g. after a git pull / branch switch)
REM changed. Same Intel oneAPI icx + VS toolchain env as d:\h5p\bin\clio_d.r.bat.
d:
set VS2022INSTALLDIR=D:\VS\
set SETVARSVC="D:\one\setvars-vcvarsall"
call %SETVARSVC%
set INCLUDE=D:\VS\VC\Tools\MSVC\14.44.35207\include;%INCLUDE%
set LIB=D:\one\compiler\latest\lib\clang\21\lib\windows;D:\one\compiler\latest\opt\compiler\lib;D:\one\compiler\latest\lib;D:\vs\vc\Tools\MSVC\14.44.35207\lib\onecore\x64;%LIB%
set LIBPATH=D:\one\mpi\latest\lib;D:\one\compiler\latest\lib;D:\vs\vc\Tools\MSVC\14.44.35207\lib\onecore\x64;%LIBPATH%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
set PATH=D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\;D:\VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;D:\VS\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64;%PATH%
d:\cmake\bin\cmake --build d:\clio-core-dev\build --target clio_run clio_bdev_runtime clio_bdev_client clio_cte_core_runtime clio_cte_core_client clio_cae_core_runtime clio_cae_core_client
exit /b %ERRORLEVEL%
