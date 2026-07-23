# Save Swimmer - Arquitectura de sincronizacion WiFi V001

Fecha: 2026-07-11

## 1. Decision

Save Swimmer debe usar tres canales con responsabilidades separadas:

```text
BLE = control cercano y lectura rapida.
GSM/LTE = seguridad remota y eventos compactos.
WiFi = sincronizacion pesada de sesiones, CSV, resumenes y mantenimiento.
```

El WiFi del ESP32-S3 no reemplaza BLE ni LTE. Sirve para descargar/subir archivos grandes cuando el nadador vuelve a casa, al club, a la laptop de pruebas o a un hotspot del celular en playa.

## 2. Problema que resuelve

Durante pruebas de campo los datos completos pueden ser grandes:

- CSV crudo de IMU/GPS/energia,
- resumen SM,
- diagnostico de gaps,
- logs de sesion,
- archivos incompletos utiles para depuracion.

BLE puede transferirlos, pero es lento y mas delicado para archivos grandes. LTE/GSM no conviene para crudo porque consume datos, bateria y costo mensual. WiFi permite sincronizar despues sin tocar la microSD.

## 3. Flujo recomendado

Durante el nado:

```text
Dispositivo registra localmente en SD/memoria
-> GSM/LTE manda solo resumen/eventos de seguridad
-> BLE sirve para estado si hay celular cerca
```

Al salir del agua:

```text
App se conecta por BLE
-> lee estado y resumen corto
-> si hay archivos pendientes, ofrece sincronizar
```

En casa, club o playa con hotspot:

```text
App o comando BLE activa WiFi temporal
-> dispositivo conecta a red guardada o hotspot
-> sube resumen y CSV al servidor
-> servidor confirma integridad
-> dispositivo marca archivo como sincronizado
-> WiFi se apaga
```

## 4. Modos WiFi posibles

### Modo A - WiFi cliente

El ESP32 se conecta a una red existente:

- WiFi de casa,
- WiFi de club,
- hotspot del celular,
- router de laboratorio.

Uso recomendado para producto.

Ventaja:

- sube directo al servidor.

Desventaja:

- requiere cargar SSID/clave antes.

### Modo B - Access Point temporal

El ESP32 crea una red propia:

```text
SAVE_SWIMMER_SS-LITE-P003
```

El celular o laptop se conecta a esa red y descarga archivos localmente.

Uso recomendado para laboratorio/respaldo.

Ventaja:

- no necesita router externo.

Desventaja:

- no sube directo a internet salvo que la app haga de puente.

### Modo C - Hotspot del celular

El celular crea WiFi, el ESP32 se conecta y sube al servidor.

Uso recomendado para playa y pruebas.

Ventaja:

- permite sincronizar en campo sin retirar microSD.

Desventaja:

- depende de bateria/datos del celular y buena cobertura.

## 5. Que subir al servidor

Orden recomendado:

1. Manifiesto de sesion.
2. Resumen SM.
3. CSV crudo SS si esta habilitado.
4. Logs/incidencias.
5. Hash o tamano final para verificar.

Manifiesto sugerido:

```json
{
  "deviceId": "SS-LITE-P003",
  "sessionId": "SS-LITE-P003-20260711-001",
  "firmware": "SS-LITE-BLE-SD-V1-055",
  "summaryFile": "SM000001.CSV",
  "rawFile": "SS000001.CSV",
  "bytes": 2793548,
  "rows": 26615,
  "startedAt": "2026-07-11T10:22:25-05:00",
  "endedAt": "2026-07-11T11:18:46-05:00"
}
```

## 6. Comandos BLE necesarios

Para que BLE controle WiFi sin transferir todo:

```text
WIFI:STATUS
WIFI:SCAN
WIFI:SET;SSID=...;PASS=...
WIFI:START_SYNC
WIFI:STOP
SYNC:STATUS
SYNC:LIST_PENDING
SYNC:UPLOAD_SUMMARY
SYNC:UPLOAD_RAW
SYNC:MARK_DONE
```

BLE no lleva el archivo grande. BLE solo enciende, configura y pregunta estado.

## 7. Estados de sincronizacion

Estados por archivo:

- LOCAL_ONLY: existe localmente, no subido.
- QUEUED: pendiente de subida.
- UPLOADING: subiendo.
- UPLOADED: servidor recibio archivo.
- VERIFIED: servidor confirmo bytes/hash.
- FAILED: fallo, reintentar.

No borrar el archivo local hasta que este verificado y haya politica clara de retencion.

## 8. Backend minimo para pruebas

Endpoint minimo:

```text
POST /api/devices/{deviceId}/sessions/{sessionId}/manifest
POST /api/devices/{deviceId}/sessions/{sessionId}/summary
POST /api/devices/{deviceId}/sessions/{sessionId}/raw
GET  /api/devices/{deviceId}/sync-status
```

Para etapa local/laptop:

```text
ESP32 -> WiFi/hotspot -> servidor local o ngrok -> carpeta de sesiones
```

Para etapa producto:

```text
ESP32 -> WiFi -> backend cloud -> almacenamiento -> analisis automatico
```

## 9. Seguridad minima

Cada dispositivo debe enviar:

- deviceId,
- sessionId,
- firmware,
- token de dispositivo o clave temporal,
- tamano de archivo,
- hash si es viable.

No aceptar subidas anonimas sin deviceId/token.

## 10. Recomendacion de implementacion

La siguiente version deberia ser:

```text
SS-LITE-BLE-SD-V1-055-WIFI-SYNC
```

Primer alcance:

- no tocar logica de nado,
- no subir mientras graba,
- activar WiFi solo despues de cerrar sesion,
- subir primero SM/resumen,
- subir CSV crudo solo si el usuario lo pide,
- apagar WiFi al terminar o por timeout.

Fase 1:

- WiFi STA con SSID/clave por constantes o BLE,
- upload de archivo resumen SM,
- servidor local simple para recibir.

Fase 2:

- upload de CSV crudo por chunks,
- reintento,
- verificacion por bytes/hash.

Fase 3:

- app Athlete maneja sincronizacion visual,
- backend procesa y genera reporte automatico.

## 11. Decision operativa

Para pruebas con 5 prototipos:

- BLE identifica y controla.
- WiFi sincroniza archivos completos.
- GSM/LTE se reserva para seguridad/eventos.
- SD sigue siendo la fuente oficial hasta que el servidor confirme integridad.

Esto permite que Codex/analisis lea los datos desde el servidor o desde una carpeta sincronizada sin retirar la tarjeta de cada prototipo.
