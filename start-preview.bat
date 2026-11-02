@echo off
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
  python tools\preview.py --open %*
) else (
  py -3 tools\preview.py --open %*
)
if errorlevel 1 pause
