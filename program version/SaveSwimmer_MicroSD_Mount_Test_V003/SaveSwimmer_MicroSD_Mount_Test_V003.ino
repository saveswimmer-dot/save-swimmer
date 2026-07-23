/*
====================================================
SAVE SWIMMER MICROSD MOUNT TEST
FIRMWARE: SS-MICROSD-MOUNT-V003
BOARD: ESP32-S3 DevKit N16R8
====================================================
Diagnostico aislado para microSD:
- Sin BLE.
- Sin MPU6050.
- Intenta montaje a 400 kHz, 1 MHz y 4 MHz.
- Si monta, realiza una sola escritura y lectura de confirmacion.

Conexion del modulo adaptador probado:
VCC  -> 5V
GND  -> GND
CS   -> GPIO10
MOSI -> GPIO11
SCK  -> GPIO12
MISO -> GPIO13
====================================================
*/

#include <Arduino.h>
#include <SPI.h>
#include <SD.h>

#define TEST_VERSION "SS-MICROSD-MOUNT-V003"
#define SD_CS   10
#define SD_MOSI 11
#define SD_SCK  12
#define SD_MISO 13

const uint32_t SD_TEST_SPEEDS[] = {400000, 1000000, 4000000};
const char* TEST_FILE = "/MOUNT.CSV";

SPIClass sdSPI(FSPI);
bool mounted = false;

String cardTypeText(uint8_t type) {
  if (type == CARD_MMC) return "MMC";
  if (type == CARD_SD) return "SDSC";
  if (type == CARD_SDHC) return "SDHC/SDXC";
  if (type == CARD_NONE) return "NONE";
  return "UNKNOWN";
}

void endSdBus() {
  SD.end();
  sdSPI.end();
  delay(200);
}

bool tryMount(uint32_t speedHz) {
  Serial.println();
  Serial.print("MOUNT ATTEMPT;SPI_HZ=");
  Serial.println(speedHz);

  pinMode(SD_CS, OUTPUT);
  digitalWrite(SD_CS, HIGH);
  sdSPI.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);
  delay(100);

  if (!SD.begin(SD_CS, sdSPI, speedHz)) {
    Serial.println("RESULT=INIT_FAILED");
    endSdBus();
    return false;
  }

  uint8_t type = SD.cardType();
  if (type == CARD_NONE) {
    Serial.println("RESULT=MOUNTED_WITHOUT_CARD_TYPE");
    endSdBus();
    return false;
  }

  Serial.print("RESULT=MOUNT_OK;CARD_TYPE=");
  Serial.println(cardTypeText(type));
  Serial.print("CARD_SIZE_MB=");
  Serial.println((unsigned long)(SD.cardSize() / (1024ULL * 1024ULL)));
  Serial.print("TOTAL_MB=");
  Serial.println((unsigned long)(SD.totalBytes() / (1024ULL * 1024ULL)));
  return true;
}

bool writeAndReadback() {
  File test = SD.open(TEST_FILE, FILE_APPEND);
  if (!test) {
    Serial.println("WRITE_TEST=OPEN_FAILED");
    return false;
  }

  if (test.size() == 0) {
    test.println("version,millis,result");
  }
  test.print(TEST_VERSION);
  test.print(",");
  test.print(millis());
  test.println(",WRITE_OK");
  test.flush();
  test.close();

  File readback = SD.open(TEST_FILE, FILE_READ);
  if (!readback) {
    Serial.println("WRITE_TEST=READBACK_OPEN_FAILED");
    return false;
  }

  unsigned long bytes = readback.size();
  Serial.print("WRITE_TEST=READBACK_OK;BYTES=");
  Serial.println(bytes);
  Serial.println("----- MOUNT.CSV -----");
  while (readback.available()) {
    Serial.write(readback.read());
  }
  readback.close();
  Serial.println("----- END FILE -----");
  return bytes > 0;
}

void setup() {
  Serial.begin(115200);
  delay(1200);

  Serial.println();
  Serial.println("================================");
  Serial.println("SAVE SWIMMER MICROSD MOUNT TEST");
  Serial.println(TEST_VERSION);
  Serial.println("================================");
  Serial.println("REQUIRED: card formatted FAT32 and inserted before power-on");
  Serial.println("MODULE VCC: 5V for the current adapter");
  Serial.print("CS="); Serial.println(SD_CS);
  Serial.print("MOSI="); Serial.println(SD_MOSI);
  Serial.print("SCK="); Serial.println(SD_SCK);
  Serial.print("MISO="); Serial.println(SD_MISO);

  for (unsigned int i = 0; i < (sizeof(SD_TEST_SPEEDS) / sizeof(SD_TEST_SPEEDS[0])); i++) {
    if (tryMount(SD_TEST_SPEEDS[i])) {
      mounted = true;
      Serial.print("SELECTED_SPI_HZ=");
      Serial.println(SD_TEST_SPEEDS[i]);
      break;
    }
  }

  if (!mounted) {
    Serial.println();
    Serial.println("FINAL_RESULT=NO_MOUNT_AT_ANY_SPEED");
    Serial.println("CHECK FAT32, CARD, MODULE SOCKET AND SPI CONTINUITY.");
    return;
  }

  bool writeOk = writeAndReadback();
  Serial.println();
  Serial.print("FINAL_RESULT=");
  Serial.println(writeOk ? "MOUNT_AND_WRITE_OK" : "MOUNT_OK_WRITE_FAILED");
  Serial.println("Test finalizado; no se realizan escrituras continuas.");
}

void loop() {
  delay(1000);
}
