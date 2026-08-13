@echo off
set "PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer;%PATH%"
set VSCMD_DEBUG=1
call "D:\VS\VC\Auxiliary\Build\vcvarsall.bat" x64
echo ===FULL_INCLUDE===
echo %INCLUDE%
echo ===VCTOOLS===
echo VCToolsInstallDir=%VCToolsInstallDir%
