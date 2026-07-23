@echo off
cd /d "%~dp0"
echo.
echo Save Swimmer Training Dashboard
echo.
echo Abre esta direccion en Chrome o Edge:
echo http://localhost:8000/save_swimmer_training_dashboard.html
echo.
echo Deja esta ventana abierta mientras ves los graficos.
echo.
py -m http.server 8000
pause
