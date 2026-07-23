# Save Swimmer - Mapa Integral Del Proyecto

Documento vivo para ordenar todo lo que rodea a Save Swimmer: empresa, dispositivo, software, certificaciones, operacion, datos, SOS, costos y crecimiento.

## 1. Identidad Del Proyecto

Save Swimmer no debe presentarse solo como un wearable deportivo.

Definicion base:

```text
Save Swimmer desarrolla, comercializa y opera soluciones tecnologicas de seguridad acuatica, monitoreo, telemetria, alertas tempranas, gestion de eventos y servicios digitales asociados.
```

Principio:

```text
No promete rescate automatico.
Entrega informacion temprana, contextual y trazable para mejorar la respuesta ante riesgo acuatico.
```

Estado actualizado al 2026-05-31:

```text
Proyecto en etapa de prototipo funcional.
Firmware de campo validado hasta V044 para registro microSD trazable.
App tecnica Android y app demo comercial separadas.
Campana StartFund aprobada y activa.
Primer feedback externo recibido desde comunidad de aguas abiertas.
```

## 2. Arbol General

```text
SAVE SWIMMER
|
+-- Empresa
|   +-- constitucion / objeto social
|   +-- marca / propiedad intelectual
|   +-- contratos / terminos / privacidad
|   +-- membresias / facturacion
|   +-- soporte / operaciones
|   +-- seguros / responsabilidad civil
|
+-- Producto
|   +-- Lite
|   +-- Events
|   +-- Pro
|
+-- Dispositivo
|   +-- electronica
|   +-- energia
|   +-- sensores
|   +-- comunicacion
|   +-- carcasa / sellado
|   +-- carga
|   +-- luz / visibilidad
|   +-- firmware
|
+-- Software
|   +-- app nadador
|   +-- app familia
|   +-- dashboard entrenador
|   +-- dashboard evento
|   +-- panel operador Save Swimmer
|   +-- backend / API
|   +-- base de datos
|
+-- Seguridad / SOS
|   +-- niveles de alerta
|   +-- cancelacion
|   +-- escalamiento
|   +-- auditoria
|   +-- reportes
|
+-- Datos
|   +-- IMU
|   +-- GPS
|   +-- agua
|   +-- bateria
|   +-- senal
|   +-- eventos
|   +-- historiales
|
+-- Comunidad / Mercado
|   +-- feedback nadadores
|   +-- feedback entrenadores
|   +-- feedback familia
|   +-- referencias competitivas
|   +-- campana StartFund
|   +-- encuesta / validacion
|
+-- Certificaciones / Validaciones
|   +-- telecomunicaciones
|   +-- bateria / carga
|   +-- impermeabilidad
|   +-- seguridad electrica
|   +-- privacidad / datos
|   +-- pilotos con clubes / entrenadores
|   +-- acercamiento autoridades
|
+-- Comercial
    +-- venta dispositivo
    +-- membresia mensual
    +-- activacion SIM/eSIM
    +-- eventos
    +-- soporte premium
    +-- expansion internacional
```

## 3. Empresa

### 3.1 Objeto Social

Debe cubrir mas que venta de hardware.

Areas a contemplar:

- desarrollo y comercializacion de dispositivos electronicos
- desarrollo de software, apps y plataformas web
- servicios digitales por suscripcion
- telemetria, monitoreo remoto y alertas tempranas
- gestion de datos, reportes e historial de actividad
- soporte tecnico y operativo
- importacion/comercializacion de equipos de telecomunicaciones, si aplica
- servicios para eventos deportivos o acuaticos
- integracion con terceros o entidades, cuando corresponda

Pendiente:

```text
Validar con contador/abogado en Peru antes de constituir o modificar empresa.
```

### 3.2 Marca E Identidad

Ramas:

- Save Swimmer
- Save Swimmer Lite
- Save Swimmer Events
- Save Swimmer Pro
- logo
- nombre comercial
- dominio web
- redes sociales
- manual de marca

Canales actuales:

- email: saveswimmer@gmail.com
- Instagram: https://www.instagram.com/saveswimmer/
- TikTok: https://www.tiktok.com/@saveswimmer
- Facebook: Save Swimmer

Pendientes:

- busqueda de marca
- registro en Indecopi
- dominio web
- lineamientos de comunicacion para no prometer rescate garantizado

### 3.3 Documentos Legales

Documentos necesarios:

- terminos y condiciones
- politica de privacidad
- politica de tratamiento de datos personales
- consentimiento de geolocalizacion
- consentimiento de contacto de emergencia
- contrato de membresia
- condiciones de uso de SIM/eSIM gestionada por SS
- limitaciones de responsabilidad
- protocolo de alertas y SOS
- garantia del dispositivo
- politica de devoluciones
- libro de reclamaciones, si corresponde por venta al publico

Regla:

```text
El usuario debe entender que Save Swimmer ayuda a detectar y comunicar riesgo, pero no reemplaza salvavidas, autoridades ni criterio personal.
```

## 4. Producto

### 4.1 Save Swimmer Lite

Objetivo:

- nadador local
- entrenamiento en playa
- nado solitario cerca de costa
- familia y entrenador

Incluye:

- IMU
- sensor de agua
- LTE/GPS
- BLE
- bateria LiPo
- carga magnetica por contactos
- luz visible 360 o casi 360
- app
- membresia
- SOS contextual

No incluye inicialmente:

- LoRa
- satelital
- pantalla
- Qi obligatorio

### 4.2 Save Swimmer Events

Objetivo:

- competencias
- grupos
- entrenadores con varios atletas
- organizadores

Incluye:

- dashboard multi-atleta
- mapa
- geocercos
- estado de cada nadador
- alertas por atleta
- reportes del evento

LoRa:

```text
Solo tiene sentido si Save Swimmer o el evento instala receptor/gateway.
```

### 4.3 Save Swimmer Pro

Objetivo:

- travesias
- mar abierto extremo
- expediciones
- usuarios premium

Incluye:

- LTE/GPS
- satelital futuro
- bateria mayor
- carcasa mas grande
- membresia mayor
- posible Qi o carga mejorada

## 5. Dispositivo

### 5.1 Electronica

Bloques:

- MCU principal
- IMU
- sensor de agua
- modulo LTE/GPS
- BLE
- memoria local o microSD en etapa desarrollo
- LEDs
- circuito de energia
- control de apagado real

Requisito clave:

```text
OFF real = consumo casi cero.
```

No debe quedar el MT3608, GSM/GPS o reguladores consumiendo bateria cuando el equipo esta apagado.

### 5.2 Energia

Prototipo actual:

```text
Bateria -> TP4056 -> interruptor -> MT3608 -> ESP32
```

Producto final:

```text
Bateria LiPo -> carga/proteccion -> switch electronico -> reguladores -> sistema
```

Pendientes:

- medir consumo ESP32 + IMU
- medir consumo microSD escribiendo
- medir picos LTE/GPS
- decidir bateria minima
- definir autonomia objetivo
- definir apagado por software y apagado real
- evitar consumo en reposo

### 5.3 Carga

Opciones:

- contactos magneticos / pogo pins
- Qi para Pro o futuro
- USB solo en prototipo

Lite:

```text
Prioridad: compacto, sellable, costo controlado.
```

### 5.4 Carcasa

Requisitos:

- dorsal
- hidrodinamica
- compacta
- resistente a salitre
- sellada
- sin botones comunes expuestos
- luz visible desde multiples angulos
- compatible con carga
- no molestar al nadador

Pendientes:

- prototipo fisico funcional
- prueba de ubicacion dorsal
- prueba de comodidad
- prueba de salpicadura
- prueba de inmersion controlada
- prueba de agua salada

### 5.5 Firmware

Funciones:

- lectura IMU
- lectura sensor agua
- deteccion postura
- deteccion movimiento
- deteccion ritmo
- registro local
- BLE
- LTE/GPS futuro
- gestion de energia
- estados de alerta
- SOS
- apagado/sleep

Regla:

```text
Cada evento debe poder explicar por que ocurrio.
```

Ejemplo:

```text
agua=true
movimiento=bajo
postura=vertical persistente
ritmo=detenido
tiempo=45 s
=> alerta nivel 2
```

## 6. Software

### 6.1 App Nadador

Uso principal:

- antes de entrar al agua
- al salir del agua
- historial
- resumen
- bateria
- configuracion
- contactos de emergencia
- cancelar alerta si esta bien

No debe depender de que el nadador mire la app durante el nado.

### 6.2 App Familia

Uso:

- ver estado simple
- ultima ubicacion
- sesion activa
- alerta recibida
- contacto de emergencia

Estados utiles:

```text
seco + BT cerca = tierra / dispositivo cercano
agua + BT cerca = cerca de playa/celular
agua + sin BT = nadando/lejos del celular
seco despues de agua = fin de sesion / sincronizacion
```

### Transferencia De Sesiones Sin Retirar Memoria

Requisito registrado para la siguiente evolucion de firmware y aplicaciones:

```text
El dispositivo debe permitir transferir los CSV guardados localmente
al celular o a la PC por BLE, sin retirar microSD ni abrir la carcasa.
```

Comportamiento esperado:

```text
1. La app inicia la sesion y envia perfil/hora.
2. Al perder BLE, el dispositivo continua grabando localmente.
3. Al volver a rango, app o PC consulta el estado del dispositivo.
4. Se detiene y cierra la sesion si aun esta activa.
5. Se lista y descarga el CSV completo almacenado.
6. La aplicacion valida transferencia y lo incorpora al historial.
```

Comandos BLE conceptuales pendientes de implementacion:

```text
STATUS?
PROFILE?
FILES:LIST
FILE:INFO;NAME=SS000005.CSV
FILE:READ;NAME=SS000005.CSV
FILE:DELETE;NAME=SS000005.CSV
```

Regla de producto:

- el usuario final no debe retirar almacenamiento interno
- la SD actual es medio de desarrollo; el Lite comercial puede usar memoria soldada
- el mismo protocolo de sincronizacion debe funcionar con cualquiera de los dos medios
- app y PC podran descargar, pero normalmente solo un cliente BLE estara conectado a la vez
- no borrar archivos del dispositivo hasta confirmar descarga completa e integridad
- al reconectar, el dispositivo debe informar el perfil real asociado a la sesion
- si existe una sesion activa, la app no debe permitir sobrescribir su atleta con campos precargados
- el archivo oficial descargado conserva el perfil registrado en el dispositivo, no el texto visible por defecto en la app

### 6.3 Dashboard Entrenador

Uso:

- mapa con atletas activos
- lista plegable de alumnos
- entrar a atleta individual
- geocerca
- ritmo cada 100 m
- pausa de ritmo
- movimiento si/no
- estado agua
- alertas por alumno
- historial por sesion

No usar datos crudos como LR/FB/UD como metrica principal para entrenador.

### 6.4 Dashboard Evento

Uso:

- mapa operativo
- grupos
- geocercos
- salida/llegada
- alertas
- operador evento
- reporte final

### 6.5 Panel Operador Save Swimmer

Uso:

- ver dispositivos activos
- ver SOS activos
- ver ultima ubicacion
- ver bateria/senal
- ver contactos
- registrar accion
- cerrar evento con motivo
- forzar ping si existe conectividad

Regla:

```text
Save Swimmer no borra un SOS. Lo clasifica y deja trazabilidad.
```

## 7. SOS Y Alertas

### 7.1 Niveles

```text
Nivel 0 - Normal
Nivel 1 - Observacion
Nivel 2 - Alerta
Nivel 3 - SOS
Nivel 4 - Emergencia critica
```

### 7.2 Cancelacion

Quien puede cancelar:

- nadador
- entrenador autorizado
- familiar autorizado, segun nivel
- operador Save Swimmer
- operador evento

Regla:

```text
Un SOS escalado no desaparece automaticamente por volver a moverse.
Debe quedar como evento resuelto, falso positivo, confirmado seguro o escalado.
```

### 7.3 Escalamiento

Inicialmente:

```text
dispositivo -> backend -> contactos / entrenador / operador SS
```

Futuro:

```text
operador SS / evento -> protocolo con autoridad o servicio local
```

No fijar PNP dentro del producto global. Debe ser configurable por pais.

## 8. Datos Y Auditoria

### 8.1 Datos Del Dispositivo

Guardar/transmitir:

- timestamp
- posicion GPS
- agua si/no
- postura
- movimiento
- ritmo
- bateria
- senal
- estado BLE
- nivel alerta
- accion tomada
- firmware
- serial

No transmitir IMU cruda permanentemente por LTE.

### 8.2 Logs De Evento

Un reporte debe responder:

- quien era el usuario
- donde estaba
- cuando entro al agua
- cuando cambio el patron
- cuando se activo alerta
- a quien se aviso
- quien confirmo
- quien cancelo
- ultima ubicacion valida
- bateria y senal al momento

Ejemplo:

```text
11:42:10 - usuario en agua
11:42:18 - patron compatible con nado
11:44:02 - ritmo baja 38%
11:44:20 - movimiento detenido
11:44:30 - postura vertical persistente
11:44:45 - alerta nivel 1
11:45:15 - SOS nivel 2
11:45:16 - aviso enviado a entrenador
11:45:19 - aviso confirmado
```

## 9. Certificaciones Y Validaciones

### 9.1 Peru

Telecomunicaciones:

- homologacion MTC para equipos/modulos con emisiones radioelectricas, segun corresponda
- verificar si modulo LTE/GPS ya cuenta con homologacion o certificaciones reconocibles
- compatibilidad con bandas locales
- SIM/eSIM local o M2M/IoT

Datos personales:

- geolocalizacion
- datos de salud/seguridad contextual
- contactos de emergencia
- consentimiento informado
- almacenamiento y eliminacion de datos

Consumidor:

- garantia
- reclamos
- terminos claros
- no publicidad enganosa

Marca:

- registro Indecopi

Autoridades/operacion:

- PNP Salvataje para playa
- DICAPI / Capitanias y Guardacostas para ambito maritimo
- SAMU/Bomberos segun tipo de emergencia
- municipalidades o organizadores para eventos

Objetivo inicial:

```text
Validacion piloto, no promesa de aprobacion oficial inmediata.
```

### 9.2 Internacional Futuro

Ramas posibles:

- CE / Europa
- FCC / Estados Unidos
- certificaciones de bateria/transporte
- IP68 por laboratorio
- compatibilidad de operadores
- privacidad por pais
- numeros de emergencia configurables
- idioma y terminos locales

### 9.3 ISO Y Sistemas De Gestion

Aclaracion:

```text
Muchas normas ISO certifican el sistema de gestion de la empresa, no el producto en si.
El producto puede requerir ensayos/certificaciones tecnicas aparte: IP68, telecom, bateria, EMC, CE/FCC, etc.
```

Normas ISO a contemplar por etapa:

| Norma | Area | Relevancia para Save Swimmer | Prioridad |
|---|---|---|---|
| ISO 9001 | Gestion de calidad | Ordena procesos, compras, produccion, control de cambios, reclamos y mejora continua | Alta futura |
| ISO/IEC 27001 | Seguridad de informacion | Importante por app, backend, geolocalizacion, SOS, datos de usuarios y membresias | Alta futura |
| ISO/IEC 27701 | Privacidad | Extension de privacidad sobre 27001; util por geolocalizacion/contactos/emergencias | Media futura |
| ISO 22301 | Continuidad del negocio | Importante si SS opera alertas/SOS y debe sostener servicio ante fallas | Media futura |
| ISO 31000 | Gestion de riesgo | Util como marco para riesgos de producto, empresa, SOS, autoridad y operacion | Referencia |
| ISO 13485 | Dispositivos medicos | Solo evaluar si el producto se posiciona o regula como dispositivo medico/salud | Condicional |
| ISO 14971 | Riesgo en dispositivos medicos | Puede servir como referencia metodologica, aunque no se venda como medico | Referencia |
| ISO 14001 | Ambiental | Futuro: baterias, residuos electronicos, empaque y sostenibilidad | Baja inicial |
| ISO 45001 | Seguridad y salud en el trabajo | Futuro: operacion, pruebas, ensamblaje, equipo humano | Baja inicial |
| ISO/IEC 20000-1 | Gestion de servicios TI | Futuro si SS opera plataforma/soporte como servicio maduro | Baja/media futura |

Lectura estrategica:

```text
Inicio: documentar procesos con mentalidad ISO, sin certificarse todavia.
Crecimiento: preparar ISO 9001 + ISO/IEC 27001.
Si se acerca a salud/medical: evaluar ISO 13485/14971 con asesor especializado.
```

Documentacion que conviene crear desde temprano:

- control de versiones de firmware
- control de versiones de app/backend
- trazabilidad de dispositivo por serial
- registro de compras y proveedores
- registro de pruebas de campo
- registro de fallas
- registro de falsos positivos y SOS
- procedimiento de carga/ensamblaje
- procedimiento de prueba final por unidad
- matriz de riesgos
- politica de privacidad
- control de acceso a datos
- protocolo de respuesta a incidentes
- backups y recuperacion de datos

### 9.4 IP, Resistencia Y Ensayos Tecnicos

IP68 no debe tratarse como una frase comercial sin ensayo.

Ramas:

- diseno de carcasa
- juntas/sellos
- carga magnetica/contactos
- corrosion salina
- presion/inmersion
- golpes/caidas
- temperatura
- vibracion
- degradacion por sol/UV

Pendiente:

```text
Definir objetivo real de IP68: profundidad, tiempo, agua dulce/salada y condicion de uso.
```

Ejemplo:

```text
IP68 declarado por laboratorio bajo condicion X no significa uso ilimitado en mar.
Debe especificarse tiempo, profundidad y limites.
```

## 10. Operacion Y Soporte

### 10.1 Activacion

Flujo:

- venta dispositivo
- registro usuario
- asignacion serial
- activacion membresia
- activacion SIM/eSIM
- alta contactos emergencia
- prueba inicial

### 10.2 Soporte

Casos:

- dispositivo no carga
- no conecta BLE
- sin senal LTE
- sensor agua falla
- falso SOS
- bateria baja
- cambio usuario
- baja membresia
- robo/perdida

### 10.3 Monitoreo Interno

Save Swimmer debe conocer:

- dispositivos activos
- membresias activas
- dispositivos sin transmitir
- fallas repetidas
- alertas falsas
- SOS reales
- zonas con mala cobertura

## 11. Costos Y Negocio

### 11.1 Hardware

Separar:

- costo real pagado de prototipo
- costo util por prototipo
- costo estimado producto final
- costo de empaque/cargador
- merma
- garantia

### 11.2 Mensualidad

Debe cubrir:

- SIM/eSIM
- datos/SMS
- backend
- base de datos
- notificaciones
- soporte
- app
- actualizaciones
- pasarela de pago
- margen

Referencia actual Lite:

```text
S/40 - S/50 mensual
```

### 11.3 Decisiones Por Valor

Preguntas antes de agregar algo:

- reduce riesgo real?
- aumenta seguridad?
- baja falsos positivos?
- ayuda a autoridad/entrenador/familia?
- justifica costo?
- afecta tamano?
- afecta autonomia?
- complica certificacion?

## 12. Roadmap De Validacion

### Fase 1 - Prototipo De Datos

- ESP32-S3
- MPU6050
- BLE
- app Android field viewer
- CSV
- analizador
- datasets tierra/nado simulado

### Fase 2 - Registro Autonomo

- microSD
- sensor agua
- energia con bateria
- apagado/sleep
- logs etiquetados

### Fase 3 - Prototipo Wearable

- carcasa basica
- ubicacion dorsal
- bateria integrada
- luz
- prueba caminata/playa
- prueba agua controlada

### Fase 4 - Conectividad Remota

- LTE/GPS
- backend basico
- app familia/entrenador
- geocerca
- eventos

### Fase 5 - Piloto

- entrenadores
- nadadores conocidos
- Agua Dulce / Costa Verde u otra zona
- datos reales
- falsos positivos
- reporte de sesiones

### Fase 6 - Pre-Serie

- PCB
- carcasa mejorada
- carga magnetica
- pruebas estanqueidad
- lote pequeno
- costos finos

### Fase 7 - Validacion Institucional

- dossier tecnico
- reporte de pilotos
- protocolo SOS
- acercamiento a clubes
- acercamiento Salvataje/DICAPI segun caso
- evaluacion legal

## 13. Riesgos Principales

| Riesgo | Impacto | Mitigacion |
|---|---|---|
| Falsos SOS | Alto | niveles de alerta, sensor agua, persistencia, cancelacion |
| Sin senal LTE | Alto | guardar local, reintentos, SMS, indicar ultima ubicacion |
| Bateria insuficiente | Alto | medicion real, duty cycle, apagado real |
| Costo Lite alto | Alto | eliminar LoRa, evitar Qi inicial, PCB final |
| Carcasa no IP68 | Alto | prototipos, pruebas, carga magnetica |
| Responsabilidad legal | Alto | terminos, protocolo, no prometer rescate |
| Autoridad no integra | Medio | usar sistema privado primero, reportes utiles |
| App confusa | Medio | datos interpretados, no LR/FB/UD al usuario final |
| Sensor agua falla | Medio | redundancia logica: agua + movimiento + contexto |

## 14. Regla Madre Del Proyecto

```text
La version de cables puede ser fea.
La logica, los datos y la trazabilidad deben nacer serios desde el primer prototipo.
```
