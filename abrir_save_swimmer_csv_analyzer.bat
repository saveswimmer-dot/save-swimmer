@echo off
cd /d "%~dp0"
echo.
echo Save Swimmer CSV Analyzer
echo.
echo Abre esta direccion en Chrome o Edge:
echo http://localhost:8000/save_swimmer_csv_analyzer.html
echo.
echo Deja esta ventana abierta mientras ves los graficos.
echo.
py -m http.server 8000
pause
