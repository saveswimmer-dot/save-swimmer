/*
====================================================
SAVE SWIMMER
FIRMWARE: SS-LITE-BLE-VIEWER-V1-012
DEVICE: SS-LT-000001
====================================================
ESP32-S3 + MPU6050 + BLE + SERIAL JSON
Compatible con save_swimmer_ble_viewer.html
====================================================

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
#include <Preferences.h>

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
#define FIRMWARE_VERSION "SS-LITE-BLE-VIEWER-V1-012"

// ====================================================
// SAVE SWIMMER BLE UUIDS
// Deben coincidir con save_swimmer_ble_viewer.html
// ====================================================

#define SS_SERVICE_UUID           "8f1c1000-5a7e-4b3d-9c21-a10000000001"
#define SS_TELEMETRY_CHAR_UUID    "8f1c1001-5a7e-4b3d-9c21-a10000000001"

// ====================================================
// TIMING
// ====================================================

#define SAMPLE_RATE_MS 100
#define BLE_SEND_MS 500
#define SERIAL_SEND_MS 100

// ====================================================
// OPTIONAL I2C PINS
// Si tu placa necesita pines especificos, cambia aqui.
// Si no, deja -1 para usar Wire.begin() normal.
// ====================================================

#define I2C_SDA_PIN -1
#define I2C_SCL_PIN -1

// ====================================================
// OBJECTS
// ====================================================

Adafruit_MPU6050 mpu;
Preferences prefs;

BLECharacteristic *pCharacteristic = nullptr;
bool deviceConnected = false;

// ====================================================
// SYSTEM STATUS
// ====================================================

String SYSTEM_STATE = "ACTIVE";
String WATER_STATE = "NO";      // placeholder hasta agregar sensor de agua
String BODY_STATE = "UNKNOWN";
String MOTION_STATE = "UNKNOWN";
String RISK_STATE = "NORMAL";
String USER_NAME = "SIN_USUARIO";
String USER_MODE = "TEST";

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

void loadUserProfile() {
  prefs.begin("ss_profile", true);
  USER_NAME = prefs.getString("user", "SIN_USUARIO");
  USER_AGE = prefs.getInt("age", 0);
  USER_HEIGHT = prefs.getFloat("height", 0);
  USER_WEIGHT = prefs.getFloat("weight", 0);
  USER_MODE = prefs.getString("mode", "TEST");
  prefs.end();

  Serial.println("USER PROFILE LOADED");
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

  prefs.begin("ss_profile", false);
  prefs.putString("user", USER_NAME);
  prefs.putInt("age", USER_AGE);
  prefs.putFloat("height", USER_HEIGHT);
  prefs.putFloat("weight", USER_WEIGHT);
  prefs.putString("mode", USER_MODE);
  prefs.end();

  String ack =
    String("CFG:OK;USER=") + USER_NAME +
    ";AGE=" + String(USER_AGE) +
    ";HEIGHT=" + String(USER_HEIGHT, 2) +
    ";WEIGHT=" + String(USER_WEIGHT, 2) +
    ";MODE=" + USER_MODE;

  Serial.println("USER PROFILE SAVED");
  Serial.println(ack);

  if (deviceConnected && pCharacteristic != nullptr) {
    pCharacteristic->setValue(ack.c_str());
    pCharacteristic->notify();
  }
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
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_WRITE
    );

  pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pCharacteristic->addDescriptor(new BLE2902());
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

  if (now - lastSample >= SAMPLE_RATE_MS) {
    lastSample = now;
    readMPU6050();
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
