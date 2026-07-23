/*
====================================================
SAVE SWIMMER
MICROSD TEST: SS-MICROSD-TEST-V001
BOARD: ESP32-S3 DevKit N16R8
====================================================
Prueba simple para modulo microSD SPI.

Hace:
1. Inicializa SPI.
2. Detecta tarjeta microSD.
3. Crea /ss_test.csv.
4. Escribe lineas de prueba cada 2 segundos.
5. Lee el archivo y lo imprime por Serial.
====================================================
*/

#include <Arduino.h>
#include <SPI.h>
#include <SD.h>

// ====================================================
// MICROSD SPI PINS
// ====================================================

#define SD_CS   10
#define SD_MOSI 11
#define SD_SCK  12
#define SD_MISO 13

// Algunos ESP32-S3 funcionan bien con FSPI para pines custom.
SPIClass sdSPI(FSPI);

// ====================================================
// FILE CONFIG
// ====================================================

const char* LOG_FILE = "/ss_test.csv";

unsigned long lastWrite = 0;
unsigned long rowNumber = 0;

// ====================================================
// HELPERS
// ====================================================

void printCardInfo() {
  uint8_t cardType = SD.cardType();

  Serial.print("CARD TYPE: ");
  if (cardType == CARD_NONE) {
    Serial.println("NO CARD");
    return;
  }

  if (cardType == CARD_MMC) {
    Serial.println("MMC");
  } else if (cardType == CARD_SD) {
    Serial.println("SDSC");
  } else if (cardType == CARD_SDHC) {
    Serial.println("SDHC/SDXC");
  } else {
    Serial.println("UNKNOWN");
  }

  uint64_t cardSizeMB = SD.cardSize() / (1024 * 1024);
  uint64_t totalMB = SD.totalBytes() / (1024 * 1024);
  uint64_t usedMB = SD.usedBytes() / (1024 * 1024);

  Serial.print("CARD SIZE: ");
  Serial.print(cardSizeMB);
  Serial.println(" MB");

  Serial.print("TOTAL: ");
  Serial.print(totalMB);
  Serial.println(" MB");

  Serial.print("USED: ");
  Serial.print(usedMB);
  Serial.println(" MB");
}

void readFileToSerial(const char* path) {
  File file = SD.open(path, FILE_READ);

  if (!file) {
    Serial.print("READ FAILED: ");
    Serial.println(path);
    return;
  }

  Serial.println("----- FILE CONTENT -----");
  while (file.available()) {
    Serial.write(file.read());
  }
  file.close();
  Serial.println();
  Serial.println("----- END FILE -----");
}

bool appendLine(const char* path, const String& line) {
  File file = SD.open(path, FILE_APPEND);

  if (!file) {
    Serial.print("OPEN APPEND FAILED: ");
    Serial.println(path);
    return false;
  }

  bool ok = file.println(line);
  file.flush();
  file.close();

  return ok;
}

void createHeaderIfNeeded() {
  if (SD.exists(LOG_FILE)) {
    Serial.println("LOG FILE EXISTS");
    return;
  }

  File file = SD.open(LOG_FILE, FILE_WRITE);
  if (!file) {
    Serial.println("CREATE LOG FILE FAILED");
    return;
  }

  file.println("millis,row,lr,fb,ud,mag,state");
  file.close();

  Serial.println("LOG FILE CREATED");
}

// ====================================================
// SETUP
// ====================================================

void setup() {
  Serial.begin(115200);
  delay(1200);

  Serial.println();
  Serial.println("================================");
  Serial.println("SAVE SWIMMER MICROSD TEST");
  Serial.println("SS-MICROSD-TEST-V001");
  Serial.println("================================");

  Serial.println("SPI PINS:");
  Serial.print("CS: ");
  Serial.println(SD_CS);
  Serial.print("MOSI: ");
  Serial.println(SD_MOSI);
  Serial.print("SCK: ");
  Serial.println(SD_SCK);
  Serial.print("MISO: ");
  Serial.println(SD_MISO);

  sdSPI.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);

  Serial.println("INITIALIZING MICROSD...");

  if (!SD.begin(SD_CS, sdSPI, 4000000)) {
    Serial.println("MICROSD INIT FAILED");
    Serial.println("CHECK:");
    Serial.println("- FAT32 format");
    Serial.println("- VCC to 3V3 first");
    Serial.println("- GND common");
    Serial.println("- CS/MOSI/SCK/MISO pins");
    Serial.println("- card inserted");
    return;
  }

  Serial.println("MICROSD OK");
  printCardInfo();
  createHeaderIfNeeded();
  readFileToSerial(LOG_FILE);
}

// ====================================================
// LOOP
// ====================================================

void loop() {
  if (SD.cardType() == CARD_NONE) {
    delay(1000);
    return;
  }

  unsigned long now = millis();

  if (now - lastWrite >= 2000) {
    lastWrite = now;
    rowNumber++;

    // Datos simulados. Luego los reemplazamos por LR/FB/UD/MAG reales del MPU6050.
    float lr = sin(rowNumber * 0.35) * 3.0;
    float fb = cos(rowNumber * 0.20) * 2.0;
    float ud = 9.0 + sin(rowNumber * 0.15);
    float mag = sqrt((lr * lr) + (fb * fb) + (ud * ud));

    String line = "";
    line += String(now);
    line += ",";
    line += String(rowNumber);
    line += ",";
    line += String(lr, 2);
    line += ",";
    line += String(fb, 2);
    line += ",";
    line += String(ud, 2);
    line += ",";
    line += String(mag, 2);
    line += ",";
    line += "MICROSD_TEST";

    if (appendLine(LOG_FILE, line)) {
      Serial.print("WRITE OK: ");
      Serial.println(line);
    } else {
      Serial.println("WRITE FAILED");
    }

    readFileToSerial(LOG_FILE);
  }
}

