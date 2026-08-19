@echo off
REM ---------------------------------------------------------------
REM  Billing Tool - starts a local web server in this folder so the
REM  app runs as a real PWA (service worker + install prompt).
REM  Just double-click this file.
REM ---------------------------------------------------------------
setlocal
cd /d "%~dp0"

set PYEXE=
where py >nul 2>nul && set PYEXE=py
if not defined PYEXE (
  where python >nul 2>nul && set PYEXE=python
)

if not defined PYEXE (
  echo.
  echo   Python was not found.
  echo.
  echo   Either install it from https://www.python.org/downloads/
  echo   ^(tick "Add python.exe to PATH" during setup^),
  echo   or, if you have Node.js, run this instead:
  echo.
  echo       npx serve -l 8000
  echo.
  pause
  exit /b 1
)

echo.
echo   Serving this folder on http://localhost:8000
echo   Leave this window open. Press Ctrl+C to stop.
echo.
start "" http://localhost:8000
%PYEXE% -m http.server 8000
