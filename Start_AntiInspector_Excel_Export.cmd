@echo off
setlocal
title AntiInspector - Excel Export
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0AntiInspector_ExcelBridge.ps1"
if errorlevel 1 (
  echo.
  echo Export helper stopped with an error.
  pause
)
endlocal
