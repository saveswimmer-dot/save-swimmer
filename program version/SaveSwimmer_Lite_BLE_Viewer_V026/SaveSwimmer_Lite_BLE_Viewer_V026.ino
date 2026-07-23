/*
====================================================
SAVE SWIMMER
FIRMWARE: SS-LITE-BLE-SD-V1-026
DEVICE: SS-LT-000001
====================================================
ESP32-S3 + MPU6050 + BLE + MICROSD + SERIAL JSON
Compatible con Save Swimmer Field Viewer Android
====================================================

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

// ====================================================
// DEVICE INFO
// ====================================================

#define DEVICE_SERIAL "SS-LT-000001"
#define FIRMWARE_VERSION "SS-LITE-BLE-SD-V1-026"

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
#define SD_FLUSH_MS 1000
#define SD_BUFFER_RESERVE_BYTES 1400

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
File sessionFile;

BLECharacteristic *pCharacteristic = nullptr;
BLECharacteristic *pConfigCharacteristic = nullptr;
bool deviceConnected = false;
bool sdReady = false;
bool sessionRecording = false;
bool sessionStartRequested = false;
bool sessionStopRequested = false;

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
String pendingSessionPayload = "";

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
unsigned long lastSdFlush = 0;
unsigned long sessionStartMillis = 0;
unsigned long sessionStartEpoch = 0;
long sessionTimezoneOffset = -18000;
unsigned long sessionRow = 0;
unsigned long savedSessionRows = 0;
String sdWriteBuffer = "";

bool mpuReady = false;
unsigned long lastMpuWarning = 0;

// Movimiento simple para prototipo
float magBaseline = 9.81;
float magDeltaFiltered = 0;
unsigned long lastMovementMs = 0;

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

bool runSdBootDiagnostic() {
  const char* path = "/BOOT.CSV";
  File boot = SD.open(path, FILE_APPEND);
  if (!boot) {
    Serial.println("SD BOOT WRITE FAILED: OPEN");
    return false;
  }

  boot.print(FIRMWARE_VERSION);
  boot.print(",");
  boot.println(millis());
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

  SD.end();
  sdSPI.end();
  delay(60);
  sdSPI.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);

  if (!SD.begin(SD_CS, sdSPI, 4000000)) {
    sdReady = false;
    Serial.println("SD SESSION REMOUNT FAILED");
    return false;
  }

  sdReady = true;
  Serial.println("SD SESSION REMOUNT OK");
  return true;
}

String createSessionFilename() {
  // Se mantiene en formato FAT 8.3 por compatibilidad con modulos SD simples.
  // La trazabilidad legible se escribe dentro del CSV, no en el nombre.
  char filename[14];
  for (unsigned long i = 1; i <= 999999UL; i++) {
    snprintf(filename, sizeof(filename), "/SS%06lu.CSV", i);
    if (!fileReadable(String(filename))) {
      return String(filename);
    }
  }
  return "";
}

bool beginSession(const String& payload) {
  if (!remountSdForSession()) {
    notifyApp("SESSION:ERROR;REASON=SD_NOT_READY");
    return false;
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
  savedSessionRows = 0;
  sdWriteBuffer = "";
  sdWriteBuffer.reserve(SD_BUFFER_RESERVE_BYTES);
  lastSdFlush = millis();
  SESSION_FILE = createSessionFilename();
  if (SESSION_FILE.length() == 0) {
    notifyApp("SESSION:ERROR;REASON=NO_FILENAME_AVAILABLE");
    return false;
  }

  // Usa la misma estrategia local que BOOT.CSV, ya validada en la tarjeta.
  File headerFile = SD.open(SESSION_FILE.c_str(), FILE_APPEND);
  if (!headerFile) {
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
  headerFile.println("row,elapsed_s,local_time,lr,fb,ud,mag,pitch,roll,body,motion,risk");
  headerFile.flush();
  headerFile.close();

  unsigned long initialBytes = 0;
  if (!verifySessionHeader(SESSION_FILE, initialBytes)) {
    SESSION_FILE = "";
    notifyApp("SESSION:ERROR;REASON=FILE_READBACK_FAILED");
    return false;
  }

  sessionRecording = true;
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

  if (!flushSessionBuffer()) {
    return;
  }

  sessionRecording = false;
  SYSTEM_STATE = "READY";

  unsigned long fileSize = readableFileSize(SESSION_FILE);

  notifyApp(String("SESSION:STOPPED;SD=SAVED;FILE=") + SESSION_FILE +
    ";ROWS=" + String(savedSessionRows) + ";BYTES=" + String(fileSize));
}

bool flushSessionBuffer() {
  if (sdWriteBuffer.length() == 0) {
    return true;
  }

  File batchFile;
  int openAttempt = 0;
  for (openAttempt = 1; openAttempt <= 3; openAttempt++) {
    batchFile = SD.open(SESSION_FILE.c_str(), FILE_APPEND);
    if (batchFile) {
      break;
    }

    Serial.print("SD BATCH OPEN FAILED;ATTEMPT=");
    Serial.println(openAttempt);
    if (openAttempt < 3) {
      notifyApp(String("SESSION:SD_RETRY;ATTEMPT=") + String(openAttempt));
      remountSdForSession(true);
      delay(150);
    }
  }

  if (!batchFile) {
    sessionRecording = false;
    SYSTEM_STATE = "SD_ERROR";
    notifyApp("SESSION:ERROR;REASON=BATCH_OPEN_FAILED_AFTER_RETRY");
    return false;
  }

  size_t expected = sdWriteBuffer.length();
  size_t written = batchFile.print(sdWriteBuffer);
  batchFile.flush();
  batchFile.close();
  if (written != expected) {
    sessionRecording = false;
    SYSTEM_STATE = "SD_ERROR";
    notifyApp(String("SESSION:ERROR;REASON=BATCH_PARTIAL_WRITE;EXPECTED=") +
      String(expected) + ";WRITTEN=" + String(written));
    return false;
  }

  savedSessionRows = sessionRow;
  sdWriteBuffer = "";
  String ack = String("SESSION:SD_WRITE;ROWS=") + String(savedSessionRows) +
    ";BATCH_BYTES=" + String(written);
  Serial.println(ack);
  notifyApp(ack);
  return true;
}

void writeSessionSample() {
  if (!sessionRecording) {
    return;
  }

  sessionRow++;
  sdWriteBuffer += String(sessionRow);
  sdWriteBuffer += ",";
  sdWriteBuffer += String((millis() - sessionStartMillis) / 1000.0, 2);
  sdWriteBuffer += ",";
  sdWriteBuffer += currentSessionDateTime(false);
  sdWriteBuffer += ",";
  sdWriteBuffer += String(LR, 2);
  sdWriteBuffer += ",";
  sdWriteBuffer += String(FB, 2);
  sdWriteBuffer += ",";
  sdWriteBuffer += String(UD, 2);
  sdWriteBuffer += ",";
  sdWriteBuffer += String(MAG, 2);
  sdWriteBuffer += ",";
  sdWriteBuffer += String(PITCH, 1);
  sdWriteBuffer += ",";
  sdWriteBuffer += String(ROLL, 1);
  sdWriteBuffer += ",";
  sdWriteBuffer += BODY_STATE;
  sdWriteBuffer += ",";
  sdWriteBuffer += MOTION_STATE;
  sdWriteBuffer += ",";
  sdWriteBuffer += RISK_STATE;
  sdWriteBuffer += "\n";

  if (millis() - lastSdFlush >= SD_FLUSH_MS) {
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

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) {
    String payload = pChar->getValue();

    if (payload.length() == 0) {
      return;
    }

    payload.trim();

    Serial.print("BLE RX: ");
    Serial.println(payload);

    if (payload.startsWith("CFG:")) {
      saveUserProfile(payload.substring(4));
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
  if (!deviceConnected || pCharacteristic == nullptr) {
    return;
  }

  // Paquete ultracorto para maxima compatibilidad con Web Bluetooth.
  // Formato: A:LR,FB,UD,MAG multiplicados por 10.
  // Ejemplo: A:2,-3,98,99 equivale a LR=0.2 FB=-0.3 UD=9.8 MAG=9.9.
  String value =
    String("A:") +
    String((int)(LR * 10.0)) + "," +
    String((int)(FB * 10.0)) + "," +
    String((int)(UD * 10.0)) + "," +
    String((int)(MAG * 10.0));

  pCharacteristic->setValue(value.c_str());
  pCharacteristic->notify();
}

// ====================================================
// SETUP
// ====================================================

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("================================");
  Serial.println("SAVE SWIMMER STARTING");
  Serial.println(DEVICE_SERIAL);
  Serial.println(FIRMWARE_VERSION);
  Serial.println("================================");

  loadUserProfile();

  // ====================================================
  // I2C + MPU6050
  // ====================================================

  if (I2C_SDA_PIN >= 0 && I2C_SCL_PIN >= 0) {
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  } else {
    Wire.begin();
  }

  scanI2CBus();

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

  if (!SD.begin(SD_CS, sdSPI, 4000000)) {
    sdReady = false;
    Serial.println("MICROSD INIT FAILED - BLE CONTINUES WITHOUT SD RECORDING");
  } else {
    sdReady = runSdBootDiagnostic();
    if (sdReady) {
      Serial.println("MICROSD READY - WAITING SESSION START FROM APP");
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
  }

  if (now - lastSerialSend >= SERIAL_SEND_MS) {
    lastSerialSend = now;
    sendSerialStudio();
  }

  if (now - lastBleSend >= BLE_SEND_MS) {
    lastBleSend = now;
    sendBleTelemetry();
  }
}
