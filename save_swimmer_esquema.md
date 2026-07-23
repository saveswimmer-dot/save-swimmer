# Save Swimmer - Esquema Vivo

## 0. Schematic Fisico Del Prototipo Actual

```mermaid
flowchart LR
  subgraph POWER["Alimentacion"]
    USB["USB 5V\nprogramacion / prueba"]
    EXT["Bateria externa\n5V prototipo"]
  end

  subgraph ESP["ESP32-S3-WROOM-1-N16R8"]
    V5["5V / VIN"]
    GND["GND"]
    SDA["GPIO SDA"]
    SCL["GPIO SCL"]
    BLEANT["BLE interno"]
    WIFIANT["WiFi interno"]
  end

  subgraph IMU["MPU6050"]
    IMUVCC["VCC"]
    IMUGND["GND"]
    IMUSDA["SDA"]
    IMUSCL["SCL"]
  end

  USB --> V5
  EXT --> V5
  V5 --> IMUVCC
  GND --- IMUGND
  SDA --- IMUSDA
  SCL --- IMUSCL

  ESP --> BLEANT
  ESP --> WIFIANT
```

### Conexion Actual Recomendada

| Modulo | Pin modulo | ESP32-S3 |
|---|---:|---:|
| MPU6050 | VCC | 3V3 recomendado o 5V si el breakout lo permite |
| MPU6050 | GND | GND |
| MPU6050 | SDA | GPIO SDA definido en firmware |
| MPU6050 | SCL | GPIO SCL definido en firmware |
| Alimentacion prototipo | 5V | VIN / 5V |
| Alimentacion prototipo | GND | GND comun |

Nota: si el MPU6050 es breakout tipo GY-521, normalmente acepta 5V por regulador integrado, pero para PCB final conviene revisar nivel logico y alimentar sensores a 3V3 cuando corresponda.

## 0.1 Schematic Fisico Previsto

```mermaid
flowchart TB
  subgraph POWER2["Energia sellada"]
    LIPO["LiPo plana"]
    PROT["Proteccion bateria\nBMS / TP4056 protegido"]
    CHG["Carga magnetica o Qi"]
    BOOST2["MT3608 / regulador\n5V estable si aplica"]
    REG33["Regulador 3V3\nsensores / logica"]
  end

  subgraph CORE["Core"]
    ESP2["ESP32-S3"]
    MPU2["MPU6050 / IMU futura"]
    WATER2["Sensor de agua"]
    SD2["microSD"]
    BTN2["Boton SOS / iman"]
    LED2["LED estado / SOS"]
  end

  subgraph COMMS2["Comunicaciones futuras"]
    LORA2["LoRa"]
    GSM2["GSM-LTE"]
    GPS2["GPS"]
    SAT2["Iridium futuro"]
  end

  CHG --> PROT
  LIPO --> PROT
  PROT --> BOOST2
  PROT --> REG33
  BOOST2 --> ESP2
  REG33 --> ESP2
  REG33 --> MPU2
  REG33 --> WATER2
  REG33 --> SD2

  MPU2 -->|"I2C SDA/SCL"| ESP2
  WATER2 -->|"GPIO / ADC"| ESP2
  SD2 -->|"SPI"| ESP2
  BTN2 -->|"GPIO interrupt"| ESP2
  ESP2 -->|"GPIO PWM"| LED2

  LORA2 -->|"SPI / UART"| ESP2
  GSM2 -->|"UART"| ESP2
  GPS2 -->|"UART / I2C"| ESP2
  SAT2 -->|"UART"| ESP2
```

## 0.2 Bloques Fisicos En El Wearable

```mermaid
flowchart TB
  TOP["Tapa superior sellada\nLED visible / logo / antenas libres"]
  PCB["PCB principal\nESP32-S3 + IMU + energia"]
  SENSOR["Zona sensor agua\ncontacto externo protegido"]
  BATP["Bateria LiPo plana\ncentro de masa bajo"]
  CHARGEPORT["Carga magnetica / Qi\nsin USB expuesto"]
  CASE["Carcasa dorsal hidrodinamica\nespalda alta / entre escapulas"]

  TOP --> PCB
  PCB --> SENSOR
  PCB --> BATP
  BATP --> CHARGEPORT
  TOP --> CASE
  PCB --> CASE
  SENSOR --> CASE
  BATP --> CASE
```

## 1. Esquema Del Dispositivo

```mermaid
flowchart TB
  subgraph WEARABLE["Wearable dorsal Save Swimmer"]
    MCU["ESP32-S3\nprocesamiento local"]
    IMU["MPU6050\norientacion + movimiento"]
    WATER["Sensor de agua\nseco / mojado"]
    BAT["Bateria LiPo\nenergia"]
    CHARGE["TP4056\ncarga"]
    BOOST["MT3608\nenergia estable"]
    LED["LEDs\nestado / SOS visual"]
    BTN["Boton / iman\nSOS / cancelar / modo"]
    SD["microSD\nlogging / datasets"]
  end

  subgraph LOGIC["Logica local"]
    CONTEXT["Contexto\nagua + BLE + movimiento"]
    BODY["Estado corporal\nhorizontal / vertical / lateral / inversion"]
    PACE["Ritmo / avance\nestable / baja / paro"]
    GEO["Geocerco\n dentro / borde / fuera"]
    EVENT["Eventos\nwatch / alerta / SOS"]
    POWER["Ahorro\ntransmision contextual"]
  end

  subgraph COMMS["Comunicaciones"]
    BLE["BLE\ncercania / config / debug"]
    WIFI["WiFi\nlaboratorio / pruebas"]
    LORA["LoRa opcional\nsolo base propia / evento"]
    GSM["GSM-LTE\nremoto / eventos criticos"]
    SAT["Iridium futuro\nmar abierto extremo"]
  end

  subgraph APP["App Save Swimmer"]
    SWIMMER["Nadador"]
    COACH["Entrenador"]
    FAMILY["Familia"]
    EVENTAPP["Evento"]
  end

  BAT --> CHARGE
  BAT --> BOOST
  BOOST --> MCU
  IMU --> MCU
  WATER --> MCU
  BTN --> MCU
  MCU --> LED
  MCU --> SD

  MCU --> CONTEXT
  CONTEXT --> BODY
  CONTEXT --> PACE
  CONTEXT --> GEO
  BODY --> EVENT
  PACE --> EVENT
  GEO --> EVENT
  EVENT --> POWER

  POWER --> BLE
  POWER --> WIFI
  POWER --> LORA
  POWER --> GSM
  POWER --> SAT

  BLE --> APP
  WIFI --> APP
  LORA --> APP
  GSM --> APP
  SAT --> APP
```

## 2. Maquina De Contexto Agua + Bluetooth

```mermaid
stateDiagram-v2
  [*] --> TierraPreparado

  TierraPreparado: Seco + BLE cerca\ntransmision minima
  EntradaAgua: Agua + BLE cerca\ninicio de sesion
  Nadando: Agua + BLE lejos\nseguimiento remoto activo
  RegresoPlaya: Agua + BLE cerca\nposible salida
  SesionFinalizada: Seco + BLE cerca\nresumen + ahorro
  Standby: Seco + BLE lejos\nsin contexto cercano

  TierraPreparado --> EntradaAgua: agua confirmada
  EntradaAgua --> Nadando: BLE se aleja
  Nadando --> RegresoPlaya: BLE vuelve cerca
  RegresoPlaya --> SesionFinalizada: seco persistente
  SesionFinalizada --> Standby: app lejos / guardado
  Standby --> TierraPreparado: BLE cerca

  Nadando --> Nadando: movimiento funcional
  Nadando --> RegresoPlaya: pausa cerca de playa
```

## 3. Arbol De La App

```mermaid
flowchart TB
  APP["Save Swimmer App"]

  APP --> LOGIN["Elegir acceso / rol"]

  LOGIN --> NADADOR["Modo Nadador"]
  LOGIN --> ENTRENADOR["Modo Entrenador"]
  LOGIN --> FAMILIA["Modo Familia"]
  LOGIN --> EVENTO["Modo Evento"]

  NADADOR --> N1["Iniciar sesion"]
  NADADOR --> N2["Elegir tipo de nado"]
  NADADOR --> N3["Compartir con entrenador / familia"]
  NADADOR --> N4["Mapa + geocerco"]
  NADADOR --> N5["Resumen post-nado"]
  NADADOR --> N6["Historial personal"]
  NADADOR --> N7["Configuracion SOS"]

  N2 --> NG["Entrenamiento grupal"]
  N2 --> NS["Nado solitario"]
  N2 --> NM["Mar abierto solitario"]
  N2 --> NE["Competencia / evento"]

  ENTRENADOR --> E1["Lista plegable de alumnos"]
  ENTRENADOR --> E2["Mapa grupal desde playa"]
  ENTRENADOR --> E3["Geocerco de entrenamiento"]
  ENTRENADOR --> E4["Atleta seleccionado"]
  ENTRENADOR --> E5["Ritmo cada 100 m"]
  ENTRENADOR --> E6["Accion sugerida"]
  ENTRENADOR --> E7["Alertas internas"]
  ENTRENADOR --> E8["Historial compartido"]

  E1 --> EA["Alumnos con dispositivo"]
  E1 --> ES["Sesiones compartidas"]
  E1 --> EL["Alertas del grupo"]

  FAMILIA --> F1["Estado simple"]
  FAMILIA --> F2["Agua + BLE"]
  FAMILIA --> F3["Ultima ubicacion"]
  FAMILIA --> F4["Notificaciones"]
  FAMILIA --> F5["Red de confianza"]

  EVENTO --> EV1["Acceso por evento"]
  EVENTO --> EV2["Mapa publico / staff"]
  EVENTO --> EV3["Atletas visibles"]
  EVENTO --> EV4["Alertas organizacion"]
  EVENTO --> EV5["Historial del evento"]
  EVENTO --> EV6["Reporte / exportacion"]
```

## 4. Escalamiento SOS Por Modo

```mermaid
flowchart TB
  ALERTA["Condicion anormal detectada"]

  ALERTA --> GRUPO["Entrenamiento grupal"]
  ALERTA --> SOLO["Nado solitario"]
  ALERTA --> MAR["Mar abierto solitario"]
  ALERTA --> COMP["Competencia"]

  GRUPO --> G1["Avisar entrenador"]
  G1 --> G2["Entrenador decide accion"]
  G2 --> G3["SOS externo manual solo si es real extremo"]

  SOLO --> S1["Cuenta regresiva"]
  S1 --> S2["Avisar red de confianza"]
  S2 --> S3["Escalar si no hay respuesta"]

  MAR --> M1["Cuenta regresiva corta"]
  M1 --> M2["Red de confianza + ubicacion"]
  M2 --> M3["SOS externo critico"]

  COMP --> C1["Centro de control"]
  C1 --> C2["Bote / rescate del evento"]
  C2 --> C3["Escalamiento oficial por protocolo"]
```

## 5. Principio De Diseno

El dispositivo procesa localmente y transmite segun contexto.

- IMU cruda: laboratorio, BLE o microSD.
- App entrenador: lenguaje humano, no ejes de sensor.
- Familia: tranquilidad y estados simples.
- Evento: supervision operativa.
- SOS externo: ultima capa, dependiente del modo de sesion.

## 6. Estrategia De Comunicacion Sin Base LoRa Publica

LoRa no debe ser parte del flujo principal de entrenador para venta al publico.

Un telefono comun no puede recibir LoRa directamente. Para usar LoRa haria falta:

- un receptor LoRa fisico conectado al celular por USB/Bluetooth, o
- un gateway LoRa con internet, o
- una base propia instalada en playa/evento.

Eso agrega hardware, soporte y friccion. Por eso LoRa queda como opcion futura para eventos o bases propias, no como requisito para entrenadores.

LoRa solo es util cuando Save Swimmer controla la infraestructura:

- competencia con base/gateway
- embarcacion o punto fijo propio

Para venta al publico no se puede asumir receptor LoRa en playa. La comunicacion debe tener una opcion celular/satelital.

```mermaid
flowchart TB
  DEVICE["Wearable Save Swimmer"]

  DEVICE --> BLEPATH["BLE cercano"]
  DEVICE --> PHONE["Telefono del nadador\nsi esta cerca"]
  DEVICE --> CELL["Modulo celular 4G/LTE"]
  DEVICE --> LORAPATH["LoRa opcional"]
  DEVICE --> SATPATH["Satelital futuro"]

  BLEPATH --> B1["Config / debug / fin de sesion"]
  PHONE --> P1["App retransmite\ncuando el telefono esta cerca"]
  CELL --> C1["Datos compactos\nMQTT/HTTPS"]
  CELL --> C2["SMS SOS fallback"]
  CELL --> C3["GPS/GNSS + ubicacion"]
  LORAPATH --> L1["Evento / base propia\ncon receptor fisico"]
  SATPATH --> S1["Mar abierto extremo\npremium / emergencia"]
```

### Opciones Evaluadas

| Opcion | Sirve para | Ventaja | Problema |
|---|---|---|---|
| BLE + telefono | cerca de playa / salida | bajo costo y bajo consumo | no sirve lejos del telefono |
| LoRa propio | competencia / base propia | largo alcance local | requiere receptor/gateway fisico; el celular no lo recibe nativamente |
| 4G LTE Cat-1 / Cat-4 | publico general | red celular disponible, datos y SMS | consumo alto, SIM, antena, cobertura |
| LTE-M | IoT movil eficiente | mejor consumo que LTE clasico | cobertura debe verificarse por operador |
| NB-IoT | mensajes muy pequenos | bajo consumo y buena penetracion | peor para movilidad; no ideal si el nadador se desplaza entre celdas |
| Satelital | mar abierto extremo | cobertura fuera de celular | costo alto, hardware y planes premium |

### Recomendacion Para Save Swimmer

```mermaid
flowchart TB
  MODE["Modo de sesion"]

  MODE --> GROUP["Grupo con entrenador"]
  MODE --> SOLO["Nado solitario cerca de costa"]
  MODE --> OPEN["Mar abierto solitario"]
  MODE --> EVENT["Competencia"]

  GROUP --> GCOM["4G/LTE directo a app\nBLE solo cerca"]
  SOLO --> SCOM["4G/LTE + GPS\nSMS SOS fallback"]
  OPEN --> OCOM["4G/LTE si hay cobertura\nsatelital futuro"]
  EVENT --> ECOM["4G/LTE principal\nLoRa solo si el evento instala gateway"]
```

### Politica De Datos

El modulo celular no debe transmitir IMU cruda.

- cada 30-60 s: estado resumido
- inmediato: evento importante
- SOS: ubicacion + estado + timestamp + bateria + modo
- fin de sesion: resumen y apagado/reduccion

Ejemplo paquete SOS:

```json
{
  "device": "SS-LT-000001",
  "mode": "SOLO_OPEN_WATER",
  "event": "SOS_PENDING",
  "lat": -12.1673,
  "lon": -77.0308,
  "water": true,
  "movement": "NO_ADVANCE",
  "last_signal_s": 3,
  "battery": 82,
  "time": "2026-05-16T09:22:10-05:00"
}
```
