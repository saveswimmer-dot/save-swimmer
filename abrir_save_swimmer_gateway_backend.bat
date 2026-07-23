@echo off
cd /d "%~dp0"
echo ========================================
echo SAVE SWIMMER - BACKEND GATEWAY
echo ========================================
echo.
echo Mantener esta ventana abierta durante la prueba.
echo Dashboard local:
echo   http://localhost:8787/
echo Vista entrenador:
echo   http://localhost:8787/coach.html
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\backend\server.ps1"
pause
