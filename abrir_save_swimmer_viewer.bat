@echo off
cd /d "%~dp0"
echo.
echo Save Swimmer BLE Viewer
echo.
echo Abre esta direccion en Chrome o Edge:
echo http://localhost:8000/save_swimmer_ble_viewer.html
echo.
echo Deja esta ventana abierta mientras usas la app.
echo.
py -m http.server 8000
pause
