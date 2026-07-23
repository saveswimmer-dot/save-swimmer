@echo off
echo ========================================
echo SAVE SWIMMER - NGROK GATEWAY
echo ========================================
echo.
echo Mantener esta ventana abierta durante la prueba.
echo Cuando aparezca Forwarding, copia la URL https.
echo.
echo URLs a usar:
echo   Celular A Gateway: https://URL_NGROK/api/telemetry
echo   Celular B Coach:   https://URL_NGROK/coach.html
echo.
ngrok http 8787
echo.
echo Si ves "file cannot be accessed", instala/ubica el ngrok.exe real y no el alias de WindowsApps.
pause
