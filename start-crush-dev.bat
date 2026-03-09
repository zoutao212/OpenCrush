@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "REPO_DIR=%~dp0"
pushd "%REPO_DIR%" >nul || (
  echo [ERROR] Failed to enter repo directory: %REPO_DIR%
  exit /b 1
)

if /I "%~1"=="--help" goto :help
if /I "%~1"=="-h" goto :help
if "%~1"=="/?" goto :help

if "%~1"=="" goto :set_default_workdir

pushd "%~1" >nul 2>nul
if not errorlevel 1 goto :arg_is_workdir

:set_default_workdir
set "WORK_DIR=%CD%"
goto :after_workdir

:arg_is_workdir
set "WORK_DIR=%CD%"
popd >nul
shift /1

:after_workdir
pushd "%WORK_DIR%" >nul 2>nul || (
  echo [ERROR] Working directory not found: %WORK_DIR%
  popd >nul
  exit /b 1
)
popd >nul

set "CRUSH_ARGS="
:collect_args
if "%~1"=="" goto :after_args
set "ARG=%~1"
set "ARG=%ARG:"=""%"
set "CRUSH_ARGS=%CRUSH_ARGS% "%ARG%""
shift /1
goto :collect_args

:after_args

where go >nul 2>nul
if errorlevel 1 (
  echo [ERROR] go was not found in PATH.
  echo [ERROR] This repository requires Go 1.26.0 or newer.
  popd >nul
  exit /b 1
)

if defined CRUSH_WORK_KEY (
  set "WORK_KEY=%CRUSH_WORK_KEY%"
) else (
  set "WORK_KEY=%WORK_DIR%"
  set "WORK_KEY=!WORK_KEY:\=_!"
  set "WORK_KEY=!WORK_KEY:/=_!"
  set "WORK_KEY=!WORK_KEY::=_!"
  set "WORK_KEY=!WORK_KEY: =_!"
  set "WORK_KEY=!WORK_KEY:(=_!"
  set "WORK_KEY=!WORK_KEY:)=_!"
  set "WORK_KEY=!WORK_KEY:[=_!"
  set "WORK_KEY=!WORK_KEY:]=_!"
  set "WORK_KEY=!WORK_KEY:;=_!"
  set "WORK_KEY=!WORK_KEY:,=_!"
)

set "CGO_ENABLED=0"
set "GOEXPERIMENT=greenteagc"

if /I "%CRUSH_DEV_PROFILE%"=="1" (
  set "CRUSH_PROFILE=true"
)

set "CRUSH_GLOBAL_CONFIG=%REPO_DIR%tmp\crush-global-config"
set "CRUSH_GLOBAL_DATA=%REPO_DIR%tmp\crush-global-data"
set "PROJECT_DATA_DIR=%REPO_DIR%tmp\workspaces\%WORK_KEY%"

if not exist "%REPO_DIR%tmp" mkdir "%REPO_DIR%tmp" >nul 2>nul
if not exist "%CRUSH_GLOBAL_CONFIG%" mkdir "%CRUSH_GLOBAL_CONFIG%" >nul 2>nul
if not exist "%CRUSH_GLOBAL_DATA%" mkdir "%CRUSH_GLOBAL_DATA%" >nul 2>nul
if not exist "%PROJECT_DATA_DIR%" mkdir "%PROJECT_DATA_DIR%" >nul 2>nul

echo [INFO] Repo Dir   : %REPO_DIR%
echo [INFO] Work Dir   : %WORK_DIR%
echo [INFO] Data Dir   : %PROJECT_DATA_DIR%
echo [INFO] Extra Args : %CRUSH_ARGS%
echo.

go run . --cwd "%WORK_DIR%" --data-dir "%PROJECT_DATA_DIR%" %CRUSH_ARGS%
set "EXIT_CODE=%ERRORLEVEL%"

popd >nul
exit /b %EXIT_CODE%

:help
echo Usage:
echo   start-crush-dev.bat [WORK_DIR] [CRUSH_ARGS...]
echo.
echo Examples:
echo   start-crush-dev.bat
echo   start-crush-dev.bat D:\Code\MyRepo
echo   start-crush-dev.bat D:\Code\MyRepo run "analyze this repository"
echo   start-crush-dev.bat --debug
echo.
echo Notes:
echo   1. WORK_DIR is optional. If omitted, the repo root is used.
echo   2. If the first argument is not an existing directory, it is treated as a Crush argument.
echo   3. Set CRUSH_DEV_PROFILE=1 before running to enable pprof.
echo   4. Set CRUSH_WORK_KEY to override the workspace key if two folders collide.
popd >nul
exit /b 0

