EESchema Schematic File Version 4
LIBS:power
LIBS:device
LIBS:Connector_Generic
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
Sheet 1 1
Title "SAVE SWIMMER - PROTOTIPO ACTUAL V001"
Date "2026-06-08"
Rev "V001"
Comp "Save Swimmer"
Comment1 "Esquema modular para pruebas. NO enviar a fabricar."
Comment2 "I2C GPIO8/GPIO9 pendiente de confirmar fisicamente."
Comment3 "microSD alimentada a 5V segun pruebas actuales."
Comment4 "Firmware de referencia: SS-LITE-BLE-SD-V1-044"
$EndDescr
Text Notes 700 650 0    120  ~ 24
ENERGIA Y CARGA
Text Notes 4300 650 0    120  ~ 24
CONTROL Y SENSORES
Text Notes 700 4550 0    90   ~ 18
Flujo de energia actual: LiPo -> TP4056 protegido -> interruptor -> MT3608 ajustado a 5.0V -> ESP32-S3 + microSD
Text Notes 700 4800 0    70   ~ 14
ADVERTENCIA: verificar polaridad y ajustar MT3608 antes de conectar el ESP32. No cargar una bateria danada o usada sin supervision.
Text Notes 700 5050 0    70   ~ 14
C1 1000uF recomendado cerca de la carga de 5V. C2/C3 son ceramicos 104 = 100nF.
Text Notes 700 5300 0    70   ~ 14
El MPU6050 usa 3V3. El modulo microSD probado usa 5V por incluir regulador/conversion de nivel.
Text Notes 700 5550 0    70   ~ 14
GPIO SPI confirmados por firmware V044: CS=10, MOSI=11, SCK=12, MISO=13.
Text Notes 700 5800 0    70   ~ 14
I2C propuesto para documentacion: SDA=GPIO8, SCL=GPIO9. Confirmar cableado real antes de usar este plano como referencia.
$Comp
L Connector_Generic:Conn_01x02 BT1
U 1 1 1
P 1200 1400
F 0 "BT1" H 1118 1617 50  0000 C CNN
F 1 "BATERIA_LIPO_3V7" H 1118 1526 50 0000 C CNN
	1    1200 1400
	-1   0 0 -1
$EndComp
Wire Wire Line
	1400 1400 1700 1400
Wire Wire Line
	1400 1500 1700 1500
Text Label 1700 1400 0    50   ~ 0
BAT_RAW+
Text Label 1700 1500 0    50   ~ 0
GND
$Comp
L Connector_Generic:Conn_01x06 U1
U 1 1 2
P 2500 1500
F 0 "U1" H 2580 1492 50  0000 L CNN
F 1 "TP4056_PROTEGIDO" H 2580 1401 50 0000 L CNN
	1    2500 1500
	1    0 0 -1
$EndComp
Wire Wire Line
	2300 1300 2000 1300
Wire Wire Line
	2300 1400 2000 1400
Wire Wire Line
	2300 1500 2000 1500
Wire Wire Line
	2300 1600 2000 1600
Wire Wire Line
	2300 1700 2000 1700
Wire Wire Line
	2300 1800 2000 1800
Text Label 2000 1300 2    50   ~ 0
USB_5V_IN
Text Label 2000 1400 2    50   ~ 0
GND
Text Label 2000 1500 2    50   ~ 0
BAT_RAW+
Text Label 2000 1600 2    50   ~ 0
GND
Text Label 2000 1700 2    50   ~ 0
BAT_PROT+
Text Label 2000 1800 2    50   ~ 0
GND
Text Notes 2600 1300 0    45   ~ 0
1 IN+
Text Notes 2600 1400 0    45   ~ 0
2 IN-
Text Notes 2600 1500 0    45   ~ 0
3 B+
Text Notes 2600 1600 0    45   ~ 0
4 B-
Text Notes 2600 1700 0    45   ~ 0
5 OUT+
Text Notes 2600 1800 0    45   ~ 0
6 OUT-
$Comp
L Switch:SW_SPST SW1
U 1 1 3
P 1900 2350
F 0 "SW1" H 1900 2585 50 0000 C CNN
F 1 "INTERRUPTOR_GENERAL" H 1900 2494 50 0000 C CNN
	1    1900 2350
	1    0 0 -1
$EndComp
Wire Wire Line
	1700 2350 1400 2350
Wire Wire Line
	2100 2350 2400 2350
Text Label 1400 2350 2    50   ~ 0
BAT_PROT+
Text Label 2400 2350 0    50   ~ 0
BAT_SW+
$Comp
L Connector_Generic:Conn_01x04 U2
U 1 1 4
P 2500 2900
F 0 "U2" H 2580 2892 50 0000 L CNN
F 1 "MT3608_AJUSTADO_5V" H 2580 2801 50 0000 L CNN
	1    2500 2900
	1    0 0 -1
$EndComp
Wire Wire Line
	2300 2800 2000 2800
Wire Wire Line
	2300 2900 2000 2900
Wire Wire Line
	2300 3000 2000 3000
Wire Wire Line
	2300 3100 2000 3100
Text Label 2000 2800 2    50   ~ 0
BAT_SW+
Text Label 2000 2900 2    50   ~ 0
GND
Text Label 2000 3000 2    50   ~ 0
+5V_SYS
Text Label 2000 3100 2    50   ~ 0
GND
Text Notes 2600 2800 0    45   ~ 0
1 IN+
Text Notes 2600 2900 0    45   ~ 0
2 IN-
Text Notes 2600 3000 0    45   ~ 0
3 OUT+
Text Notes 2600 3100 0    45   ~ 0
4 OUT-
$Comp
L Device:C_Polarized C1
U 1 1 5
P 1200 3400
F 0 "C1" H 1318 3446 50 0000 L CNN
F 1 "1000uF_16V_RECOMENDADO" H 1318 3355 50 0000 L CNN
	1    1200 3400
	1    0 0 -1
$EndComp
Wire Wire Line
	1200 3250 1200 3150
Wire Wire Line
	1200 3550 1200 3650
Text Label 1200 3150 1    50   ~ 0
+5V_SYS
Text Label 1200 3650 3    50   ~ 0
GND
$Comp
L Device:C C2
U 1 1 6
P 3000 3400
F 0 "C2" H 3115 3446 50 0000 L CNN
F 1 "100nF_104" H 3115 3355 50 0000 L CNN
	1    3000 3400
	1    0 0 -1
$EndComp
Wire Wire Line
	3000 3250 3000 3150
Wire Wire Line
	3000 3550 3000 3650
Text Label 3000 3150 1    50   ~ 0
+5V_SYS
Text Label 3000 3650 3    50   ~ 0
GND
$Comp
L Connector_Generic:Conn_01x08 U3
U 1 1 7
P 5400 1700
F 0 "U3" H 5480 1692 50 0000 L CNN
F 1 "ESP32-S3_DEVKIT_N16R8" H 5480 1601 50 0000 L CNN
	1    5400 1700
	1    0 0 -1
$EndComp
Wire Wire Line
	5200 1400 4850 1400
Wire Wire Line
	5200 1500 4850 1500
Wire Wire Line
	5200 1600 4850 1600
Wire Wire Line
	5200 1700 4850 1700
Wire Wire Line
	5200 1800 4850 1800
Wire Wire Line
	5200 1900 4850 1900
Wire Wire Line
	5200 2000 4850 2000
Wire Wire Line
	5200 2100 4850 2100
Text Label 4850 1400 2    50   ~ 0
+5V_SYS
Text Label 4850 1500 2    50   ~ 0
GND
Text Label 4850 1600 2    50   ~ 0
+3V3
Text Label 4850 1700 2    50   ~ 0
I2C_SDA_GPIO8
Text Label 4850 1800 2    50   ~ 0
I2C_SCL_GPIO9
Text Label 4850 1900 2    50   ~ 0
SD_CS_GPIO10
Text Label 4850 2000 2    50   ~ 0
SD_MOSI_GPIO11
Text Label 4850 2100 2    50   ~ 0
SD_SCK_GPIO12
$Comp
L Connector_Generic:Conn_01x02 U3B
U 1 1 8
P 5400 2450
F 0 "U3B" H 5480 2442 50 0000 L CNN
F 1 "ESP32_CONTINUACION" H 5480 2351 50 0000 L CNN
	1    5400 2450
	1    0 0 -1
$EndComp
Wire Wire Line
	5200 2350 4850 2350
Wire Wire Line
	5200 2450 4850 2450
Text Label 4850 2350 2    50   ~ 0
SD_MISO_GPIO13
Text Label 4850 2450 2    50   ~ 0
GND
$Comp
L Connector_Generic:Conn_01x06 U4
U 1 1 9
P 7700 1650
F 0 "U4" H 7780 1642 50 0000 L CNN
F 1 "MPU6050_MODULO" H 7780 1551 50 0000 L CNN
	1    7700 1650
	1    0 0 -1
$EndComp
Wire Wire Line
	7500 1450 7100 1450
Wire Wire Line
	7500 1550 7100 1550
Wire Wire Line
	7500 1650 7100 1650
Wire Wire Line
	7500 1750 7100 1750
Wire Wire Line
	7500 1850 7100 1850
Wire Wire Line
	7500 1950 7100 1950
Text Label 7100 1450 2    50   ~ 0
+3V3
Text Label 7100 1550 2    50   ~ 0
GND
Text Label 7100 1650 2    50   ~ 0
I2C_SCL_GPIO9
Text Label 7100 1750 2    50   ~ 0
I2C_SDA_GPIO8
Text Label 7100 1850 2    50   ~ 0
GND
Text Label 7100 1950 2    50   ~ 0
MPU_INT_NC
Text Notes 7900 1450 0    45   ~ 0
VCC
Text Notes 7900 1550 0    45   ~ 0
GND
Text Notes 7900 1650 0    45   ~ 0
SCL
Text Notes 7900 1750 0    45   ~ 0
SDA
Text Notes 7900 1850 0    45   ~ 0
AD0=GND
Text Notes 7900 1950 0    45   ~ 0
INT no conectado
$Comp
L Device:C C3
U 1 1 10
P 6850 2450
F 0 "C3" H 6965 2496 50 0000 L CNN
F 1 "100nF_104" H 6965 2405 50 0000 L CNN
	1    6850 2450
	1    0 0 -1
$EndComp
Wire Wire Line
	6850 2300 6850 2200
Wire Wire Line
	6850 2600 6850 2700
Text Label 6850 2200 1    50   ~ 0
+3V3
Text Label 6850 2700 3    50   ~ 0
GND
$Comp
L Connector_Generic:Conn_01x06 U5
U 1 1 11
P 7700 3300
F 0 "U5" H 7780 3292 50 0000 L CNN
F 1 "MICROSD_SPI_CONVERSION_3V3" H 7780 3201 50 0000 L CNN
	1    7700 3300
	1    0 0 -1
$EndComp
Wire Wire Line
	7500 3100 7050 3100
Wire Wire Line
	7500 3200 7050 3200
Wire Wire Line
	7500 3300 7050 3300
Wire Wire Line
	7500 3400 7050 3400
Wire Wire Line
	7500 3500 7050 3500
Wire Wire Line
	7500 3600 7050 3600
Text Label 7050 3100 2    50   ~ 0
+5V_SYS
Text Label 7050 3200 2    50   ~ 0
GND
Text Label 7050 3300 2    50   ~ 0
SD_CS_GPIO10
Text Label 7050 3400 2    50   ~ 0
SD_MOSI_GPIO11
Text Label 7050 3500 2    50   ~ 0
SD_SCK_GPIO12
Text Label 7050 3600 2    50   ~ 0
SD_MISO_GPIO13
Text Notes 7900 3100 0    45   ~ 0
VCC 5V probado
Text Notes 7900 3200 0    45   ~ 0
GND
Text Notes 7900 3300 0    45   ~ 0
CS
Text Notes 7900 3400 0    45   ~ 0
MOSI
Text Notes 7900 3500 0    45   ~ 0
SCK
Text Notes 7900 3600 0    45   ~ 0
MISO
$Comp
L Connector_Generic:Conn_01x02 J1
U 1 1 12
P 1200 1950
F 0 "J1" H 1118 2167 50 0000 C CNN
F 1 "ENTRADA_CARGA_5V" H 1118 2076 50 0000 C CNN
	1    1200 1950
	-1   0 0 -1
$EndComp
Wire Wire Line
	1400 1950 1700 1950
Wire Wire Line
	1400 2050 1700 2050
Text Label 1700 1950 0    50   ~ 0
USB_5V_IN
Text Label 1700 2050 0    50   ~ 0
GND
Text Notes 4300 3150 0    80   ~ 16
CONEXIONES CONFIRMADAS
Text Notes 4300 3400 0    60   ~ 12
microSD SPI: GPIO10 CS / GPIO11 MOSI / GPIO12 SCK / GPIO13 MISO
Text Notes 4300 3600 0    60   ~ 12
MPU6050 detectado en direccion I2C 0x68
Text Notes 4300 3800 0    60   ~ 12
Alimentacion en pruebas de bateria: MT3608 = 5.06V; microSD conectada a 5V
Text Notes 4300 4000 0    60   ~ 12
BLE integrado en ESP32-S3; no requiere cableado adicional
$EndSCHEMATC
