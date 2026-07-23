package com.saveswimmer.fieldviewer;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.os.ParcelUuid;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.DashPathEffect;
import android.graphics.Paint;
import android.graphics.Path;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Queue;
import java.util.Scanner;
import java.util.TimeZone;
import java.util.UUID;

public class MainActivity extends Activity {
    private static final String DEVICE_NAME = "SS-LT-000001";
    private static final UUID SERVICE_UUID = UUID.fromString("8f1c1000-5a7e-4b3d-9c21-a10000000001");
    private static final UUID TELEMETRY_UUID = UUID.fromString("8f1c1001-5a7e-4b3d-9c21-a10000000001");
    private static final UUID CONFIG_UUID = UUID.fromString("8f1c1002-5a7e-4b3d-9c21-a10000000001");
    private static final UUID CCCD_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
    private static final long GATEWAY_SEND_INTERVAL_MS = 5000L;

    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothLeScanner scanner;
    private BluetoothGatt gatt;
    private BluetoothGattCharacteristic telemetryCharacteristic;
    private BluetoothGattCharacteristic configCharacteristic;
    private boolean scanning = false;
    private boolean recording = false;

    private TextView statusText;
    private TextView scanLogText;
    private TextView rawText;
    private TextView configStatusText;
    private EditText userNameInput;
    private StrokeTimelineView strokeTimelineView;
    private Button connectButton;
    private Button sendUserButton;
    private Button startSessionButton;
    private Button stopSessionButton;
    private Button downloadSessionButton;
    private Button downloadRawSessionButton;
    private Button demoAnalysisButton;
    private Button recordButton;
    private Button saveButton;
    private Button gatewayButton;
    private Button placementBaseButton;
    private TextView gatewayStatusText;
    private EditText gatewayUrlInput;
    private TextView deviceGpsText;
    private TextView strokeWindowText;
    private TextView deviceSessionText;
    private TextView analysisStatusText;
    private TextView analysisSummaryText;
    private TextView analysisZeroText;
    private TextView analysisRotationText;
    private TextView analysisPaceText;
    private TextView analysisRegularityText;
    private TextView analysisImpulseText;
    private DownloadAnalysisLoopView analysisLoopView;

    private final StringBuilder csv = new StringBuilder();
    private boolean csvHeaderReady = false;
    private final StringBuilder downloadedCsv = new StringBuilder();
    private String downloadedFilename = "";
    private int downloadedExpectedBytes = 0;
    private int downloadedLastSequence = 0;
    private boolean downloadingSession = false;
    private boolean downloadedSessionClean = false;
    private boolean gatewayEnabled = false;
    private boolean gatewaySending = false;
    private long lastGatewaySendMs = 0;
    private SensorSample latestSample = null;
    private DeviceGpsSample latestDeviceGps = null;
    private Location latestLocation = null;
    private Location gatewayBaseLocation = null;
    private LocationManager locationManager;

    private final LocationListener locationListener = new LocationListener() {
        @Override
        public void onLocationChanged(Location location) {
            latestLocation = location;
            updateDeviceGpsPanel();
            updateGatewayStatus("GPS telefono: " + gpsSummary(location) + " | GPS ESP "
                    + deviceGpsSummary(latestDeviceGps) + " | Gateway "
                    + (gatewayEnabled ? "ON" : "OFF"));
        }
    };

    private final ScanCallback scanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            BluetoothDevice device = result.getDevice();
            String name = scanResultName(result);
            appendScanLog(name, device.getAddress(), result.getRssi());
            if (isSaveSwimmer(result, name)) {
                stopScan();
                setStatus("Conectando a " + (name == null ? "Save Swimmer" : name) + "...");
                connectGatt(device);
            }
        }

        @Override
        public void onScanFailed(int errorCode) {
            setStatus("Error de escaneo BLE: " + errorCode);
            mainHandler.post(() -> scanLogText.setText(scanLogText.getText() + "SCAN FAILED: " + errorCode + "\n"));
        }
    };

    private final BluetoothGattCallback gattCallback = new BluetoothGattCallback() {
        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                setStatus("BLE conectado. Buscando servicio...");
                requestMtuThenDiscover(gatt);
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                setStatus("Desconectado");
                closeGatt();
            }
        }

        @Override
        public void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
            gatt.discoverServices();
        }

        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            BluetoothGattService service = gatt.getService(SERVICE_UUID);
            if (service == null) {
                setStatus("Servicio Save Swimmer no encontrado");
                return;
            }

            BluetoothGattCharacteristic characteristic = service.getCharacteristic(TELEMETRY_UUID);
            if (characteristic == null) {
                setStatus("Caracteristica de telemetria no encontrada");
                return;
            }

            telemetryCharacteristic = characteristic;

            BluetoothGattCharacteristic config = service.getCharacteristic(CONFIG_UUID);
            if (config != null) {
                configCharacteristic = config;
                int props = config.getProperties();
                mainHandler.post(() -> configStatusText.setText("Config BLE lista. Props: " + props));
            } else {
                configCharacteristic = characteristic;
                mainHandler.post(() -> configStatusText.setText("Config BLE 1002 no encontrada. Usando respaldo 1001. Carga firmware V014 si falla."));
            }

            enableNotifications(gatt, characteristic);
        }

        @Override
        public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
            String written = new String(characteristic.getValue(), StandardCharsets.UTF_8);
            if (written.startsWith("FILE:ACK;")) {
                return;
            }
            String message = status == BluetoothGatt.GATT_SUCCESS
                    ? "Configuracion enviada al dispositivo"
                    : "Error enviando configuracion BLE: " + status;
            mainHandler.post(() -> {
                configStatusText.setText(message);
                toast(message);
            });
        }

        @Override
        public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                mainHandler.postDelayed(() -> writeConfigPayload("PROFILE?", "Leyendo perfil del dispositivo: "), 250);
                mainHandler.postDelayed(() -> writeConfigPayload("STATUS?", "Leyendo sesion del dispositivo: "), 700);
            } else {
                setStatus("Conectado, pero no se activaron notificaciones BLE");
            }
        }

        @Override
        public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
            byte[] bytes = characteristic.getValue();
            String text = new String(bytes, StandardCharsets.UTF_8);
            mainHandler.post(() -> handleTelemetry(text));
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        buildUi();

        BluetoothManager manager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        bluetoothAdapter = manager.getAdapter();
        scanner = bluetoothAdapter == null ? null : bluetoothAdapter.getBluetoothLeScanner();

        requestNeededPermissions();
    }

    @Override
    protected void onDestroy() {
        stopGateway();
        stopScan();
        closeGatt();
        super.onDestroy();
    }

    private void buildUi() {
        int cyan = Color.rgb(40, 215, 236);
        int bg = Color.rgb(4, 11, 16);
        int panel = Color.rgb(13, 32, 41);
        int text = Color.rgb(237, 248, 251);
        int muted = Color.rgb(145, 172, 181);

        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(bg);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(16), dp(18), dp(16), dp(18));
        scroll.addView(root);

        TextView title = text("SAVE SWIMMER", 24, text, true);
        title.setLetterSpacing(0.18f);
        root.addView(title);

        TextView subtitle = text("Field Viewer BLE | FIELD V0.3.48", 14, cyan, true);
        subtitle.setLetterSpacing(0.12f);
        root.addView(subtitle);

        TextView connectionTitle = text("Conexion BLE", 13, cyan, true);
        connectionTitle.setPadding(0, dp(14), 0, dp(6));
        root.addView(connectionTitle);

        statusText = text("Desconectado", 14, muted, false);
        statusText.setPadding(0, dp(4), 0, dp(4));
        root.addView(statusText);

        connectButton = button("Conectar BLE", cyan, Color.rgb(3, 33, 38));
        connectButton.setOnClickListener(v -> startScan());
        root.addView(connectButton);

        scanLogText = text("Escaneo: sin iniciar", 12, muted, false);
        scanLogText.setPadding(0, dp(4), 0, dp(4));
        root.addView(scanLogText);

        TextView configTitle = text("Bloque 2 | Atleta de prueba", 14, cyan, true);
        configTitle.setPadding(0, dp(14), 0, dp(6));
        root.addView(configTitle);

        userNameInput = input("Nombre / atleta", "", panel, text, muted);
        root.addView(userNameInput);

        sendUserButton = button("Enviar perfil al dispositivo", cyan, Color.rgb(3, 33, 38));
        sendUserButton.setOnClickListener(v -> sendUserProfile());
        root.addView(sendUserButton);

        configStatusText = text("Perfil aun no enviado", 12, muted, false);
        configStatusText.setPadding(0, dp(8), 0, dp(4));
        root.addView(configStatusText);

        TextView sessionTitle = text("Bloque 3 | Registro microSD", 14, cyan, true);
        sessionTitle.setPadding(0, dp(14), 0, dp(6));
        root.addView(sessionTitle);

        startSessionButton = button("Iniciar sesion en dispositivo", cyan, Color.rgb(3, 33, 38));
        startSessionButton.setOnClickListener(v -> startDeviceSession());
        root.addView(startSessionButton);

        stopSessionButton = button("Detener y cerrar archivo SD", Color.rgb(17, 43, 54), text);
        stopSessionButton.setOnClickListener(v -> stopDeviceSession());
        root.addView(stopSessionButton);

        TextView sessionHint = text("Al finalizar, descarga el resumen rapido. El CSV completo queda en microSD y su descarga BLE es solo para diagnostico.", 12, muted, false);
        sessionHint.setPadding(dp(12), dp(8), dp(12), dp(10));
        sessionHint.setBackgroundColor(panel);
        root.addView(sessionHint);

        downloadSessionButton = button("Descargar resumen rapido por BLE", Color.rgb(17, 43, 54), text);
        downloadSessionButton.setOnClickListener(v -> downloadLatestDeviceSummary());
        root.addView(downloadSessionButton);

        downloadRawSessionButton = button("Descargar CSV completo | diagnostico lento", Color.rgb(12, 31, 40), muted);
        downloadRawSessionButton.setOnClickListener(v -> downloadLatestDeviceSession());
        root.addView(downloadRawSessionButton);

        deviceSessionText = text("Esperando inicio. Primero envia el perfil del atleta.", 12, muted, false);
        deviceSessionText.setPadding(dp(12), dp(8), dp(12), dp(10));
        deviceSessionText.setBackgroundColor(panel);
        root.addView(deviceSessionText);

        TextView liveTitle = text("Telemetria corporal en vivo", 15, cyan, true);
        liveTitle.setPadding(0, dp(18), 0, dp(6));
        root.addView(liveTitle);

        TextView strokeTitle = text("Rotacion + alineacion + movimiento | ventana 30 s + historial", 14, cyan, true);
        strokeTitle.setPadding(0, dp(6), 0, dp(6));
        root.addView(strokeTitle);

        placementBaseButton = button("Tomar base de colocacion", Color.rgb(17, 43, 54), text);
        placementBaseButton.setOnClickListener(v -> takePlacementBase());
        root.addView(placementBaseButton);

        strokeTimelineView = new StrokeTimelineView(this);
        strokeTimelineView.setBackgroundColor(Color.rgb(7, 21, 28));
        LinearLayout.LayoutParams strokeParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(760)
        );
        strokeParams.setMargins(0, dp(4), 0, dp(6));
        root.addView(strokeTimelineView, strokeParams);

        strokeWindowText = text("Ventana en vivo lista. Rotacion dorsal, alineacion corporal y movimiento/picos.", 12, muted, false);
        strokeWindowText.setPadding(dp(12), dp(8), dp(12), dp(12));
        root.addView(strokeWindowText);

        TextView deviceGpsTitle = text("GPS del dispositivo", 14, cyan, true);
        deviceGpsTitle.setPadding(0, dp(14), 0, dp(6));
        root.addView(deviceGpsTitle);

        deviceGpsText = text("Esperando paquetes GPS del ESP. Debe llegar un paquete G: desde firmware V050.", 13, muted, false);
        deviceGpsText.setPadding(dp(12), dp(10), dp(12), dp(12));
        deviceGpsText.setBackgroundColor(panel);
        root.addView(deviceGpsText);

        TextView diagnosticsTitle = text("Herramientas | Diagnostico local", 14, cyan, true);
        diagnosticsTitle.setPadding(0, dp(16), 0, dp(6));
        root.addView(diagnosticsTitle);

        rawText = text("Diagnostico BLE local opcional. La sesion oficial queda en microSD.", 13, muted, false);
        rawText.setPadding(dp(12), dp(12), dp(12), dp(12));
        rawText.setBackgroundColor(panel);
        LinearLayout.LayoutParams rawParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        rawParams.setMargins(0, dp(10), 0, dp(10));
        root.addView(rawText, rawParams);

        recordButton = button("Diagnostico BLE local: OFF", Color.rgb(17, 43, 54), text);
        recordButton.setOnClickListener(v -> {
            recording = !recording;
            recordButton.setText(recording ? "Diagnostico BLE local: ON" : "Diagnostico BLE local: OFF");
        });
        root.addView(recordButton);

        saveButton = button("Guardar CSV BLE local", Color.rgb(17, 43, 54), text);
        saveButton.setOnClickListener(v -> saveCsv());
        root.addView(saveButton);

        TextView gatewayTitle = text("Herramientas | Gateway opcional", 14, cyan, true);
        gatewayTitle.setPadding(0, dp(18), 0, dp(6));
        root.addView(gatewayTitle);

        gatewayUrlInput = input("URL servidor /api/telemetry", "http://192.168.1.100:8787/api/telemetry", panel, text, muted);
        root.addView(gatewayUrlInput);

        gatewayButton = button("Gateway GSM: OFF", Color.rgb(17, 43, 54), text);
        gatewayButton.setOnClickListener(v -> toggleGateway());
        root.addView(gatewayButton);

        gatewayStatusText = text("Opcional. Solo para enviar BLE + GPS del dispositivo hacia dashboard remoto.", 12, muted, false);
        gatewayStatusText.setPadding(dp(12), dp(8), dp(12), dp(10));
        gatewayStatusText.setBackgroundColor(panel);
        root.addView(gatewayStatusText);

        setContentView(scroll);
    }

    private void takePlacementBase() {
        if (latestSample == null) {
            toast("Aun no hay telemetria para tomar base");
            return;
        }
        strokeTimelineView.takePlacementBase(latestSample);
        strokeWindowText.setText(strokeTimelineView.readout());
        toast("Base de colocacion tomada");
    }

    private void toggleGateway() {
        if (gatewayEnabled) {
            stopGateway();
        } else {
            startGateway();
        }
    }

    private void startGateway() {
        String url = gatewayUrlInput == null ? "" : gatewayUrlInput.getText().toString().trim();
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            toast("Ingresa una URL http/https del backend");
            return;
        }
        if (!hasBlePermissions()) {
            requestNeededPermissions();
            toast("Permite Bluetooth y ubicacion para Gateway");
            return;
        }

        gatewayEnabled = true;
        lastGatewaySendMs = 0;
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        startPhoneLocation();
        gatewayBaseLocation = latestLocation;
        if (gatewayButton != null) {
            gatewayButton.setText("Gateway GSM: ON");
            gatewayButton.setBackgroundColor(Color.rgb(40, 215, 236));
            gatewayButton.setTextColor(Color.rgb(3, 33, 38));
        }
        Location gatewayLocation = gatewayLocation();
        gatewayBaseLocation = gatewayLocation;
        String baseText = gatewayBaseLocation == null ? "Base pendiente: esperando GPS del dispositivo o telefono." : "Base fijada: " + gpsSummary(gatewayBaseLocation);
        updateGatewayStatus("Gateway ON. Pantalla protegida para mantener BLE activo. " + baseText + " Esperando telemetria BLE.");
    }

    private void stopGateway() {
        gatewayEnabled = false;
        gatewaySending = false;
        gatewayBaseLocation = null;
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        if (gatewayButton != null) {
            gatewayButton.setText("Gateway GSM: OFF");
            gatewayButton.setBackgroundColor(Color.rgb(17, 43, 54));
            gatewayButton.setTextColor(Color.rgb(237, 248, 251));
        }
        stopPhoneLocation();
        updateGatewayStatus("Gateway OFF. No se suben datos a internet.");
    }

    private void startPhoneLocation() {
        if (!hasBlePermissions()) return;
        try {
            locationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
            if (locationManager == null) return;
            Location gps = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER);
            Location network = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
            latestLocation = newerLocation(gps, network);
            locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1000, 0f, locationListener, Looper.getMainLooper());
            locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 1500, 1f, locationListener, Looper.getMainLooper());
        } catch (SecurityException ignored) {
            requestNeededPermissions();
        } catch (Exception error) {
            updateGatewayStatus("No se pudo iniciar GPS telefono: " + error.getMessage());
        }
    }

    private void stopPhoneLocation() {
        if (locationManager == null) return;
        try {
            locationManager.removeUpdates(locationListener);
        } catch (SecurityException ignored) {
        }
    }

    private Location newerLocation(Location a, Location b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.getTime() >= b.getTime() ? a : b;
    }

    private String gpsSummary(Location location) {
        if (location == null) return "sin ubicacion";
        return String.format(Locale.US, "%.5f, %.5f acc %.0fm",
                location.getLatitude(), location.getLongitude(), location.getAccuracy());
    }

    private String deviceGpsSummary(DeviceGpsSample gps) {
        if (gps == null) return "sin datos";
        if (!gps.valid()) {
            return String.format(Locale.US, "sin fix | sats %d | hdop %.2f", gps.satellites, gps.hdop);
        }
        return String.format(Locale.US, "%.6f, %.6f | %.2f km/h | sats %d | hdop %.2f",
                gps.lat, gps.lon, gps.speedKmh, gps.satellites, gps.hdop);
    }

    private String deviceGpsPanelText() {
        String phoneText = "Telefono: " + gpsSummary(latestLocation);
        if (latestDeviceGps == null) {
            return "ESP GPS: esperando paquete G:\n"
                    + phoneText + "\n"
                    + "Mapa: usara GPS del telefono hasta recibir fix del ESP.";
        }
        if (!latestDeviceGps.valid()) {
            return String.format(Locale.US,
                    "ESP GPS: SIN FIX\nSatelites: %d | HDOP: %.2f | edad: %d ms\nLat/Lon: --\nVelocidad: --\n%s\nMapa: aun no hay ubicacion valida del ESP.",
                    latestDeviceGps.satellites,
                    latestDeviceGps.hdop,
                    latestDeviceGps.ageMs,
                    phoneText);
        }
        return String.format(Locale.US,
                "ESP GPS: FIX OK\nLat/Lon: %.6f, %.6f\nVelocidad: %.2f km/h | Satelites: %d | HDOP: %.2f | edad: %d ms\n%s\nMapa: enviando ubicacion del ESP al dashboard Coach.",
                latestDeviceGps.lat,
                latestDeviceGps.lon,
                latestDeviceGps.speedKmh,
                latestDeviceGps.satellites,
                latestDeviceGps.hdop,
                latestDeviceGps.ageMs,
                phoneText);
    }

    private void updateDeviceGpsPanel() {
        if (deviceGpsText != null) {
            deviceGpsText.setText(deviceGpsPanelText());
        }
    }

    private void updateGatewayStatus(String text) {
        if (gatewayStatusText != null) {
            gatewayStatusText.setText(text);
        }
    }

    private void maybeSendGatewaySample(String raw, SensorSample sample) {
        if (!gatewayEnabled || gatewaySending || sample == null) return;
        long now = System.currentTimeMillis();
        if (now - lastGatewaySendMs < GATEWAY_SEND_INTERVAL_MS) return;
        lastGatewaySendMs = now;
        gatewaySending = true;

        String endpoint = gatewayUrlInput.getText().toString().trim();
        String user = cleanField(userNameInput.getText().toString(), "SIN_USUARIO");
        Location location = gatewayLocation();
        if (gatewayBaseLocation == null && location != null) {
            gatewayBaseLocation = location;
        }
        String payload = buildGatewayJson(endpoint, user, raw, sample, location);
        updateGatewayStatus("Gateway enviando... " + gatewaySourceLabel() + " " + gpsSummary(location));

        new Thread(() -> {
            int code = -1;
            String error = null;
            try {
                URL url = new URL(endpoint);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("POST");
                connection.setConnectTimeout(6000);
                connection.setReadTimeout(6000);
                connection.setDoOutput(true);
                connection.setRequestProperty("Content-Type", "application/json; charset=utf-8");
                byte[] bytes = payload.getBytes(StandardCharsets.UTF_8);
                connection.setFixedLengthStreamingMode(bytes.length);
                try (OutputStream out = connection.getOutputStream()) {
                    out.write(bytes);
                }
                code = connection.getResponseCode();
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                        code >= 200 && code < 300 ? connection.getInputStream() : connection.getErrorStream(),
                        StandardCharsets.UTF_8))) {
                    while (reader.readLine() != null) {
                        // consume response so the connection can close cleanly
                    }
                }
                connection.disconnect();
            } catch (Exception ex) {
                error = ex.getMessage();
            }

            int finalCode = code;
            String finalError = error;
            mainHandler.post(() -> {
                gatewaySending = false;
                if (finalCode >= 200 && finalCode < 300) {
                    updateGatewayStatus("Gateway OK -> " + finalCode + " | " + gatewaySourceLabel() + " " + gpsSummary(gatewayLocation())
                            + " | ultimo envio " + new SimpleDateFormat("HH:mm:ss", Locale.US).format(new Date()));
                } else {
                    updateGatewayStatus("Gateway fallo: " + (finalError == null ? ("HTTP " + finalCode) : finalError)
                            + " | revisa datos moviles/URL");
                }
            });
        }).start();
    }

    private String buildGatewayJson(String endpoint, String user, String raw, SensorSample sample, Location location) {
        StringBuilder json = new StringBuilder();
        json.append('{');
        json.append("\"serial\":\"").append(jsonSafe(DEVICE_NAME)).append("\",");
        json.append("\"user\":\"").append(jsonSafe(user)).append("\",");
        json.append("\"mode\":\"GATEWAY_FIELD_TEST\",");
        json.append("\"time\":\"").append(new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.US).format(new Date())).append("\",");
        json.append("\"lr\":").append(num(sample.lr)).append(',');
        json.append("\"fb\":").append(num(sample.fb)).append(',');
        json.append("\"ud\":").append(num(sample.ud)).append(',');
        json.append("\"mag\":").append(num(sample.mag)).append(',');
        if (location != null) {
            json.append("\"lat\":").append(num(location.getLatitude())).append(',');
            json.append("\"lon\":").append(num(location.getLongitude())).append(',');
            json.append("\"gpsAccuracy\":").append(num(location.getAccuracy())).append(',');
        }
        if (latestDeviceGps != null && latestDeviceGps.valid()) {
            json.append("\"speed\":").append(num(latestDeviceGps.speedKmh / 3.6)).append(',');
            json.append("\"gpsFix\":").append(latestDeviceGps.fix).append(',');
            json.append("\"gpsSats\":").append(latestDeviceGps.satellites).append(',');
            json.append("\"gpsHdop\":").append(num(latestDeviceGps.hdop)).append(',');
            json.append("\"gpsAgeMs\":").append(latestDeviceGps.ageMs).append(',');
            json.append("\"gpsSource\":\"ESP\",");
        } else {
            json.append("\"gpsSource\":\"PHONE\",");
        }
        if (gatewayBaseLocation != null) {
            json.append("\"baseLat\":").append(num(gatewayBaseLocation.getLatitude())).append(',');
            json.append("\"baseLon\":").append(num(gatewayBaseLocation.getLongitude())).append(',');
        }
        json.append("\"battery\":100,");
        json.append("\"water\":true,");
        json.append("\"motion\":\"MOVING\",");
        json.append("\"risk\":\"NORMAL\",");
        json.append("\"signal\":0,");
        json.append("\"gateway\":\"PHONE\",");
        json.append("\"raw\":\"").append(jsonSafe(raw)).append("\"");
        json.append('}');
        return json.toString();
    }

    private Location gatewayLocation() {
        if (latestDeviceGps != null && latestDeviceGps.valid()) {
            return latestDeviceGps.toLocation();
        }
        return latestLocation;
    }

    private String gatewaySourceLabel() {
        return latestDeviceGps != null && latestDeviceGps.valid() ? "GPS ESP" : "GPS telefono";
    }

    private String num(double value) {
        if (!Double.isFinite(value)) return "null";
        return String.format(Locale.US, "%.5f", value);
    }

    private String jsonSafe(String value) {
        if (value == null) return "";
        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r");
    }

    private TextView metric(LinearLayout root, String label, String value, int panel, int textColor, int muted) {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(13), dp(10), dp(13), dp(10));
        box.setBackgroundColor(panel);

        TextView labelView = text(label, 12, muted, false);
        TextView valueView = text(value, 26, textColor, true);
        box.addView(labelView);
        box.addView(valueView);

        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        params.setMargins(0, 0, 0, dp(8));
        root.addView(box, params);
        return valueView;
    }

    private EditText input(String hint, String value, int bg, int textColor, int hintColor) {
        EditText input = new EditText(this);
        input.setHint(hint);
        input.setText(value);
        input.setSingleLine(true);
        input.setTextColor(textColor);
        input.setHintTextColor(hintColor);
        input.setTextSize(15);
        input.setPadding(dp(12), 0, dp(12), 0);
        input.setBackgroundColor(bg);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(48)
        );
        params.setMargins(0, dp(6), 0, 0);
        input.setLayoutParams(params);
        return input;
    }

    private TextView text(String value, int sp, int color, boolean bold) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(sp);
        view.setTextColor(color);
        view.setGravity(Gravity.START);
        if (bold) {
            view.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
        }
        return view;
    }

    private Button button(String label, int bg, int fg) {
        Button button = new Button(this);
        button.setText(label);
        button.setTextColor(fg);
        button.setBackgroundColor(bg);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(48)
        );
        params.setMargins(0, dp(8), 0, 0);
        button.setLayoutParams(params);
        return button;
    }

    private void startScan() {
        if (scanner == null) {
            toast("Bluetooth BLE no disponible");
            return;
        }
        if (!hasBlePermissions()) {
            requestNeededPermissions();
            return;
        }
        closeGatt();
        csv.setLength(0);
        csvHeaderReady = false;

        scanning = true;
        setStatus("Buscando " + DEVICE_NAME + "...");
        scanLogText.setText("Escaneo iniciado. Dispositivos vistos:\n");
        scanner.startScan(scanCallback);
        mainHandler.postDelayed(this::stopScanIfNeeded, 20000);
    }

    private void stopScanIfNeeded() {
        if (scanning) {
            stopScan();
            setStatus("No encontrado. Revisa que el ESP32 este encendido.");
        }
    }

    private void stopScan() {
        if (scanner != null && scanning && hasBlePermissions()) {
            scanner.stopScan(scanCallback);
        }
        scanning = false;
    }

    private void connectGatt(BluetoothDevice device) {
        if (!hasBlePermissions()) {
            requestNeededPermissions();
            return;
        }
        gatt = device.connectGatt(this, false, gattCallback);
    }

    private void requestMtuThenDiscover(BluetoothGatt gatt) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            gatt.requestMtu(185);
        } else {
            gatt.discoverServices();
        }
    }

    private void enableNotifications(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
        if (!hasBlePermissions()) {
            requestNeededPermissions();
            return;
        }
        gatt.setCharacteristicNotification(characteristic, true);
        BluetoothGattDescriptor descriptor = characteristic.getDescriptor(CCCD_UUID);
        if (descriptor != null) {
            descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
            gatt.writeDescriptor(descriptor);
            setStatus("Conectado. Esperando telemetria...");
        } else {
            setStatus("Descriptor BLE2902 no encontrado");
        }
    }

    private void closeGatt() {
        if (gatt != null && hasBlePermissions()) {
            gatt.close();
        }
        gatt = null;
        telemetryCharacteristic = null;
        configCharacteristic = null;
    }

    private void sendUserProfile() {
        if (gatt == null) {
            configStatusText.setText("No conectado: primero conecta el dispositivo por BLE");
            toast("Primero conecta BLE");
            return;
        }
        String name = cleanField(userNameInput.getText().toString(), "SIN_NOMBRE");
        String age = "0";
        String height = "0";
        String weight = "0";
        String mode = "TEST";

        String payload = "CFG:USER=" + name
                + ";AGE=" + age
                + ";HEIGHT=" + height
                + ";WEIGHT=" + weight
                + ";MODE=" + mode;

        writeConfigPayload(payload, "Enviando perfil BLE: ");
    }

    private void startDeviceSession() {
        long epochSeconds = System.currentTimeMillis() / 1000L;
        int timezoneOffsetSeconds = TimeZone.getDefault().getOffset(System.currentTimeMillis()) / 1000;
        String payload = "SESSION:START;EPOCH=" + epochSeconds + ";OFFSET=" + timezoneOffsetSeconds;
        writeConfigPayload(payload, "Solicitando inicio SD: ");
        deviceSessionText.setText("Solicitando inicio. La hora sera tomada del telefono...");
    }

    private void stopDeviceSession() {
        writeConfigPayload("SESSION:STOP", "Solicitando cierre SD: ");
        deviceSessionText.setText("Solicitando cierre seguro del archivo...");
    }

    private void downloadLatestDeviceSession() {
        prepareDeviceDownload();
        writeConfigPayload("FILE:GET_LAST", "Solicitando CSV completo SD: ");
        deviceSessionText.setText("Solicitando CSV completo. Esta descarga puede tardar bastante...");
    }

    private void downloadLatestDeviceSummary() {
        prepareDeviceDownload();
        writeConfigPayload("FILE:GET_SUMMARY", "Solicitando resumen SD: ");
        deviceSessionText.setText("Solicitando resumen rapido de la ultima sesion...");
    }

    private void prepareDeviceDownload() {
        downloadedCsv.setLength(0);
        downloadedFilename = "";
        downloadedExpectedBytes = 0;
        downloadedLastSequence = 0;
        downloadingSession = false;
        downloadedSessionClean = false;
    }

    private void writeConfigPayload(String payload, String sendingLabel) {
        BluetoothGattCharacteristic target = configCharacteristic != null ? configCharacteristic : telemetryCharacteristic;
        if (gatt == null || target == null) {
            configStatusText.setText("No conectado: primero conecta el dispositivo por BLE");
            toast("Primero conecta BLE");
            return;
        }
        if (!hasBlePermissions()) {
            configStatusText.setText("Faltan permisos BLE. Acepta permisos y vuelve a conectar.");
            requestNeededPermissions();
            return;
        }

        int properties = target.getProperties();
        boolean canWrite = (properties & BluetoothGattCharacteristic.PROPERTY_WRITE) != 0;
        boolean canWriteNoResponse = (properties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0;

        if (!canWrite && !canWriteNoResponse) {
            configStatusText.setText("La caracteristica conectada no permite escritura. Props: " + properties + ". Revisa firmware V015.");
            toast("BLE sin escritura");
            return;
        }

        if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0) {
            target.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
        } else {
            target.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        }
        target.setValue(payload.getBytes(StandardCharsets.UTF_8));
        boolean started = gatt.writeCharacteristic(target);

        if (started) {
            String type = target.getWriteType() == BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                    ? "sin respuesta"
                    : "con respuesta";
            configStatusText.setText(sendingLabel + type + ": " + payload);
        } else {
            configStatusText.setText("No se pudo iniciar escritura BLE. Props: " + properties + " conectado=" + (gatt != null));
            toast("No se pudo enviar por BLE");
        }
    }

    private String cleanField(String value, String fallback) {
        String cleaned = value == null ? "" : value.trim().replace(";", " ").replace("=", " ");
        cleaned = cleaned.replaceAll("[^A-Za-z0-9_ .-]", "");
        return cleaned.length() == 0 ? fallback : cleaned;
    }

    private String cleanNumber(String value, String fallback) {
        String cleaned = value == null ? "" : value.trim().replace(",", ".");
        cleaned = cleaned.replaceAll("[^0-9.]", "");
        return cleaned.length() == 0 ? fallback : cleaned;
    }

    private String filenameSafe(String value) {
        String cleaned = value == null ? "" : value.toLowerCase(Locale.US).trim();
        cleaned = cleaned.replaceAll("[^a-z0-9]+", "_");
        cleaned = cleaned.replaceAll("^_+|_+$", "");
        return cleaned.length() == 0 ? "sin_usuario" : cleaned;
    }

    private String csvSafe(String value) {
        if (value == null) {
            return "";
        }
        return value.replace(",", " ").replace("\n", " ").replace("\r", " ").trim();
    }

    private void sendFileAck(int sequence) {
        BluetoothGattCharacteristic target = configCharacteristic != null ? configCharacteristic : telemetryCharacteristic;
        if (gatt == null || target == null || !hasBlePermissions()) {
            return;
        }
        int properties = target.getProperties();
        if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0) {
            target.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
        } else {
            target.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        }
        target.setValue(("FILE:ACK;SEQ=" + sequence).getBytes(StandardCharsets.UTF_8));
        gatt.writeCharacteristic(target);
    }

    private String responseField(String raw, String name) {
        String token = name + "=";
        int start = raw.indexOf(token);
        if (start < 0) {
            return "";
        }
        start += token.length();
        int end = raw.indexOf(';', start);
        return end < 0 ? raw.substring(start).trim() : raw.substring(start, end).trim();
    }

    private void applyDeviceProfile(String raw) {
        String user = responseField(raw, "USER");

        userNameInput.setText("SIN_USUARIO".equals(user) ? "" : user);
    }

    private void setProfileEditingEnabled(boolean enabled) {
        userNameInput.setEnabled(enabled);
        sendUserButton.setEnabled(enabled);
    }

    private void ensureCsvHeader() {
        if (csvHeaderReady) {
            return;
        }

        csv.append("#SAVE_SWIMMER_FIELD_VIEWER\n");
        csv.append("#user,").append(csvSafe(cleanField(userNameInput.getText().toString(), "SIN_USUARIO"))).append('\n');
        csv.append("#age,0\n");
        csv.append("#height_m,0\n");
        csv.append("#weight_kg,0\n");
        csv.append("#mode,TEST\n");
        csv.append("#created_at,").append(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(new Date())).append('\n');
        csv.append("time,lr,fb,ud,mag,raw\n");

        csvHeaderReady = true;
    }

    private void handleTelemetry(String raw) {
        if (raw.startsWith("FILE:BEGIN")) {
            downloadedCsv.setLength(0);
            downloadedFilename = responseField(raw, "NAME").replace("/", "");
            downloadedExpectedBytes = Integer.parseInt(responseField(raw, "BYTES"));
            downloadedLastSequence = 0;
            downloadedSessionClean = "YES".equals(responseField(raw, "CLEAN"));
            downloadingSession = true;
            deviceSessionText.setText((downloadedSessionClean ? "Descargando " : "Descargando sesion INCOMPLETA ")
                    + downloadedFilename + " desde el dispositivo: 0%");
            rawText.setText("Transferencia SD por BLE iniciada");
            return;
        }
        if (raw.startsWith("FILE:DATA;SEQ=")) {
            int payloadStart = raw.indexOf(';', "FILE:DATA;".length());
            if (payloadStart < 0) {
                return;
            }
            int sequence = Integer.parseInt(responseField(raw.substring(0, payloadStart), "SEQ"));
            if (sequence == downloadedLastSequence + 1) {
                downloadedCsv.append(raw.substring(payloadStart + 1));
                downloadedLastSequence = sequence;
            } else if (sequence > downloadedLastSequence + 1) {
                deviceSessionText.setText("Descarga incompleta: falta un bloque. Vuelve a descargar la sesion.");
                downloadingSession = false;
                return;
            }
            sendFileAck(sequence);
            int receivedBytes = downloadedCsv.toString().getBytes(StandardCharsets.UTF_8).length;
            int progress = downloadedExpectedBytes > 0 ? (receivedBytes * 100 / downloadedExpectedBytes) : 0;
            deviceSessionText.setText("Descargando " + downloadedFilename + " desde el dispositivo: " + Math.min(progress, 100) + "%");
            return;
        }
        if (raw.startsWith("FILE:END")) {
            int receivedBytes = downloadedCsv.toString().getBytes(StandardCharsets.UTF_8).length;
            downloadingSession = false;
            if (receivedBytes != downloadedExpectedBytes) {
                deviceSessionText.setText("Descarga incompleta: esperado " + downloadedExpectedBytes
                        + " bytes, recibidos " + receivedBytes + ". Reintenta.");
                toast("Descarga incompleta");
                return;
            }
            boolean footerClosed = downloadedCsv.toString().contains("#END_SESSION;") || downloadedCsv.toString().contains("#END_SUMMARY;");
            String outputName = (downloadedSessionClean || footerClosed) ? downloadedFilename : "INCOMPLETA_" + downloadedFilename;
            saveDownloadedCsv(outputName, downloadedCsv.toString());
            if (downloadedSessionClean || footerClosed) {
                if (downloadedFilename.startsWith("SM")) {
                    deviceSessionText.setText("Resumen rapido descargado: " + outputName
                            + " | " + receivedBytes + " bytes. El CSV completo permanece en la microSD.");
                } else {
                    deviceSessionText.setText("CSV completo descargado por BLE para diagnostico: " + outputName
                            + " | " + receivedBytes + " bytes."
                            + (footerClosed && !downloadedSessionClean ? " Footer valido detectado." : ""));
                }
            } else {
                deviceSessionText.setText("Archivo recuperado, pero la sesion no cerro correctamente: " + outputName);
                toast("Sesion incompleta recuperada para diagnostico");
            }
            return;
        }
        if (raw.startsWith("FILE:ERROR")) {
            downloadingSession = false;
            String reason = responseField(raw, "REASON");
            deviceSessionText.setText("No se pudo descargar sesion SD: " + reason);
            toast("Descarga SD no disponible");
            return;
        }
        if (raw.startsWith("PROFILE:")) {
            applyDeviceProfile(raw);
            configStatusText.setText("Perfil recuperado desde el dispositivo: " + responseField(raw, "USER"));
            rawText.setText(raw);
            return;
        }
        if (raw.startsWith("CFG:") || raw.startsWith("USER:")) {
            configStatusText.setText(raw);
            rawText.setText(raw);
            if (raw.startsWith("CFG:OK")) {
                applyDeviceProfile(raw);
                deviceSessionText.setText("Perfil recibido por el dispositivo. Listo para iniciar sesion SD.");
            } else if (raw.startsWith("CFG:ERROR") && raw.contains("SESSION_ACTIVE")) {
                deviceSessionText.setText("Sesion activa: el perfil no puede modificarse hasta detenerla.");
                toast("No se puede cambiar atleta durante una sesion activa");
            }
            return;
        }
        if (raw.startsWith("SESSION:")) {
            deviceSessionText.setText(raw);
            rawText.setText(raw);
            if (raw.startsWith("SESSION:ACTIVE")) {
                setProfileEditingEnabled(false);
                applyDeviceProfile(raw);
                deviceSessionText.setText("Sesion activa en dispositivo: " + responseField(raw, "FILE")
                        + " | Atleta: " + responseField(raw, "USER")
                        + " | Filas: " + responseField(raw, "ROWS"));
                toast("Sesion activa recuperada desde el dispositivo");
            } else if (raw.startsWith("SESSION:IDLE")) {
                setProfileEditingEnabled(true);
                String lastEvent = responseField(raw, "LAST_EVENT");
                String lastFile = responseField(raw, "FILE");
                String reset = responseField(raw, "RESET");
                if ("RECOVERED_INCOMPLETE_AFTER_BOOT".equals(lastEvent)) {
                    deviceSessionText.setText("La sesion " + lastFile
                            + " se interrumpio mientras el dispositivo estaba solo. Reinicio detectado: "
                            + reset + ". Descargala para diagnostico.");
                    toast("Sesion interrumpida detectada");
                } else if (lastEvent.startsWith("BATCH_") || "CLOSE_VALIDATION_FAILED".equals(lastEvent)) {
                    deviceSessionText.setText("Grabacion detenida por microSD: " + lastEvent
                            + " en " + lastFile + ". Descarga la sesion para diagnostico.");
                    toast("Fallo SD recuperado al reconectar");
                } else {
                    deviceSessionText.setText("Dispositivo conectado. Sin sesion activa; puedes enviar un perfil nuevo.");
                }
            } else if (raw.startsWith("SESSION:STARTED")) {
                csv.setLength(0);
                csvHeaderReady = false;
                recording = false;
                setProfileEditingEnabled(false);
                recordButton.setText("Diagnostico BLE local: OFF");
                toast("Archivo SD creado. La sesion oficial se guarda en el dispositivo.");
            } else if (raw.startsWith("SESSION:SD_WRITE")) {
                String confirmedRows = responseField(raw, "CONFIRMED_ROWS");
                String batchBytes = responseField(raw, "BATCH_BYTES");
                String fileBytes = responseField(raw, "FILE_BYTES");
                String expectedBytes = responseField(raw, "EXPECTED_BYTES");
                String flushCount = responseField(raw, "FLUSH_COUNT");
                String flushMs = responseField(raw, "FLUSH_MS");
                String flushMaxMs = responseField(raw, "FLUSH_MAX_MS");
                String fileInfo = fileBytes.length() > 0
                        ? "Archivo: " + fileBytes + " bytes"
                        : "Archivo estimado: " + expectedBytes + " bytes";
                deviceSessionText.setText("microSD confirmada: " + confirmedRows
                        + " filas aseguradas | " + fileInfo
                        + " | Lote: " + batchBytes + " bytes | Flush "
                        + flushCount + ": " + flushMs + " ms (max " + flushMaxMs + " ms).");
            } else if (raw.startsWith("SESSION:SD_RETRY")) {
                deviceSessionText.setText(raw + " | Reintentando acceso a microSD...");
            } else if (raw.startsWith("SESSION:STOPPED")) {
                recording = false;
                setProfileEditingEnabled(true);
                recordButton.setText("Diagnostico BLE local: OFF");
                if (raw.contains("CLEAN=NO")) {
                    if (raw.contains("FOOTER=FAILED")) {
                        deviceSessionText.setText("Fallo al escribir el cierre final en microSD. Sesion conservada solo para diagnostico.");
                    } else {
                        deviceSessionText.setText("Sesion sin cierre validado o con datos incompletos. Guardala solo como diagnostico.");
                    }
                    toast("Sesion SD incompleta");
                } else {
                    deviceSessionText.setText("Sesion cerrada y validada en microSD: "
                            + responseField(raw, "VALID_ROWS") + " filas completas.");
                    toast("Archivo SD guardado y cerrado");
                }
            } else if (raw.startsWith("SESSION:ERROR")) {
                if (raw.contains("SEND_PROFILE_FIRST")) {
                    toast("Primero envia el perfil del atleta");
                } else {
                    String reason = raw.contains("REASON=")
                            ? responseField(raw, "REASON")
                            : raw;
                    if ("INDEX_WRITE_FAILED".equals(reason)) {
                    deviceSessionText.setText("No se pudo guardar el numero de sesion en INDEX.CSV. Verifica firmware V044, microSD y alimentacion.");
                } else if ("SD_SESSION_REMOUNT_FAILED".equals(reason)) {
                    deviceSessionText.setText("La microSD no pudo reiniciarse para una nueva sesion. Revisa tarjeta, cables y alimentacion.");
                } else if ("SD_RECOVERY_FAILED".equals(reason)) {
                    deviceSessionText.setText("La microSD no inicio al encender y tampoco pudo recuperarse al iniciar sesion. Revisa tarjeta, cables y alimentacion.");
                    } else if ("SD_BOOT_NOT_READY".equals(reason)) {
                        deviceSessionText.setText("La microSD responde, pero no confirma escritura de diagnostico. Revisa alimentacion o modulo SD.");
                    } else {
                    deviceSessionText.setText("Fallo SD: " + reason + ". Verifica firmware V044, conexiones y alimentacion.");
                    }
                    toast("Fallo SD: " + reason);
                }
            }
            return;
        }

        DeviceGpsSample gpsSample = DeviceGpsSample.parse(raw);
        if (gpsSample != null) {
            latestDeviceGps = gpsSample;
            updateDeviceGpsPanel();
            rawText.setText("GPS ESP: " + deviceGpsSummary(gpsSample));
            if (gatewayEnabled) {
                updateGatewayStatus("GPS ESP recibido: " + deviceGpsSummary(gpsSample)
                        + " | esperando movimiento para subir al mapa.");
            }
            return;
        }

        SensorSample sample = SensorSample.parse(raw);
        if (sample == null) {
            rawText.setText("Paquete no reconocido: " + raw);
            return;
        }

        latestSample = sample;
        strokeTimelineView.add(sample);
        strokeWindowText.setText(strokeTimelineView.readout());
        maybeSendGatewaySample(raw, sample);

        if (recording) {
            ensureCsvHeader();
            csv.append(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(new Date()))
                    .append(',')
                    .append(String.format(Locale.US, "%.2f", sample.lr)).append(',')
                    .append(String.format(Locale.US, "%.2f", sample.fb)).append(',')
                    .append(String.format(Locale.US, "%.2f", sample.ud)).append(',')
                    .append(String.format(Locale.US, "%.2f", sample.mag)).append(',')
                    .append(raw.replace(",", ";"))
                    .append('\n');
        }
    }

    private void analyzeDownloadedSession(String content, boolean transferClean) {
        SessionAnalysis analysis = SessionAnalysis.fromCsv(content, transferClean);
        if (analysis == null || analysis.samples.size() < 4) {
            analysisStatusText.setText("NO SE PUDO ANALIZAR");
            analysisStatusText.setTextColor(Color.rgb(255, 83, 106));
            analysisSummaryText.setText("El CSV no contiene suficientes datos validos para interpretar movimiento.");
            analysisLoopView.setAnalysis(null);
            return;
        }

        int green = Color.rgb(73, 226, 133);
        int yellow = Color.rgb(255, 209, 102);
        int red = Color.rgb(255, 83, 106);
        if (!analysis.clean) {
            analysisStatusText.setText("SESION INCOMPLETA | DIAGNOSTICO");
            analysisStatusText.setTextColor(red);
            analysisSummaryText.setText("Datos visibles para revisar el dispositivo. No usar esta sesion para evaluar tecnica o rendimiento.");
        } else if (analysis.referenceReady) {
            analysisStatusText.setText("SESION VALIDA | BASE INICIAL");
            analysisStatusText.setTextColor(green);
            analysisSummaryText.setText("Lectura inicial del atleta. A medida que sumemos sesiones podremos comparar ritmo, rotacion, avance y movimiento.");
        } else {
            analysisStatusText.setText("SESION VALIDA | PRUEBA TECNICA");
            analysisStatusText.setTextColor(yellow);
            analysisSummaryText.setText("La sesion permite ver el movimiento del dispositivo. Aun es corta o de prueba para tomarla como patron de nado.");
        }

        analysisZeroText.setText(String.format(Locale.US, "%.2f / %.2f", analysis.zeroLR, analysis.zeroFB));
        analysisRotationText.setText(String.format(Locale.US, "%.2f / +%.2f", analysis.minLateral, analysis.maxLateral));
        analysisPaceText.setText(analysis.cycles > 1
                ? String.format(Locale.US, "%.2f s | %d ciclos", analysis.avgCycleSeconds, analysis.cycles)
                : "--");
        analysisRegularityText.setText(Float.isNaN(analysis.regularity)
                ? "--"
                : String.format(Locale.US, "%.0f%%", analysis.regularity));
        analysisImpulseText.setText(String.format(Locale.US, "%.2f", analysis.impulse));
        analysisLoopView.setAnalysis(analysis);
    }

    private void loadDemoAnalysis() {
        try (Scanner scanner = new Scanner(getAssets().open("SS000013_VALIDADA.CSV"), "UTF-8")) {
            scanner.useDelimiter("\\A");
            String content = scanner.hasNext() ? scanner.next() : "";
            analyzeDownloadedSession(content, true);
            analysisSummaryText.setText("Demo con una sesion tecnica valida de 20 s. En una prueba real, este panel se completa al descargar los datos del participante.");
            toast("Demo de interpretacion cargada");
        } catch (Exception e) {
            toast("No se pudo cargar la demo: " + e.getMessage());
        }
    }

    private String classify(SensorSample sample) {
        float absLr = Math.abs(sample.lr);
        float absFb = Math.abs(sample.fb);
        float absUd = Math.abs(sample.ud);

        if (sample.mag < 2) {
            return "Sin lectura";
        }
        if (absUd >= absLr && absUd >= absFb) {
            return sample.ud >= 0 ? "Espalda arriba / estable" : "Invertido";
        }
        if (absLr >= absFb) {
            return sample.lr >= 0 ? "Lateral derecha" : "Lateral izquierda";
        }
        return sample.fb >= 0 ? "Frente/cabeza" : "Atras/pies";
    }

    private void saveCsv() {
        try {
            ensureCsvHeader();
            String user = filenameSafe(cleanField(userNameInput.getText().toString(), "sin_usuario"));
            String mode = "test";
            String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date());
            String filename = "ss_" + user + "_" + mode + "_" + timestamp + ".csv";
            ContentResolver resolver = getContentResolver();
            ContentValues values = new ContentValues();
            values.put(MediaStore.Downloads.DISPLAY_NAME, filename);
            values.put(MediaStore.Downloads.MIME_TYPE, "text/csv");
            values.put(MediaStore.Downloads.RELATIVE_PATH, "Download/SaveSwimmer");

            Uri uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
            if (uri == null) {
                toast("No se pudo crear CSV");
                return;
            }
            try (OutputStream out = resolver.openOutputStream(uri)) {
                out.write(csv.toString().getBytes(StandardCharsets.UTF_8));
            }
            toast("CSV guardado en Descargas/SaveSwimmer");
        } catch (Exception e) {
            toast("Error guardando CSV: " + e.getMessage());
        }
    }

    private void saveDownloadedCsv(String filename, String content) {
        try {
            String safeName = filename == null || filename.isEmpty() ? "sesion_sd.csv" : filename;
            ContentResolver resolver = getContentResolver();
            ContentValues values = new ContentValues();
            values.put(MediaStore.Downloads.DISPLAY_NAME, safeName);
            values.put(MediaStore.Downloads.MIME_TYPE, "text/csv");
            values.put(MediaStore.Downloads.RELATIVE_PATH, "Download/SaveSwimmer");

            Uri uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
            if (uri == null) {
                toast("No se pudo guardar sesion descargada");
                return;
            }
            try (OutputStream out = resolver.openOutputStream(uri)) {
                out.write(content.getBytes(StandardCharsets.UTF_8));
            }
            toast("Sesion SD completa guardada en Descargas/SaveSwimmer");
        } catch (Exception e) {
            toast("Error guardando sesion SD: " + e.getMessage());
        }
    }

    private String safeDeviceName(BluetoothDevice device) {
        if (!hasBlePermissions()) {
            return null;
        }
        try {
            return device.getName();
        } catch (SecurityException e) {
            return null;
        }
    }

    private String scanResultName(ScanResult result) {
        if (result.getScanRecord() != null && result.getScanRecord().getDeviceName() != null) {
            return result.getScanRecord().getDeviceName();
        }
        return safeDeviceName(result.getDevice());
    }

    private boolean isSaveSwimmer(ScanResult result, String name) {
        if (DEVICE_NAME.equals(name)) {
            return true;
        }
        String normalized = normalizeName(name);
        if (normalized.contains("SSLT000001")
                || normalized.contains("SSLT00001")
                || normalized.contains("SAVESWIMMER")
                || normalized.startsWith("SS")) {
            return true;
        }
        if (result.getScanRecord() == null || result.getScanRecord().getServiceUuids() == null) {
            return false;
        }
        for (ParcelUuid uuid : result.getScanRecord().getServiceUuids()) {
            if (SERVICE_UUID.equals(uuid.getUuid())) {
                return true;
            }
        }
        return false;
    }

    private String normalizeName(String name) {
        if (name == null) {
            return "";
        }
        return name.toUpperCase(Locale.US).replaceAll("[^A-Z0-9]", "");
    }

    private void appendScanLog(String name, String address, int rssi) {
        mainHandler.post(() -> {
            String shownName = name == null || name.length() == 0 ? "(sin nombre)" : name;
            String current = scanLogText.getText().toString();
            String line = shownName + "  " + address + "  RSSI " + rssi;
            if (!current.contains(address)) {
                scanLogText.setText(current + line + "\n");
            }
        });
    }

    private boolean hasBlePermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
                    && checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
                    && checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        }
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestNeededPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            requestPermissions(new String[]{
                    Manifest.permission.BLUETOOTH_SCAN,
                    Manifest.permission.BLUETOOTH_CONNECT,
                    Manifest.permission.ACCESS_FINE_LOCATION
            }, 100);
        } else {
            requestPermissions(new String[]{
                    Manifest.permission.ACCESS_FINE_LOCATION
            }, 100);
        }
    }

    private void setStatus(String value) {
        mainHandler.post(() -> statusText.setText(value));
    }

    private void toast(String value) {
        Toast.makeText(this, value, Toast.LENGTH_SHORT).show();
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }

    private static class DeviceGpsSample {
        final int fix;
        final double lat;
        final double lon;
        final double speedKmh;
        final int satellites;
        final double hdop;
        final long ageMs;

        DeviceGpsSample(int fix, double lat, double lon, double speedKmh, int satellites, double hdop, long ageMs) {
            this.fix = fix;
            this.lat = lat;
            this.lon = lon;
            this.speedKmh = speedKmh;
            this.satellites = satellites;
            this.hdop = hdop;
            this.ageMs = ageMs;
        }

        boolean valid() {
            return fix > 0 && Double.isFinite(lat) && Double.isFinite(lon)
                    && Math.abs(lat) > 0.000001 && Math.abs(lon) > 0.000001;
        }

        Location toLocation() {
            Location location = new Location("save_swimmer_esp_gps");
            location.setLatitude(lat);
            location.setLongitude(lon);
            location.setTime(System.currentTimeMillis());
            location.setAccuracy((float) Math.max(3.0, hdop * 5.0));
            location.setSpeed((float) (speedKmh / 3.6));
            return location;
        }

        static DeviceGpsSample parse(String raw) {
            try {
                if (!raw.startsWith("G:")) {
                    return null;
                }
                String[] parts = raw.substring(2).split(",");
                if (parts.length < 7) {
                    return null;
                }
                return new DeviceGpsSample(
                        Integer.parseInt(parts[0].trim()),
                        Double.parseDouble(parts[1].trim()),
                        Double.parseDouble(parts[2].trim()),
                        Double.parseDouble(parts[3].trim()),
                        Integer.parseInt(parts[4].trim()),
                        Double.parseDouble(parts[5].trim()),
                        Long.parseLong(parts[6].trim())
                );
            } catch (Exception e) {
                return null;
            }
        }
    }

    private static class SensorSample {
        final float lr;
        final float fb;
        final float ud;
        final float mag;

        SensorSample(float lr, float fb, float ud, float mag) {
            this.lr = lr;
            this.fb = fb;
            this.ud = ud;
            this.mag = mag;
        }

        static SensorSample parse(String raw) {
            try {
                if (raw.startsWith("A:")) {
                    String[] parts = raw.substring(2).split(",");
                    if (parts.length < 4) {
                        return null;
                    }
                    return new SensorSample(
                            Integer.parseInt(parts[0].trim()) / 10f,
                            Integer.parseInt(parts[1].trim()) / 10f,
                            Integer.parseInt(parts[2].trim()) / 10f,
                            Integer.parseInt(parts[3].trim()) / 10f
                    );
                }

                Float lr = null;
                Float fb = null;
                Float ud = null;
                Float mag = null;
                String[] parts = raw.split(",");
                for (String part : parts) {
                    int index = part.indexOf(':');
                    if (index < 0) {
                        continue;
                    }
                    String key = part.substring(0, index).trim().toUpperCase(Locale.US);
                    String value = part.substring(index + 1).trim();
                    if ("LR".equals(key) || "X".equals(key)) lr = Float.parseFloat(value);
                    if ("FB".equals(key) || "Y".equals(key)) fb = Float.parseFloat(value);
                    if ("UD".equals(key) || "Z".equals(key)) ud = Float.parseFloat(value);
                    if ("MAG".equals(key) || "M".equals(key)) mag = Float.parseFloat(value);
                }
                if (lr == null || fb == null || ud == null || mag == null) {
                    return null;
                }
                return new SensorSample(lr, fb, ud, mag);
            } catch (Exception e) {
                return null;
            }
        }
    }

    private static class SessionAnalysis {
        final List<SensorSample> samples = new ArrayList<>();
        final List<Float> lateral = new ArrayList<>();
        final List<Float> vertical = new ArrayList<>();
        boolean clean;
        boolean referenceReady;
        String mode = "";
        float zeroLR;
        float zeroFB;
        float angleDegrees;
        float minLateral;
        float maxLateral;
        float durationSeconds;
        float avgCycleSeconds = Float.NaN;
        float regularity = Float.NaN;
        float impulse;
        int cycles;

        static SessionAnalysis fromCsv(String content, boolean transferClean) {
            try {
                SessionAnalysis result = new SessionAnalysis();
                String[] lines = content.split("\\r?\\n");
                int lrIndex = -1;
                int fbIndex = -1;
                int udIndex = -1;
                int magIndex = -1;
                int elapsedIndex = -1;
                boolean hasFooter = false;
                int invalidRows = 0;
                List<Float> elapsedValues = new ArrayList<>();

                for (String rawLine : lines) {
                    String line = rawLine.trim();
                    if (line.length() == 0) {
                        continue;
                    }
                    if (line.startsWith("#mode,")) {
                        result.mode = line.substring(6).trim();
                        continue;
                    }
                    if (line.startsWith("#END_SESSION;")) {
                        hasFooter = true;
                        continue;
                    }
                    if (line.startsWith("#")) {
                        continue;
                    }
                    if (line.toLowerCase(Locale.US).startsWith("row,")) {
                        String[] headers = line.toLowerCase(Locale.US).split(",");
                        for (int i = 0; i < headers.length; i++) {
                            if ("elapsed_s".equals(headers[i])) elapsedIndex = i;
                            if ("lr".equals(headers[i])) lrIndex = i;
                            if ("fb".equals(headers[i])) fbIndex = i;
                            if ("ud".equals(headers[i])) udIndex = i;
                            if ("mag".equals(headers[i])) magIndex = i;
                        }
                        continue;
                    }
                    if (lrIndex < 0 || fbIndex < 0 || udIndex < 0 || magIndex < 0) {
                        continue;
                    }
                    String[] values = line.split(",");
                    int required = Math.max(Math.max(lrIndex, fbIndex), Math.max(udIndex, magIndex));
                    if (values.length <= required) {
                        invalidRows++;
                        continue;
                    }
                    try {
                        SensorSample sample = new SensorSample(
                                Float.parseFloat(values[lrIndex]),
                                Float.parseFloat(values[fbIndex]),
                                Float.parseFloat(values[udIndex]),
                                Float.parseFloat(values[magIndex])
                        );
                        result.samples.add(sample);
                        elapsedValues.add(elapsedIndex >= 0 && values.length > elapsedIndex
                                ? Float.parseFloat(values[elapsedIndex])
                                : (float) result.samples.size() / 10f);
                    } catch (Exception ignored) {
                        invalidRows++;
                    }
                }

                if (result.samples.size() < 4) {
                    return null;
                }

                result.clean = transferClean && hasFooter && invalidRows == 0;
                result.durationSeconds = elapsedValues.get(elapsedValues.size() - 1) - elapsedValues.get(0);
                result.referenceReady = result.clean && result.durationSeconds >= 60f
                        && result.mode.toUpperCase(Locale.US).contains("NADO");
                result.calculateFrame(elapsedValues);
                return result;
            } catch (Exception e) {
                return null;
            }
        }

        private void calculateFrame(List<Float> elapsedValues) {
            zeroLR = mean(samples, 0);
            zeroFB = mean(samples, 1);
            float varX = 0f;
            float varY = 0f;
            float covariance = 0f;
            for (SensorSample sample : samples) {
                float dx = sample.lr - zeroLR;
                float dy = sample.fb - zeroFB;
                varX += dx * dx;
                varY += dy * dy;
                covariance += dx * dy;
            }
            varX /= samples.size();
            varY /= samples.size();
            covariance /= samples.size();
            double angle = 0.5 * Math.atan2(2.0 * covariance, varX - varY);
            float agreement = 0f;
            for (SensorSample sample : samples) {
                float dx = sample.lr - zeroLR;
                float dy = sample.fb - zeroFB;
                agreement += (float) (dx * (dx * Math.cos(angle) + dy * Math.sin(angle)));
            }
            if (agreement < 0f) {
                angle += Math.PI;
            }
            angleDegrees = (float) (angle * 180.0 / Math.PI);

            minLateral = Float.MAX_VALUE;
            maxLateral = -Float.MAX_VALUE;
            float meanUd = mean(samples, 2);
            float meanMag = mean(samples, 3);
            float impulseSum = 0f;
            for (SensorSample sample : samples) {
                float dx = sample.lr - zeroLR;
                float dy = sample.fb - zeroFB;
                float lateralValue = (float) (dx * Math.cos(angle) + dy * Math.sin(angle));
                float verticalValue = (float) (-dx * Math.sin(angle) + dy * Math.cos(angle));
                lateral.add(lateralValue);
                vertical.add(verticalValue);
                minLateral = Math.min(minLateral, lateralValue);
                maxLateral = Math.max(maxLateral, lateralValue);
                impulseSum += Math.abs(sample.ud - meanUd) + Math.max(0f, sample.mag - meanMag);
            }
            impulse = impulseSum / samples.size();

            List<Float> periods = new ArrayList<>();
            int segmentStart = 0;
            int lastSign = lateral.get(0) >= 0f ? 1 : -1;
            for (int i = 1; i < lateral.size(); i++) {
                int sign = lateral.get(i) >= 0f ? 1 : -1;
                if (sign != lastSign) {
                    if (i - segmentStart >= 2) {
                        float amplitude = 0f;
                        for (int j = segmentStart; j <= i; j++) {
                            amplitude = Math.max(amplitude, Math.abs(lateral.get(j)));
                        }
                        if (amplitude > 0.25f) {
                            periods.add(elapsedValues.get(i) - elapsedValues.get(segmentStart));
                        }
                    }
                    segmentStart = i;
                    lastSign = sign;
                }
            }
            cycles = periods.size();
            if (!periods.isEmpty()) {
                float total = 0f;
                for (float period : periods) total += period;
                avgCycleSeconds = total / periods.size();
                float variance = 0f;
                for (float period : periods) {
                    variance += (period - avgCycleSeconds) * (period - avgCycleSeconds);
                }
                float std = (float) Math.sqrt(variance / periods.size());
                regularity = Math.max(0f, Math.min(100f, 100f - (std / Math.max(0.01f, avgCycleSeconds)) * 120f));
            }
        }

        private static float mean(List<SensorSample> data, int key) {
            float sum = 0f;
            for (SensorSample sample : data) {
                if (key == 0) sum += sample.lr;
                if (key == 1) sum += sample.fb;
                if (key == 2) sum += sample.ud;
                if (key == 3) sum += sample.mag;
            }
            return data.isEmpty() ? 0f : sum / data.size();
        }
    }

    public static class DownloadAnalysisLoopView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private SessionAnalysis analysis;

        public DownloadAnalysisLoopView(Context context) {
            super(context);
        }

        public void setAnalysis(SessionAnalysis value) {
            analysis = value;
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int w = getWidth();
            int h = getHeight();
            float cx = w / 2f;
            float cy = h / 2f;
            float pad = 28f;
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(Color.rgb(7, 21, 28));
            canvas.drawRect(0, 0, w, h, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(Color.rgb(36, 72, 84));
            canvas.drawLine(pad, cy, w - pad, cy, paint);
            canvas.drawLine(cx, pad, cx, h - pad, paint);
            drawInfinity(canvas, cx, cy, w, h);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(18);
            paint.setColor(Color.rgb(145, 172, 181));
            canvas.drawText("IZQ", pad, cy - 8, paint);
            canvas.drawText("DER", w - pad - 40, cy - 8, paint);
            canvas.drawText("SOBRE 0", cx + 8, pad + 18, paint);
            canvas.drawText("BAJO 0", cx + 8, h - pad, paint);

            if (analysis == null || analysis.lateral.size() < 2) {
                return;
            }

            float maxX = 1f;
            float maxY = 0.4f;
            for (int i = 0; i < analysis.lateral.size(); i++) {
                maxX = Math.max(maxX, Math.abs(analysis.lateral.get(i)));
                maxY = Math.max(maxY, Math.abs(analysis.vertical.get(i)));
            }
            float plotW = (w - pad * 2) * 0.43f;
            float plotH = (h - pad * 2) * 0.34f;
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(4);
            paint.setColor(Color.rgb(40, 215, 236));
            Path path = new Path();
            for (int i = 0; i < analysis.lateral.size(); i++) {
                float x = cx + clamp(analysis.lateral.get(i) / maxX, -1f, 1f) * plotW;
                float y = cy - clamp(analysis.vertical.get(i) / maxY, -1f, 1f) * plotH;
                if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
            }
            canvas.drawPath(path, paint);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(16);
            paint.setColor(Color.rgb(145, 172, 181));
            canvas.drawText(String.format(Locale.US, "Eje corregido %.1f deg", analysis.angleDegrees), pad, 24, paint);
        }

        private void drawInfinity(Canvas canvas, float cx, float cy, int w, int h) {
            float plotW = (w - 56f) * 0.43f;
            float plotH = (h - 56f) * 0.34f;
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(Color.argb(90, 255, 83, 106));
            Path path = new Path();
            for (int i = 0; i <= 180; i++) {
                double t = Math.PI * 2.0 * i / 180.0;
                double d = 1.0 + Math.pow(Math.sin(t), 2.0);
                float x = (float) (cx + (Math.cos(t) / d) * plotW * 1.15);
                float y = (float) (cy - ((Math.sin(t) * Math.cos(t)) / d) * plotH * 1.25);
                if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
            }
            canvas.drawPath(path, paint);
        }

        private float clamp(float value, float min, float max) {
            return Math.max(min, Math.min(max, value));
        }
    }

    public static class SensorGraphView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private SensorSample latest = new SensorSample(0, 0, 0, 0);

        public SensorGraphView(Context context) {
            super(context);
        }

        public void add(SensorSample sample) {
            latest = sample;
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int w = getWidth();
            int h = getHeight();
            float cx = w / 2f;
            float cy = h * 0.38f;

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(Color.rgb(36, 72, 84));
            canvas.drawLine(24, cy, w - 24, cy, paint);
            canvas.drawLine(cx, 24, cx, h * 0.72f, paint);

            float dotX = clamp(cx + latest.lr * 22f, 28, w - 28);
            float dotY = clamp(cy - latest.fb * 22f, 28, h * 0.72f);
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(Color.rgb(40, 215, 236));
            canvas.drawCircle(dotX, dotY, 16, paint);

            drawLabel(canvas, "ARRIBA", cx - 34, 42);
            drawLabel(canvas, "ABAJO", cx - 32, h * 0.70f);
            drawLabel(canvas, "IZQ", 28, cy - 10);
            drawLabel(canvas, "DER", w - 62, cy - 10);
        }

        private void drawLabel(Canvas canvas, String label, float x, float y) {
            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(24);
            paint.setColor(Color.rgb(145, 172, 181));
            canvas.drawText(label, x, y, paint);
        }

        private float clamp(float value, float min, float max) {
            return Math.max(min, Math.min(max, value));
        }
    }

    public static class StrokeTimelineView extends View {
        private static final long WINDOW_MS = 30000L;
        private static final long HISTORY_MAX_MS = 2L * 60L * 60L * 1000L;
        private static final long GRID_MS = 5000L;
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Queue<TimedSample> samples = new ArrayDeque<>();
        private long sessionStartMs = 0L;
        private long latestMs = 0L;
        private long viewportStartMs = 0L;
        private boolean followLive = true;
        private float lastTouchX = 0f;
        private boolean placementBaseReady = false;
        private float baseLr = 0f;
        private float baseFb = 0f;
        private float baseUd = 0f;
        private float baseMag = 0f;
        private float baseRotationDeg = 0f;
        private float baseAlignmentDeg = 0f;

        private static class TimedSample {
            final long timeMs;
            final SensorSample sample;

            TimedSample(long timeMs, SensorSample sample) {
                this.timeMs = timeMs;
                this.sample = sample;
            }
        }

        public StrokeTimelineView(Context context) {
            super(context);
        }

        public void add(SensorSample sample) {
            long now = android.os.SystemClock.elapsedRealtime();
            if (sessionStartMs == 0L) {
                sessionStartMs = now;
                viewportStartMs = now;
                followLive = true;
            }
            latestMs = now;
            samples.add(new TimedSample(now, sample));
            long historyLimit = Math.max(sessionStartMs, latestMs - HISTORY_MAX_MS);
            while (!samples.isEmpty() && samples.peek().timeMs < historyLimit) {
                samples.poll();
            }
            if (followLive) {
                viewportStartMs = liveStartMs();
            } else {
                viewportStartMs = clampViewportStart(viewportStartMs);
            }
            invalidate();
        }

        public void takePlacementBase(SensorSample sample) {
            placementBaseReady = true;
            baseLr = sample.lr;
            baseFb = sample.fb;
            baseUd = sample.ud;
            baseMag = sample.mag;
            baseRotationDeg = rawRotationDeg(sample);
            baseAlignmentDeg = rawAlignmentDeg(sample);
            invalidate();
        }

        public String readout() {
            if (sessionStartMs == 0L) {
                return "Ventana en vivo lista. Toma base de colocacion cuando el dispositivo ya este en la espalda.";
            }
            float startSeconds = (visibleStartMs() - sessionStartMs) / 1000f;
            float endSeconds = (latestMs - sessionStartMs) / 1000f;
            String base = placementBaseReady ? "base de colocacion activa" : "sin base de colocacion";
            String mode = followLive ? "en vivo" : "historial";
            return String.format(Locale.US,
                    "Mostrando %.0f-%.0f s (%s) | rotacion dorsal + alineacion corporal | %s.",
                    Math.max(0f, startSeconds),
                    Math.max(0f, endSeconds),
                    mode,
                    base
            );
        }

        @Override
        public boolean onTouchEvent(MotionEvent event) {
            if (sessionStartMs == 0L || latestMs - sessionStartMs <= WINDOW_MS) {
                return true;
            }
            switch (event.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    lastTouchX = event.getX();
                    getParent().requestDisallowInterceptTouchEvent(true);
                    return true;
                case MotionEvent.ACTION_MOVE:
                    float dx = event.getX() - lastTouchX;
                    lastTouchX = event.getX();
                    float graphWidth = Math.max(1f, getWidth() - 90f);
                    long deltaMs = (long) (-(dx / graphWidth) * WINDOW_MS);
                    viewportStartMs = clampViewportStart(visibleStartMs() + deltaMs);
                    followLive = viewportStartMs >= liveStartMs() - 750L;
                    if (followLive) viewportStartMs = liveStartMs();
                    invalidate();
                    return true;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    getParent().requestDisallowInterceptTouchEvent(false);
                    return true;
                default:
                    return true;
            }
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int w = getWidth();
            int h = getHeight();
            float left = 72f;
            float right = w - 18f;
            float top = 38f;
            float rotationBottom = h * 0.25f;
            float alignmentTop = h * 0.31f;
            float alignmentBottom = h * 0.45f;
            float magTop = h * 0.51f;
            float magBottom = h * 0.63f;
            float shoulderTop = h * 0.70f;
            float rotationZero = top + (rotationBottom - top) * 0.50f;
            float alignmentZero = alignmentTop + (alignmentBottom - alignmentTop) * 0.50f;
            float magZero = magTop + (magBottom - magTop) * 0.50f;

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(Color.rgb(7, 21, 28));
            canvas.drawRect(0, 0, w, h, paint);

            drawPanelGrid(canvas, left, right, top, rotationBottom, rotationZero);
            drawPanelGrid(canvas, left, right, alignmentTop, alignmentBottom, alignmentZero);
            drawPanelGrid(canvas, left, right, magTop, magBottom, magZero);

            if (samples.size() > 1) {
                List<TimedSample> visible = visibleSamples();
                float lrScale = 90f;
                float alignmentBase = placementBaseReady ? 0f : meanAlignment(visible);
                float alignmentScale = Math.max(8f, maxSmoothedAlignment(visible, alignmentBase));
                float magBase = placementBaseReady ? baseMag : meanMag(visible);
                float magScale = Math.max(0.6f, robustMagScale(visible, magBase));

                drawDegreeGuides(canvas, left, right, rotationZero, (rotationBottom - top) * 0.42f);
                drawRotation(canvas, visible, left, right, rotationZero, (rotationBottom - top) * 0.42f, lrScale);
                drawAlignment(canvas, visible, left, right, alignmentZero, (alignmentBottom - alignmentTop) * 0.42f, alignmentBase, alignmentScale);
                drawMag(canvas, visible, left, right, magBottom - 6f, (magBottom - magTop) * 0.82f, magBase, magScale);
                drawShoulderGuide(canvas, visible, left, right, shoulderTop, h - 62f, lrScale);

                paint.setTextSize(20);
                paint.setStyle(Paint.Style.FILL);
                paint.setColor(Color.rgb(145, 172, 181));
                canvas.drawText("+90", 10, rotationZero - (rotationBottom - top) * 0.36f, paint);
                canvas.drawText("-90", 10, rotationZero + (rotationBottom - top) * 0.43f, paint);
                canvas.drawText(String.format(Locale.US, "+%.0f", alignmentScale), 8, alignmentZero - (alignmentBottom - alignmentTop) * 0.32f, paint);
                canvas.drawText(String.format(Locale.US, "-%.0f", alignmentScale), 8, alignmentZero + (alignmentBottom - alignmentTop) * 0.42f, paint);
                canvas.drawText(String.format(Locale.US, "+%.1f", magScale), 8, magTop + 16f, paint);
                canvas.drawText("0", 18, magBottom - 4f, paint);
            }

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(20);
            paint.setColor(Color.rgb(145, 172, 181));
            canvas.drawText("ROTACION", 8, rotationZero + 6, paint);
            canvas.drawText("ALINEACION", 8, alignmentZero + 6, paint);
            canvas.drawText("MOV", 8, magBottom - 6, paint);
            paint.setColor(Color.rgb(40, 215, 236));
            canvas.drawText("DER", left + 8, top - 10, paint);
            paint.setColor(Color.rgb(255, 209, 102));
            canvas.drawText("IZQ", left + 62, top - 10, paint);
            paint.setColor(Color.rgb(40, 215, 236));
            canvas.drawText("ROTACION ESTIMADA FB/UD", left + 112, top - 10, paint);
            paint.setColor(Color.rgb(130, 170, 255));
            canvas.drawText("ALINEACION ESTIMADA -LR/UD", left + 8, alignmentTop - 10, paint);
            paint.setColor(Color.rgb(69, 224, 137));
            canvas.drawText("MOVIMIENTO | picos", left + 8, magTop - 10, paint);
            paint.setColor(Color.rgb(145, 172, 181));
            canvas.drawText(placementBaseReady
                    ? String.format(Locale.US, "base LR %.2f | FB %.2f | UD %.2f | MAG %.2f", baseLr, baseFb, baseUd, baseMag)
                    : "sin base: usa Tomar base de colocacion", left + 8, h - 8, paint);
            drawHistoryBar(canvas, left, right, h - 36f);
        }

        private void drawPanelGrid(Canvas canvas, float left, float right, float top, float bottom, float zero) {
            paint.setPathEffect(null);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(Color.rgb(36, 72, 84));
            canvas.drawLine(left, zero, right, zero, paint);

            long start = visibleStartMs();
            for (int i = 0; i <= 4; i++) {
                float x = left + (right - left) * i / 4f;
                canvas.drawLine(x, top, x, bottom, paint);
                if (sessionStartMs > 0L && bottom - top > 100f) {
                    long tick = start + (GRID_MS * i);
                    float seconds = Math.max(0f, (tick - sessionStartMs) / 1000f);
                    paint.setStyle(Paint.Style.FILL);
                    paint.setTextSize(18);
                    paint.setColor(Color.rgb(145, 172, 181));
                    canvas.drawText(String.format(Locale.US, "%.0fs", seconds), x - 12, bottom + 24, paint);
                    paint.setStyle(Paint.Style.STROKE);
                    paint.setColor(Color.rgb(36, 72, 84));
                }
            }
        }

        private void drawGrid(Canvas canvas, float left, float right, float top, float bottom,
                              float rotationZero, float elevationZero) {
            paint.setPathEffect(null);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(Color.rgb(36, 72, 84));
            canvas.drawLine(left, rotationZero, right, rotationZero, paint);
            canvas.drawLine(left, elevationZero, right, elevationZero, paint);

            long start = visibleStartMs();
            for (int i = 0; i <= 4; i++) {
                float x = left + (right - left) * i / 4f;
                canvas.drawLine(x, top, x, bottom, paint);
                if (sessionStartMs > 0L) {
                    long tick = start + (GRID_MS * i);
                    float seconds = Math.max(0f, (tick - sessionStartMs) / 1000f);
                    paint.setStyle(Paint.Style.FILL);
                    paint.setTextSize(19);
                    paint.setColor(Color.rgb(145, 172, 181));
                    canvas.drawText(String.format(Locale.US, "%.0fs", seconds), x - 12, bottom + 25, paint);
                    paint.setStyle(Paint.Style.STROKE);
                    paint.setColor(Color.rgb(36, 72, 84));
                }
            }
        }

        private void drawRotation(Canvas canvas, List<TimedSample> data, float left, float right,
                                  float zero, float height, float scale) {
            for (int i = 1; i < data.size(); i++) {
                TimedSample previous = data.get(i - 1);
                TimedSample timed = data.get(i);
                float previousValue = smoothed(data, i - 1, 0);
                float value = smoothed(data, i, 0);
                float previousX = timeX(previous.timeMs, left, right);
                float previousY = zero - clamp(previousValue / 90f, -1f, 1f) * height;
                float x = timeX(timed.timeMs, left, right);
                float y = zero - clamp(value / 90f, -1f, 1f) * height;

                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(4);
                paint.setColor(value >= 0
                        ? Color.rgb(40, 215, 236)
                        : Color.rgb(255, 209, 102));
                Path curve = new Path();
                curve.moveTo(previousX, previousY);
                curve.quadTo((previousX + x) / 2f, previousY, x, y);
                canvas.drawPath(curve, paint);
            }
        }

        private void drawDegreeGuides(Canvas canvas, float left, float right, float zero, float height) {
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setPathEffect(new DashPathEffect(new float[]{10f, 8f}, 0));

            paint.setColor(Color.argb(155, 69, 224, 137));
            drawDegreeLine(canvas, left, right, zero, height, 35f);
            drawDegreeLine(canvas, left, right, zero, height, -35f);
            drawDegreeLine(canvas, left, right, zero, height, 55f);
            drawDegreeLine(canvas, left, right, zero, height, -55f);

            paint.setColor(Color.argb(150, 255, 106, 24));
            drawDegreeLine(canvas, left, right, zero, height, 65f);
            drawDegreeLine(canvas, left, right, zero, height, -65f);
            paint.setPathEffect(null);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(18);
            paint.setColor(Color.rgb(69, 224, 137));
            canvas.drawText("funcional 35-55", left + 6, zero - height * 0.56f, paint);
            paint.setColor(Color.rgb(255, 106, 24));
            canvas.drawText("alto 55-65", right - 102, zero - height * 0.72f, paint);
        }

        private void drawDegreeLine(Canvas canvas, float left, float right, float zero, float height, float degree) {
            float y = zero - clamp(degree / 90f, -1f, 1f) * height;
            canvas.drawLine(left, y, right, y, paint);
        }

        private void drawShoulderGuide(Canvas canvas, List<TimedSample> data, float left, float right, float top, float bottom, float scale) {
            if (data.isEmpty()) return;
            float width = right - left;
            float height = bottom - top;
            float cx = left + width * 0.52f;
            float cy = top + height * 0.52f;
            float radius = Math.min(width * 0.35f, height * 0.42f);
            float half = Math.min(radius * 1.02f, width * 0.36f);
            SensorSample current = data.get(data.size() - 1).sample;
            float currentDeg = rotationDeltaDeg(current);
            float avgDeg = averageRotationDeg(data, scale);

            paint.setPathEffect(null);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(Color.rgb(36, 72, 84));
            canvas.drawLine(cx - radius, cy, cx + radius, cy, paint);
            canvas.drawLine(cx, top + 8f, cx, bottom - 38f, paint);

            paint.setPathEffect(new DashPathEffect(new float[]{9f, 8f}, 0));
            paint.setStrokeWidth(2);
            paint.setColor(Color.argb(150, 69, 224, 137));
            drawAngleGuide(canvas, cx, cy, radius, -35f);
            drawAngleGuide(canvas, cx, cy, radius, 35f);
            drawAngleGuide(canvas, cx, cy, radius, -55f);
            drawAngleGuide(canvas, cx, cy, radius, 55f);
            paint.setColor(Color.argb(140, 255, 106, 24));
            drawAngleGuide(canvas, cx, cy, radius, -65f);
            drawAngleGuide(canvas, cx, cy, radius, 65f);
            paint.setPathEffect(null);

            int step = Math.max(1, data.size() / 10);
            paint.setStrokeWidth(4);
            for (int i = 0; i < data.size(); i += step) {
                float deg = rotationDeltaDeg(data.get(i).sample);
                int alpha = 35 + Math.round(75f * i / Math.max(1, data.size() - 1));
                paint.setColor(Color.argb(alpha, 40, 215, 236));
                drawShoulderLine(canvas, cx, cy, half * 0.92f, deg);
            }

            paint.setStrokeWidth(9);
            paint.setColor(Color.argb(170, 69, 224, 137));
            drawShoulderLine(canvas, cx, cy, half * 0.96f, avgDeg);

            paint.setStrokeWidth(12);
            paint.setColor(Color.rgb(40, 215, 236));
            drawShoulderLine(canvas, cx, cy, half, currentDeg);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(18);
            paint.setColor(Color.rgb(145, 172, 181));
            canvas.drawText(String.format(Locale.US, "rotacion %.0f deg | promedio %.0f | comparar con base", currentDeg, avgDeg), left, bottom - 8f, paint);
        }

        private void drawAngleGuide(Canvas canvas, float cx, float cy, float radius, float degrees) {
            float rad = (float) Math.toRadians(degrees);
            float dx = (float) Math.cos(rad) * radius;
            float dy = -(float) Math.sin(rad) * radius;
            canvas.drawLine(cx - dx, cy - dy, cx + dx, cy + dy, paint);
        }

        private void drawShoulderLine(Canvas canvas, float cx, float cy, float half, float degrees) {
            float rad = (float) Math.toRadians(degrees);
            float dx = (float) Math.cos(rad) * half;
            float dy = -(float) Math.sin(rad) * half;
            canvas.drawLine(cx - dx, cy - dy, cx + dx, cy + dy, paint);
        }

        private float averageRotationDeg(List<TimedSample> data, float scale) {
            float sum = 0f;
            int count = 0;
            for (TimedSample timed : data) {
                sum += rotationDeltaDeg(timed.sample);
                count++;
            }
            return count == 0 ? 0f : sum / count;
        }

        private void drawAlignment(Canvas canvas, List<TimedSample> data, float left, float right,
                                   float zero, float height, float base, float scale) {
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(3);
            paint.setColor(Color.rgb(130, 170, 255));
            Path curve = new Path();
            for (int i = 0; i < data.size(); i++) {
                TimedSample timed = data.get(i);
                float value = smoothed(data, i, 1) - base;
                float x = timeX(timed.timeMs, left, right);
                float y = zero - clamp(value / scale, -1f, 1f) * height;
                if (i == 0) {
                    curve.moveTo(x, y);
                } else {
                    TimedSample previous = data.get(i - 1);
                    float previousValue = smoothed(data, i - 1, 1) - base;
                    float previousX = timeX(previous.timeMs, left, right);
                    float previousY = zero - clamp(previousValue / scale, -1f, 1f) * height;
                    curve.quadTo((previousX + x) / 2f, previousY, x, y);
                }
            }
            canvas.drawPath(curve, paint);
        }

        private void drawMag(Canvas canvas, List<TimedSample> data, float left, float right,
                             float zero, float height, float base, float scale) {
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(3);
            paint.setColor(Color.rgb(69, 224, 137));
            Path curve = new Path();
            for (int i = 0; i < data.size(); i++) {
                TimedSample timed = data.get(i);
                float value = magImpulse(smoothedMag(data, i), base);
                float x = timeX(timed.timeMs, left, right);
                float y = zero - clamp(value / scale, 0f, 1f) * height;
                if (i == 0) {
                    curve.moveTo(x, y);
                } else {
                    TimedSample previous = data.get(i - 1);
                    float previousValue = magImpulse(smoothedMag(data, i - 1), base);
                    float previousX = timeX(previous.timeMs, left, right);
                    float previousY = zero - clamp(previousValue / scale, 0f, 1f) * height;
                    curve.quadTo((previousX + x) / 2f, previousY, x, y);
                }
            }
            canvas.drawPath(curve, paint);
        }

        private float timeX(long sampleMs, float left, float right) {
            float ratio = (sampleMs - visibleStartMs()) / (float) WINDOW_MS;
            return left + clamp(ratio, 0f, 1f) * (right - left);
        }

        private long visibleStartMs() {
            if (sessionStartMs == 0L) return 0L;
            return followLive ? liveStartMs() : clampViewportStart(viewportStartMs);
        }

        private List<TimedSample> visibleSamples() {
            List<TimedSample> visible = new ArrayList<>();
            if (sessionStartMs == 0L) return visible;
            long start = visibleStartMs();
            long end = start + WINDOW_MS;
            TimedSample nearestBefore = null;
            TimedSample nearestAfter = null;
            for (TimedSample timed : samples) {
                if (timed.timeMs < start) {
                    nearestBefore = timed;
                } else if (timed.timeMs <= end) {
                    visible.add(timed);
                } else {
                    nearestAfter = timed;
                    break;
                }
            }
            if (nearestBefore != null) {
                visible.add(0, nearestBefore);
            }
            if (nearestAfter != null) {
                visible.add(nearestAfter);
            }
            return visible;
        }

        private long liveStartMs() {
            if (sessionStartMs == 0L) return 0L;
            return Math.max(sessionStartMs, latestMs - WINDOW_MS);
        }

        private long clampViewportStart(long start) {
            if (sessionStartMs == 0L) return 0L;
            long maxStart = liveStartMs();
            return Math.max(sessionStartMs, Math.min(start, maxStart));
        }

        private void drawHistoryBar(Canvas canvas, float left, float right, float y) {
            if (sessionStartMs == 0L || latestMs <= sessionStartMs) return;
            float width = right - left;
            long totalMs = Math.max(WINDOW_MS, latestMs - sessionStartMs);
            float startRatio = (visibleStartMs() - sessionStartMs) / (float) totalMs;
            float endRatio = (Math.min(latestMs, visibleStartMs() + WINDOW_MS) - sessionStartMs) / (float) totalMs;
            float barStart = left + clamp(startRatio, 0f, 1f) * width;
            float barEnd = left + clamp(endRatio, 0f, 1f) * width;

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(6);
            paint.setColor(Color.rgb(36, 72, 84));
            canvas.drawLine(left, y, right, y, paint);

            paint.setStrokeWidth(8);
            paint.setColor(followLive ? Color.rgb(40, 215, 236) : Color.rgb(255, 209, 102));
            canvas.drawLine(barStart, y, Math.max(barStart + 12f, barEnd), y, paint);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(16);
            paint.setColor(Color.rgb(145, 172, 181));
            canvas.drawText(followLive ? "vivo" : "historial", right - 72f, y - 8f, paint);
        }

        private float maxAbs(List<TimedSample> data, boolean lr) {
            float max = 0f;
            for (TimedSample timed : data) {
                max = Math.max(max, Math.abs(lr ? rotationDeltaDeg(timed.sample) : alignmentDeltaDeg(timed.sample)));
            }
            return max;
        }

        private float meanAlignment(List<TimedSample> data) {
            float sum = 0f;
            for (TimedSample timed : data) sum += alignmentDeltaDeg(timed.sample);
            return data.isEmpty() ? 0f : sum / data.size();
        }

        private float maxSmoothedAlignment(List<TimedSample> data, float base) {
            float max = 0f;
            for (int i = 0; i < data.size(); i++) {
                max = Math.max(max, Math.abs(smoothed(data, i, 1) - base));
            }
            return max;
        }

        private float meanMag(List<TimedSample> data) {
            float sum = 0f;
            for (TimedSample timed : data) sum += timed.sample.mag;
            return data.isEmpty() ? baseMag : sum / data.size();
        }

        private float maxSmoothedMag(List<TimedSample> data, float base) {
            float max = 0f;
            for (int i = 0; i < data.size(); i++) {
                max = Math.max(max, magImpulse(smoothedMag(data, i), base));
            }
            return max;
        }

        private float robustMagScale(List<TimedSample> data, float base) {
            if (data.isEmpty()) return 1f;
            List<Float> values = new ArrayList<>();
            for (int i = 0; i < data.size(); i++) {
                values.add(magImpulse(smoothedMag(data, i), base));
            }
            Collections.sort(values);
            int index = Math.min(values.size() - 1, Math.max(0, Math.round(values.size() * 0.90f) - 1));
            float p90 = values.get(index);
            return Math.max(p90, maxSmoothedMag(data, base) * 0.35f);
        }

        private float magImpulse(float mag, float base) {
            return Math.abs(mag - base);
        }

        private float smoothedMag(List<TimedSample> data, int index) {
            float sum = 0f;
            int count = 0;
            for (int i = Math.max(0, index - 1); i <= Math.min(data.size() - 1, index + 1); i++) {
                sum += data.get(i).sample.mag;
                count++;
            }
            return count == 0 ? 0f : sum / count;
        }

        private float smoothed(List<TimedSample> data, int index, int key) {
            float sum = 0f;
            int count = 0;
            for (int i = Math.max(0, index - 1); i <= Math.min(data.size() - 1, index + 1); i++) {
                sum += key == 0 ? rotationDeltaDeg(data.get(i).sample) : alignmentDeltaDeg(data.get(i).sample);
                count++;
            }
            return count == 0 ? 0f : sum / count;
        }

        private float correctedLr(SensorSample sample) {
            return placementBaseReady ? sample.lr - baseLr : sample.lr;
        }

        private float correctedUd(SensorSample sample) {
            return placementBaseReady ? sample.ud - baseUd : sample.ud;
        }

        private float rawAlignmentDeg(SensorSample sample) {
            return (float) Math.toDegrees(Math.atan2(-sample.lr, sample.ud));
        }

        private float rawRotationDeg(SensorSample sample) {
            return (float) Math.toDegrees(Math.atan2(sample.fb, sample.ud));
        }

        private float rotationDeltaDeg(SensorSample sample) {
            float reference = placementBaseReady ? baseRotationDeg : 0f;
            float delta = rawRotationDeg(sample) - reference;
            while (delta > 180f) delta -= 360f;
            while (delta < -180f) delta += 360f;
            return clamp(delta, -90f, 90f);
        }

        private float alignmentDeltaDeg(SensorSample sample) {
            float reference = placementBaseReady ? baseAlignmentDeg : 0f;
            float delta = rawAlignmentDeg(sample) - reference;
            while (delta > 180f) delta -= 360f;
            while (delta < -180f) delta += 360f;
            return clamp(delta, -90f, 90f);
        }

        private float clamp(float value, float min, float max) {
            return Math.max(min, Math.min(max, value));
        }
    }

    public static class RotationLoopView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Queue<SensorSample> samples = new ArrayDeque<>();
        private final List<SensorSample> baseline = new ArrayList<>();

        public RotationLoopView(Context context) {
            super(context);
        }

        public void add(SensorSample sample) {
            samples.add(sample);
            while (samples.size() > 90) {
                samples.poll();
            }
            invalidate();
        }

        public boolean captureBaseline() {
            if (samples.size() < 12) {
                return false;
            }
            baseline.clear();
            baseline.addAll(samples);
            invalidate();
            return true;
        }

        public String readout() {
            if (samples.size() < 8) {
                return "Esperando mas datos para leer rotacion.";
            }

            float current = rotationMagnitude(new ArrayList<>(samples));
            if (baseline.isEmpty()) {
                return String.format(Locale.US,
                        "Rotacion actual %.2f. Sin base tecnica; toma una base con brazada estable.",
                        current
                );
            }

            float base = rotationMagnitude(baseline);
            float diff = base > 0.1f ? ((current - base) / base) * 100f : 0f;
            String reading;
            if (diff >= -12f) {
                reading = "dentro de tu rango tecnico";
            } else if (diff >= -35f) {
                reading = "rotacion baja, intenta ampliar giro de torso";
            } else {
                reading = "muy por debajo de la base, posible espalda plana";
            }

            return String.format(Locale.US,
                    "Rotacion actual %.2f | base %.2f | diferencia %.0f%%: %s.",
                    current,
                    base,
                    diff,
                    reading
            );
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int w = getWidth();
            int h = getHeight();
            float cx = w / 2f;
            float cy = h / 2f;
            float pad = 26f;

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(Color.rgb(7, 21, 28));
            canvas.drawRect(0, 0, w, h, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(Color.rgb(36, 72, 84));
            canvas.drawLine(pad, cy, w - pad, cy, paint);
            canvas.drawLine(cx, pad, cx, h - pad, paint);

            drawInfinityReference(canvas, cx, cy, w, h);

            List<SensorSample> current = new ArrayList<>(samples);
            float scale = sharedScale(current, baseline);
            if (!baseline.isEmpty()) {
                drawPath(canvas, baseline, scale, Color.rgb(255, 209, 102), 3f, 0.72f);
            }
            drawPath(canvas, current, scale, Color.rgb(40, 215, 236), 4f, 0.95f);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(22);
            paint.setColor(Color.rgb(145, 172, 181));
            canvas.drawText("IZQ", pad, cy - 10, paint);
            canvas.drawText("DER", w - pad - 44, cy - 10, paint);
            canvas.drawText("BASE", pad, 28, paint);
            paint.setColor(Color.rgb(255, 209, 102));
            canvas.drawCircle(pad + 70, 22, 8, paint);
            paint.setColor(Color.rgb(40, 215, 236));
            canvas.drawCircle(pad + 122, 22, 8, paint);
            paint.setColor(Color.rgb(145, 172, 181));
            canvas.drawText("ACTUAL", pad + 136, 28, paint);
        }

        private void drawInfinityReference(Canvas canvas, float cx, float cy, int w, int h) {
            float plotW = (w - 52f) * 0.42f;
            float plotH = (h - 52f) * 0.42f;
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(Color.argb(90, 255, 83, 106));
            boolean started = false;
            for (int i = 0; i <= 220; i++) {
                double t = Math.PI * 2.0 * i / 220.0;
                double d = 1.0 + Math.pow(Math.sin(t), 2.0);
                float x = (float) (cx + (Math.cos(t) / d) * plotW * 1.18);
                float y = (float) (cy - ((Math.sin(t) * Math.cos(t)) / d) * plotH * 1.28);
                if (!started) {
                    canvas.drawPoint(x, y, paint);
                    started = true;
                } else {
                    canvas.drawPoint(x, y, paint);
                }
            }
        }

        private void drawPath(Canvas canvas, List<SensorSample> data, float scale, int color, float width, float alpha) {
            if (data.size() < 2) return;
            float lrMean = mean(data, 0);
            float fbMean = mean(data, 1);
            float cx = getWidth() / 2f;
            float cy = getHeight() / 2f;
            float plotW = (getWidth() - 52f) * 0.42f;
            float plotH = (getHeight() - 52f) * 0.42f;

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(width);
            paint.setColor(withAlpha(color, alpha));

            float prevX = 0;
            float prevY = 0;
            for (int i = 0; i < data.size(); i++) {
                SensorSample s = data.get(i);
                float x = cx + clamp((s.lr - lrMean) / scale, -1f, 1f) * plotW;
                float y = cy - clamp((s.fb - fbMean) / scale, -1f, 1f) * plotH;
                if (i > 0) {
                    canvas.drawLine(prevX, prevY, x, y, paint);
                }
                prevX = x;
                prevY = y;
            }
        }

        private int withAlpha(int color, float alpha) {
            return Color.argb(
                    Math.max(0, Math.min(255, (int) (alpha * 255))),
                    Color.red(color),
                    Color.green(color),
                    Color.blue(color)
            );
        }

        private float sharedScale(List<SensorSample> current, List<SensorSample> base) {
            float currentScale = Math.max(axisRange(current, 0), axisRange(current, 1)) / 2f;
            float baseScale = base.isEmpty() ? 0f : Math.max(axisRange(base, 0), axisRange(base, 1)) / 2f;
            return Math.max(1f, Math.max(currentScale, baseScale));
        }

        private float rotationMagnitude(List<SensorSample> data) {
            if (data.size() < 2) return 0f;
            float lrRange = axisRange(data, 0);
            float fbRange = axisRange(data, 1);
            return (float) Math.sqrt((lrRange * lrRange) + (fbRange * fbRange));
        }

        private float axisRange(List<SensorSample> data, int key) {
            if (data.isEmpty()) return 0f;
            float min = Float.MAX_VALUE;
            float max = -Float.MAX_VALUE;
            for (SensorSample s : data) {
                float v = key == 0 ? s.lr : s.fb;
                min = Math.min(min, v);
                max = Math.max(max, v);
            }
            return max - min;
        }

        private float mean(List<SensorSample> data, int key) {
            if (data.isEmpty()) return 0f;
            float sum = 0f;
            for (SensorSample s : data) {
                sum += key == 0 ? s.lr : s.fb;
            }
            return sum / data.size();
        }

        private float clamp(float value, float min, float max) {
            return Math.max(min, Math.min(max, value));
        }
    }
}
