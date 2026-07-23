@echo off
cd /d "%~dp0"
echo.
echo Save Swimmer Mobile Sim
echo.
echo Abre esta direccion en Chrome o Edge:
echo http://localhost:8000/save_swimmer_mobile_sim.html
echo.
echo Deja esta ventana abierta mientras ves la simulacion.
echo.
py -m http.server 8000
pause
