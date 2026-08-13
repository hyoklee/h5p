@echo off
REM Build clio_run.exe using the toolchain environment from
REM d:\h5p\bin\clio_d.r.bat (Intel oneAPI icx + VS 2022 + vcpkg).
REM Env preamble is copied verbatim from that script so the Intel runtime
REM libs (libircmt.lib in D:\one\compiler\latest\lib) and MSVC onecore libs
REM are on LIB. Scoped to the clio_run target in the existing, already
REM configured d:\clio-core\build instead of a full clean rebuild + ctest.
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
d:\cmake\bin\cmake --build d:\clio-core\build --target clio_run
exit /b %ERRORLEVEL%
