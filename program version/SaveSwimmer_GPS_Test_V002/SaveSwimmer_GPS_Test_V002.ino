/*
====================================================
SAVE SWIMMER
GPS TEST: SS-GPS-TEST-V002
DEVICE: SS-LT-000001
====================================================
ESP32-S3 + GPS NEO-M9N / GY-GPS6MV2
AUTO BAUD NMEA TEST SIN LIBRERIAS EXTERNAS
====================================================

Conexion:
GPS VCC -> ESP32 3V3
GPS GND -> ESP32 GND
GPS TX  -> ESP32 GPIO17
GPS RX  -> ESP32 GPIO18

Monitor Serie:
115200 baudios
====================================================
*/

#define DEVICE_SERIAL "SS-LT-000001"
#define TEST_VERSION "SS-GPS-TEST-V002"

#define GPS_RX_PIN 17
#define GPS_TX_PIN 18

HardwareSerial gpsSerial(1);

const long baudRates[] = {9600, 38400, 57600, 115200};
const int baudRateCount = sizeof(baudRates) / sizeof(baudRates[0]);

int currentBaudIndex = 0;
long lockedBaud = 0;
String nmeaLine = "";
unsigned long baudStartedMs = 0;
unsigned long lastStatusMs = 0;
unsigned long lastGpsByteMs = 0;
unsigned long lastGoodNmeaMs = 0;
unsigned long nmeaLines = 0;
unsigned long validLines = 0;
unsigned long garbageLines = 0;

String lastUtc = "NO_TIME";
String lastLat = "NO_LAT";
String lastLon = "NO_LON";
String lastFixQuality = "0";
String lastSatellites = "0";
String lastHdop = "0";
String lastSpeedKmh = "0";
String lastCourse = "0";

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
  if (dot < 0) return 0.0;
  int degDigits = dot > 4 ? 3 : 2;
  float degrees = raw.substring(0, degDigits).toFloat();
  float minutes = raw.substring(degDigits).toFloat();
  float decimal = degrees + (minutes / 60.0);
  if (hemisphere == "S" || hemisphere == "W") decimal *= -1.0;
  return decimal;
}

bool looksLikeNmea(const String& line) {
  return line.startsWith("$GP") || line.startsWith("$GN") || line.startsWith("$GL") || line.startsWith("$GA");
}

void startGpsBaud(long baud) {
  gpsSerial.end();
  delay(100);
  nmeaLine = "";
  baudStartedMs = millis();
  Serial.println("--------------------------------");
  Serial.print("TESTING GPS BAUD: ");
  Serial.println(baud);
  gpsSerial.begin(baud, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
}

void nextBaud() {
  currentBaudIndex++;
  if (currentBaudIndex >= baudRateCount) {
    currentBaudIndex = 0;
  }
  startGpsBaud(baudRates[currentBaudIndex]);
}

void parseGGA(const String& line) {
  String utc = getCsvField(line, 1);
  String latRaw = getCsvField(line, 2);
  String latHem = getCsvField(line, 3);
  String lonRaw = getCsvField(line, 4);
  String lonHem = getCsvField(line, 5);
  String quality = getCsvField(line, 6);
  String satellites = getCsvField(line, 7);
  String hdop = getCsvField(line, 8);

  if (utc.length() > 0) lastUtc = utc;
  if (quality.length() > 0) lastFixQuality = quality;
  if (satellites.length() > 0) lastSatellites = satellites;
  if (hdop.length() > 0) lastHdop = hdop;

  if (quality.toInt() > 0 && latRaw.length() > 0 && lonRaw.length() > 0) {
    lastLat = String(nmeaCoordToDecimal(latRaw, latHem), 6);
    lastLon = String(nmeaCoordToDecimal(lonRaw, lonHem), 6);
  }
}

void parseRMC(const String& line) {
  String utc = getCsvField(line, 1);
  String status = getCsvField(line, 2);
  String latRaw = getCsvField(line, 3);
  String latHem = getCsvField(line, 4);
  String lonRaw = getCsvField(line, 5);
  String lonHem = getCsvField(line, 6);
  String speedKnots = getCsvField(line, 7);
  String course = getCsvField(line, 8);

  if (utc.length() > 0) lastUtc = utc;
  if (speedKnots.length() > 0) lastSpeedKmh = String(speedKnots.toFloat() * 1.852, 2);
  if (course.length() > 0) lastCourse = course;

  if (status == "A" && latRaw.length() > 0 && lonRaw.length() > 0) {
    lastLat = String(nmeaCoordToDecimal(latRaw, latHem), 6);
    lastLon = String(nmeaCoordToDecimal(lonRaw, lonHem), 6);
  }
}

void handleLine(String line) {
  line.trim();
  if (line.length() == 0) return;

  nmeaLines++;
  if (!looksLikeNmea(line)) {
    garbageLines++;
    if (garbageLines <= 6) {
      Serial.print("GARBAGE ");
      Serial.print(garbageLines);
      Serial.print(": ");
      Serial.println(line);
    }
    return;
  }

  validLines++;
  lastGoodNmeaMs = millis();
  if (lockedBaud == 0) {
    lockedBaud = baudRates[currentBaudIndex];
    Serial.print("GPS BAUD LOCKED: ");
    Serial.println(lockedBaud);
  }

  Serial.print("NMEA OK ");
  Serial.print(validLines);
  Serial.print(": ");
  Serial.println(line);

  if (line.startsWith("$GPGGA") || line.startsWith("$GNGGA")) {
    parseGGA(line);
  } else if (line.startsWith("$GPRMC") || line.startsWith("$GNRMC")) {
    parseRMC(line);
  }
}

void printStatus() {
  Serial.println("--------------------------------");
  Serial.println("SAVE SWIMMER GPS STATUS");
  Serial.print("CURRENT BAUD: ");
  Serial.println(baudRates[currentBaudIndex]);
  Serial.print("LOCKED BAUD: ");
  Serial.println(lockedBaud > 0 ? String(lockedBaud) : "NO");
  Serial.print("GPS BYTES: ");
  Serial.println(lastGpsByteMs > 0 ? "YES" : "NO");
  Serial.print("TOTAL LINES: ");
  Serial.println(nmeaLines);
  Serial.print("VALID NMEA: ");
  Serial.println(validLines);
  Serial.print("GARBAGE LINES: ");
  Serial.println(garbageLines);
  Serial.print("UTC: ");
  Serial.println(lastUtc);
  Serial.print("FIX QUALITY: ");
  Serial.println(lastFixQuality);
  Serial.print("SATELLITES: ");
  Serial.println(lastSatellites);
  Serial.print("HDOP: ");
  Serial.println(lastHdop);
  Serial.print("LAT: ");
  Serial.println(lastLat);
  Serial.print("LON: ");
  Serial.println(lastLon);
  Serial.print("SPEED KMH: ");
  Serial.println(lastSpeedKmh);
  Serial.print("COURSE: ");
  Serial.println(lastCourse);
  Serial.println("--------------------------------");
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("================================");
  Serial.println("SAVE SWIMMER GPS TEST STARTING");
  Serial.println(DEVICE_SERIAL);
  Serial.println(TEST_VERSION);
  Serial.print("GPS RX PIN: ");
  Serial.println(GPS_RX_PIN);
  Serial.print("GPS TX PIN: ");
  Serial.println(GPS_TX_PIN);
  Serial.println("================================");

  startGpsBaud(baudRates[currentBaudIndex]);
}

void loop() {
  while (gpsSerial.available()) {
    char c = gpsSerial.read();
    lastGpsByteMs = millis();

    if (c == '\n') {
      handleLine(nmeaLine);
      nmeaLine = "";
    } else if (c != '\r') {
      if (nmeaLine.length() < 120) {
        nmeaLine += c;
      } else {
        nmeaLine = "";
      }
    }
  }

  if (lockedBaud == 0 && millis() - baudStartedMs >= 7000) {
    nextBaud();
  }

  if (lockedBaud > 0 && millis() - lastGoodNmeaMs > 20000) {
    Serial.println("GPS LOCK LOST - RESTARTING BAUD SCAN");
    lockedBaud = 0;
    validLines = 0;
    garbageLines = 0;
    currentBaudIndex = 0;
    startGpsBaud(baudRates[currentBaudIndex]);
  }

  if (millis() - lastStatusMs >= 5000) {
    lastStatusMs = millis();
    printStatus();
  }
}
