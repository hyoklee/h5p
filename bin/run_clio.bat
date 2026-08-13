@echo off
REM Launch the CLIO Core runtime on this node (raven) to join the
REM jelly/nene/raven distributed memory pool. Uses the same Intel oneAPI +
REM VS toolchain env as the build so the Intel runtime DLLs (libmmd.dll, ...)
REM and ZMQ/msgpack/yaml-cpp DLLs resolve on PATH. ChiMod *_runtime.dll
REM files are auto-discovered from the clio_run binary's own directory.
d:
set SETVARSVC="D:\one\setvars-vcvarsall"
call %SETVARSVC%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
set PATH=D:\one\compiler\latest\bin;D:\clio-core\build\bin;%PATH%

REM Cluster config (hostfile + port 9413) lives at ~/.clio/clio.yaml; point
REM CLIO_SERVER_CONF at it explicitly so there is no ambiguity.
set CLIO_SERVER_CONF=C:\Users\hyoklee\.clio\clio.yaml
REM Also expose build\bin as an explicit ChiMod repo path (belt and braces).
set CHI_REPO_PATH=D:\clio-core\build\bin
set CTP_LOG_LEVEL=info

cd /d D:\clio-core\build\bin
clio_run.exe start
