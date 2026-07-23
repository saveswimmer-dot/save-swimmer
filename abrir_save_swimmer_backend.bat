@echo off
cd /d "%~dp0backend"
echo ========================================
echo SAVE SWIMMER BACKEND
echo ========================================
echo Abriendo http://localhost:8787/
start "" "http://localhost:8787/"
powershell -NoProfile -ExecutionPolicy Bypass -File "%cd%\server.ps1"
pause
