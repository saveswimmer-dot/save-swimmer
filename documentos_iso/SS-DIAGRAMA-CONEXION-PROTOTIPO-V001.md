# SAVE SWIMMER - DIAGRAMA DE CONEXION PROTOTIPO V001

Fecha: 2026-06-16
Firmware base: SS-LITE-BLE-SD-V1-050
Placa principal: ESP32-S3 DevKit N16R8

## 1. Resumen general

El prototipo actual integra:

- ESP32-S3 DevKit N16R8
- MPU6050 por I2C
- INA219 por I2C
- microSD por SPI
- GPS NEO-M9N por UART
- TP4056 con proteccion
- MT3608 regulado a 5V
- bateria LiPo
- interruptor fisico

## 2. Alimentacion general

Flujo recomendado:

```text
BATERIA LiPo
  |
  | + / -
  v
TP4056 B+ / B-
  |
  | OUT+ / OUT-
  v
INTERRUPTOR en positivo
  |
  v
MT3608 IN+ / IN-
  |
  | salida ajustada a 5.0V aprox
  v
INA219 VIN+ -> INA219 VIN- -> ESP32 5V
GND comun para todo el sistema
```

Conexion de potencia:

| Desde | Hacia | Nota |
|---|---|---|
| Bateria + | TP4056 B+ | Entrada bateria |
| Bateria - | TP4056 B- | Entrada bateria |
| TP4056 OUT+ | Interruptor entrada | Corte fisico del positivo |
| Interruptor salida | MT3608 IN+ | Positivo controlado |
| TP4056 OUT- | MT3608 IN- | GND |
| MT3608 OUT+ | INA219 VIN+ | Entrada de corriente medida |
| INA219 VIN- | ESP32 5V | Alimentacion ESP medida |
| MT3608 OUT- | ESP32 GND | Tierra comun |

Importante:

- El INA219 debe quedar en serie con el positivo.
- Si solo conectas VCC/GND/SDA/SCL del INA219, el modulo es detectado pero no mide consumo real.
- Todos los GND deben estar unidos.

## 3. Bus I2C compartido

El MPU6050 y el INA219 comparten SDA/SCL.

```text
ESP32-S3
  3V3  ---- MPU6050 VCC
  GND  ---- MPU6050 GND
  SDA  ---- MPU6050 SDA
  SCL  ---- MPU6050 SCL

  3V3  ---- INA219 VCC
  GND  ---- INA219 GND
  SDA  ---- INA219 SDA
  SCL  ---- INA219 SCL
```

Tabla I2C:

| Modulo | VCC | GND | SDA | SCL | Direccion esperada |
|---|---|---|---|---|---|
| MPU6050 | 3V3 | GND | SDA ESP32 | SCL ESP32 | 0x68 |
| INA219 | 3V3 | GND | SDA ESP32 | SCL ESP32 | 0x40 |

Nota:

- En ESP32-S3 el firmware usa `Wire.begin()`, por lo que toma los pines I2C definidos por la placa/core.
- Mantener cables SDA/SCL cortos y ordenados.
- Si hay falsos cortes o lecturas raras, revisar empalmes SDA/SCL y GND.

## 4. microSD por SPI

Pines usados por firmware:

| microSD | ESP32-S3 GPIO | Nota |
|---|---:|---|
| CS | GPIO10 | Chip Select |
| MOSI | GPIO11 | Datos ESP -> SD |
| SCK | GPIO12 | Reloj SPI |
| MISO | GPIO13 | Datos SD -> ESP |
| VCC | 5V o 3V3 segun modulo | En pruebas funciono mejor a 5V |
| GND | GND | Tierra comun |

Conexion:

```text
ESP32 GPIO10 ---- microSD CS
ESP32 GPIO11 ---- microSD MOSI
ESP32 GPIO12 ---- microSD SCK
ESP32 GPIO13 ---- microSD MISO
ESP32 5V    ---- microSD VCC
ESP32 GND   ---- microSD GND
```

Nota importante:

- Tu modulo microSD tiene conversion de nivel, por eso pudo trabajar con VCC 5V.
- Si se cambia el modulo, confirmar si acepta 5V antes de conectarlo.
- Mantener los cables SPI lo mas cortos posible.
- Evitar que microSD y GPS queden con cables cruzados encima del ESP.

## 5. GPS NEO-M9N por UART

Firmware V050:

| GPS | ESP32-S3 GPIO | Nota |
|---|---:|---|
| VCC | 3V3 o 5V segun modulo | Confirmar modulo |
| GND | GND | Tierra comun |
| TX | GPIO17 | GPS transmite, ESP recibe |
| RX | GPIO18 | ESP transmite, GPS recibe |

Conexion:

```text
GPS TX ---- ESP32 GPIO17
GPS RX ---- ESP32 GPIO18
GPS VCC --- VCC segun modulo
GPS GND --- GND comun
```

Parametros confirmados:

```text
Baud GPS: 38400
Fix confirmado: si
Satelites observados: 12
HDOP observado: 0.92 aprox
Lat/Lon observado: -12.120702, -77.014175
```

Nota:

- La antena GPS debe quedar lo mas despejada posible.
- Evitar poner bateria o cables sobre la antena.
- Para pruebas, orientar la antena hacia arriba.

## 6. Diagrama esquematico simple

```text
                   +-------------------+
                   |     BATERIA       |
                   +---------+---------+
                             |
                             v
                   +-------------------+
                   |      TP4056       |
                   |   carga/proteccion|
                   +---------+---------+
                             |
                         OUT+|OUT-
                             |
                      [INTERRUPTOR]
                             |
                             v
                   +-------------------+
                   |      MT3608       |
                   |   salida 5.0V     |
                   +----+---------+----+
                        |         |
                       5V        GND
                        |         |
                        v         +----------------------+
                 +--------------+                         |
                 |    INA219    |                         |
                 | VIN+ -> VIN- |                         |
                 +------+-------+                         |
                        |                                 |
                        v                                 |
                +---------------+                         |
                |    ESP32-S3   |<------------------------+
                |               |
                | I2C SDA/SCL   |---- MPU6050
                | I2C SDA/SCL   |---- INA219 logica
                | SPI 10-13     |---- microSD
                | UART 17/18    |---- GPS NEO-M9N
                | BLE           |---- App celular
                +---------------+
```

## 7. Orden fisico recomendado dentro de la caja

Vista superior sugerida:

```text
+------------------------------------------------+
| GPS ANTENA                                     |
| despejada / mirando hacia arriba               |
|                                                |
| MPU6050 cerca del centro dorsal                |
|                                                |
| ESP32-S3               microSD al borde        |
|                                                |
| INA219 / MT3608 / TP4056 agrupados energia     |
|                                                |
| BATERIA plana debajo o lateral, bien fija      |
+------------------------------------------------+
```

Recomendacion de orden:

1. Separar zona de energia: bateria, TP4056, MT3608, INA219.
2. Separar zona de sensores: MPU6050 y GPS.
3. microSD al borde para poder retirar sin tocar todo.
4. Mantener GPS arriba y despejado.
5. Mantener MPU6050 firme, sin movimiento independiente de la caja.
6. Evitar cables largos en SPI.
7. Etiquetar cables con cinta chica: SD, GPS, I2C, POWER.

## 8. Checklist antes de encender

- [ ] MT3608 ajustado a 5.0V aprox antes de conectar al ESP.
- [ ] GND comun entre todos los modulos.
- [ ] INA219 en serie: MT3608 OUT+ -> VIN+ -> VIN- -> ESP 5V.
- [ ] microSD con VCC correcto.
- [ ] microSD insertada antes de encender.
- [ ] GPS TX/RX cruzados: TX GPS a RX ESP GPIO17, RX GPS a TX ESP GPIO18.
- [ ] MPU6050 fijo y conectado por I2C.
- [ ] No hay cables sueltos tocando pines vecinos.
- [ ] Bateria cargada.

## 9. Mensajes esperados por Serial

Al iniciar correctamente:

```text
MPU6050 CONNECTED
INA219 CONNECTED
MICROSD READY
GPS BYTES: YES
BLE READY
```

En JSON:

```text
INPUT_V
LOAD_V
CURRENT_MA
POWER_MW
GPS_FIX
GPS_LAT
GPS_LON
GPS_SATS
GPS_HDOP
```

## 10. Notas de seguridad

- No conectar bateria al ESP directamente sin pasar por regulacion si no estas seguro del voltaje.
- No invertir polaridad.
- No mover cables con el sistema encendido si hay riesgo de corto.
- Antes de cerrar caja, hacer prueba corta:
  - BLE conectado
  - SD inicia/cierra
  - GPS fija ubicacion
  - INA mide voltaje/corriente
  - MPU6050 responde

