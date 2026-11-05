@echo off
setlocal enabledelayedexpansion

echo ==============================================================================
echo LichtFeld Studio - Windows Release Installer Builder
echo ==============================================================================

:: Find Visual Studio vcvars64.bat
set "VCVARS="
if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
)

if not defined VCVARS (
    echo [ERROR] Could not find Visual Studio 2022 vcvars64.bat
    exit /b 1
)

call "%VCVARS%"
if errorlevel 1 (
    echo [ERROR] Failed to initialize Visual Studio build environment.
    exit /b 1
)

:: Find Inno Setup compiler
set "ISCC_EXE="
where iscc.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "ISCC_EXE=iscc.exe"
) else if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set "ISCC_EXE=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) else if exist "%USERPROFILE%\development\tools\innosetup\ISCC.exe" (
    set "ISCC_EXE=%USERPROFILE%\development\tools\innosetup\ISCC.exe"
)

if not defined ISCC_EXE (
    echo [ERROR] Inno Setup (ISCC.exe) not found! Please install Inno Setup 6.
    exit /b 1
)

set "BUILD_DIR=build-windows-release"
if not exist "%BUILD_DIR%" set "BUILD_DIR=b"

cd /d "%~dp0"

echo [Step 1/3] Building Release binaries...
cmake --build "%BUILD_DIR%" --config Release -j %NUMBER_OF_PROCESSORS%
if errorlevel 1 (
    echo [ERROR] Compilation failed!
    exit /b 1
)

echo [Step 2/3] Installing staged distribution to dist/...
cmake --install "%BUILD_DIR%" --prefix dist
if errorlevel 1 (
    echo [ERROR] Install to dist/ failed!
    exit /b 1
)

echo [Step 3/3] Compiling Inno Setup Release Installer (.exe)...
if not exist "installer_output" mkdir "installer_output"
"%ISCC_EXE%" /DSourceRootDir=. lichtfeld_installer.iss
if errorlevel 1 (
    echo [ERROR] Installer packaging failed!
    exit /b 1
)

echo ==============================================================================
echo Installer Generated Successfully!
echo ==============================================================================
dir /b /s installer_output\*.exe
