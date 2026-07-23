/*
====================================================
SAVE SWIMMER MICROSD STRESS TEST
FIRMWARE: SS-MICROSD-STRESS-V002
====================================================
Prueba aislada para confirmar estabilidad de microSD,
alimentacion y cableado sin BLE ni MPU6050.
====================================================
*/

#include <SPI.h>
#include <SD.h>

#define TEST_VERSION "SS-MICROSD-STRESS-V002"
#define SD_CS   10
#define SD_MOSI 11
#define SD_SCK  12
#define SD_MISO 13
#define SD_SPI_HZ 1000000
#define SAMPLE_MS 100
#define SYNC_MS 3000
#define TEST_FILE "/STRESS.CSV"

SPIClass sdSPI(FSPI);
File stressFile;

bool recording = false;
unsigned long rowNumber = 0;
unsigned long lastSample = 0;
unsigned long lastSync = 0;

void stopWithError(const char* reason) {
  Serial.print("STRESS ERROR: ");
  Serial.println(reason);
  if (stressFile) {
    stressFile.flush();
    stressFile.close();
  }
  recording = false;
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("================================");
  Serial.println("SAVE SWIMMER MICROSD STRESS TEST");
  Serial.println(TEST_VERSION);
  Serial.println("TARGET: keep recording at least 10 minutes");
  Serial.println("================================");
  Serial.print("CS: "); Serial.println(SD_CS);
  Serial.print("MOSI: "); Serial.println(SD_MOSI);
  Serial.print("SCK: "); Serial.println(SD_SCK);
  Serial.print("MISO: "); Serial.println(SD_MISO);
  Serial.print("SPI HZ: "); Serial.println(SD_SPI_HZ);

  pinMode(SD_CS, OUTPUT);
  digitalWrite(SD_CS, HIGH);
  sdSPI.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);

  if (!SD.begin(SD_CS, sdSPI, SD_SPI_HZ)) {
    Serial.println("MICROSD INIT FAILED");
    return;
  }

  stressFile = SD.open(TEST_FILE, FILE_APPEND);
  if (!stressFile) {
    Serial.println("STRESS FILE OPEN FAILED");
    return;
  }

  if (stressFile.size() == 0) {
    stressFile.println("test_version,row,elapsed_ms,payload");
  }
  stressFile.print(TEST_VERSION);
  stressFile.println(",START,0,BEGIN");
  stressFile.flush();

  recording = true;
  lastSample = millis();
  lastSync = millis();
  Serial.println("STRESS RECORDING STARTED: /STRESS.CSV");
}

void loop() {
  if (!recording) {
    delay(1000);
    return;
  }

  unsigned long now = millis();
  if (now - lastSample >= SAMPLE_MS) {
    lastSample = now;
    rowNumber++;

    stressFile.print(TEST_VERSION);
    stressFile.print(",");
    stressFile.print(rowNumber);
    stressFile.print(",");
    stressFile.print(now);
    stressFile.println(",SAVE_SWIMMER_SD_STABILITY_CHECK");

    if (!stressFile) {
      stopWithError("WRITE_STREAM_INVALID");
      return;
    }
  }

  if (now - lastSync >= SYNC_MS) {
    lastSync = now;
    stressFile.flush();
    Serial.print("STRESS CHECKPOINT;ROWS=");
    Serial.println(rowNumber);
  }
}
