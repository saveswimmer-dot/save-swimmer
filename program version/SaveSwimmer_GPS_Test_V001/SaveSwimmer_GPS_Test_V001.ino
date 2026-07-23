/*
====================================================
SAVE SWIMMER
GPS TEST: SS-GPS-TEST-V001
DEVICE: SS-LT-000001
====================================================
ESP32-S3 + GPS NEO-M9N / GY-GPS6MV2
UART TEST SIN LIBRERIAS EXTERNAS
====================================================

Conexion recomendada:
GPS VCC -> ESP32 3V3
GPS GND -> ESP32 GND
GPS TX  -> ESP32 GPIO17
GPS RX  -> ESP32 GPIO18

Monitor Serie:
115200 baudios
====================================================
*/

#define DEVICE_SERIAL "SS-LT-000001"
#define TEST_VERSION "SS-GPS-TEST-V001"

#define GPS_RX_PIN 17
#define GPS_TX_PIN 18
#define GPS_BAUD 9600

HardwareSerial gpsSerial(1);

String nmeaLine = "";
unsigned long lastGpsByteMs = 0;
unsigned long lastStatusMs = 0;
unsigned long lastFixMs = 0;
unsigned long nmeaLines = 0;

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
  if (raw.length() < 4) {
    return 0.0;
  }

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

void parseGGA(const String& line) {
  String utc = getCsvField(line, 1);
  String latRaw = getCsvField(line, 2);
  String latHem = getCsvField(line, 3);
  String lonRaw = getCsvField(line, 4);
  String lonHem = getCsvField(line, 5);
  String quality = getCsvField(line, 6);
  String satellites = getCsvField(line, 7);
  String hdop = getCsvField(line, 8);

  lastUtc = utc.length() > 0 ? utc : lastUtc;
  lastFixQuality = quality.length() > 0 ? quality : "0";
  lastSatellites = satellites.length() > 0 ? satellites : "0";
  lastHdop = hdop.length() > 0 ? hdop : "0";

  if (quality.toInt() > 0 && latRaw.length() > 0 && lonRaw.length() > 0) {
    lastLat = String(nmeaCoordToDecimal(latRaw, latHem), 6);
    lastLon = String(nmeaCoordToDecimal(lonRaw, lonHem), 6);
    lastFixMs = millis();
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

  lastUtc = utc.length() > 0 ? utc : lastUtc;
  if (speedKnots.length() > 0) {
    lastSpeedKmh = String(speedKnots.toFloat() * 1.852, 2);
  }
  if (course.length() > 0) {
    lastCourse = course;
  }

  if (status == "A" && latRaw.length() > 0 && lonRaw.length() > 0) {
    lastLat = String(nmeaCoordToDecimal(latRaw, latHem), 6);
    lastLon = String(nmeaCoordToDecimal(lonRaw, lonHem), 6);
    lastFixMs = millis();
  }
}

void handleNmeaLine(String line) {
  line.trim();
  if (line.length() == 0) {
    return;
  }

  nmeaLines++;
  Serial.print("NMEA ");
  Serial.print(nmeaLines);
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
  Serial.print("GPS BYTES: ");
  Serial.println(lastGpsByteMs > 0 ? "YES" : "NO");
  Serial.print("NMEA LINES: ");
  Serial.println(nmeaLines);
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
  Serial.print("LAST FIX AGE MS: ");
  Serial.println(lastFixMs > 0 ? String(millis() - lastFixMs) : "NO_FIX");
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
  Serial.print("GPS BAUD: ");
  Serial.println(GPS_BAUD);
  Serial.println("================================");

  gpsSerial.begin(GPS_BAUD, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
  Serial.println("WAITING GPS NMEA...");
}

void loop() {
  while (gpsSerial.available()) {
    char c = gpsSerial.read();
    lastGpsByteMs = millis();

    if (c == '\n') {
      handleNmeaLine(nmeaLine);
      nmeaLine = "";
    } else if (c != '\r') {
      if (nmeaLine.length() < 120) {
        nmeaLine += c;
      } else {
        nmeaLine = "";
      }
    }
  }

  if (millis() - lastStatusMs >= 5000) {
    lastStatusMs = millis();
    printStatus();
  }
}
