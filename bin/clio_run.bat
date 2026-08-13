@echo off
REM Launch the CLIO Core runtime on this node (raven) to join the
REM jelly/nene/raven distributed memory pool.
REM
REM Runs from the d:\clio-core-dev build tree (d:\clio-core\build is wiped by a
REM cron job). Sources the same Intel oneAPI + VS toolchain env as the build
REM scripts so the Intel/ZMQ runtime DLLs resolve; ChiMod *_runtime.dll files
REM are auto-discovered from the clio_run binary's own directory.
d:
set SETVARSVC="D:\one\setvars-vcvarsall"
call %SETVARSVC%
set SETVARS="D:\one\setvars.bat"
call %SETVARS%
set PATH=D:\one\compiler\latest\bin;D:\clio-core-dev\build\bin;%PATH%

REM Cluster config (hostfile + port 9413 + swim:false) at ~/.clio/clio.yaml.
set CLIO_SERVER_CONF=C:\Users\hyoklee\.clio\clio.yaml
set CHI_REPO_PATH=D:\clio-core-dev\build\bin
set CTP_LOG_LEVEL=info

cd /d D:\clio-core-dev\build\bin
clio_run.exe start
