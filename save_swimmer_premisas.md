# Save Swimmer - Premisas De Producto

## Vision

Save Swimmer es un wearable dorsal de seguridad para aguas abiertas. No es un reloj deportivo ni un monitor fitness. Su valor esta en interpretar contexto acuatico, detectar situaciones incompatibles con nado funcional y comunicar estados/eventos a nadador, entrenador, familia o evento.

Actualizacion de criterio - 2026-07-10:

```text
Save Swimmer se piensa principalmente para aguas abiertas.
Piscina puede usarse para calibracion interna, desarrollo y toma controlada de datos,
pero no debe presentarse al usuario final como "prueba" de seguridad.
En seguridad no se habla de "si funciona"; se habla de monitoreo activo,
alerta, falso positivo, alerta atendida, emergencia confirmada o evento sin confirmar.
```

Actualizacion de versiones - 2026-07-11:

```text
Athlete actual: SaveSwimmer_Athlete_NUEVO_V016.apk | version 0.3.4 | package com.saveswimmer.athletenew
Family actual: SaveSwimmer_Family_NUEVA_V003.apk | version 0.1.2 | package com.saveswimmer.familyactive
Coach actual: SaveSwimmer_Coach_NUEVO_V018.apk | version 0.1.18 | package com.saveswimmer.coachauthorized
Firmware actual ordenado: SaveSwimmer_Lite_BLE_Viewer_V054.ino | SS-LITE-BLE-SD-V1-054
```

## Premisa Madre

Save Swimmer existe para **rescate, atencion primaria y reduccion del tiempo de respuesta en agua**.

Las metricas deportivas, tecnicas y visuales son herramientas de adopcion y valor de uso, pero no deben desplazar la finalidad principal del sistema.

Principio rector:

```text
Detectar riesgo acuatico
-> avisar a quien puede actuar primero
-> ubicar al nadador o su ultima ubicacion asociada al nado
-> reducir tiempo de verificacion/respuesta
-> facilitar rescate o atencion primaria
```

Toda nueva funcion debe evaluarse preguntando:

```text
Ã‚?Mejora seguridad real?
Ã‚?Reduce tiempo de respuesta?
Ã‚?Reduce falsos positivos?
Ã‚?Mejora adopcion sin distraer del rescate?
Ã‚?Mantiene el alcance acuatico del producto?
```

## Modelo De Apps Y Membresia

Decision vigente:

```text
El atleta/dispositivo es el pagador principal de la membresia.
La app Family/contacto de emergencia esta incluida y es obligatoria para una sesion real.
La app Coach es opcional y solo recibe datos si el atleta decide compartir.
```

Roles:

- Athlete: inicia sesion, toma base, muestra estado propio, beneficio tecnico diario, membresia y permisos.
- Family: recibe estado de seguridad, ultima ubicacion, alerta, sin senal, salida del agua y acciones simples.
- Coach: monitor opcional para entrenador, clubes o equipos; debe priorizar a quien mirar primero y por que.

Reglas:

- Family/contacto de emergencia no se desconecta durante una sesion activa.
- Para iniciar una sesion real debe existir al menos un contacto de emergencia validado.
- Coach nunca debe ser requisito para seguridad.
- Compartir con Coach debe ser una opcion explicita al iniciar sesion.
- La membresia vive asociada al atleta/dispositivo, no al familiar.
- Family puede ser app gratuita/incluida, pero en la UI no debe presentarse como "gratis" si eso reduce percepcion de seguridad; usar mejor "incluido", "contacto activo" o "seguridad familiar".

Modelo Coach sugerido:

- Coach basico: estado actual, ultima senal, alerta y ubicacion durante sesion compartida.
- Coach Pro/pago: historial, reportes, tecnica posterior, comparacion, grupos, notas, exportacion y analisis avanzado.

Flujo de inicio recomendado:

```text
Atleta abre Athlete
-> app verifica membresia
-> verifica contacto Family obligatorio
-> muestra contacto activo
-> muestra compartir con Coach ON/OFF
-> inicia monitoreo de aguas abiertas
-> Family recibe inicio y estados de seguridad
-> Coach recibe datos solo si fue autorizado
```

## Lenguaje De Seguridad

No usar en producto final:

- modo prueba
- probar seguridad
- demo de alerta
- simulacion de seguridad
- si funciona
- riesgo experimental
- pendiente de validar

Usar:

- monitoreo activo
- sesion activa
- contacto listo
- ubicacion compartida
- alerta enviada
- revisar senal
- posible falso positivo
- alerta descartada
- alerta atendida
- emergencia confirmada
- evento sin confirmar
- salida del agua registrada
- sin senal durante sesion

Estados recomendados para Family:

- Normal
- Observar
- Alerta
- Sin senal
- Salio del agua
- Sesion finalizada

Estados de resultado posterior:

- Sin alertas
- Alerta enviada
- Falso positivo marcado
- Emergencia confirmada
- Sin confirmar

## Alcance Acuatico Del Producto

Save Swimmer es un sistema de seguridad para uso en agua. No debe prometer seguridad terrestre ni monitoreo confiable en arena, malecon, estacionamiento o ciudad.

Alcance operativo:

- entrada al agua
- salida del agua
- estado agua/seco
- movimiento acuatico
- detencion en agua
- nado fuera de geocerca acuatico
- tiempo excedido durante sesion acuatico
- distancia a base/punto de encuentro mientras la sesion esta activa
- ultima ubicacion disponible asociada al nado
- salida del agua fuera del punto esperado

Fuera de alcance por ahora:

- seguimiento terrestre posterior al nado
- incidencias en arena o borde de playa como funcion principal
- rescate terrestre
- prometer ubicacion continua despues de finalizada la condicion acuatico

Frase tecnica recomendada:

```text
Save Swimmer no monitorea seguridad terrestre; informa eventos relevantes de entrada/salida del agua, actividad acuatico y ultima ubicacion disponible asociada al nado.
```

## Eventos De Seguridad Acuatica

Los eventos no deben clasificarse todos como SOS. Deben existir niveles de severidad para evitar alarmas innecesarias y para ordenar la respuesta.

Eventos base:

- entrada al agua
- inicio de sesion
- nado activo
- movimiento irregular
- ritmo/rotacion cae
- sin avance
- detencion en agua
- salida de geocerca
- tiempo objetivo excedido
- distancia objetivo no completada dentro del tiempo
- salida del agua en punto esperado
- salida del agua fuera del punto esperado
- sesion sin cierre confirmado
- senal perdida durante sesion
- SOS manual o automatico confirmado

Salida del agua fuera del punto esperado:

```text
sesion activa
+ sensor de agua cambia de mojado a seco
+ ubicacion/distancia indica alejamiento del punto de cierre/base
= incidencia de seguridad, no SOS automatico
```

Lectura para Coach:

```text
Atleta salio del agua fuera del punto esperado.
Distancia a base: X m.
Ultima ubicacion disponible: X.
Verificar estado.
```

Escalamiento sugerido:

```text
verde -> salida en punto esperado / cierre seguro
amarillo -> salida fuera del punto esperado / verificar
rojo -> salida fuera de punto + no confirma + sin senal o patron de riesgo previo
SOS -> emergencia confirmada o protocolo definido por modo
```

## Sesiones Por Tiempo O Distancia

Save Swimmer debe permitir programar objetivo de entrenamiento o competencia:

- tiempo objetivo
- distancia objetivo
- ruta/zona/geocerca
- nado libre

Ejemplo:

```text
Entrenamiento: 2 km o 30 min
Alerta si excede 30 min sin llegar/cerrar
Alerta si sale de geocerca
Alerta si se detiene o pierde avance
```

En competencia o entrenamiento grupal, esto permite identificar atletas fuera de tiempo sin depender de memoria humana o conteo visual.

Estados sugeridos:

- activo
- llego/cerrado seguro
- pendiente de cierre
- fuera de tiempo
- rezagado
- fuera de zona
- sin senal
- verificar
- alerta activa

## Control De Cierre De Sesion

En entrenamientos grupales y competencias, la sesion debe cerrarse conscientemente.

Motivo:

```text
Puede ocurrir que alguien asuma que un nadador ya salio o se fue, sin corroborarlo.
```

Regla:

```text
Si una sesion tiene duracion objetivo y un atleta no cerro o no fue confirmado,
la app debe generar una alerta de verificacion.
```

Escalamiento propuesto:

```text
tiempo cumplido -> aviso suave de cierre
+5 min -> alerta amarilla: atleta pendiente
+10 min + lejos/base o sin confirmacion -> alerta fuerte
+15 min + sin senal/sin cierre -> protocolo de busqueda/verificacion
```

Esto no reemplaza SOS. Cubre fallas de coordinacion humana.

## Coach Como App Monitor

La app Coach es una app monitor. No es centro de datos ni propietario del historial del atleta.

Debe permitir:

- ver mapa de atletas activos
- definir geocerca de entrenamiento grupal
- monitorear estados y alertas
- recibir alarmas fuertes cuando el coach es primer contacto
- ver rotacion/ritmo en vivo si el atleta lo habilito
- ver resumen compartido si el atleta lo autorizo
- confirmar asistencia/cierre seguro durante sesion

No debe permitir por defecto:

- descargar datos crudos completos del atleta
- ver historial privado no compartido
- modificar datos historicos del atleta
- pedir acceso invasivo desde la interfaz principal

Premisa:

```text
El atleta define que comparte.
El coach solo ve lo autorizado.
```

En nado grupal o entrenamiento con coach:

```text
El primer contacto ante una emergencia es el coach.
```

Por lo tanto, la app Coach debe tener alarma extremadamente visible, sonora y vibratoria para:

- SOS
- detencion prolongada
- salida de geocerca
- senal perdida en condicion critica
- tiempo excedido con cierre pendiente
- salida de agua fuera de punto esperado sin confirmacion

## Geocerca De Entrenamiento

En sesion con coach, el coach puede definir la geocerca del entrenamiento.

Flujo:

```text
Coach crea entrenamiento
-> define geocerca/punto base/tiempo/distancia
-> atletas se unen
-> atleta acepta compartir seguridad en vivo durante esa sesion
-> se aplica geocerca del coach
-> al terminar, la geocerca deja de aplicar
```

Esto reduce errores porque cada atleta no debe configurar su propia zona.

El atleta conserva control de datos fuera de esa sesion.

## Datos Compartibles

Los datos compartibles deben estar definidos como permisos, no como acceso libre del coach.

Categorias:

- seguridad basica: ubicacion, senal, agua/seco, geocerca, movimiento, SOS
- entrenamiento en vivo: seguridad basica + ritmo, rotacion dorsal, velocidad, tiempo
- resumen tecnico: promedios, alertas, graficos resumidos de sesion cerrada
- sesion completa: datos detallados, solo con autorizacion explicita del atleta

Datos posibles:

- ubicacion en vivo
- ultima ubicacion asociada al nado
- estado de senal
- estado agua/seco
- distancia a base
- geocerca
- tiempo de sesion
- distancia recorrida
- ritmo por 100 m
- velocidad GPS
- movimiento/detencion
- rotacion dorsal actual
- rotacion dorsal promedio
- simetria izquierda/derecha
- regularidad de brazada
- impulso/energia estimada
- alertas de ritmo
- alertas de detencion
- alertas de geocerca
- eventos SOS
- resumen de sesion
- historial de sesiones compartidas

## Validacion Actual

Estado al 2026-05-31:

- firmware de pruebas estable hasta **SS-LITE-BLE-SD-V1-044**
- app tecnica Android separada para campo: **Field Viewer BLE**
- app demo Android separada para vision comercial: **Nadador / Coach / Familia / Evento**
- campana StartFund aprobada y activa
- primeras validaciones de comunidad en grupos de aguas abiertas
- microSD ya registra sesiones largas validas, con marcadores de pausa #SD_GAP

Hallazgo tecnico actual:

```text
V044 permite obtener CSV trazable y util para analisis.
Todavia hay pausas de grabacion declaradas como #SD_GAP que deben reducirse.
```

Hallazgo de comunidad:

```text
La gente pide seguridad contextual en lenguaje simple:
ubicacion, geocerca, inmovilidad, sin avance, ritmo/velocidad, SOS e identificacion.
```

Primer formulario completo recibido:

```text
Participante de Cancun, Mexico, mas de 5 anos en aguas abiertas.
Entrena 2 a 3 veces por semana en mar y en grupo grande.
Asigna importancia 10/10 al monitoreo activo.
Valida perdida visual por oleaje/neblina, corrientes, desorientacion y falta de monitoreo real durante entrenamientos.
```

Tension comercial detectada:

```text
El usuario valora la seguridad, pero prefiere compra unica y precio menor a S/170.
Esto confirma que la membresia debe comunicarse como servicio activo de conectividad/seguridad,
no como simple pago extra por una app.
```

## Producto Principal

La version principal sera **Save Swimmer Lite**.

Motivo:

- la mayoria de usuarios nadan en forma local, cerca de costa/playa
- el producto debe ser compacto
- el precio debe ser accesible dentro del segmento
- no debe cargar costos de Pro que solo necesita una minoria

Referencia de precio objetivo Lite:

```text
S/600 - S/800 dispositivo
S/40 - S/50 membresia mensual
```

No es un limite obligatorio, pero es la base de evaluacion.

## Lineas De Producto

### Lite

Uso:

- nadadores locales
- entrenamiento en playa
- nado solitario cerca de costa
- familia / entrenador

Incluye:

- ESP32-S3 o equivalente
- IMU
- sensor de agua
- LTE/GPS
- BLE cercano
- luz de visibilidad 360 o casi 360
- bateria LiPo
- carga magnetica por contactos
- app
- historial basico
- alertas contextuales

No incluye:

- LoRa
- satelital
- Qi obligatorio
- pantalla

### Events

Uso:

- competencias
- organizadores
- monitoreo multi-atleta

Incluye:

- dashboard evento
- geocercos
- mapa operativo
- historial de evento
- posible infraestructura propia

LoRa solo podria tener sentido aqui si Save Swimmer o el organizador instala receptor/gateway.

### Pro

Uso:

- mar abierto extremo
- travesias
- expediciones
- usuarios premium

Incluye:

- LTE/GPS
- satelital futuro
- mayor bateria
- carcasa mas robusta
- posible Qi/carga inductiva
- membresia mayor

La version Pro puede ser mas grande que Lite.

## Comunicacion

LoRa queda eliminado de Lite y del flujo principal de entrenador.

Motivo:

- un celular comun no recibe LoRa
- requiere receptor/gateway fisico
- agrega friccion y soporte

Arquitectura Lite:

```text
Dispositivo -> LTE/GPS -> backend/app -> entrenador/familia/nadador
BLE -> cercania/configuracion/fin de sesion
```

### Sincronizacion De Sesiones Locales

La grabacion completa no debe depender de permanecer en rango Bluetooth.

Flujo requerido:

```text
celular cerca -> enviar perfil e iniciar sesion
nadador lejos de BLE -> dispositivo continua grabando localmente
nadador regresa -> app o PC reconecta
reconexion -> consultar estado de sesion
detener/cerrar archivo -> descargar sesion completa sin retirar memoria
```

Requisito para proxima version de firmware/app:

- comando BLE para consultar si existe sesion activa o cerrada
- listado de archivos/sesiones disponibles en almacenamiento local
- descarga por BLE del CSV completo al celular
- descarga por BLE desde viewer de PC
- confirmacion de integridad antes de marcar sesion como transferida
- evitar duplicar datos cuando la app registro solo una parte en vivo
- al conectar o reconectar, tomar del dispositivo el perfil asociado a la sesion
- no usar datos precargados en la app para nombrar o atribuir una sesion ya iniciada

Fuente de verdad durante una sesion:

```text
dispositivo / archivo local -> atleta, sesion, inicio y datos oficiales
app -> interfaz de configuracion y descarga, nunca debe reemplazar sin confirmacion el perfil activo
```

Riesgo detectado en prototipo:

```text
la app actual muestra Paula por defecto; si el dispositivo graba Vitto,
un respaldo local de app puede quedar con nombre incorrecto.
```

Implementacion de prueba incorporada:

```text
firmware SS-LITE-BLE-SD-V1-030 + app Field Viewer v0.3.12
-> PROFILE? y STATUS? al conectar/reconectar
-> edicion de perfil bloqueada mientras la sesion esta activa
-> modo laboratorio BLE apagado por defecto
```

Implementacion siguiente lista para prueba:

```text
firmware SS-LITE-BLE-SD-V1-031 + app Field Viewer v0.3.13
-> descargar ultima sesion cerrada desde la microSD al celular por BLE
-> transferencia en bloques confirmados
-> guardado en telefono solo si los bytes recibidos coinciden con el archivo oficial
```

La visualizacion BLE en vivo es apoyo operativo. El registro completo local es la fuente de datos para analisis cuando el nadador sale de rango.

LoRa:

```text
solo Events / base propia / infraestructura controlada
```

Satelital:

```text
solo Pro
```

## SIM / Conectividad

El dispositivo sera sellado IP68, por lo que el usuario no debe cambiar SIM.

Implicaciones:

- SIM/eSIM interna
- conectividad gestionada por Save Swimmer
- membresia obligatoria para conectividad remota
- soporte de activacion/suspension por pago
- evaluar proveedor nacional para Peru
- evaluar SIM internacional o multioperador para Travel/Pro futuro

La membresia debe cubrir no solo SIM/datos, sino toda la estructura de servicio.

## Membresia Lite

Referencia:

```text
S/40 - S/50 mensual
```

Debe cubrir:

- SIM/eSIM nacional
- datos compactos
- SMS SOS fallback si aplica
- backend
- base de datos
- almacenamiento de historial
- notificaciones
- web
- e-commerce
- panel administrativo
- app
- dashboard
- actualizaciones OTA
- mantenimiento firmware/app
- soporte tecnico
- pasarela de pago/comisiones
- margen empresa

Regla:

```text
El costo variable directo por usuario debe ser bastante menor que la membresia.
```

## Politica De Datos

No transmitir IMU cruda por LTE.

Transmitir:

- estado
- ubicacion
- agua
- movimiento
- ritmo
- accion sugerida
- bateria
- timestamp
- eventos importantes

Intervalos tentativos:

```text
sin sesion: casi nada
sesion normal: cada 30-60 s
alerta: inmediato
SOS: inmediato + reintentos
fin de sesion: resumen + reducir transmision
```

## IA / Interpretacion

La primera IA debe ser local y liviana:

- baseline del nadador
- ventanas moviles
- comparacion contra su propio patron
- deteccion de ritmo estable/baja/paro
- contexto agua + BLE
- geocerco

Costo mensual IA local:

```text
S/0
```

IA cloud avanzada:

- futura
- solo cuando existan datasets reales
- debe justificar costo mensual

## Primer Uso / Perfil De Nado

El usuario debe crear un perfil de nado.

Nombre sugerido:

```text
Primer nado de referencia
Crear perfil de nado
```

El dispositivo aprende:

- ritmo promedio
- periodicidad
- amplitud de movimiento
- estabilidad del ciclo
- comportamiento normal del nadador

Si no hay perfil:

```text
modo basico conservador
```

## Entrenador

El entrenador normalmente esta en playa y observa a sus alumnos desde tierra.

La vista principal debe ser:

- mapa del grupo
- alumnos activos
- colores por estado
- distancia a playa/base
- geocerco
- alerta si ritmo baja o se detiene
- ficha del atleta seleccionado
- lista plegable de alumnos con dispositivo

La app debe hablar en lenguaje humano:

- movimiento
- ritmo
- velocidad
- accion sugerida
- distancia a playa
- ultima seÃ±al

No en ejes crudos:

- LR
- FB
- UD
- MAG

Los datos crudos pueden quedar ocultos para modo tecnico.

Validacion externa:

```text
La comunidad ya pidio ritmo de brazada, velocidad y alertas simples como "sin avance".
```

## Familia

La vista Familia debe ser simple.

Usa contexto:

```text
agua + Bluetooth cercano
```

Estados:

```text
seco + BLE cerca -> en tierra / preparado
agua + BLE cerca -> cerca de playa / ingreso o regreso
agua + BLE lejos -> nadando
seco + BLE cerca -> salio del agua / finalizar
seco + BLE lejos -> standby / sin contexto cercano
```

La familia no necesita telemetria tecnica.

## SOS

SOS externo no debe dispararse por cualquier alerta.

Depende del modo:

```text
entrenamiento grupal -> entrenador decide
nado solitario -> red de confianza + escalamiento
mar abierto solitario -> SOS critico
evento -> centro de control / protocolo del evento
```

Niveles:

- monitorear
- observar
- contactar
- intervenir
- SOS pendiente
- SOS confirmado

Senales simples validadas por comunidad:

- nadador sin avance
- boya/dispositivo sin movimiento
- inmovilidad
- salida de geocerca
- patron anormal
- emergencia donde el nadador no alcanza a pedir ayuda

No prometer todavia:

```text
frecuencia cardiaca u oxigenacion como funcion Lite
```

Motivo:

- medicion confiable en agua abierta es mas compleja
- exige contacto optico o sensor adicional
- puede subir costo, consumo, carcasa y validacion

Clasificacion actual:

```text
Lite -> deteccion indirecta por movimiento, GPS, agua, geocerca e inmovilidad
Pro/futuro -> biometria si demuestra confiabilidad y valor
```

## Carga

Lite:

- carga magnetica por contactos/pogo pins
- contactos protegidos
- limpieza/secado antes de carga
- deteccion de humedad idealmente

Pro:

- Qi o carga inductiva posible
- mayor costo/tamano

## Luz De Visibilidad

La luz no debe ser solo decorativa en la parte superior. Debe ayudar a que el nadador sea visible desde playa, laterales, botes u otros nadadores.

Para Lite:

```text
luz perimetral o ventanas laterales difusas
visible 360 o casi 360
bajo consumo en modo normal
alta intensidad solo en alerta/SOS
```

Estados posibles:

```text
cyan lento -> sesion activa
verde -> cerca de playa / seguro
amarillo -> observar / bateria baja
rojo -> alerta
rojo/blanco intenso -> SOS
```

Control de consumo:

```text
de dia -> apagada o minima
amanecer/tarde -> pulso bajo
alerta/SOS -> maxima visibilidad
```

Para prototipo:

- probar 2 a 4 LEDs de alta eficiencia
- usar difusor o guia de luz simple
- medir consumo por modo
- evaluar visibilidad al amanecer/tarde
- evitar que la luz obligue a agrandar demasiado la carcasa

Clasificacion:

```text
CORE para Lite si se resuelve con bajo costo y bajo consumo
```

## Prototipo

El prototipo actual puede ser grande.

Objetivo:

- validar LTE/GPS
- validar IMU dorsal
- validar sensor de agua
- medir consumo
- medir tiempos de envio
- validar logica contextual
- probar en playa/agua

No busca ser compacto ni final.

Despues de validar:

- prototipo integrado
- PCB personalizada
- carcasa IP68
- antenas internas optimizadas

## Criterio De Decision

Cada idea debe evaluarse con:

```text
?Mejora seguridad real?
?Reduce falsos positivos?
?Mejora comunicacion/cobertura?
?Ayuda a vender membresia?
?Aumenta confianza?
?Es viable en IP68?
?Sube mucho el costo unitario?
?Sube mucho el costo mensual?
?Complica soporte?
?Debe ir en Lite, Events, Pro o descartarse?
```

Clasificacion:

```text
CORE -> necesario para Lite
VALIOSO -> aporta pero puede esperar
EVENTS -> institucional/eventos
PRO -> premium
DESCARTAR POR AHORA -> no justifica costo/complejidad
```
