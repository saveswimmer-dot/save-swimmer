# Save Swimmer - Documento tecnico prototipo Lite V002

Fecha: 2026-07-11

Estado: documento tecnico vivo para desarrollo interno.

## 1. Proposito del sistema

Save Swimmer es un wearable dorsal de seguridad para aguas abiertas. Su objetivo central es reducir el tiempo entre una situacion incompatible con nado funcional y la verificacion/respuesta por una persona responsable.

No debe comunicarse como reloj deportivo, monitor fitness ni sistema medico. Las metricas tecnicas de nado sirven para adopcion, entrenamiento y lectura diaria, pero no reemplazan la finalidad de seguridad.

Principio vigente:

```text
Family/contacto de emergencia siempre.
Coach solo por permiso del atleta.
Tecnica avanzada por plan o autorizacion.
```

## 2. Alcance vigente

Uso principal:

- aguas abiertas,
- nado solitario costero,
- entrenamiento con contacto de emergencia,
- entrenamiento con coach opcional,
- futura operacion Events.

Piscina:

- sirve para calibracion interna,
- toma controlada de datos,
- comparacion de patrones,
- no se comunica como prueba de seguridad.

Lenguaje prohibido en producto:

- modo prueba,
- probar seguridad,
- simulacion de seguridad,
- si funciona,
- riesgo experimental.

Lenguaje recomendado:

- monitoreo activo,
- sesion activa,
- contacto listo,
- ubicacion compartida,
- alerta enviada,
- revisar senal,
- posible falso positivo,
- alerta atendida,
- emergencia confirmada,
- evento sin confirmar.

## 3. Versiones actuales

Firmware ordenado:

```text
Carpeta: SaveSwimmer_Lite_BLE_Viewer_V054
Archivo: SaveSwimmer_Lite_BLE_Viewer_V054.ino
Version interna: SS-LITE-BLE-SD-V1-054
```

Apps actuales recomendadas:

| App | APK | Package | Version |
|---|---|---|---|
| Athlete | SaveSwimmer_Athlete_NUEVO_V016.apk | com.saveswimmer.athletenew | 0.3.4 |
| Family | SaveSwimmer_Family_NUEVA_V003.apk | com.saveswimmer.familyactive | 0.1.2 |
| Coach | SaveSwimmer_Coach_NUEVO_V018.apk | com.saveswimmer.coachauthorized | 0.1.18 |

Nota Android:

- Las apps nuevas usan package distinto para evitar cache o apertura de versiones viejas.
- Instalar solo APKs que digan Nuevo/Nueva.

## 4. Hardware actual del prototipo

Base actual:

- ESP32-S3 DevKit N16R8,
- MPU6050,
- INA219,
- microSD por SPI,
- GPS/GNSS NEO-M9N,
- bateria LiPo,
- TP4056 con proteccion,
- MT3608 a 5V,
- BLE hacia celular,
- gateway por telefono para pruebas.

Componentes pendientes o por consolidar:

- sensor de agua/humedad,
- LED 360 o casi 360,
- activacion magnetica o boton sellado,
- carcasa flotante/autoenderezable,
- LTE Cat 4 o modulo celular equivalente,
- SIM/eSIM gestionada por Save Swimmer,
- antena celular/GNSS validada en carcasa.

No comprar o no prometer todavia como Lite:

- satelital,
- LoRa para usuario individual,
- Qi obligatorio,
- biometria medica,
- PCB final sin cerrar arquitectura.

## 5. Conexion y alimentacion

Flujo de energia vigente:

```text
Bateria LiPo
-> TP4056 con proteccion
-> interruptor positivo
-> MT3608 regulado a 5V
-> INA219 en serie
-> ESP32-S3 / modulos
```

Reglas:

- INA219 debe ir en serie con el positivo para medir consumo real.
- Todos los GND deben estar unidos.
- microSD debe mantener cables SPI cortos.
- GPS debe quedar despejado, sin bateria o cables sobre antena.
- MPU6050 debe quedar firme y solidario a la carcasa, no flotando sobre cables.

## 6. Lectura IMU vigente

El prototipo cambio el montaje fisico del IMU. El criterio actual es:

```text
ROT = FB
ALIGN = -LR
UD como referencia gravitacional/contextual
MAG como energia contextual, no empuje directo
```

Advertencia tecnica:

- Un unico IMU dorsal mide consecuencias corporales del nado.
- No mide mano, brazo, pierna, cabeza ni fuerza real.
- La app debe usar lenguaje probable/contextual y comparado contra base del atleta.

Lecturas utiles:

- rotacion dorsal por lado,
- simetria izquierda/derecha,
- alineacion estimada,
- continuidad/ritmo,
- energia MAG contextual,
- cambios contra base, promedio de sesion y ventana reciente.

No debe decir:

- fuerza exacta,
- respiracion exacta,
- brazada completa,
- diagnostico biomecanico total.

## 7. Datos y transmision

Durante desarrollo:

- CSV sigue siendo fuente tecnica para auditoria y analisis.
- JSON/BLE sirve para vivo y prototipo.
- Backend/ngrok sirve como prueba de flujo, no infraestructura final.
- WiFi debe evaluarse como canal de sincronizacion pesada para archivos grandes al volver de campo.

Producto futuro:

- no transmitir IMU cruda todo el tiempo,
- enviar paquetes resumidos compactos,
- usar eventos cuando cambie el estado,
- subir frecuencia solo ante alerta,
- guardar crudo local o diagnostico cuando sea necesario.

Resumen normal sugerido:

```text
deviceId
sessionId
timestamp
lat/lon si fix confiable
gpsAge
speed
waterState
motionState
rotationSummary
alignmentSummary
battery
signal
riskState
event
```

Intervalos tentativos:

- normal: 5-30 s segun version y bateria,
- bajo consumo: 30-60 s,
- alerta: 1-2 s temporalmente,
- SOS: inmediato con reintentos.

Arquitectura de canales recomendada:

```text
BLE = control cercano, perfil, deviceId, estado y resumen corto.
GSM/LTE = seguridad remota, eventos compactos y ultima ubicacion.
WiFi = subida de CSV/resumen/logs cuando hay casa, club, laptop o hotspot.
SD/memoria = respaldo oficial hasta confirmar integridad en servidor.
```

Regla WiFi:

- no subir archivos grandes mientras graba una sesion,
- activar WiFi solo por comando o ventana corta,
- subir primero resumen SM,
- subir CSV crudo solo si se necesita analisis profundo,
- apagar WiFi al terminar o por timeout.

Documento relacionado:

- `documentos_iso/SS-ARQUITECTURA-SINCRONIZACION-WIFI-V001-20260711.md`

## 8. Apps y permisos

Athlete:

- inicia sesion,
- verifica membresia,
- exige contacto Family/emergencia,
- permite compartir con Coach ON/OFF,
- muestra lectura tecnica traducida,
- conserva datos propios.

Family:

- incluida en la membresia del atleta/dispositivo,
- obligatoria para sesion real,
- no muestra tecnica cruda,
- muestra estado simple, ultima ubicacion, alerta y accion.

Coach:

- opcional,
- recibe datos solo si el atleta comparte,
- puede tener modelo basico y Pro futuro,
- no es propietario del historial por defecto.

Regla de seguridad:

- Family/contacto siempre debe quedar activo.
- Coach nunca debe ser requisito para que exista seguridad.

## 9. Estados de seguridad

Estados simples:

- Normal,
- Observar,
- Alerta,
- Sin senal,
- Salio del agua,
- Sesion finalizada.

Eventos tecnicos:

- inicio de sesion,
- entrada al agua,
- nado activo,
- detencion prolongada,
- sin avance,
- salida de geocerca,
- tiempo excedido,
- salida fuera de punto esperado,
- senal perdida durante sesion,
- SOS manual,
- alerta automatica contextual.

Escalamiento sugerido:

```text
verde -> todo normal
amarillo -> verificar
rojo -> alerta activa
SOS -> emergencia confirmada o protocolo definido
```

## 10. Lite, Pro y Travel

Lite:

- Peru/local primero,
- conectividad celular nacional,
- costo contenido,
- familia obligatoria,
- coach opcional,
- tecnica util diaria.

Pro:

- hardware distinto,
- mayor bateria/antena/comunicacion,
- opcion futura de roaming/global/satelital,
- puede operar como Lite si no activa Pro.

Regla de hardware:

```text
Lite no sube a Pro solo por software.
Pro puede bajar temporalmente a Lite.
```

Opcion futura:

- activar Pro/Travel temporal para viajes si el hardware Pro ya existe y la conectividad lo permite.

## 11. Costos internos vivos

No fijar precio publico todavia.

Rangos de referencia actuales:

- inversion directa/reposicion prototipo: S/3,000-S/5,000,
- valor tecnico con desarrollo acumulado: S/6,000-S/12,000+,
- dos prototipos mas ajustados: S/3,000-S/4,500,
- dos prototipos mas realistas: S/5,000-S/7,500,
- carcasa/PCB mas seria: S/8,000-S/12,000.

Archivos relacionados:

- `outputs/SS-INVERSION-PROTOTIPO-AJUSTABLE-V001-20260711.md`
- `outputs/SS-COSTEO-VIVO-PROTOTIPO-PRODUCTO-MENSUAL-V001-20260711.md`
- `outputs/SS-COSTO-MENSUAL-OPERACION-LOCAL-INTERNACIONAL-V001-20260711.md`
- `outputs/SS-COSTO-SERVIDORES-24-7-V001-20260711.md`

Decision de costo mensual vigente:

- Lite Peru debe disenarse para vivir en 30-50 MB/mes y buscar SIM/datos local en S/5-S/12 por dispositivo activo.
- La membresia Lite no deberia bajar de S/49/mes si incluye conectividad, backend, Family, soporte y reserva operativa.
- Pro/Travel internacional debe cobrarse separado; referencia inicial S/79-S/149/mes segun cobertura y soporte.
- Satelital queda fuera de Lite y solo debe evaluarse para Pro con paquetes de emergencia, no telemetria continua.
- Servidores/backoffice 24/7 separados de SIM: piloto tecnico S/150-S/400/mes; producto inicial cobrado S/800-S/1,500/mes; robusto regional S/2,500-S/7,000/mes.

## 12. Pendientes criticos

Hardware:

- definir sensor de agua real,
- validar flotabilidad positiva,
- validar autoenderezamiento,
- medir autonomia con GPS/SD/BLE/LED,
- probar luz visible en condiciones reales,
- definir carcasa y sujecion dorsal,
- validar antena GPS y celular en caja.

Firmware:

- confirmar V054 en prueba controlada,
- mejorar estado de sesion,
- separar modo campo de modo laboratorio,
- registrar eventos compactos,
- preparar identidad unica por dispositivo.

Backend:

- identidad deviceId/sessionId/userId,
- membresia,
- permisos Family/Coach,
- reglas de alerta,
- historial minimo,
- auditoria de eventos.

Apps:

- Athlete: permisos reales y perfil de nado,
- Family: conectar a backend real,
- Coach: autorizacion real por atleta,
- reportes: resumen tecnico sin saturar pantalla movil.

Producto:

- no cerrar precio hasta costear carcasa, packaging, conectividad, servidor, soporte y garantia,
- encuesta V005 sin precio para medir prioridades,
- preparar dos prototipos adicionales para comparacion.

## 13. Criterio para decidir nuevas ideas

Cada idea debe responder:

```text
Mejora seguridad real?
Reduce tiempo de verificacion?
Reduce falsos positivos?
Ayuda a vender membresia sin distraer?
Es viable en carcasa sellada?
Sube mucho consumo/costo/soporte?
Pertenece a Lite, Pro, Events o futuro?
```

Clasificacion:

- CORE: necesario para Lite.
- VALIOSO: aporta adopcion, puede esperar.
- EVENTS: requiere infraestructura/organizador.
- PRO: premium o global.
- FUTURO: investigar, no prometer.
- DESCARTAR POR AHORA: no justifica costo o complejidad.
