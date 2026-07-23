SAVE SWIMMER - ESQUEMA KICAD DEL PROTOTIPO ACTUAL V001
Fecha: 2026-06-08

OBJETIVO
Representar las conexiones modulares que actualmente forman el prototipo:

- Bateria LiPo
- TP4056 con proteccion
- Interruptor general
- MT3608 ajustado a 5.0 V
- ESP32-S3 DevKit N16R8
- MPU6050
- Modulo microSD SPI con conversion a 3.3 V
- Capacitores de estabilizacion

ARCHIVO PRINCIPAL RECOMENDADO
SS-PROTOTIPO-ACTUAL-BLOQUES-V001.kicad_sch

Este archivo usa el formato moderno de KiCad 10 y presenta el prototipo como
diagrama modular editable. Es la mejor entrada para comprender la arquitectura
y agregar los siguientes bloques.

ARCHIVO AUXILIAR DETALLADO
SS-PROTOTIPO-ACTUAL-V001.sch

El archivo .sch usa formato legado y documenta pines y etiquetas con mayor
detalle. Debe considerarse referencia auxiliar; la tabla PINOUT es la fuente
principal para conexiones fisicas confirmadas.

VISTA RAPIDA
export/SS-PROTOTIPO-ACTUAL-BLOQUES-V001.pdf

IMPORTANTE
- Es un diagrama del prototipo modular, NO un esquema listo para fabricar PCB.
- Confirmar fisicamente SDA/SCL. El plano propone GPIO8/GPIO9 porque el
  firmware V044 usa Wire.begin() sin pines explicitos.
- Los GPIO SPI microSD si estan confirmados en firmware V044:
  CS 10, MOSI 11, SCK 12, MISO 13.
- La microSD figura a 5 V porque esa conexion fue la validada durante pruebas.
- Ajustar el MT3608 antes de conectar el ESP32.
- Revisar polaridad de bateria, TP4056 y capacitores electroliticos.

SIGUIENTE VERSION
Cuando se confirmen GPS, sensor de agua, medicion INA219, LED 360 y activacion
magnetica se agregaran como una nueva version del esquema. La PCB final
reemplazara los modulos por componentes y footprints exactos.
