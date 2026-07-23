@echo off
setlocal
cd /d "%~dp0\.."
powershell -ExecutionPolicy Bypass -File "herramientas\generar_reporte_ultimo_csv_v001.ps1"
echo.
echo Presiona una tecla para cerrar.
pause >nul
