/*
====================================================
SAVE SWIMMER
FIRMWARE: SS-LITE-BLE-SD-V1-052
DEVICE: SS-LT-000001
====================================================
ESP32-S3 + MPU6050 + INA219 + GPS + BLE + MICROSD + SERIAL JSON
Compatible con Save Swimmer Field Viewer Android
====================================================

CHANGELOG V1-052:
- Agrega diagnostico #TIME_GAP cuando el muestreo se atrasa durante una sesion.
- Registra fila previa, siguiente fila, gap en ms y hora local dentro del CSV.
- Agrega conteo de gaps y gap maximo al cierre de sesion.
- Ayuda a distinguir salto de datos, pausa de loop, SD/BLE o bloqueo temporal.

BASE V1-051:
- Integra modulo RGB HW-479 como indicador visual de estado.
- Usa GPIO 4/5/6 para R/G/B con pulsos no bloqueantes.
- Indica arranque, BLE, GPS/listo, grabacion, error SD/sensor y alerta.
- Pensado para prototipo; en version final debe ir con difusor visible 360.

BASE V1-050:
- GPS BLE alternado para mapa en vivo y resumen SD.
- Mantiene GPS/INA219/microSD/BLE con paquetes ultracortos.

CHANGELOG V1-047:
- Integra GPS NEO-M9N/GY-GPS6MV2 por UART1 a 38400 baudios.
- Registra fix, satelites, HDOP, latitud, longitud, velocidad y edad del fix.
- Agrega datos GPS al CSV crudo, resumen rapido y Serial JSON.
- Mantiene BLE ultracorto para movimiento; ubicacion queda en SD/resumen.

BASE V1-046:
- Prioriza continuidad de muestreo: elimina readback/remontaje despues de cada lote correcto.
- La validacion fuerte del CSV crudo se realiza al cerrar la sesion.
- Genera archivo resumen SMxxxxxx.CSV con una muestra representativa cada 5 segundos.
- Permite descargar resumen rapido o CSV crudo completo por comandos BLE separados.

BASE V1-045:
- Integra monitor de energia INA219 en el bus I2C compartido con MPU6050.
- Registra voltaje de carga, corriente y potencia en Serial JSON y microSD.
- Lee energia cada segundo para no interferir con MPU6050, BLE ni microSD.
- Conserva el paquete BLE ultracorto y la estabilidad SD de V044.

BASE V1-044:
- Verifica que el archivo crezca despues de cada flush SD.
- Si el lote no aparece en el archivo, conserva buffer y reintenta sin cortar sesion.
- Si el crecimiento es parcial, detiene por seguridad para no duplicar datos.

BASE V1-043:
- Baja el lote SD a 1 segundo para reducir perdida por fallo de escritura.
- Reduce buffer reservado y limite pendiente para reaccionar antes.
- Mantiene marcadores #SD_GAP/#SD_RESUME de V042.

BASE V1-042:
- Evita saltos numericos de fila durante recuperacion SD.
- Si hay buffer pendiente por fallo SD, pausa nuevas filas hasta persistirlo.
- Registra eventos #SD_GAP/#SD_RESUME en el CSV para analisis posterior.

BASE V1-041:
- No corta la sesion por fallo puntual al abrir lote SD.
- Conserva el buffer en RAM, remonta microSD y reintenta en el siguiente flush.
- Agrega diagnostico de fallos SD y tamano de buffer pendiente en STATUS?.

BASE V1-040:
- Registro SD conservador: flush cada 2 segundos para evitar bloques grandes.
- Durante grabacion no envia confirmacion BLE por cada lote SD.
- Reduce carga de Serial JSON mientras la microSD esta grabando.

BASE V1-039:
- Cierre limpio multi-atleta: limpia estado interno al cerrar sesion.
- Cancela transferencia BLE pendiente antes de nueva sesion/perfil.
- Remonta microSD al iniciar cada nueva sesion para evitar reiniciar ESP entre atletas.

BASE V1-038:
- No aborta la sesion por readback intermedio de tamano de archivo.
- Durante la sesion valida write/flush; la validacion fuerte queda para cierre.
- Mantiene CSV y bloque de 10 segundos para reducir escrituras.
- Reporta CHECKPOINT=WRITE_FLUSH_OK y BYTES_BEFORE/EXPECTED_BYTES.

CHANGELOG V1-037:
- Reduce bloqueos visibles: escribe microSD cada 10 segundos.
- Pausa telemetria BLE y Serial durante escritura/verificacion SD.
- Agrega metricas FLUSH_COUNT, FLUSH_MS y BUFFER_BYTES.
- No agrega GPS, temperatura ni vibrador; version enfocada solo en estabilidad SD.

CHANGELOG V1-036:
- Reduce accesos SD: escribe y confirma lotes cada 3 segundos.
- Si el readback inmediato falla, espera y relee antes de abortar la sesion.
- Como ultima verificacion remonta la microSD sin reescribir ni duplicar filas.

CHANGELOG V1-035:
- Conserva el ultimo motivo de detencion SD durante la ejecucion.
- Al reiniciar, detecta si la ultima sesion quedo sin cierre validado.
- STATUS? informa ultimo evento y motivo de reset para diagnostico en la app.

CHANGELOG V1-034:
- Escribe cada lote SD abriendo, cerrando y releyendo el archivo.
- No mantiene un stream abierto durante toda la sesion.
- Confirma el crecimiento real del archivo antes de reportar filas aseguradas.

CHANGELOG V1-033:
- Fuerza checkpoint fisico microSD cada 1 segundo durante pruebas.
- Informa filas confirmadas y bytes del lote, sin confundir lote con archivo total.
- Registra la causa de reinicio del ESP en Serial y BOOT.CSV.
- Cierra el stream y reabre el archivo para escribir/verificar el marcador final.

CHANGELOG V1-032:
- Agrega marca #END_SESSION al detener correctamente una sesion.
- Valida que todas las filas tengan columnas completas antes de confirmar guardado.
- Informa CLEAN=YES/NO al cerrar y al descargar una sesion.
- Construye cada fila completa antes de agregarla al buffer SD.

CHANGELOG V1-031:
- Permite descargar la ultima sesion cerrada de la microSD por BLE.
- Transfiere CSV por bloques confirmados para evitar perdida silenciosa.
- Pausa telemetria en vivo durante la descarga para priorizar integridad.

CHANGELOG V1-030:
- Responde PROFILE? para que la app recupere el atleta real al reconectar.
- Responde STATUS? indicando si la sesion continua activa y en que archivo.
- Rechaza cambio de perfil mientras una sesion se encuentra grabando.

CHANGELOG V1-029:
- No desmonta una SD que ya fue validada al iniciar el dispositivo.
- Solo intenta remontar la tarjeta si el arranque no la dejo disponible.
- Distingue SD_BOOT_NOT_READY de SD_RECOVERY_FAILED en la app/Serial.

CHANGELOG V1-028:
- Mantiene el CSV abierto durante la sesion y lo cierra solamente al detener.
- Reduce operaciones FAT de abrir/cerrar que podian cortar grabaciones largas.
- Baja SPI SD a 1 MHz para mejorar tolerancia al cableado del prototipo.
- Sincroniza el archivo cada 3 segundos para limitar perdida ante apagado.

CHANGELOG V1-027:
- Agrega /INDEX.CSV como contador persistente de sesiones en microSD.
- No reutiliza SS000001.CSV si la sesion anterior fue renombrada o retirada.
- INDEX.CSV es archivo de sistema del dispositivo y no debe borrarse.

CHANGELOG V1-026:
- Aplica al reloj interno del ESP la fecha/hora recibida desde el celular.
- Los CSV de sesion se crean con fecha FAT real, no 01/01/1980.
- BOOT.CSV puede mantener fecha inicial porque se escribe antes de sincronizar BLE.

CHANGELOG V1-025:
- Vuelve a lotes SD pequenos de 1 segundo: V024 fallo con el primer lote grande.
- Si falla la apertura de un lote, remonta SD y reintenta hasta dos veces.
- Reserva memoria del buffer para reducir fragmentacion durante la sesion.

CHANGELOG V1-023:
- Reinicializa el bus y montaje microSD al comenzar cada nueva sesion.
- Permite recuperacion despues de una sesion cerrada o tarjeta reinsertada.
- Mantiene muestreo 10 Hz y escritura estable por lotes de 1 segundo.

CHANGELOG V1-022:
- Conserva muestreo a 10 Hz, pero acumula filas en RAM y escribe SD cada 1 segundo.
- Evita abrir/cerrar/releer la tarjeta diez veces por segundo.
- Al detener, guarda cualquier lote pendiente antes de cerrar sesion.

CHANGELOG V1-021:
- La sesion escribe con archivos locales abrir-escribir-cerrar, igual que BOOT.CSV.
- Evita mantener un File global abierto entre telemetria BLE y escritura SD.
- Reporta bytes reales del encabezado y de las filas ya persistidas.

CHANGELOG V1-020:
- Crea el CSV de sesion con FILE_APPEND, igual que BOOT.CSV validado.
- Corrige archivos SS00000X.CSV creados en cero bytes con FILE_WRITE.

CHANGELOG V1-019:
- Procesa START/STOP de sesion en loop(), fuera del callback BLE.
- Agrega prueba /BOOT.CSV antes de iniciar BLE para diagnosticar SD integrada.
- Permite separar falla de hardware SD de conflicto durante la orden Bluetooth.

CHANGELOG V1-018:
- Reemplaza SD.exists() por verificacion real abriendo y leyendo el CSV.
- Evita falso FILE_NOT_CREATED aunque la tarjeta haya escrito correctamente.
- Selecciona nuevo nombre corto comprobando archivos mediante lectura.

CHANGELOG V1-017:
- Cambia nombre de archivo a formato FAT corto 8.3: SS000001.CSV.
- Evita fallo FILE_NOT_CREATED observado con nombres largos por fecha/atleta.
- La fecha y el perfil permanecen dentro del encabezado CSV.

CHANGELOG V1-016:
- Verifica fisicamente la creacion del CSV antes de confirmar inicio a la app.
- Confirma escritura SD cada segundo con filas grabadas.
- Al detener informa filas y bytes guardados en la tarjeta.
- Cierra/reabre el archivo periodicamente para reducir perdida por apagado o retiro accidental.

CHANGELOG V1-015:
- Integra microSD con SPI probado: CS 10, MOSI 11, SCK 12, MISO 13.
- No graba al encender: inicia/detiene sesion por comando BLE desde la app.
- La app envia fecha/hora del telefono por BLE; no depende de WiFi/NTP en playa.
- CSV por sesion con perfil, serial, firmware y telemetria real MPU6050.

CHANGELOG V1-014:
- Config BLE acepta WRITE y WRITE_NR para mejorar compatibilidad Android.

CHANGELOG V1-013:
- Config BLE mas estable: caracteristica separada para escritura.
- Desactiva Preferences temporalmente para evitar reinicio en loop.
- Mantiene perfil en RAM durante la prueba.

CHANGELOG V1-012:
- BLE bidireccional: la app puede enviar perfil de usuario.
- Guarda USER/AGE/HEIGHT/WEIGHT/MODE en memoria interna Preferences.
- Responde por BLE/Serial con confirmacion de configuracion.

CHANGELOG V1-011:
- Agrega diagnostico I2C para detectar MPU6050 en 0x68/0x69.
- Imprime aviso si el BLE funciona pero el sensor no entrega datos.

CHANGELOG V1-010:
- Paquete BLE ultracorto A:LR,FB,UD,MAG para Web Bluetooth y APK Android.
- Compatible con Save Swimmer Field Viewer Android.
- Blynk desactivado para pruebas sin consumo de cupo.
- Salida Serial JSON conservada para laboratorio.

Notas:
- Blynk queda fuera de esta version para no consumir cupo.
- La app web lee BLE en tiempo real desde Chrome/Edge.
- Serial Studio puede leer el JSON por USB.
*/

#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include <time.h>
#include <sys/time.h>

#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <esp_system.h>

// ====================================================
// DEVICE INFO
// ====================================================

#define DEVICE_SERIAL "SS-LT-000001"
#define FIRMWARE_VERSION "SS-LITE-BLE-SD-V1-052"

// ====================================================
// SAVE SWIMMER BLE UUIDS
// Deben coincidir con save_swimmer_ble_viewer.html
// ====================================================

#define SS_SERVICE_UUID           "8f1c1000-5a7e-4b3d-9c21-a10000000001"
#define SS_TELEMETRY_CHAR_UUID    "8f1c1001-5a7e-4b3d-9c21-a10000000001"
#define SS_CONFIG_CHAR_UUID       "8f1c1002-5a7e-4b3d-9c21-a10000000001"

// ====================================================
// TIMING
// ====================================================

#define SAMPLE_RATE_MS 100
#define BLE_SEND_MS 500
#define SERIAL_SEND_MS 100
#define SD_WRITE_MS 1000
#define SD_BUFFER_RESERVE_BYTES 2000
#define SD_MAX_PENDING_BYTES 8000
#define SD_VERIFY_ATTEMPTS 3
#define SD_VERIFY_DELAY_MS 100
#define SD_SPI_HZ 1000000
#define FILE_CHUNK_BYTES 120
#define FILE_ACK_TIMEOUT_MS 1200
#define POWER_SAMPLE_MS 1000
#define SUMMARY_SAMPLE_MS 5000
#define SUMMARY_WRITE_MS 30000
#define SAMPLE_GAP_WARN_MS 400

// ====================================================
// GPS UART CONFIG
// Confirmado con SS-GPS-TEST-V002:
// GPS BAUD LOCKED: 38400
// ====================================================

#define GPS_RX_PIN 17
#define GPS_TX_PIN 18
#define GPS_BAUD 38400

// ====================================================
// RGB STATUS LED - HW-479 / KY-016
// Pin "-" del modulo a GND. Pines R/G/B a GPIO.
// El modulo HW-479 suele traer resistencias integradas.
// ====================================================

#define RGB_ENABLED true
#define RGB_COMMON_CATHODE true
#define RGB_R_PIN 4
#define RGB_G_PIN 5
#define RGB_B_PIN 6
#define RGB_PULSE_MS 80

// ====================================================
// INA219 CONFIG
// Modulo tipico con shunt de 0.1 ohm:
// corriente maxima medible aproximada 3.2 A.
// ====================================================

#define INA219_ADDRESS 0x40
#define INA219_REG_CONFIG 0x00
#define INA219_REG_SHUNT_VOLTAGE 0x01
#define INA219_REG_BUS_VOLTAGE 0x02
#define INA219_REG_POWER 0x03
#define INA219_REG_CURRENT 0x04
#define INA219_REG_CALIBRATION 0x05
#define INA219_CALIBRATION_VALUE 4096
#define INA219_CONFIG_VALUE 0x399F

// ====================================================
// OPTIONAL I2C PINS
// Si tu placa necesita pines especificos, cambia aqui.
// Si no, deja -1 para usar Wire.begin() normal.
// ====================================================

#define I2C_SDA_PIN -1
#define I2C_SCL_PIN -1

// ====================================================
// MICROSD SPI PINS
// Conexion confirmada con SS-MICROSD-TEST-V001.
// ====================================================

#define SD_CS   10
#define SD_MOSI 11
#define SD_SCK  12
#define SD_MISO 13

// ====================================================
// OBJECTS
// ====================================================

Adafruit_MPU6050 mpu;
SPIClass sdSPI(FSPI);
File transferFile;
HardwareSerial gpsSerial(1);

BLECharacteristic *pCharacteristic = nullptr;
BLECharacteristic *pConfigCharacteristic = nullptr;
bool deviceConnected = false;
bool sdReady = false;
bool sessionRecording = false;
bool sessionStartRequested = false;
bool sessionStopRequested = false;
bool downloadLastRequested = false;
bool downloadSummaryRequested = false;
bool fileTransferActive = false;
bool fileTransferWaitingAck = false;
bool sdFlushActive = false;

// ====================================================
// SYSTEM STATUS
// ====================================================

String SYSTEM_STATE = "READY";
String WATER_STATE = "NO";      // placeholder hasta agregar sensor de agua
String BODY_STATE = "UNKNOWN";
String MOTION_STATE = "UNKNOWN";
String RISK_STATE = "NORMAL";
String USER_NAME = "SIN_USUARIO";
String USER_MODE = "TEST";
String SESSION_FILE = "";
String SUMMARY_FILE = "";
String pendingSessionPayload = "";
String transferFileName = "";
String transferLastPayload = "";
String LAST_SESSION_EVENT = "NONE";
String LAST_SESSION_FILE = "";
String LAST_SUMMARY_FILE = "";

int BATTERY_LEVEL = 100;        // placeholder hasta medir bateria real
int RISK_SCORE = 0;
int USER_AGE = 0;
float USER_HEIGHT = 0;
float USER_WEIGHT = 0;

// ====================================================
// SENSOR VALUES
// ====================================================

float LR = 0;       // X
float FB = 0;       // Y
float UD = 0;       // Z
float MAG = 0;
float TIME_S = 0;

float PITCH = 0;
float ROLL = 0;

float POWER_BUS_V = 0;
float POWER_SHUNT_MV = 0;
float POWER_INPUT_V = 0;
float POWER_LOAD_V = 0;
float POWER_CURRENT_MA = 0;
float POWER_MW = 0;

String gpsNmeaLine = "";
String GPS_UTC = "NO_TIME";
String GPS_FIX_QUALITY = "0";
String GPS_SATELLITES = "0";
String GPS_HDOP = "0";
String GPS_STATUS = "NO_FIX";
float GPS_LAT = 0;
float GPS_LON = 0;
float GPS_SPEED_KMH = 0;
float GPS_COURSE = 0;
bool gpsHasFix = false;
unsigned long gpsLines = 0;
unsigned long gpsValidLines = 0;
unsigned long lastGpsByteMs = 0;
unsigned long lastGpsFixMs = 0;

// Cambia estos signos si al probar ves ejes invertidos.
// Objetivo conceptual:
// LR+ derecha del nadador
// FB+ hacia cabeza/frente
// UD+ fuera de la espalda / hacia superficie
const float LR_SIGN = 1.0;
const float FB_SIGN = 1.0;
const float UD_SIGN = 1.0;

unsigned long lastSample = 0;
unsigned long lastBleSend = 0;
unsigned long lastSerialSend = 0;
unsigned long lastPowerSample = 0;
unsigned long lastSessionSampleMs = 0;
unsigned long sampleGapCount = 0;
unsigned long maxSampleGapMs = 0;
bool bleSendGpsNext = false;
unsigned long lastSdFlush = 0;
unsigned long lastSummarySample = 0;
unsigned long lastSummaryFlush = 0;
unsigned long sessionStartMillis = 0;
unsigned long sessionStartEpoch = 0;
long sessionTimezoneOffset = -18000;
unsigned long sessionRow = 0;
unsigned long streamedSessionRows = 0;
unsigned long savedSessionRows = 0;
unsigned long transferFileBytes = 0;
unsigned long transferBytesConfirmed = 0;
unsigned long transferSequence = 0;
unsigned long transferLastSend = 0;
unsigned long sdFlushCount = 0;
unsigned long lastSdFlushDurationMs = 0;
unsigned long maxSdFlushDurationMs = 0;
unsigned long sdFlushFailCount = 0;
unsigned long lastSdFailureMs = 0;
unsigned long sdPausedSamples = 0;
unsigned long sdPauseStartedMs = 0;
bool sdRecoveryPause = false;
bool sdRecoveryMarkerPending = false;
size_t transferLastChunkBytes = 0;
String sdWriteBuffer = "";
String summaryWriteBuffer = "";

bool mpuReady = false;
bool ina219Ready = false;
unsigned long lastMpuWarning = 0;
String RESET_REASON = "UNKNOWN";

// Movimiento simple para prototipo
float magBaseline = 9.81;
float magDeltaFiltered = 0;
unsigned long lastMovementMs = 0;

// ====================================================
// RGB STATUS LED
// ====================================================

unsigned long lastRgbUpdate = 0;
bool rgbPulseOn = false;

void writeRgbPin(int pin, bool on) {
  if (!RGB_ENABLED) {
    return;
  }

  if (RGB_COMMON_CATHODE) {
    digitalWrite(pin, on ? HIGH : LOW);
  } else {
    digitalWrite(pin, on ? LOW : HIGH);
  }
}

void setRgbColor(bool red, bool green, bool blue) {
  if (!RGB_ENABLED) {
    return;
  }

  writeRgbPin(RGB_R_PIN, red);
  writeRgbPin(RGB_G_PIN, green);
  writeRgbPin(RGB_B_PIN, blue);
}

void setupRgbLed() {
  if (!RGB_ENABLED) {
    return;
  }

  pinMode(RGB_R_PIN, OUTPUT);
  pinMode(RGB_G_PIN, OUTPUT);
  pinMode(RGB_B_PIN, OUTPUT);
  setRgbColor(false, false, false);

  // Pulso corto de arranque para confirmar cableado.
  setRgbColor(false, true, true);
  delay(120);
  setRgbColor(false, false, false);
}

bool rgbPulse(unsigned long now, unsigned long periodMs, unsigned long onMs) {
  unsigned long phase = now % periodMs;
  return phase < onMs;
}

void applyRgbState(bool red, bool green, bool blue, bool on) {
  if (on) {
    setRgbColor(red, green, blue);
  } else {
    setRgbColor(false, false, false);
  }
}

void updateRgbLed() {
  if (!RGB_ENABLED) {
    return;
  }

  unsigned long now = millis();
  if (now - lastRgbUpdate < 25) {
    return;
  }
  lastRgbUpdate = now;

  bool sensorOrSdError = !mpuReady || SYSTEM_STATE == "SD_ERROR";
  bool sdUnavailable = !sdReady && !sessionRecording;
  bool activeAlert = RISK_STATE != "NORMAL" || RISK_SCORE >= 70;

  if (activeAlert) {
    // Rojo rapido: prioridad maxima.
    applyRgbState(true, false, false, rgbPulse(now, 300, 120));
    return;
  }

  if (sensorOrSdError) {
    // Rojo lento: revisar hardware/sensor/SD.
    applyRgbState(true, false, false, rgbPulse(now, 1200, RGB_PULSE_MS));
    return;
  }

  if (sdUnavailable) {
    // Naranja: sistema vivo, pero SD no lista para grabar.
    applyRgbState(true, true, false, rgbPulse(now, 1500, RGB_PULSE_MS));
    return;
  }

  if (sessionRecording) {
    // Cian: grabando datos.
    applyRgbState(false, true, true, rgbPulse(now, 900, RGB_PULSE_MS));
    return;
  }

  if (fileTransferActive) {
    // Blanco: transfiriendo archivo/resumen por BLE.
    applyRgbState(true, true, true, rgbPulse(now, 450, 90));
    return;
  }

  if (deviceConnected) {
    // Violeta: conectado por BLE, listo para comandos.
    applyRgbState(true, false, true, rgbPulse(now, 1600, RGB_PULSE_MS));
    return;
  }

  if (gpsHasFix && sdReady && mpuReady) {
    // Verde: listo con GPS/sensor/SD.
    applyRgbState(false, true, false, rgbPulse(now, 2200, RGB_PULSE_MS));
    return;
  }

  // Azul: encendido, esperando GPS/BLE/inicio.
  applyRgbState(false, false, true, rgbPulse(now, 2200, RGB_PULSE_MS));
}

// ====================================================
// BLE CALLBACKS
// ====================================================

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("BLE DEVICE CONNECTED");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    if (fileTransferActive) {
      if (transferFile) {
        transferFile.close();
      }
      fileTransferActive = false;
      fileTransferWaitingAck = false;
      Serial.println("FILE TRANSFER CANCELLED - BLE DISCONNECTED");
    }
    Serial.println("BLE DEVICE DISCONNECTED");
    BLEDevice::startAdvertising();
    Serial.println("BLE ADVERTISING RESTARTED");
  }
};

String getFieldValue(const String& payload, const String& key) {
  String token = key + "=";
  int start = payload.indexOf(token);
  if (start < 0) {
    return "";
  }

  start += token.length();
  int end = payload.indexOf(';', start);
  if (end < 0) {
    end = payload.length();
  }

  String value = payload.substring(start, end);
  value.trim();
  return value;
}

String csvSafe(String value) {
  value.replace(",", " ");
  value.replace("\n", " ");
  value.replace("\r", " ");
  value.trim();
  return value;
}

String getCsvField(const String& line, int index) {
  int current = 0;
  int start = 0;
  for (int i = 0; i <= line.length(); i++) {
    if (i == line.length() || line.charAt(i) == ',') {
      if (current == index) {
        return line.substring(start, i);
      }
      current++;
      start = i + 1;
    }
  }
  return "";
}

float nmeaCoordToDecimal(const String& raw, const String& hemisphere) {
  int dot = raw.indexOf('.');
  if (dot < 0) {
    return 0.0;
  }

  int degDigits = dot > 4 ? 3 : 2;
  float degrees = raw.substring(0, degDigits).toFloat();
  float minutes = raw.substring(degDigits).toFloat();
  float decimal = degrees + (minutes / 60.0);

  if (hemisphere == "S" || hemisphere == "W") {
    decimal *= -1.0;
  }

  return decimal;
}

String fileSafe(String value) {
  value.trim();
  value.replace(" ", "_");
  String safe = "";
  for (unsigned int i = 0; i < value.length(); i++) {
    char c = value.charAt(i);
    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
        (c >= '0' && c <= '9') || c == '_' || c == '-') {
      safe += c;
    }
  }
  if (safe.length() == 0) {
    safe = "USUARIO";
  }
  if (safe.length() > 16) {
    safe = safe.substring(0, 16);
  }
  return safe;
}

void notifyApp(const String& message) {
  Serial.println(message);
  if (deviceConnected && pCharacteristic != nullptr) {
    pCharacteristic->setValue(message.c_str());
    pCharacteristic->notify();
  }
  if (deviceConnected && pConfigCharacteristic != nullptr) {
    pConfigCharacteristic->setValue(message.c_str());
  }
}

void notifyFileChunk(const String& message) {
  if (deviceConnected && pCharacteristic != nullptr) {
    pCharacteristic->setValue(message.c_str());
    pCharacteristic->notify();
  }
}

String currentSessionDateTime(bool filenameFormat) {
  unsigned long elapsedSeconds = 0;
  if (sessionStartMillis > 0) {
    elapsedSeconds = (millis() - sessionStartMillis) / 1000UL;
  }

  time_t localEpoch = (time_t)(sessionStartEpoch + elapsedSeconds + sessionTimezoneOffset);
  struct tm timeinfo;
  gmtime_r(&localEpoch, &timeinfo);

  char result[25];
  strftime(result, sizeof(result), filenameFormat ? "%Y%m%d_%H%M%S" : "%Y-%m-%d %H:%M:%S", &timeinfo);
  return String(result);
}

void syncEspClockFromPhone() {
  struct timeval clockValue;
  clockValue.tv_sec = (time_t) sessionStartEpoch;
  clockValue.tv_usec = 0;
  settimeofday(&clockValue, nullptr);

  // Peru permanece en UTC-5 para estas pruebas. El offset tambien queda
  // guardado por sesion para representar hora local dentro del CSV.
  setenv("TZ", "<-05>5", 1);
  tzset();

  Serial.print("ESP CLOCK SYNCED FROM PHONE: ");
  Serial.println(currentSessionDateTime(false));
}

bool fileReadable(const String& path) {
  File file = SD.open(path.c_str(), FILE_READ);
  if (!file) {
    return false;
  }
  file.close();
  return true;
}

unsigned long readableFileSize(const String& path) {
  File file = SD.open(path.c_str(), FILE_READ);
  if (!file) {
    return 0;
  }
  unsigned long bytes = file.size();
  file.close();
  return bytes;
}

bool verifySessionHeader(const String& path, unsigned long& bytes) {
  File file = SD.open(path.c_str(), FILE_READ);
  if (!file) {
    bytes = 0;
    return false;
  }
  bytes = file.size();
  String firstLine = file.readStringUntil('\n');
  firstLine.trim();
  file.close();
  return bytes > 0 && firstLine == "#SAVE_SWIMMER_SD_SESSION";
}

bool validateClosedSession(const String& path, unsigned long& dataRows) {
  File file = SD.open(path.c_str(), FILE_READ);
  if (!file) {
    return false;
  }

  bool hasEndMarker = false;
  bool rowsValid = true;
  dataRows = 0;
  while (file.available()) {
    String line = file.readStringUntil('\n');
    line.trim();
    if (line.length() == 0) {
      continue;
    }
    if (line.startsWith("#END_SESSION;")) {
      hasEndMarker = true;
      continue;
    }
    if (line.charAt(0) >= '0' && line.charAt(0) <= '9') {
      int commas = 0;
      for (unsigned int i = 0; i < line.length(); i++) {
        if (line.charAt(i) == ',') {
          commas++;
        }
      }
      // V044 usa 12 columnas; V045/V046 agregan energia; V047 agrega GPS.
      // Acepta formatos anteriores para validar sesiones historicas.
      if (commas != 11 && commas != 14 && commas != 23) {
        rowsValid = false;
      } else {
        dataRows++;
      }
    }
  }
  file.close();
  return hasEndMarker && rowsValid;
}

String resetReasonText(esp_reset_reason_t reason) {
  switch (reason) {
    case ESP_RST_POWERON: return "POWERON";
    case ESP_RST_EXT: return "EXTERNAL_PIN";
    case ESP_RST_SW: return "SOFTWARE";
    case ESP_RST_PANIC: return "PANIC";
    case ESP_RST_INT_WDT: return "INTERRUPT_WATCHDOG";
    case ESP_RST_TASK_WDT: return "TASK_WATCHDOG";
    case ESP_RST_WDT: return "OTHER_WATCHDOG";
    case ESP_RST_DEEPSLEEP: return "DEEP_SLEEP";
    case ESP_RST_BROWNOUT: return "BROWNOUT_POWER_DROP";
    case ESP_RST_SDIO: return "SDIO";
    default: return "UNKNOWN";
  }
}

bool runSdBootDiagnostic() {
  const char* path = "/BOOT.CSV";
  File boot = SD.open(path, FILE_APPEND);
  if (!boot) {
    Serial.println("SD BOOT WRITE FAILED: OPEN");
    return false;
  }

  boot.print(FIRMWARE_VERSION);
  boot.print(",");
  boot.print(millis());
  boot.print(",RESET=");
  boot.println(RESET_REASON);
  boot.flush();
  boot.close();

  File check = SD.open(path, FILE_READ);
  if (!check) {
    Serial.println("SD BOOT WRITE FAILED: READBACK");
    return false;
  }
  unsigned long bytes = check.size();
  check.close();

  Serial.print("SD BOOT WRITE OK;FILE=/BOOT.CSV;BYTES=");
  Serial.println(bytes);
  return bytes > 0;
}

bool remountSdForSession(bool force = false) {
  if (sessionRecording && !force) {
    return true;
  }

  for (int attempt = 1; attempt <= 3; attempt++) {
    SD.end();
    sdSPI.end();
    delay(120);
    pinMode(SD_CS, OUTPUT);
    digitalWrite(SD_CS, HIGH);
    delay(20);
    sdSPI.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);

    if (SD.begin(SD_CS, sdSPI, SD_SPI_HZ)) {
      sdReady = true;
      Serial.print("SD SESSION REMOUNT OK;ATTEMPT=");
      Serial.println(attempt);
      return true;
    }

    Serial.print("SD SESSION REMOUNT FAILED;ATTEMPT=");
    Serial.println(attempt);
    delay(180);
  }

  sdReady = false;
  return false;
}

unsigned long readSessionIndex() {
  File indexFile = SD.open("/INDEX.CSV", FILE_READ);
  if (!indexFile) {
    Serial.println("SD INDEX NOT FOUND - STARTING NEW COUNTER");
    return 0;
  }

  unsigned long lastValue = 0;
  while (indexFile.available()) {
    String line = indexFile.readStringUntil('\n');
    line.trim();
    if (line.length() == 0 || line.startsWith("#")) {
      continue;
    }
    unsigned long value = (unsigned long) line.toInt();
    if (value > lastValue) {
      lastValue = value;
    }
  }
  indexFile.close();
  Serial.print("SD INDEX LAST SESSION: ");
  Serial.println(lastValue);
  return lastValue;
}

bool storeSessionIndex(unsigned long sessionNumber) {
  File indexFile = SD.open("/INDEX.CSV", FILE_APPEND);
  if (!indexFile) {
    Serial.println("SD INDEX WRITE FAILED");
    return false;
  }

  if (indexFile.size() == 0) {
    indexFile.println("#SAVE_SWIMMER_SESSION_INDEX");
  }
  indexFile.println(sessionNumber);
  indexFile.flush();
  indexFile.close();
  Serial.print("SD INDEX UPDATED: ");
  Serial.println(sessionNumber);
  return true;
}

String createSessionFilename(unsigned long& reservedNumber) {
  // Usa contador persistente para no reutilizar nombres aunque se retiren sesiones.
  unsigned long candidateNumber = readSessionIndex() + 1;
  char filename[14];
  while (candidateNumber <= 999999UL) {
    snprintf(filename, sizeof(filename), "/SS%06lu.CSV", candidateNumber);
    if (!fileReadable(String(filename))) {
      reservedNumber = candidateNumber;
      return String(filename);
    }
    candidateNumber++;
  }
  reservedNumber = 0;
  return "";
}

String summaryFilenameForNumber(unsigned long sessionNumber) {
  char filename[14];
  snprintf(filename, sizeof(filename), "/SM%06lu.CSV", sessionNumber);
  return String(filename);
}

String latestSessionFilename() {
  unsigned long lastNumber = readSessionIndex();
  if (lastNumber == 0) {
    return "";
  }

  char filename[14];
  snprintf(filename, sizeof(filename), "/SS%06lu.CSV", lastNumber);
  String path = String(filename);
  return fileReadable(path) ? path : "";
}

String latestSummaryFilename() {
  unsigned long lastNumber = readSessionIndex();
  if (lastNumber == 0) {
    return "";
  }

  String path = summaryFilenameForNumber(lastNumber);
  return fileReadable(path) ? path : "";
}

void setLastSessionEvent(const String& event, const String& file = "") {
  LAST_SESSION_EVENT = event;
  if (file.length() > 0) {
    LAST_SESSION_FILE = file;
  }
  Serial.print("LAST SESSION EVENT: ");
  Serial.print(LAST_SESSION_EVENT);
  if (LAST_SESSION_FILE.length() > 0) {
    Serial.print(";FILE=");
    Serial.print(LAST_SESSION_FILE);
  }
  Serial.println();
}

void recoverLastSessionStateAfterBoot() {
  String latestFile = latestSessionFilename();
  if (latestFile.length() == 0) {
    return;
  }

  unsigned long validatedRows = 0;
  bool clean = validateClosedSession(latestFile, validatedRows);
  LAST_SESSION_FILE = latestFile;
  LAST_SUMMARY_FILE = latestSummaryFilename();
  savedSessionRows = validatedRows;

  if (!clean) {
    setLastSessionEvent("RECOVERED_INCOMPLETE_AFTER_BOOT", latestFile);
    Serial.print("INCOMPLETE SESSION FOUND AFTER RESET;RESET=");
    Serial.println(RESET_REASON);
  } else {
    setLastSessionEvent("LAST_FILE_CLOSED_OK", latestFile);
  }
}

void cancelFileTransfer() {
  if (transferFile) {
    transferFile.close();
  }
  fileTransferActive = false;
  fileTransferWaitingAck = false;
  transferFileName = "";
  transferLastPayload = "";
  transferFileBytes = 0;
  transferBytesConfirmed = 0;
  transferSequence = 0;
  transferLastChunkBytes = 0;
}

void resetIdleSessionRuntime(const String& lastFile = "") {
  if (lastFile.length() > 0) {
    LAST_SESSION_FILE = lastFile;
  }

  SESSION_FILE = "";
  SUMMARY_FILE = "";
  pendingSessionPayload = "";
  sessionStartRequested = false;
  sessionStopRequested = false;
  downloadLastRequested = false;
  downloadSummaryRequested = false;
  sdFlushActive = false;
  sdWriteBuffer = "";
  sdWriteBuffer.reserve(SD_BUFFER_RESERVE_BYTES);
  summaryWriteBuffer = "";
  summaryWriteBuffer.reserve(1600);
  SYSTEM_STATE = "READY";
}

void beginFileTransfer(const String& requestedFile, bool validateRawSession) {
  if (sessionRecording) {
    notifyApp("FILE:ERROR;REASON=SESSION_ACTIVE_STOP_FIRST");
    return;
  }
  if (!sdReady) {
    notifyApp("FILE:ERROR;REASON=SD_NOT_READY");
    return;
  }

  cancelFileTransfer();
  transferFileName = requestedFile;
  if (transferFileName.length() == 0) {
    notifyApp("FILE:ERROR;REASON=NO_SESSION_FILE");
    return;
  }

  unsigned long validatedRows = 0;
  bool clean = validateRawSession ? validateClosedSession(transferFileName, validatedRows) : true;
  transferFileBytes = readableFileSize(transferFileName);

  transferFile = SD.open(transferFileName.c_str(), FILE_READ);
  if (!transferFile) {
    notifyApp("FILE:ERROR;REASON=OPEN_FAILED");
    cancelFileTransfer();
    return;
  }

  transferBytesConfirmed = 0;
  transferSequence = 0;
  fileTransferWaitingAck = false;
  fileTransferActive = true;

  notifyApp(String("FILE:BEGIN;NAME=") + transferFileName +
    ";BYTES=" + String(transferFileBytes) +
    ";CLEAN=" + String(clean ? "YES" : "NO") +
    ";ROWS=" + String(validatedRows));
}

void beginLatestFileTransfer() {
  beginFileTransfer(latestSessionFilename(), true);
}

void beginLatestSummaryTransfer() {
  beginFileTransfer(latestSummaryFilename(), false);
}

void serviceFileTransfer() {
  if (!fileTransferActive || !deviceConnected) {
    return;
  }

  if (fileTransferWaitingAck) {
    if (millis() - transferLastSend >= FILE_ACK_TIMEOUT_MS) {
      notifyFileChunk(transferLastPayload);
      transferLastSend = millis();
      Serial.print("FILE CHUNK RETRY;SEQ=");
      Serial.println(transferSequence);
    }
    return;
  }

  if (!transferFile.available()) {
    transferFile.close();
    notifyApp(String("FILE:END;NAME=") + transferFileName +
      ";BYTES=" + String(transferBytesConfirmed) +
      ";CHUNKS=" + String(transferSequence));
    fileTransferActive = false;
    transferFileName = "";
    return;
  }

  char buffer[FILE_CHUNK_BYTES];
  size_t count = transferFile.read((uint8_t*) buffer, FILE_CHUNK_BYTES);
  if (count == 0) {
    notifyApp("FILE:ERROR;REASON=READ_FAILED");
    cancelFileTransfer();
    return;
  }

  String content = "";
  content.reserve(count);
  for (size_t i = 0; i < count; i++) {
    content += buffer[i];
  }

  transferSequence++;
  transferLastChunkBytes = count;
  transferLastPayload = String("FILE:DATA;SEQ=") + String(transferSequence) + ";" + content;
  notifyFileChunk(transferLastPayload);
  fileTransferWaitingAck = true;
  transferLastSend = millis();
}

bool beginSession(const String& payload) {
  cancelFileTransfer();
  downloadLastRequested = false;
  sessionStartRequested = false;

  if (!sessionRecording) {
    Serial.println("SD SESSION START: USING CURRENT SD MOUNT FIRST");
  }

  if (!sdReady) {
    Serial.println("SD NOT READY AT SESSION START - RECOVERY ATTEMPT");
    if (!remountSdForSession(true)) {
      notifyApp("SESSION:ERROR;REASON=SD_SESSION_REMOUNT_FAILED");
      return false;
    }
    if (!runSdBootDiagnostic()) {
      sdReady = false;
      notifyApp("SESSION:ERROR;REASON=SD_BOOT_NOT_READY");
      return false;
    }
  }
  if (!mpuReady) {
    notifyApp("SESSION:ERROR;REASON=SENSOR_NOT_READY");
    return false;
  }
  if (USER_NAME == "SIN_USUARIO") {
    notifyApp("SESSION:ERROR;REASON=SEND_PROFILE_FIRST");
    return false;
  }
  if (sessionRecording) {
    notifyApp(String("SESSION:ALREADY_RECORDING;FILE=") + SESSION_FILE);
    return true;
  }

  String epoch = getFieldValue(payload, "EPOCH");
  String offset = getFieldValue(payload, "OFFSET");
  if (epoch.length() == 0) {
    notifyApp("SESSION:ERROR;REASON=NO_PHONE_TIME");
    return false;
  }

  sessionStartEpoch = (unsigned long) epoch.toInt();
  if (offset.length() > 0) {
    sessionTimezoneOffset = offset.toInt();
  }
  sessionStartMillis = millis();
  syncEspClockFromPhone();
  sessionRow = 0;
  streamedSessionRows = 0;
  savedSessionRows = 0;
  sdFlushCount = 0;
  lastSdFlushDurationMs = 0;
  maxSdFlushDurationMs = 0;
  sdFlushFailCount = 0;
  lastSdFailureMs = 0;
  sdPausedSamples = 0;
  sdPauseStartedMs = 0;
  lastSessionSampleMs = 0;
  sampleGapCount = 0;
  maxSampleGapMs = 0;
  sdRecoveryPause = false;
  sdRecoveryMarkerPending = false;
  LAST_SESSION_EVENT = "STARTING";
  LAST_SESSION_FILE = "";
  sdWriteBuffer = "";
  sdWriteBuffer.reserve(SD_BUFFER_RESERVE_BYTES);
  summaryWriteBuffer = "";
  summaryWriteBuffer.reserve(1600);
  lastSdFlush = millis();
  lastSummarySample = millis();
  lastSummaryFlush = millis();
  unsigned long sessionNumber = 0;
  SESSION_FILE = createSessionFilename(sessionNumber);
  if (SESSION_FILE.length() == 0) {
    setLastSessionEvent("NO_FILENAME_AVAILABLE");
    notifyApp("SESSION:ERROR;REASON=NO_FILENAME_AVAILABLE");
    return false;
  }
  LAST_SESSION_FILE = SESSION_FILE;
  SUMMARY_FILE = summaryFilenameForNumber(sessionNumber);
  LAST_SUMMARY_FILE = SUMMARY_FILE;

  // Usa la misma estrategia local que BOOT.CSV, ya validada en la tarjeta.
  File headerFile = SD.open(SESSION_FILE.c_str(), FILE_APPEND);
  if (!headerFile) {
    setLastSessionEvent("FILE_OPEN_FAILED", SESSION_FILE);
    SESSION_FILE = "";
    notifyApp("SESSION:ERROR;REASON=FILE_OPEN_FAILED");
    return false;
  }

  headerFile.println("#SAVE_SWIMMER_SD_SESSION");
  headerFile.print("#serial,"); headerFile.println(DEVICE_SERIAL);
  headerFile.print("#firmware,"); headerFile.println(FIRMWARE_VERSION);
  headerFile.print("#user,"); headerFile.println(csvSafe(USER_NAME));
  headerFile.print("#age,"); headerFile.println(USER_AGE);
  headerFile.print("#height_m,"); headerFile.println(USER_HEIGHT, 2);
  headerFile.print("#weight_kg,"); headerFile.println(USER_WEIGHT, 2);
  headerFile.print("#mode,"); headerFile.println(csvSafe(USER_MODE));
  headerFile.print("#start_local,"); headerFile.println(currentSessionDateTime(false));
  headerFile.print("#file_id,"); headerFile.println(SESSION_FILE);
  headerFile.println("row,elapsed_s,local_time,lr,fb,ud,mag,pitch,roll,body,motion,risk,load_v,current_ma,power_mw,gps_status,gps_fix,gps_sats,gps_hdop,gps_lat,gps_lon,gps_speed_kmh,gps_course,gps_age_ms");
  headerFile.flush();
  headerFile.close();

  if (fileReadable(SUMMARY_FILE)) {
    SD.remove(SUMMARY_FILE.c_str());
  }
  File summaryHeader = SD.open(SUMMARY_FILE.c_str(), FILE_APPEND);
  if (!summaryHeader) {
    setLastSessionEvent("SUMMARY_OPEN_FAILED", SUMMARY_FILE);
    SESSION_FILE = "";
    SUMMARY_FILE = "";
    notifyApp("SESSION:ERROR;REASON=SUMMARY_OPEN_FAILED");
    return false;
  }
  summaryHeader.println("#SAVE_SWIMMER_SESSION_SUMMARY");
  summaryHeader.print("#source_file,"); summaryHeader.println(SESSION_FILE);
  summaryHeader.print("#serial,"); summaryHeader.println(DEVICE_SERIAL);
  summaryHeader.print("#firmware,"); summaryHeader.println(FIRMWARE_VERSION);
  summaryHeader.print("#user,"); summaryHeader.println(csvSafe(USER_NAME));
  summaryHeader.print("#start_local,"); summaryHeader.println(currentSessionDateTime(false));
  summaryHeader.println("elapsed_s,local_time,lr,fb,ud,mag,pitch,roll,body,motion,risk,load_v,current_ma,power_mw,gps_status,gps_fix,gps_sats,gps_hdop,gps_lat,gps_lon,gps_speed_kmh,gps_course,gps_age_ms");
  summaryHeader.flush();
  summaryHeader.close();

  unsigned long initialBytes = 0;
  if (!verifySessionHeader(SESSION_FILE, initialBytes)) {
    setLastSessionEvent("FILE_READBACK_FAILED", SESSION_FILE);
    SESSION_FILE = "";
    notifyApp("SESSION:ERROR;REASON=FILE_READBACK_FAILED");
    return false;
  }

  if (!storeSessionIndex(sessionNumber)) {
    setLastSessionEvent("INDEX_WRITE_FAILED", SESSION_FILE);
    notifyApp("SESSION:ERROR;REASON=INDEX_WRITE_FAILED");
    return false;
  }

  sessionRecording = true;
  setLastSessionEvent("RECORDING", SESSION_FILE);
  SYSTEM_STATE = "RECORDING";
  Serial.print("SD SESSION HEADER VERIFIED;FILE=");
  Serial.print(SESSION_FILE);
  Serial.print(";BYTES=");
  Serial.println(initialBytes);
  notifyApp(String("SESSION:STARTED;SD=VERIFIED;FILE=") + SESSION_FILE +
    ";BYTES=" + String(initialBytes) + ";USER=" + USER_NAME);
  return true;
}

void endSession() {
  if (!sessionRecording) {
    notifyApp("SESSION:NOT_RECORDING");
    return;
  }

  notifyApp(String("SESSION:CLOSING;ROWS=") + String(sessionRow) +
    ";BUFFER_BYTES=" + String(sdWriteBuffer.length()) +
    ";SUMMARY_BYTES=" + String(summaryWriteBuffer.length()));

  bool rawFlushed = false;
  for (int attempt = 1; attempt <= 3; attempt++) {
    if (flushSessionBuffer() && sdWriteBuffer.length() == 0) {
      rawFlushed = true;
      break;
    }
    Serial.print("SESSION FINAL FLUSH RETRY;ATTEMPT=");
    Serial.print(attempt);
    Serial.print(";BUFFER_BYTES=");
    Serial.println(sdWriteBuffer.length());
    remountSdForSession(true);
    delay(120);
  }
  if (!rawFlushed) {
    notifyApp(String("SESSION:ERROR;REASON=FINAL_FLUSH_FAILED;BUFFER_BYTES=") +
      String(sdWriteBuffer.length()));
    return;
  }

  bool summaryFlushed = false;
  for (int attempt = 1; attempt <= 3; attempt++) {
    if (flushSummaryBuffer() && summaryWriteBuffer.length() == 0) {
      summaryFlushed = true;
      break;
    }
    Serial.print("SUMMARY FINAL FLUSH RETRY;ATTEMPT=");
    Serial.print(attempt);
    Serial.print(";BUFFER_BYTES=");
    Serial.println(summaryWriteBuffer.length());
    remountSdForSession(true);
    delay(120);
  }
  if (!summaryFlushed) {
    notifyApp("SESSION:ERROR;REASON=SUMMARY_FLUSH_FAILED");
    return;
  }

  savedSessionRows = sessionRow;
  sessionRecording = false;
  SYSTEM_STATE = "READY";
  String closedSessionFile = SESSION_FILE;

  String footer = String("\n#END_SESSION;ROWS=") + String(savedSessionRows) +
    ";CLOSED_LOCAL=" + currentSessionDateTime(false) +
    ";TIME_GAPS=" + String(sampleGapCount) +
    ";MAX_GAP_MS=" + String(maxSampleGapMs) + "\n";
  File footerFile = SD.open(closedSessionFile.c_str(), FILE_APPEND);
  bool footerWritten = false;
  if (footerFile) {
    size_t footerExpected = footer.length();
    size_t footerBytes = footerFile.print(footer);
    footerFile.flush();
    footerFile.close();
    footerWritten = footerBytes == footerExpected;
  }

  unsigned long fileSize = readableFileSize(closedSessionFile);
  unsigned long validatedRows = savedSessionRows;
  bool clean = footerWritten;

  File summaryFooter = SD.open(SUMMARY_FILE.c_str(), FILE_APPEND);
  bool summaryClosed = false;
  if (summaryFooter) {
    String summaryEnd = String("#END_SUMMARY;SOURCE_ROWS=") + String(savedSessionRows) +
      ";CLOSED_LOCAL=" + currentSessionDateTime(false) + "\n";
    summaryClosed = summaryFooter.print(summaryEnd) == summaryEnd.length();
    summaryFooter.flush();
    summaryFooter.close();
  }
  unsigned long summaryBytes = readableFileSize(SUMMARY_FILE);
  if (summaryClosed) {
    clean = clean && true;
  }
  setLastSessionEvent(clean ? "CLOSED_OK_FAST" : "CLOSE_FOOTER_FAILED", closedSessionFile);

  notifyApp(String("SESSION:STOPPED;SD=SAVED;FILE=") + closedSessionFile +
    ";ROWS=" + String(savedSessionRows) + ";BYTES=" + String(fileSize) +
    ";CLEAN=" + String(clean ? "YES" : "NO") +
    ";VALID_ROWS=" + String(validatedRows) +
    ";FOOTER=" + String(footerWritten ? "WRITTEN" : "FAILED") +
    ";SUMMARY=" + SUMMARY_FILE +
    ";SUMMARY_BYTES=" + String(summaryBytes) +
    ";SUMMARY_CLEAN=" + String(summaryClosed ? "YES" : "NO") +
    ";TIME_GAPS=" + String(sampleGapCount) +
    ";MAX_GAP_MS=" + String(maxSampleGapMs) +
    ";FLUSH_COUNT=" + String(sdFlushCount) +
    ";FLUSH_MAX_MS=" + String(maxSdFlushDurationMs));

  resetIdleSessionRuntime(closedSessionFile);
}

bool flushSessionBuffer() {
  if (sdWriteBuffer.length() == 0) {
    return true;
  }

  sdFlushActive = true;
  unsigned long flushStartedMs = millis();
  size_t expected = sdWriteBuffer.length();
  File batchFile = SD.open(SESSION_FILE.c_str(), FILE_APPEND);
  if (!batchFile) {
    sdFlushActive = false;
    sdFlushFailCount++;
    lastSdFailureMs = millis();
    sdRecoveryPause = true;
    if (sdPauseStartedMs == 0) {
      sdPauseStartedMs = millis();
    }
    setLastSessionEvent("BATCH_OPEN_FAILED", SESSION_FILE);
    Serial.print("SESSION:SD_RETRY;REASON=BATCH_OPEN_FAILED;FAILS=");
    Serial.print(sdFlushFailCount);
    Serial.print(";BUFFER_BYTES=");
    Serial.println(sdWriteBuffer.length());
    remountSdForSession(true);
    lastSdFlush = millis();
    return false;
  }

  size_t written = batchFile.print(sdWriteBuffer);
  batchFile.flush();
  batchFile.close();
  if (written != expected) {
    sdFlushActive = false;
    sessionRecording = false;
    SYSTEM_STATE = "SD_ERROR";
    setLastSessionEvent("BATCH_PARTIAL_WRITE", SESSION_FILE);
    notifyApp(String("SESSION:ERROR;REASON=BATCH_PARTIAL_WRITE;EXPECTED=") +
      String(expected) + ";WRITTEN=" + String(written));
    return false;
  }

  bool recoveredPause = sdRecoveryPause;
  unsigned long pausedSamples = sdPausedSamples;
  unsigned long pausedMs = sdPauseStartedMs > 0 ? millis() - sdPauseStartedMs : 0;

  streamedSessionRows = sessionRow;
  sdWriteBuffer = "";
  if (recoveredPause && pausedSamples > 0) {
    sdWriteBuffer += "#SD_GAP;PAUSED_SAMPLES=";
    sdWriteBuffer += String(pausedSamples);
    sdWriteBuffer += ";PAUSED_MS=";
    sdWriteBuffer += String(pausedMs);
    sdWriteBuffer += ";ROWS_CONTINUE_FROM=";
    sdWriteBuffer += String(sessionRow + 1);
    sdWriteBuffer += "\n";
    sdWriteBuffer += "#SD_RESUME;LOCAL=";
    sdWriteBuffer += currentSessionDateTime(false);
    sdWriteBuffer += "\n";
    sdRecoveryMarkerPending = true;
  }
  sdRecoveryPause = false;
  sdPausedSamples = 0;
  sdPauseStartedMs = 0;
  savedSessionRows = streamedSessionRows;
  sdFlushCount++;
  lastSdFlushDurationMs = millis() - flushStartedMs;
  if (lastSdFlushDurationMs > maxSdFlushDurationMs) {
    maxSdFlushDurationMs = lastSdFlushDurationMs;
  }
  sdFlushActive = false;
  String ack = String("SESSION:SD_WRITE;ROWS=") + String(savedSessionRows) +
    ";CONFIRMED_ROWS=" + String(savedSessionRows) +
    ";CHECKPOINT=WRITE_COUNT_OK;BATCH_BYTES=" + String(written) +
    ";FLUSH_COUNT=" + String(sdFlushCount) +
    ";FLUSH_MS=" + String(lastSdFlushDurationMs) +
    ";FLUSH_MAX_MS=" + String(maxSdFlushDurationMs);
  Serial.println(ack);
  return true;
}

void appendGpsCsvFields(String& row) {
  unsigned long gpsAgeMs = lastGpsFixMs > 0 ? millis() - lastGpsFixMs : 0;
  row += ",";
  row += GPS_STATUS;
  row += ",";
  row += String(gpsHasFix ? 1 : 0);
  row += ",";
  row += GPS_SATELLITES;
  row += ",";
  row += GPS_HDOP;
  row += ",";
  row += String(GPS_LAT, 6);
  row += ",";
  row += String(GPS_LON, 6);
  row += ",";
  row += String(GPS_SPEED_KMH, 2);
  row += ",";
  row += String(GPS_COURSE, 1);
  row += ",";
  row += String(gpsAgeMs);
}

bool flushSummaryBuffer() {
  if (summaryWriteBuffer.length() == 0) {
    return true;
  }

  File summaryFile = SD.open(SUMMARY_FILE.c_str(), FILE_APPEND);
  if (!summaryFile) {
    Serial.println("SUMMARY WRITE DEFERRED: OPEN_FAILED");
    return false;
  }

  size_t expected = summaryWriteBuffer.length();
  size_t written = summaryFile.print(summaryWriteBuffer);
  summaryFile.flush();
  summaryFile.close();
  if (written != expected) {
    Serial.print("SUMMARY WRITE DEFERRED: PARTIAL;EXPECTED=");
    Serial.print(expected);
    Serial.print(";WRITTEN=");
    Serial.println(written);
    return false;
  }

  summaryWriteBuffer = "";
  lastSummaryFlush = millis();
  return true;
}

void writeSummarySample() {
  if (!sessionRecording || millis() - lastSummarySample < SUMMARY_SAMPLE_MS) {
    return;
  }

  lastSummarySample = millis();
  summaryWriteBuffer += String((millis() - sessionStartMillis) / 1000.0, 2);
  summaryWriteBuffer += ",";
  summaryWriteBuffer += currentSessionDateTime(false);
  summaryWriteBuffer += ",";
  summaryWriteBuffer += String(LR, 2);
  summaryWriteBuffer += ",";
  summaryWriteBuffer += String(FB, 2);
  summaryWriteBuffer += ",";
  summaryWriteBuffer += String(UD, 2);
  summaryWriteBuffer += ",";
  summaryWriteBuffer += String(MAG, 2);
  summaryWriteBuffer += ",";
  summaryWriteBuffer += String(PITCH, 1);
  summaryWriteBuffer += ",";
  summaryWriteBuffer += String(ROLL, 1);
  summaryWriteBuffer += ",";
  summaryWriteBuffer += BODY_STATE;
  summaryWriteBuffer += ",";
  summaryWriteBuffer += MOTION_STATE;
  summaryWriteBuffer += ",";
  summaryWriteBuffer += RISK_STATE;
  summaryWriteBuffer += ",";
  summaryWriteBuffer += String(POWER_LOAD_V, 3);
  summaryWriteBuffer += ",";
  summaryWriteBuffer += String(POWER_CURRENT_MA, 1);
  summaryWriteBuffer += ",";
  summaryWriteBuffer += String(POWER_MW, 1);
  appendGpsCsvFields(summaryWriteBuffer);
  summaryWriteBuffer += "\n";

  if (millis() - lastSummaryFlush >= SUMMARY_WRITE_MS) {
    flushSummaryBuffer();
  }
}

void writeSessionSample() {
  if (!sessionRecording) {
    return;
  }
  if (sdRecoveryPause) {
    sdPausedSamples++;
    if (millis() - lastSdFlush >= SD_WRITE_MS) {
      lastSdFlush = millis();
      flushSessionBuffer();
    }
    return;
  }
  if (sdWriteBuffer.length() > SD_MAX_PENDING_BYTES) {
    setLastSessionEvent("SD_BUFFER_BACKPRESSURE", SESSION_FILE);
    if (millis() - lastSdFlush >= SD_WRITE_MS) {
      lastSdFlush = millis();
      flushSessionBuffer();
    }
    return;
  }

  unsigned long sampleNow = millis();
  if (lastSessionSampleMs > 0) {
    unsigned long sampleGapMs = sampleNow - lastSessionSampleMs;
    if (sampleGapMs > SAMPLE_GAP_WARN_MS) {
      sampleGapCount++;
      if (sampleGapMs > maxSampleGapMs) {
        maxSampleGapMs = sampleGapMs;
      }
      sdWriteBuffer += "#TIME_GAP;PREV_ROW=";
      sdWriteBuffer += String(sessionRow);
      sdWriteBuffer += ";NEXT_ROW=";
      sdWriteBuffer += String(sessionRow + 1);
      sdWriteBuffer += ";GAP_MS=";
      sdWriteBuffer += String(sampleGapMs);
      sdWriteBuffer += ";EXPECTED_MS=";
      sdWriteBuffer += String(SAMPLE_RATE_MS);
      sdWriteBuffer += ";LOCAL=";
      sdWriteBuffer += currentSessionDateTime(false);
      sdWriteBuffer += "\n";
      Serial.print("SESSION TIME GAP;PREV_ROW=");
      Serial.print(sessionRow);
      Serial.print(";NEXT_ROW=");
      Serial.print(sessionRow + 1);
      Serial.print(";GAP_MS=");
      Serial.println(sampleGapMs);
    }
  }
  lastSessionSampleMs = sampleNow;

  sessionRow++;
  String row = String(sessionRow);
  row += ",";
  row += String((sampleNow - sessionStartMillis) / 1000.0, 2);
  row += ",";
  row += currentSessionDateTime(false);
  row += ",";
  row += String(LR, 2);
  row += ",";
  row += String(FB, 2);
  row += ",";
  row += String(UD, 2);
  row += ",";
  row += String(MAG, 2);
  row += ",";
  row += String(PITCH, 1);
  row += ",";
  row += String(ROLL, 1);
  row += ",";
  row += BODY_STATE;
  row += ",";
  row += MOTION_STATE;
  row += ",";
  row += RISK_STATE;
  row += ",";
  row += String(POWER_LOAD_V, 3);
  row += ",";
  row += String(POWER_CURRENT_MA, 1);
  row += ",";
  row += String(POWER_MW, 1);
  appendGpsCsvFields(row);
  row += "\n";
  sdWriteBuffer += row;

  if (millis() - lastSdFlush >= SD_WRITE_MS) {
    lastSdFlush = millis();
    flushSessionBuffer();
  }
}

void loadUserProfile() {
  Serial.println("USER PROFILE DEFAULT RAM");
  Serial.print("USER: ");
  Serial.println(USER_NAME);
  Serial.print("AGE: ");
  Serial.println(USER_AGE);
  Serial.print("HEIGHT: ");
  Serial.println(USER_HEIGHT, 2);
  Serial.print("WEIGHT: ");
  Serial.println(USER_WEIGHT, 2);
  Serial.print("MODE: ");
  Serial.println(USER_MODE);
}

void saveUserProfile(const String& payload) {
  if (!sessionRecording) {
    cancelFileTransfer();
    resetIdleSessionRuntime(LAST_SESSION_FILE);
    LAST_SESSION_EVENT = "PROFILE_READY";
  }

  String user = getFieldValue(payload, "USER");
  String age = getFieldValue(payload, "AGE");
  String height = getFieldValue(payload, "HEIGHT");
  String weight = getFieldValue(payload, "WEIGHT");
  String mode = getFieldValue(payload, "MODE");

  if (user.length() > 0) {
    USER_NAME = user;
  }
  if (age.length() > 0) {
    USER_AGE = age.toInt();
  }
  if (height.length() > 0) {
    USER_HEIGHT = height.toFloat();
  }
  if (weight.length() > 0) {
    USER_WEIGHT = weight.toFloat();
  }
  if (mode.length() > 0) {
    USER_MODE = mode;
  }

  String ack =
    String("CFG:OK;USER=") + USER_NAME +
    ";AGE=" + String(USER_AGE) +
    ";HEIGHT=" + String(USER_HEIGHT, 2) +
    ";WEIGHT=" + String(USER_WEIGHT, 2) +
    ";MODE=" + USER_MODE;

  Serial.println("USER PROFILE SAVED");
  notifyApp(ack);
}

void sendCurrentProfile() {
  String profile =
    String("PROFILE:USER=") + USER_NAME +
    ";AGE=" + String(USER_AGE) +
    ";HEIGHT=" + String(USER_HEIGHT, 2) +
    ";WEIGHT=" + String(USER_WEIGHT, 2) +
    ";MODE=" + USER_MODE;

  notifyApp(profile);
}

void sendCurrentSessionStatus() {
  String state = sessionRecording ? "ACTIVE" : "IDLE";
  String status =
    String("SESSION:") + state +
    ";FILE=" + String(sessionRecording ? SESSION_FILE : LAST_SESSION_FILE) +
    ";SUMMARY=" + String(sessionRecording ? SUMMARY_FILE : LAST_SUMMARY_FILE) +
    ";USER=" + USER_NAME +
    ";ROWS=" + String(sessionRecording ? sessionRow : savedSessionRows) +
    ";LAST_EVENT=" + LAST_SESSION_EVENT +
    ";RESET=" + RESET_REASON +
    ";FLUSH_COUNT=" + String(sdFlushCount) +
    ";FLUSH_MS=" + String(lastSdFlushDurationMs) +
    ";FLUSH_MAX_MS=" + String(maxSdFlushDurationMs) +
    ";SD_FAILS=" + String(sdFlushFailCount) +
    ";BUFFER_BYTES=" + String(sdWriteBuffer.length()) +
    ";PAUSED_SAMPLES=" + String(sdPausedSamples) +
    ";SD_PAUSE=" + String(sdRecoveryPause ? "YES" : "NO") +
    ";GPS_STATUS=" + GPS_STATUS +
    ";GPS_FIX=" + String(gpsHasFix ? 1 : 0) +
    ";GPS_SATS=" + GPS_SATELLITES +
    ";GPS_HDOP=" + GPS_HDOP +
    ";GPS_LAT=" + String(GPS_LAT, 6) +
    ";GPS_LON=" + String(GPS_LON, 6) +
    ";GPS_AGE_MS=" + String(lastGpsFixMs > 0 ? millis() - lastGpsFixMs : 0);

  notifyApp(status);
}

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) {
    String payload = pChar->getValue();

    if (payload.length() == 0) {
      return;
    }

    payload.trim();

    Serial.print("BLE RX: ");
    Serial.println(payload);

    if (payload == "PROFILE?") {
      sendCurrentProfile();
    } else if (payload == "STATUS?") {
      sendCurrentSessionStatus();
    } else if (payload == "FILE:GET_LAST") {
      downloadLastRequested = true;
      Serial.println("RAW FILE DOWNLOAD QUEUED FOR MAIN LOOP");
    } else if (payload == "FILE:GET_SUMMARY") {
      downloadSummaryRequested = true;
      Serial.println("SUMMARY DOWNLOAD QUEUED FOR MAIN LOOP");
    } else if (payload.startsWith("FILE:ACK;SEQ=")) {
      unsigned long confirmedSequence = (unsigned long) getFieldValue(payload, "SEQ").toInt();
      if (fileTransferActive && fileTransferWaitingAck && confirmedSequence == transferSequence) {
        transferBytesConfirmed += transferLastChunkBytes;
        fileTransferWaitingAck = false;
      }
    } else if (payload.startsWith("CFG:")) {
      if (sessionRecording) {
        notifyApp("CFG:ERROR;REASON=SESSION_ACTIVE");
      } else {
        saveUserProfile(payload.substring(4));
      }
    } else if (payload.startsWith("SESSION:START")) {
      pendingSessionPayload = payload;
      sessionStartRequested = true;
      Serial.println("SESSION START QUEUED FOR MAIN LOOP");
    } else if (payload.startsWith("SESSION:STOP")) {
      sessionStopRequested = true;
      Serial.println("SESSION STOP QUEUED FOR MAIN LOOP");
    } else {
      Serial.println("BLE RX UNKNOWN COMMAND");
    }
  }
};

// ====================================================
// CLASSIFICATION
// ====================================================

void updateBodyState() {
  float absLR = abs(LR);
  float absFB = abs(FB);
  float absUD = abs(UD);

  if (!mpuReady || MAG < 2.0) {
    BODY_STATE = "NO_SENSOR";
    return;
  }

  // Clasificacion simple por eje dominante de gravedad.
  // Se ajustara cuando definamos orientacion fisica final del sensor.
  if (absUD >= absLR && absUD >= absFB) {
    if (UD >= 0) {
      BODY_STATE = "BACK_UP";
    } else {
      BODY_STATE = "INVERTED";
    }
  } else if (absLR >= absFB) {
    BODY_STATE = (LR >= 0) ? "RIGHT_SIDE" : "LEFT_SIDE";
  } else {
    BODY_STATE = (FB >= 0) ? "FORWARD_TILT" : "BACKWARD_TILT";
  }
}

void updateMotionState() {
  float magDelta = abs(MAG - magBaseline);
  magDeltaFiltered = (magDeltaFiltered * 0.85) + (magDelta * 0.15);

  if (magDeltaFiltered > 0.35) {
    lastMovementMs = millis();
    MOTION_STATE = "MOVING";
  } else {
    unsigned long stillMs = millis() - lastMovementMs;
    if (stillMs > 10000) {
      MOTION_STATE = "NO_ADVANCE";
    } else if (stillMs > 3000) {
      MOTION_STATE = "LOW_MOTION";
    } else {
      MOTION_STATE = "MOVING";
    }
  }
}

void updateRiskState() {
  RISK_SCORE = 0;

  if (WATER_STATE == "YES") {
    if (MOTION_STATE == "LOW_MOTION") {
      RISK_SCORE += 25;
    }
    if (MOTION_STATE == "NO_ADVANCE") {
      RISK_SCORE += 55;
    }
    if (BODY_STATE == "INVERTED") {
      RISK_SCORE += 30;
    }
  }

  if (RISK_SCORE >= 70) {
    RISK_STATE = "WARNING";
  } else if (RISK_SCORE >= 35) {
    RISK_STATE = "WATCH";
  } else {
    RISK_STATE = "NORMAL";
  }
}

// ====================================================
// READ SENSOR
// ====================================================

bool writeIna219Register(uint8_t reg, uint16_t value) {
  Wire.beginTransmission(INA219_ADDRESS);
  Wire.write(reg);
  Wire.write((uint8_t)(value >> 8));
  Wire.write((uint8_t)(value & 0xFF));
  return Wire.endTransmission() == 0;
}

bool readIna219Register(uint8_t reg, uint16_t &value) {
  Wire.beginTransmission(INA219_ADDRESS);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) {
    return false;
  }

  if (Wire.requestFrom((uint8_t)INA219_ADDRESS, (uint8_t)2) != 2) {
    return false;
  }

  value = ((uint16_t)Wire.read() << 8) | Wire.read();
  return true;
}

bool looksLikeNmea(const String& line) {
  return line.startsWith("$GP") || line.startsWith("$GN") ||
         line.startsWith("$GL") || line.startsWith("$GA");
}

void updateGpsStateFromFix() {
  if (gpsHasFix && lastGpsFixMs > 0 && millis() - lastGpsFixMs <= 10000UL) {
    GPS_STATUS = "FIX";
  } else if (lastGpsByteMs > 0) {
    GPS_STATUS = "NO_RECENT_FIX";
  } else {
    GPS_STATUS = "NO_GPS_DATA";
  }
}

void parseGpsGGA(const String& line) {
  String utc = getCsvField(line, 1);
  String latRaw = getCsvField(line, 2);
  String latHem = getCsvField(line, 3);
  String lonRaw = getCsvField(line, 4);
  String lonHem = getCsvField(line, 5);
  String quality = getCsvField(line, 6);
  String satellites = getCsvField(line, 7);
  String hdop = getCsvField(line, 8);

  if (utc.length() > 0) GPS_UTC = utc;
  if (quality.length() > 0) GPS_FIX_QUALITY = quality;
  if (satellites.length() > 0) GPS_SATELLITES = satellites;
  if (hdop.length() > 0) GPS_HDOP = hdop;

  if (quality.toInt() > 0 && latRaw.length() > 0 && lonRaw.length() > 0) {
    GPS_LAT = nmeaCoordToDecimal(latRaw, latHem);
    GPS_LON = nmeaCoordToDecimal(lonRaw, lonHem);
    gpsHasFix = true;
    lastGpsFixMs = millis();
  }
  updateGpsStateFromFix();
}

void parseGpsRMC(const String& line) {
  String utc = getCsvField(line, 1);
  String status = getCsvField(line, 2);
  String latRaw = getCsvField(line, 3);
  String latHem = getCsvField(line, 4);
  String lonRaw = getCsvField(line, 5);
  String lonHem = getCsvField(line, 6);
  String speedKnots = getCsvField(line, 7);
  String course = getCsvField(line, 8);

  if (utc.length() > 0) GPS_UTC = utc;
  if (speedKnots.length() > 0) GPS_SPEED_KMH = speedKnots.toFloat() * 1.852;
  if (course.length() > 0) GPS_COURSE = course.toFloat();

  if (status == "A" && latRaw.length() > 0 && lonRaw.length() > 0) {
    GPS_LAT = nmeaCoordToDecimal(latRaw, latHem);
    GPS_LON = nmeaCoordToDecimal(lonRaw, lonHem);
    gpsHasFix = true;
    lastGpsFixMs = millis();
  }
  updateGpsStateFromFix();
}

void handleGpsNmeaLine(String line) {
  line.trim();
  if (line.length() == 0) {
    return;
  }

  gpsLines++;
  if (!looksLikeNmea(line)) {
    return;
  }

  gpsValidLines++;
  if (line.startsWith("$GPGGA") || line.startsWith("$GNGGA")) {
    parseGpsGGA(line);
  } else if (line.startsWith("$GPRMC") || line.startsWith("$GNRMC")) {
    parseGpsRMC(line);
  }
}

void readGPS() {
  while (gpsSerial.available()) {
    char c = gpsSerial.read();
    lastGpsByteMs = millis();

    if (c == '\n') {
      handleGpsNmeaLine(gpsNmeaLine);
      gpsNmeaLine = "";
    } else if (c != '\r') {
      if (gpsNmeaLine.length() < 120) {
        gpsNmeaLine += c;
      } else {
        gpsNmeaLine = "";
      }
    }
  }
  updateGpsStateFromFix();
}

bool beginINA219() {
  Wire.beginTransmission(INA219_ADDRESS);
  if (Wire.endTransmission() != 0) {
    return false;
  }

  if (!writeIna219Register(INA219_REG_CALIBRATION, INA219_CALIBRATION_VALUE)) {
    return false;
  }

  return writeIna219Register(INA219_REG_CONFIG, INA219_CONFIG_VALUE);
}

void readINA219() {
  if (!ina219Ready) {
    return;
  }

  // Reaplica calibracion por seguridad ante posibles reinicios internos del sensor.
  if (!writeIna219Register(INA219_REG_CALIBRATION, INA219_CALIBRATION_VALUE)) {
    ina219Ready = false;
    Serial.println("INA219 READ FAILED - ENERGY DATA PAUSED");
    return;
  }

  uint16_t busRaw = 0;
  uint16_t shuntRaw = 0;
  uint16_t currentRaw = 0;
  uint16_t powerRaw = 0;

  if (!readIna219Register(INA219_REG_BUS_VOLTAGE, busRaw) ||
      !readIna219Register(INA219_REG_SHUNT_VOLTAGE, shuntRaw) ||
      !readIna219Register(INA219_REG_CURRENT, currentRaw) ||
      !readIna219Register(INA219_REG_POWER, powerRaw)) {
    ina219Ready = false;
    Serial.println("INA219 READ FAILED - ENERGY DATA PAUSED");
    return;
  }

  POWER_BUS_V = (float)((busRaw >> 3) * 4) / 1000.0;
  POWER_SHUNT_MV = (float)((int16_t)shuntRaw) * 0.01;
  POWER_LOAD_V = POWER_BUS_V;
  POWER_INPUT_V = POWER_BUS_V + (POWER_SHUNT_MV / 1000.0);
  POWER_CURRENT_MA = (float)((int16_t)currentRaw) / 10.0;
  POWER_MW = (float)powerRaw * 2.0;
}

void scanI2CBus() {
  Serial.println("I2C SCAN START");

  byte foundCount = 0;

  for (byte address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    byte error = Wire.endTransmission();

    if (error == 0) {
      Serial.print("I2C DEVICE FOUND AT 0x");
      if (address < 16) {
        Serial.print("0");
      }
      Serial.println(address, HEX);
      foundCount++;
    }
  }

  if (foundCount == 0) {
    Serial.println("I2C SCAN: NO DEVICES FOUND");
  } else {
    Serial.print("I2C SCAN: DEVICES FOUND = ");
    Serial.println(foundCount);
  }

  Serial.println("I2C SCAN END");
}

void readMPU6050() {
  if (!mpuReady) {
    unsigned long now = millis();
    if (now - lastMpuWarning >= 3000) {
      lastMpuWarning = now;
      Serial.println("MPU6050 NOT READY: BLE/Serial alive, sensor data forced to 0");
      Serial.println("CHECK MPU6050 VCC/GND/SDA/SCL AND I2C ADDRESS 0x68/0x69");
    }
    return;
  }

  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  LR = a.acceleration.x * LR_SIGN;
  FB = a.acceleration.y * FB_SIGN;
  UD = a.acceleration.z * UD_SIGN;

  MAG = sqrt((LR * LR) + (FB * FB) + (UD * UD));
  TIME_S = millis() / 1000.0;

  // Orientacion aproximada con acelerometro.
  // Sirve para visualizacion y tendencia, no como verdad absoluta.
  ROLL = atan2(FB, UD) * 180.0 / PI;
  PITCH = atan2(-LR, sqrt((FB * FB) + (UD * UD))) * 180.0 / PI;

  updateBodyState();
  updateMotionState();
  updateRiskState();
}

// ====================================================
// SERIAL STUDIO JSON OUTPUT
// ====================================================

void sendSerialStudio() {
  if (sdFlushActive) {
    return;
  }
  if (sessionRecording) {
    return;
  }

  String jsonData = "{";

  jsonData += "\"TIME\":";
  jsonData += String(TIME_S, 2);

  jsonData += ",\"LR\":";
  jsonData += String(LR, 2);

  jsonData += ",\"FB\":";
  jsonData += String(FB, 2);

  jsonData += ",\"UD\":";
  jsonData += String(UD, 2);

  jsonData += ",\"MAG\":";
  jsonData += String(MAG, 2);

  jsonData += ",\"PITCH\":";
  jsonData += String(PITCH, 1);

  jsonData += ",\"ROLL\":";
  jsonData += String(ROLL, 1);

  jsonData += ",\"SCORE\":";
  jsonData += String(RISK_SCORE);

  jsonData += ",\"BATT\":";
  jsonData += String(BATTERY_LEVEL);

  jsonData += ",\"INPUT_V\":";
  jsonData += String(POWER_INPUT_V, 3);

  jsonData += ",\"LOAD_V\":";
  jsonData += String(POWER_LOAD_V, 3);

  jsonData += ",\"SHUNT_MV\":";
  jsonData += String(POWER_SHUNT_MV, 2);

  jsonData += ",\"CURRENT_MA\":";
  jsonData += String(POWER_CURRENT_MA, 1);

  jsonData += ",\"POWER_MW\":";
  jsonData += String(POWER_MW, 1);

  jsonData += ",\"INA_OK\":";
  jsonData += String(ina219Ready ? "true" : "false");

  jsonData += ",\"GPS_STATUS\":\"";
  jsonData += GPS_STATUS;
  jsonData += "\"";

  jsonData += ",\"GPS_FIX\":";
  jsonData += String(gpsHasFix ? 1 : 0);

  jsonData += ",\"GPS_SATS\":";
  jsonData += GPS_SATELLITES;

  jsonData += ",\"GPS_HDOP\":";
  jsonData += GPS_HDOP;

  jsonData += ",\"LAT\":";
  jsonData += String(GPS_LAT, 6);

  jsonData += ",\"LON\":";
  jsonData += String(GPS_LON, 6);

  jsonData += ",\"SPEED_KMH\":";
  jsonData += String(GPS_SPEED_KMH, 2);

  jsonData += ",\"GPS_AGE_MS\":";
  jsonData += String(lastGpsFixMs > 0 ? millis() - lastGpsFixMs : 0);

  jsonData += ",\"BODY\":\"";
  jsonData += BODY_STATE;
  jsonData += "\"";

  jsonData += ",\"MOTION\":\"";
  jsonData += MOTION_STATE;
  jsonData += "\"";

  jsonData += ",\"RISK\":\"";
  jsonData += RISK_STATE;
  jsonData += "\"";

  jsonData += ",\"USER\":\"";
  jsonData += USER_NAME;
  jsonData += "\"";

  jsonData += ",\"MODE\":\"";
  jsonData += USER_MODE;
  jsonData += "\"";

  jsonData += "}";

  Serial.println(jsonData);
}

// ====================================================
// BLE OUTPUT
// Formato compatible con save_swimmer_ble_viewer.html
// ====================================================

void sendBleTelemetry() {
  if (sdFlushActive) {
    return;
  }

  if (!deviceConnected || pCharacteristic == nullptr) {
    return;
  }

  String value;

  if (bleSendGpsNext) {
    // GPS en vivo para app gateway/mapa.
    // Formato: G:FIX,LAT,LON,SPEED_KMH,SATS,HDOP,AGE_MS
    unsigned long gpsAgeMs = lastGpsFixMs > 0 ? millis() - lastGpsFixMs : 0;
    value =
      String("G:") +
      String(GPS_FIX_QUALITY) + "," +
      String(GPS_LAT, 6) + "," +
      String(GPS_LON, 6) + "," +
      String(GPS_SPEED_KMH, 2) + "," +
      String(GPS_SATELLITES) + "," +
      String(GPS_HDOP) + "," +
      String(gpsAgeMs);
  } else {
    // Paquete ultracorto para maxima compatibilidad con Web Bluetooth.
    // Formato: A:LR,FB,UD,MAG multiplicados por 10.
    // Ejemplo: A:2,-3,98,99 equivale a LR=0.2 FB=-0.3 UD=9.8 MAG=9.9.
    value =
      String("A:") +
      String((int)(LR * 10.0)) + "," +
      String((int)(FB * 10.0)) + "," +
      String((int)(UD * 10.0)) + "," +
      String((int)(MAG * 10.0));
  }

  bleSendGpsNext = !bleSendGpsNext;

  pCharacteristic->setValue(value.c_str());
  pCharacteristic->notify();
}

// ====================================================
// SETUP
// ====================================================

void setup() {
  Serial.begin(115200);
  delay(1000);
  setupRgbLed();
  RESET_REASON = resetReasonText(esp_reset_reason());

  Serial.println("================================");
  Serial.println("SAVE SWIMMER STARTING");
  Serial.println(DEVICE_SERIAL);
  Serial.println(FIRMWARE_VERSION);
  Serial.print("RESET REASON: ");
  Serial.println(RESET_REASON);
  Serial.println("RGB STATUS LED HW-479 READY");
  Serial.print("RGB R PIN: "); Serial.println(RGB_R_PIN);
  Serial.print("RGB G PIN: "); Serial.println(RGB_G_PIN);
  Serial.print("RGB B PIN: "); Serial.println(RGB_B_PIN);
  Serial.println("================================");

  loadUserProfile();

  // ====================================================
  // GPS INIT
  // ====================================================

  gpsSerial.begin(GPS_BAUD, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
  Serial.println("GPS UART READY");
  Serial.print("GPS RX PIN: "); Serial.println(GPS_RX_PIN);
  Serial.print("GPS TX PIN: "); Serial.println(GPS_TX_PIN);
  Serial.print("GPS BAUD: "); Serial.println(GPS_BAUD);

  // ====================================================
  // I2C + MPU6050
  // ====================================================

  if (I2C_SDA_PIN >= 0 && I2C_SCL_PIN >= 0) {
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  } else {
    Wire.begin();
  }

  scanI2CBus();

  if (!beginINA219()) {
    Serial.println("INA219 NOT DETECTED AT 0x40");
    Serial.println("CHECK INA219 VCC/GND/SDA/SCL");
    ina219Ready = false;
  } else {
    ina219Ready = true;
    readINA219();
    Serial.println("INA219 CONNECTED");
    Serial.print("INA219 INPUT V: "); Serial.println(POWER_INPUT_V, 3);
    Serial.print("INA219 LOAD V: "); Serial.println(POWER_LOAD_V, 3);
    Serial.print("INA219 CURRENT MA: "); Serial.println(POWER_CURRENT_MA, 1);
    Serial.print("INA219 POWER MW: "); Serial.println(POWER_MW, 1);
  }

  if (!mpu.begin()) {
    Serial.println("MPU6050 NOT DETECTED");
    mpuReady = false;
  } else {
    Serial.println("MPU6050 CONNECTED");
    mpuReady = true;

    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

    lastMovementMs = millis();
  }

  // ====================================================
  // MICROSD INIT
  // ====================================================

  Serial.println("MICROSD SPI PINS:");
  Serial.print("CS: "); Serial.println(SD_CS);
  Serial.print("MOSI: "); Serial.println(SD_MOSI);
  Serial.print("SCK: "); Serial.println(SD_SCK);
  Serial.print("MISO: "); Serial.println(SD_MISO);

  sdSPI.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);
  Serial.println("INITIALIZING MICROSD...");

  if (!SD.begin(SD_CS, sdSPI, SD_SPI_HZ)) {
    sdReady = false;
    Serial.println("MICROSD INIT FAILED - BLE CONTINUES WITHOUT SD RECORDING");
  } else {
    sdReady = runSdBootDiagnostic();
    if (sdReady) {
      Serial.println("MICROSD READY - WAITING SESSION START FROM APP");
      recoverLastSessionStateAfterBoot();
    } else {
      Serial.println("MICROSD PRESENT BUT WRITE DIAGNOSTIC FAILED");
    }
  }

  // ====================================================
  // BLE INIT
  // ====================================================

  BLEDevice::init(DEVICE_SERIAL);
  BLEDevice::setMTU(185);

  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SS_SERVICE_UUID);

  pCharacteristic =
    pService->createCharacteristic(
      SS_TELEMETRY_CHAR_UUID,
      BLECharacteristic::PROPERTY_NOTIFY |
      BLECharacteristic::PROPERTY_READ
    );

  pCharacteristic->addDescriptor(new BLE2902());

  pConfigCharacteristic =
    pService->createCharacteristic(
      SS_CONFIG_CHAR_UUID,
      BLECharacteristic::PROPERTY_WRITE |
      BLECharacteristic::PROPERTY_WRITE_NR |
      BLECharacteristic::PROPERTY_READ
    );

  pConfigCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();

  pAdvertising->addServiceUUID(SS_SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);

  BLEDevice::startAdvertising();

  Serial.println("BLE READY");
  Serial.println("WAITING FOR CONNECTION...");
}

// ====================================================
// LOOP
// ====================================================

void loop() {
  unsigned long now = millis();

  readGPS();
  updateRgbLed();

  if (now - lastPowerSample >= POWER_SAMPLE_MS) {
    lastPowerSample = now;
    if (!ina219Ready) {
      ina219Ready = beginINA219();
      if (ina219Ready) {
        Serial.println("INA219 RECONNECTED");
      }
    }
    readINA219();
  }

  if (downloadLastRequested) {
    downloadLastRequested = false;
    beginLatestFileTransfer();
  }

  if (downloadSummaryRequested) {
    downloadSummaryRequested = false;
    beginLatestSummaryTransfer();
  }

  serviceFileTransfer();

  if (sessionStopRequested) {
    sessionStopRequested = false;
    endSession();
  }

  if (sessionStartRequested) {
    String command = pendingSessionPayload;
    sessionStartRequested = false;
    pendingSessionPayload = "";
    beginSession(command);
  }

  if (now - lastSample >= SAMPLE_RATE_MS) {
    lastSample = now;
    readMPU6050();
    writeSessionSample();
    writeSummarySample();
  }

  if (now - lastSerialSend >= SERIAL_SEND_MS) {
    lastSerialSend = now;
    sendSerialStudio();
  }

  if (!fileTransferActive && now - lastBleSend >= BLE_SEND_MS) {
    lastBleSend = now;
    sendBleTelemetry();
  }

  updateRgbLed();
}
