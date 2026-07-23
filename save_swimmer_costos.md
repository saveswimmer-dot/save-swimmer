# Save Swimmer - Tabla De Costos

Valores referenciales para ordenar decisiones. No son precio final ni cotizacion cerrada.

## 1. Costo Por Unidad - Dispositivo Lite

| Rubro | Prototipo ladrillo | Prototipo integrado | Pre-serie | Producto final Lite | Notas |
|---|---:|---:|---:|---:|---|
| ESP32-S3 / MCU | S/0 - S/85 | S/50 - S/85 | S/35 - S/70 | S/25 - S/55 | Ya disponible para prototipo actual |
| IMU | S/0 - S/20 | S/10 - S/20 | S/8 - S/18 | S/5 - S/15 | MPU6050 u otra IMU |
| LTE/GPS | S/300 - S/560 | S/220 - S/450 | S/160 - S/320 | S/120 - S/260 | Rubro critico de costo |
| Antenas LTE/GNSS | S/0 - S/80 | S/30 - S/80 | S/20 - S/60 | S/15 - S/45 | Depende si vienen incluidas |
| Sensor de agua | S/5 - S/25 | S/10 - S/30 | S/8 - S/25 | S/5 - S/20 | Debe ser confiable en salitre |
| LEDs visibilidad + difusor | S/5 - S/35 | S/15 - S/60 | S/15 - S/50 | S/8 - S/35 | Luz 360/casi 360 bajo consumo |
| Bateria | S/30 - S/100 | S/40 - S/120 | S/35 - S/90 | S/25 - S/70 | LiPo plana final |
| Carga / proteccion | S/0 - S/40 | S/20 - S/70 | S/20 - S/55 | S/15 - S/45 | TP4056 disponible para prototipo |
| Regulacion energia | S/20 - S/60 | S/20 - S/70 | S/15 - S/50 | S/10 - S/35 | Picos LTE importantes |
| microSD / memoria | S/20 - S/50 | S/15 - S/45 | S/10 - S/35 | S/0 - S/25 | Puede ser desarrollo, no final |
| PCB / cables / conectores | S/30 - S/100 | S/80 - S/180 | S/60 - S/130 | S/35 - S/90 | PCB custom baja errores |
| Carcasa experimental/final | S/30 - S/100 | S/100 - S/250 | S/120 - S/280 | S/70 - S/180 | IP68 final sube costo |
| Sellado / juntas / adhesivos | S/10 - S/40 | S/30 - S/90 | S/25 - S/75 | S/15 - S/55 | Prueba salitre/agua |
| Cargador magnetico | S/12 - S/35 | S/15 - S/45 | S/15 - S/40 | S/10 - S/35 | Debe incluirse en kit |
| Cable USB-C | S/5 - S/12 | S/5 - S/12 | S/4 - S/10 | S/3 - S/8 | Si no viene integrado |
| Empaque | S/0 - S/25 | S/8 - S/35 | S/8 - S/30 | S/6 - S/25 | Caja + presentacion |
| Inserto / proteccion | S/0 - S/12 | S/3 - S/15 | S/3 - S/12 | S/2 - S/10 | Carton/espuma/molde |
| Manual / QR / etiquetas | S/1 - S/6 | S/2 - S/8 | S/1 - S/6 | S/1 - S/5 | Serial, QR, garantia |
| Ensamblaje | S/0 - S/80 | S/60 - S/150 | S/45 - S/120 | S/25 - S/90 | Depende volumen |
| Pruebas funcionales | S/0 - S/60 | S/40 - S/120 | S/40 - S/100 | S/25 - S/80 | LTE/GPS/IMU/carga |
| Prueba estanqueidad | S/0 - S/80 | S/50 - S/150 | S/50 - S/130 | S/30 - S/100 | Necesaria para IP68 |
| Activacion SIM/eSIM | S/0 - S/30 | S/5 - S/35 | S/5 - S/30 | S/3 - S/25 | Costo inicial por linea |
| Merma / garantia provision | S/0 - S/80 | S/50 - S/150 | S/50 - S/130 | S/35 - S/120 | Depende tasa de fallas |

### Total Referencial Por Fase

| Fase | Rango referencial |
|---|---:|
| Prototipo ladrillo | S/463 - S/1,640 |
| Prototipo integrado | S/903 - S/2,005 |
| Pre-serie | S/737 - S/1,620 |
| Producto final Lite | S/455 - S/1,293 |

Notas:

- El prototipo puede costar mas que el producto final.
- El rubro LTE/GPS domina el costo inicial.
- Producto final necesita PCB personalizada para bajar tamano, errores y costo.
- El precio objetivo S/600-S/800 es referencia, no limite.

## 2. Bloque Cargador + Presentacion

| Item | Rango prototipo/pre-serie | Rango producto final |
|---|---:|---:|
| Cargador magnetico pogo/contactos | S/12 - S/45 | S/10 - S/35 |
| Cable USB-C | S/5 - S/12 | S/3 - S/8 |
| Caja / empaque | S/8 - S/35 | S/6 - S/25 |
| Inserto/proteccion | S/3 - S/15 | S/2 - S/10 |
| Manual QR / tarjeta activacion | S/1 - S/6 | S/1 - S/5 |
| Etiqueta serial / garantia | S/0.50 - S/2 | S/0.50 - S/2 |

Total bloque:

```text
Prototipo/pre-serie: S/29.50 - S/115
Producto final: S/22.50 - S/85
```

## 3. Costo Mensual Por Usuario - Lite

| Rubro mensual | Rango objetivo | Notas |
|---|---:|---|
| SIM/eSIM datos | S/5 - S/15 | Negociar M2M/IoT |
| SMS SOS fallback | S/0 - S/5 | Solo eventos, no uso continuo |
| Backend/API | S/1 - S/5 | Depende usuarios activos |
| Base de datos | S/1 - S/5 | Historial limitado |
| Almacenamiento | S/0.50 - S/3 | No guardar IMU cruda indefinidamente |
| Notificaciones push/email | S/0.50 - S/3 | SMS aparte |
| Web/e-commerce/admin | S/1 - S/5 | Costo fijo prorrateado |
| Pasarela de pagos/comisiones | S/1 - S/4 | Depende plataforma |
| Soporte/operacion | S/3 - S/10 | Debe monitorearse |
| Mantenimiento app/firmware | S/2 - S/8 | Prorrateado |
| Margen empresa | variable | Debe quedar despues de costos |

### Membresia Lite Referencial

```text
S/40 - S/50 mensual
```

Regla:

```text
El costo variable directo ideal deberia mantenerse debajo de S/15 - S/20 por usuario/mes.
```

## 4. Clasificacion De Decisiones Por Costo/Valor

| Elemento | Lite | Events | Pro | Comentario |
|---|---|---|---|---|
| LTE/GPS | CORE | CORE | CORE | Comunicacion publica principal |
| BLE | CORE | CORE | CORE | Cercania/configuracion |
| LoRa | No | Opcional | No principal | Requiere gateway fisico |
| Satelital | No | No principal | CORE | Membresia alta |
| Qi | No inicial | No | Valioso | Sube tamano/costo |
| Carga magnetica | CORE | CORE | Opcional | Mejor para Lite |
| Sensor agua | CORE | CORE | CORE | Reduce falsos SOS |
| Luz visibilidad 360 | CORE | CORE | CORE | Seguridad amanecer/tarde; controlar consumo |
| IA local basica | CORE | CORE | CORE | No sube hardware |
| IA cloud avanzada | Futuro | Valioso | Valioso | Costo mensual |
| Pantalla | No | No | No inicial | Poco valor dorsal |
| microSD | Desarrollo | Opcional | Opcional | Puede no ir en final |

## 5. Recuperacion De Inversion Inicial

Los costos de prototipo, pruebas, compras fallidas, herramientas y desarrollo inicial deben recuperarse con la venta de dispositivos y/o membresias.

Esta inversion no forma parte del costo directo de cada unidad final, pero debe recuperarse porque sale del bolsillo del fundador.

### Rubros De Inversion Inicial

| Rubro | Monto estimado | Notas |
|---|---:|---|
| Prototipos electronicos | por completar | ESP32, LTE/GPS, sensores, baterias |
| Carcasas experimentales | por completar | cajas, impresiones, sellado |
| Herramientas | por completar | soldador, multimetro, insumos |
| Pruebas de campo | por completar | movilidad, playa, SIMs, reposiciones |
| Software/prototipos app | por completar | tiempo propio o terceros |
| Compras descartadas | por completar | modulos que no queden en final |
| Branding/presentacion | por completar | imagen, empaque piloto |
| Total inversion inicial | por completar | suma general |

### Recuperacion Via Hardware

Formula:

```text
unidades_para_recuperar = inversion_inicial / margen_neto_por_dispositivo
```

Ejemplo:

| Inversion inicial | Margen neto por dispositivo | Unidades para recuperar |
|---:|---:|---:|
| S/5,000 | S/100 | 50 |
| S/5,000 | S/150 | 34 |
| S/5,000 | S/200 | 25 |
| S/10,000 | S/100 | 100 |
| S/10,000 | S/150 | 67 |
| S/10,000 | S/200 | 50 |
| S/20,000 | S/100 | 200 |
| S/20,000 | S/150 | 134 |
| S/20,000 | S/200 | 100 |

### Recuperacion Via Membresia

Formula:

```text
meses_usuario_para_recuperar = inversion_inicial / margen_mensual_por_usuario
```

Ejemplo con membresia de S/45:

| Costo variable mensual | Margen mensual usuario |
|---:|---:|
| S/10 | S/35 |
| S/15 | S/30 |
| S/20 | S/25 |

Ejemplo:

| Inversion inicial | Margen mensual usuario | Usuarios activos | Meses para recuperar |
|---:|---:|---:|---:|
| S/10,000 | S/30 | 100 | 3.4 |
| S/10,000 | S/30 | 50 | 6.7 |
| S/10,000 | S/30 | 25 | 13.4 |
| S/20,000 | S/30 | 100 | 6.7 |
| S/20,000 | S/30 | 50 | 13.4 |
| S/20,000 | S/30 | 25 | 26.7 |

### Estrategia Recomendada

No cargar toda la recuperacion de prototipo al primer lote si eso vuelve invendible el dispositivo.

Separar:

```text
1. margen del dispositivo
2. margen mensual de membresia
3. recuperacion gradual de I+D
```

Ejemplo:

```text
S/80 - S/150 de margen por dispositivo
+ S/20 - S/30 de margen mensual por usuario
= recuperacion gradual sin matar precio inicial
```

### Regla De Decision

Si una mejora sube mucho el costo del prototipo pero no reduce riesgo tecnico ni aumenta valor comercial claro, debe esperar.

Priorizar inversion que responda preguntas criticas:

- LTE/GPS funciona en playa/agua
- antena interna es viable
- sensor de agua reduce falsos positivos
- IMU dorsal detecta patrones utiles
- bateria alcanza duracion minima
- app justifica membresia
