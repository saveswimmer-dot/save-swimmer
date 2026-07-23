@echo off
setlocal
cd /d "%~dp0\.."
powershell -ExecutionPolicy Bypass -File "herramientas\calibracion_usb_serial_v001.ps1"
echo.
echo Presiona una tecla para cerrar.
pause >nul
