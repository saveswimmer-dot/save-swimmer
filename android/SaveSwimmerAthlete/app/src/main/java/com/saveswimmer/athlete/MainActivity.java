package com.saveswimmer.athlete;

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
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.DashPathEffect;
import android.graphics.Paint;
import android.graphics.Path;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

public class MainActivity extends Activity {
    private static final int BG = Color.rgb(4, 16, 22);
    private static final int PANEL = Color.rgb(13, 37, 48);
    private static final int PANEL_2 = Color.rgb(18, 51, 64);
    private static final int LINE = Color.rgb(36, 75, 88);
    private static final int TEXT = Color.rgb(238, 248, 251);
    private static final int MUTED = Color.rgb(155, 181, 189);
    private static final int CYAN = Color.rgb(40, 215, 236);
    private static final int GREEN = Color.rgb(69, 224, 137);
    private static final int YELLOW = Color.rgb(255, 209, 102);
    private static final int RED = Color.rgb(255, 83, 106);
    private static final int ORANGE = Color.rgb(255, 106, 24);

    private static final String APP_VERSION = "ATHLETE LIVE + CSV V0.3.11 NUEVA";
    private static final String DEVICE_PREFIX = "SS-LT";
    private static final UUID SS_SERVICE = UUID.fromString("8f1c1000-5a7e-4b3d-9c21-a10000000001");
    private static final UUID SS_TELEMETRY = UUID.fromString("8f1c1001-5a7e-4b3d-9c21-a10000000001");
    private static final UUID CCCD = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
    private static final int REQ_CSV = 7001;
    private static final int REQ_PERMS = 7002;

    private LinearLayout root;
    private int selectedTab = 0;
    private String bleState = "sin conexion";
    private String lastPacket = "--";
    private String fileName = "--";
    private String csvFileStatus = "sin archivo";
    private String csvSummary = "Carga un CSV de la microSD o de Descargas para ver la lectura de sesion.";
    private String csvWhy = "Sin archivo analizado.";
    private boolean scanning = false;
    private boolean connected = false;
    private boolean familyContactActive = true;
    private boolean shareWithCoach = false;
    private BluetoothGatt gatt;
    private BluetoothLeScanner scanner;

    private final ArrayList<Sample> live = new ArrayList<>();
    private final ArrayList<Sample> csvSamples = new ArrayList<>();
    private SessionStats liveStats = new SessionStats();
    private SessionStats csvStats = new SessionStats();
    private double csvWindowStart = 0;
    private double liveWindowStart = 0;
    private boolean liveFollow = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(build());
        renderLive();
    }

    @Override
    protected void onDestroy() {
        stopScan();
        if (hasBleConnect() && gatt != null) {
            gatt.disconnect();
            gatt.close();
        }
        super.onDestroy();
    }

    private View build() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackgroundColor(BG);
        root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(14), dp(12), dp(14), dp(18));
        scroll.addView(root, new ScrollView.LayoutParams(-1, -2));
        return scroll;
    }

    private void renderBase(String subtitle) {
        root.removeAllViews();

        LinearLayout header = row();
        header.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout titleBox = new LinearLayout(this);
        titleBox.setOrientation(LinearLayout.VERTICAL);
        TextView title = text("SAVE SWIMMER\nATHLETE NUEVO", 24, TEXT, true);
        title.setLetterSpacing(0.12f);
        TextView version = text(APP_VERSION, 12, CYAN, true);
        version.setLetterSpacing(0.12f);
        titleBox.addView(title);
        titleBox.addView(version);
        header.addView(titleBox, new LinearLayout.LayoutParams(0, -2, 1));
        header.addView(pill(connected ? "BLE vivo" : "lectura", connected), new LinearLayout.LayoutParams(dp(112), dp(40)));
        root.addView(header);

        TextView sub = text(subtitle, 14, MUTED, false);
        sub.setPadding(dp(2), dp(8), dp(2), dp(2));
        root.addView(sub);

        LinearLayout tabs = row();
        tabs.addView(tab("En vivo BLE", 0), new LinearLayout.LayoutParams(0, dp(48), 1));
        tabs.addView(tab("Analizar CSV", 1), new LinearLayout.LayoutParams(0, dp(48), 1));
        tabs.addView(tab("Lectura", 2), new LinearLayout.LayoutParams(0, dp(48), 1));
        root.addView(tabs, paramsTop(12, -2));

        root.addView(safetyPanel(), paramsTop(9, -2));
    }

    private Button tab(String label, int index) {
        Button b = button(label, selectedTab != index);
        b.setOnClickListener(v -> {
            selectedTab = index;
            if (index == 0) renderLive();
            else if (index == 1) renderCsv();
            else renderReading();
        });
        return b;
    }

    private void renderLive() {
        selectedTab = 0;
        renderBase("Vista solo lectura: no inicia ni cierra SD. La app laboratorio sigue controlando la sesion.");

        LinearLayout actions = row();
        Button connect = button(connected ? "Desconectar" : (scanning ? "Escaneando..." : "Conectar BLE"), false);
        connect.setOnClickListener(v -> {
            if (connected) disconnectBle();
            else startBle();
        });
        Button zero = button("Tomar base", true);
        zero.setOnClickListener(v -> {
            if (!live.isEmpty()) {
                Sample s = live.get(live.size() - 1);
                Sample.baselineRotationDeg = s.rawRotationDeg;
                Sample.baselineAlignmentDeg = s.rawAlignmentDeg;
                Sample.baselineMag = s.mag;
                live.clear();
                lastPacket = "Base tomada. Ahora mueve el cuerpo para leer desde cero.";
                recomputeLive();
                renderLive();
            }
        });
        actions.addView(connect, new LinearLayout.LayoutParams(0, dp(52), 1));
        actions.addView(zero, new LinearLayout.LayoutParams(0, dp(52), 1));
        root.addView(actions, paramsTop(12, -2));

        root.addView(panel("Estado BLE", text(bleState + "\nUltimo paquete: " + lastPacket, 15, connected ? TEXT : MUTED, true)), paramsTop(9, -2));

        LinearLayout grid = row();
        grid.addView(metric("Rotacion", liveStats.rotationLabel, liveStats.rotationValue), new LinearLayout.LayoutParams(0, dp(112), 1));
        grid.addView(metric("Alineacion", liveStats.alignmentLabel, liveStats.alignmentValue), new LinearLayout.LayoutParams(0, dp(112), 1));
        root.addView(grid, paramsTop(9, -2));

        LinearLayout grid2 = row();
        grid2.addView(metric("Movimiento", liveStats.motionLabel, liveStats.motionValue), new LinearLayout.LayoutParams(0, dp(112), 1));
        grid2.addView(metric("Ritmo", liveStats.rhythmLabel, liveStats.rhythmValue), new LinearLayout.LayoutParams(0, dp(112), 1));
        root.addView(grid2, paramsTop(9, -2));

        root.addView(panel("Rotacion + alineacion + movimiento | ventana 30 s", liveTrendPanel()), paramsTop(9, 680));
        root.addView(panel("Rotacion dorsal | referencia visual", new XAngleView(this, liveStats, true)), paramsTop(9, 880));
        root.addView(panel("Lectura para atleta", text(liveStats.summary, 18, TEXT, true)), paramsTop(9, -2));
        root.addView(panel("Por que", text(liveStats.why, 15, MUTED, false)), paramsTop(9, -2));
    }

    private View safetyPanel() {
        LinearLayout box = panelBox();
        box.addView(text("Seguridad de sesion", 13, MUTED, false));
        String family = familyContactActive
                ? "Familia/contacto: ACTIVO obligatorio"
                : "Familia/contacto: PENDIENTE";
        String coach = shareWithCoach
                ? "Coach: compartiendo datos tecnicos"
                : "Coach: privado, no compartido";
        TextView status = text(family + "\n" + coach, 17, familyContactActive ? TEXT : RED, true);
        status.setPadding(0, dp(6), 0, dp(8));
        box.addView(status);

        LinearLayout actions = row();
        Button familyBtn = button(familyContactActive ? "Contacto activo" : "Activar contacto", !familyContactActive);
        familyBtn.setOnClickListener(v -> {
            familyContactActive = true;
            if (selectedTab == 0) renderLive();
            else if (selectedTab == 1) renderCsv();
            else renderReading();
        });
        Button coachBtn = button(shareWithCoach ? "Coach ON" : "Coach OFF", !shareWithCoach);
        coachBtn.setOnClickListener(v -> {
            shareWithCoach = !shareWithCoach;
            if (selectedTab == 0) renderLive();
            else if (selectedTab == 1) renderCsv();
            else renderReading();
        });
        actions.addView(familyBtn, new LinearLayout.LayoutParams(0, dp(46), 1));
        actions.addView(coachBtn, new LinearLayout.LayoutParams(0, dp(46), 1));
        box.addView(actions);
        box.addView(text("Una sesion real requiere contacto familiar activo. Coach es opcional y puede apagarse sin afectar emergencias.", 13, MUTED, false));
        return box;
    }

    private void renderCsv() {
        selectedTab = 1;
        renderBase("Analisis posterior: carga el CSV completo sin usar la descarga BLE larga.");

        LinearLayout actions = row();
        Button load = button("Cargar CSV", false);
        load.setOnClickListener(v -> openCsvPicker());
        Button clear = button("Limpiar", true);
        clear.setOnClickListener(v -> {
            csvSamples.clear();
            csvStats = new SessionStats();
            csvWindowStart = 0;
            fileName = "--";
            csvFileStatus = "sin archivo";
            csvSummary = "Carga un CSV de la microSD o de Descargas para ver la lectura de sesion.";
            csvWhy = "Sin archivo analizado.";
            renderCsv();
        });
        actions.addView(load, new LinearLayout.LayoutParams(0, dp(52), 1));
        actions.addView(clear, new LinearLayout.LayoutParams(0, dp(52), 1));
        root.addView(actions, paramsTop(12, -2));

        root.addView(panel("Archivo", text(fileName + "\n" + csvFileStatus, 17, TEXT, true)), paramsTop(9, -2));

        LinearLayout grid = row();
        grid.addView(metric("Duracion", csvStats.durationLabel, "sesion completa"), new LinearLayout.LayoutParams(0, dp(112), 1));
        grid.addView(metric("Ciclos/mov.", csvStats.strokeLabel, csvStats.strokeValue), new LinearLayout.LayoutParams(0, dp(112), 1));
        root.addView(grid, paramsTop(9, -2));

        LinearLayout grid2 = row();
        grid2.addView(metric("Distancia GPS", csvStats.distanceLabel, csvStats.gpsLabel), new LinearLayout.LayoutParams(0, dp(112), 1));
        grid2.addView(metric("Avance GPS", csvStats.advanceLabel, csvStats.advanceValue), new LinearLayout.LayoutParams(0, dp(112), 1));
        root.addView(grid2, paramsTop(9, -2));

        LinearLayout grid3 = row();
        grid3.addView(metric("Movimiento", csvStats.motionLabel, csvStats.motionValue), new LinearLayout.LayoutParams(0, dp(112), 1));
        grid3.addView(metric("Picos/contexto", csvStats.impactLabel, csvStats.impactValue), new LinearLayout.LayoutParams(0, dp(112), 1));
        root.addView(grid3, paramsTop(9, -2));

        LinearLayout grid4 = row();
        grid4.addView(metric("Tecnica", csvStats.reachLabel, csvStats.reachValue), new LinearLayout.LayoutParams(0, dp(112), 1));
        grid4.addView(metric("Eficiencia", csvStats.efficiencyLabel, csvStats.efficiencyValue), new LinearLayout.LayoutParams(0, dp(112), 1));
        root.addView(grid4, paramsTop(9, -2));

        root.addView(panel("Resumen temporal", text(csvSummary, 19, TEXT, true)), paramsTop(9, -2));
        root.addView(panel("Que significa", text(csvWhy, 16, MUTED, false)), paramsTop(9, -2));
        root.addView(panel("Tendencia clara | tramo 30 s", csvTrendPanel()), paramsTop(9, 1180));
        root.addView(panel("Rotacion y simetria", new XAngleView(this, csvStats, false)), paramsTop(9, 880));
    }

    private View csvTrendPanel() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        MultiLineView graph = new MultiLineView(this, csvSamples, 30f, csvWindowStart, true);
        box.addView(graph, new LinearLayout.LayoutParams(-1, 0, 1));
        TextView segment = text(csvSegmentLabel(csvWindowStart), 13, TEXT, true);
        box.addView(segment, new LinearLayout.LayoutParams(-1, dp(54)));
        TextView range = text(csvRangeLabel(csvWindowStart), 14, TEXT, true);
        box.addView(range, new LinearLayout.LayoutParams(-1, dp(30)));
        SeekBar bar = new SeekBar(this);
        double duration = sessionDuration(csvSamples);
        int max = (int) Math.max(0, Math.ceil(duration - 30));
        bar.setMax(max);
        bar.setProgress((int) Math.max(0, Math.min(max, Math.round(csvWindowStart))));
        bar.setEnabled(max > 0);
        bar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser) {
                    csvWindowStart = progress;
                    graph.fixedStart = progress;
                    segment.setText(csvSegmentLabel(progress));
                    range.setText(csvRangeLabel(progress));
                    graph.invalidate();
                }
            }
            @Override public void onStartTrackingTouch(SeekBar seekBar) {}
            @Override public void onStopTrackingTouch(SeekBar seekBar) { renderCsv(); }
        });
        box.addView(bar, new LinearLayout.LayoutParams(-1, dp(42)));
        box.addView(text(max > 0 ? "Azul: rotacion | violeta: alineacion | verde: velocidad GPS." : "Sesion menor a 30 segundos.", 13, MUTED, false), new LinearLayout.LayoutParams(-1, dp(48)));
        return box;
    }

    private String csvSegmentLabel(double start) {
        if (csvSamples.isEmpty()) return "Sin tramo.";
        double base = csvSamples.get(0).t;
        List<Sample> part = slice(csvSamples, base + start, base + start + 30);
        if (part.isEmpty()) part = csvSamples;
        double speed = SessionStats.avg(part, "speed");
        double maxSpeed = SessionStats.max(part, "speed");
        double rot = SessionStats.avgAbs(part, "rot");
        double align = SessionStats.avgAbs(part, "align");
        String advance = SessionStats.labelAdvance(part, speed, maxSpeed, SessionStats.distance(part));
        return String.format(Locale.US, "Tramo: %s | %.1f km/h prom | rot %.0f deg | alin %.0f deg", advance, speed, rot, align);
    }

    private static List<Sample> slice(List<Sample> samples, double from, double to) {
        ArrayList<Sample> out = new ArrayList<>();
        for (Sample s : samples) if (s.t >= from && s.t <= to) out.add(s);
        return out;
    }

    private View liveTrendPanel() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        double duration = sessionDuration(live);
        int max = (int) Math.max(0, Math.ceil(duration - 30));
        if (liveFollow) liveWindowStart = max;

        MultiLineView graph = new MultiLineView(this, live, 30f, liveWindowStart);
        box.addView(graph, new LinearLayout.LayoutParams(-1, 0, 1));
        TextView range = text(liveRangeLabel(liveWindowStart, liveFollow), 14, TEXT, true);
        box.addView(range, new LinearLayout.LayoutParams(-1, dp(30)));

        SeekBar bar = new SeekBar(this);
        bar.setMax(max);
        bar.setProgress((int) Math.max(0, Math.min(max, Math.round(liveWindowStart))));
        bar.setEnabled(max > 0);
        bar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser) {
                    liveWindowStart = progress;
                    liveFollow = progress >= Math.max(0, seekBar.getMax() - 1);
                    graph.fixedStart = progress;
                    range.setText(liveRangeLabel(progress, liveFollow));
                    graph.invalidate();
                }
            }
            @Override public void onStartTrackingTouch(SeekBar seekBar) {}
            @Override public void onStopTrackingTouch(SeekBar seekBar) { renderLive(); }
        });
        box.addView(bar, new LinearLayout.LayoutParams(-1, dp(42)));
        box.addView(text(max > 0
                ? (liveFollow ? "Siguiendo el vivo. Mueve la barra para revisar atras." : "Revisando historial. Lleva la barra al final para volver al vivo.")
                : "Ventana viva menor a 30 segundos.", 13, MUTED, false));
        return box;
    }

    private String csvRangeLabel(double start) {
        double duration = sessionDuration(csvSamples);
        double from = Math.max(0, Math.min(Math.max(0, duration), start));
        double to = Math.min(duration, from + 30);
        return String.format(Locale.US, "Viendo %s-%s de %s", SessionStats.fmtTime(from), SessionStats.fmtTime(to), SessionStats.fmtTime(duration));
    }

    private String liveRangeLabel(double start, boolean follow) {
        double duration = sessionDuration(live);
        double from = Math.max(0, Math.min(Math.max(0, duration), start));
        double to = Math.min(duration, from + 30);
        return String.format(Locale.US, "%s %s-%s de %s",
                follow ? "Vivo:" : "Revisando:",
                SessionStats.fmtTime(from),
                SessionStats.fmtTime(to),
                SessionStats.fmtTime(duration));
    }

    private void renderReading() {
        selectedTab = 2;
        renderBase("Diccionario de lectura: lo que la app debe decir y por que.");

        root.addView(readingCard("Rotacion", "Mide rolido dorsal derecha/izquierda.", "Sirve para ver si el atleta nada plano, gira demasiado o tiene asimetria entre lados."), paramsTop(10, -2));
        root.addView(readingCard("Alineacion", "Observa estabilidad del cuerpo con UD/FB y tendencia.", "Si empieza estable y luego cambia mucho, puede indicar perdida de linea corporal o fatiga tecnica."), paramsTop(9, -2));
        root.addView(readingCard("Movimiento", "Usa MAG como energia relativa y detecta picos de impacto.", "No confirma propulsion ni avance por si solo; sirve para entender golpes, agitacion y patron corporal."), paramsTop(9, -2));
        root.addView(readingCard("Ritmo", "Detecta periodicidad de ciclos.", "Indica si el atleta mantiene frecuencia, acelera, baja o se detiene."), paramsTop(9, -2));
        root.addView(readingCard("Avance GPS", "Mide desplazamiento y velocidad cuando hay fix valido.", "En mesa debe quedar en 0 o sin GPS aunque el sensor detecte movimiento lateral."), paramsTop(9, -2));
        root.addView(readingCard("Eficiencia", "Cruza GPS con movimiento, rotacion y alineacion.", "Si avanza mas con igual energia, probablemente mejoro tecnica. Si se mueve mas y avanza menos, algo se desordeno."), paramsTop(9, -2));
        root.addView(readingCard("Regla de comparacion", "Actual vs inicio + ultimos 30 s + promedio de sesion.", "Evita decir que bajo el rendimiento cuando solo bajo respecto al tramo reciente pero sigue mejor que al inicio."), paramsTop(9, -2));
    }

    private View readingCard(String title, String what, String why) {
        LinearLayout box = panelBox();
        box.addView(text(title, 22, CYAN, true));
        box.addView(text("Que mide: " + what, 15, TEXT, true));
        TextView w = text("Para que sirve: " + why, 14, MUTED, false);
        w.setPadding(0, dp(4), 0, 0);
        box.addView(w);
        return box;
    }

    private void startBle() {
        if (!ensurePermissions()) return;
        BluetoothManager manager = (BluetoothManager) getSystemService(BLUETOOTH_SERVICE);
        BluetoothAdapter adapter = manager == null ? null : manager.getAdapter();
        if (adapter == null || !adapter.isEnabled()) {
            bleState = "Bluetooth apagado. Enciendelo para conectar.";
            renderLive();
            return;
        }
        scanner = adapter.getBluetoothLeScanner();
        if (scanner == null) {
            bleState = "No se pudo iniciar escaneo BLE.";
            renderLive();
            return;
        }
        live.clear();
        Sample.resetBaseline();
        liveWindowStart = 0;
        liveFollow = true;
        recomputeLive();
        scanning = true;
        bleState = "buscando SS-LT...";
        renderLive();
        if (hasBleScan()) scanner.startScan(scanCallback);
        root.postDelayed(() -> {
            if (scanning) {
                stopScan();
                bleState = "No encontrado. Verifica ESP encendido y sin otra app conectada.";
                renderLive();
            }
        }, 12000);
    }

    private void stopScan() {
        if (scanning && scanner != null && hasBleScan()) scanner.stopScan(scanCallback);
        scanning = false;
    }

    private final ScanCallback scanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            BluetoothDevice d = result.getDevice();
            String name = hasBleConnect() ? d.getName() : null;
            if (name == null && result.getScanRecord() != null) name = result.getScanRecord().getDeviceName();
            if (name != null && name.startsWith(DEVICE_PREFIX)) {
                stopScan();
                bleState = "conectando a " + name;
                renderLive();
                if (hasBleConnect()) gatt = d.connectGatt(MainActivity.this, false, gattCallback);
            }
        }
    };

    private final BluetoothGattCallback gattCallback = new BluetoothGattCallback() {
        @Override
        public void onConnectionStateChange(BluetoothGatt g, int status, int newState) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                connected = true;
                bleState = "conectado, buscando telemetria...";
                runOnUiThread(() -> renderLive());
                if (hasBleConnect()) g.discoverServices();
            } else {
                connected = false;
                bleState = "desconectado";
                runOnUiThread(() -> renderLive());
            }
        }

        @Override
        public void onServicesDiscovered(BluetoothGatt g, int status) {
            BluetoothGattService s = g.getService(SS_SERVICE);
            BluetoothGattCharacteristic ch = s == null ? null : s.getCharacteristic(SS_TELEMETRY);
            if (ch == null) {
                bleState = "servicio Save Swimmer no encontrado";
                runOnUiThread(() -> renderLive());
                return;
            }
            if (hasBleConnect()) {
                g.setCharacteristicNotification(ch, true);
                BluetoothGattDescriptor d = ch.getDescriptor(CCCD);
                if (d != null) {
                    d.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                    g.writeDescriptor(d);
                }
            }
            bleState = "conectado, esperando datos...";
            runOnUiThread(() -> renderLive());
        }

        @Override
        public void onCharacteristicChanged(BluetoothGatt g, BluetoothGattCharacteristic ch) {
            String raw = new String(ch.getValue(), StandardCharsets.UTF_8);
            onPacket(raw);
        }
    };

    private void disconnectBle() {
        stopScan();
        if (hasBleConnect() && gatt != null) {
            gatt.disconnect();
            gatt.close();
        }
        gatt = null;
        connected = false;
        bleState = "desconectado";
        renderLive();
    }

    private void onPacket(String raw) {
        Sample s = Sample.fromLine(raw);
        if (s == null) return;
        runOnUiThread(() -> {
            if (s.t <= 0 && !live.isEmpty()) s.t = live.get(live.size() - 1).t + 0.5;
            live.add(s);
            if (live.size() > 1200) live.remove(0);
            if (liveFollow) liveWindowStart = Math.max(0, sessionDuration(live) - 30);
            lastPacket = String.format(Locale.US, "LR %.1f | FB %.1f | UD %.1f | MAG %.1f | ROT %.1f | ALIGN %.1f",
                    s.lr, s.fb, s.ud, s.mag, s.rotation, s.alignment);
            recomputeLive();
            if (selectedTab == 0) renderLive();
        });
    }

    private void recomputeLive() {
        liveStats = SessionStats.from(live, true);
    }

    private boolean ensurePermissions() {
        ArrayList<String> missing = new ArrayList<>();
        if (Build.VERSION.SDK_INT >= 31) {
            if (checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) missing.add(Manifest.permission.BLUETOOTH_SCAN);
            if (checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) missing.add(Manifest.permission.BLUETOOTH_CONNECT);
        } else if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            missing.add(Manifest.permission.ACCESS_FINE_LOCATION);
        }
        if (!missing.isEmpty()) {
            requestPermissions(missing.toArray(new String[0]), REQ_PERMS);
            return false;
        }
        return true;
    }

    private boolean hasBleScan() {
        return Build.VERSION.SDK_INT < 31 || checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED;
    }

    private boolean hasBleConnect() {
        return Build.VERSION.SDK_INT < 31 || checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED;
    }

    private void openCsvPicker() {
        Intent i = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        i.addCategory(Intent.CATEGORY_OPENABLE);
        i.setType("*/*");
        startActivityForResult(i, REQ_CSV);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQ_CSV && resultCode == RESULT_OK && data != null) {
            loadCsv(data.getData());
        }
    }

    private void loadCsv(Uri uri) {
        csvSamples.clear();
        try (InputStream in = getContentResolver().openInputStream(uri);
             BufferedReader br = new BufferedReader(new InputStreamReader(in))) {
            fileName = uri.getLastPathSegment() == null ? "CSV seleccionado" : uri.getLastPathSegment();
            CsvMeta meta = new CsvMeta(fileName);
            String[] headers = null;
            String line;
            while ((line = br.readLine()) != null) {
                String clean = line.trim();
                if (clean.startsWith("#")) {
                    meta.readComment(clean);
                    continue;
                }
                if (clean.isEmpty()) continue;

                Sample rawSample = Sample.fromLine(clean);
                if (rawSample != null && looksLikeTelemetryLine(clean)) {
                    csvSamples.add(rawSample);
                    continue;
                }

                String[] cells = splitCsv(clean);
                if (headers == null) {
                    if (looksLikeHeader(cells)) headers = cells;
                    continue;
                }

                Sample s = Sample.fromCsv(headers, cells);
                if (s != null) csvSamples.add(s);
            }
            if (csvSamples.isEmpty()) throw new IllegalArgumentException("No encontre muestras validas. Revisa que el CSV tenga TIME/LR/FB/UD/MAG o lineas JSON del firmware.");
            csvStats = SessionStats.from(csvSamples, false);
            csvWindowStart = Math.max(0, sessionDuration(csvSamples) - 30);
            csvFileStatus = meta.statusText();
            csvSummary = csvStats.summary;
            csvWhy = csvStats.why;
        } catch (Exception e) {
            csvSummary = "No se pudo leer el CSV.";
            csvWhy = e.getMessage() == null ? "Error desconocido." : e.getMessage();
            csvStats = new SessionStats();
            csvFileStatus = "archivo no validado";
        }
        renderCsv();
    }

    private static class CsvMeta {
        final String name;
        boolean endSession = false;
        boolean endSummary = false;
        int timeGaps = -1;
        int maxGapMs = -1;
        int sourceRows = -1;

        CsvMeta(String name) {
            this.name = name == null ? "" : name;
        }

        void readComment(String line) {
            String u = line.toUpperCase(Locale.US);
            if (u.startsWith("#END_SESSION")) {
                endSession = true;
                timeGaps = (int) numberAfter(u, "TIME_GAPS=", timeGaps);
                maxGapMs = (int) numberAfter(u, "MAX_GAP_MS=", maxGapMs);
            } else if (u.startsWith("#END_SUMMARY")) {
                endSummary = true;
                sourceRows = (int) numberAfter(u, "SOURCE_ROWS=", sourceRows);
            } else if (u.startsWith("#SD_GAP")) {
                if (timeGaps < 0) timeGaps = 0;
                timeGaps++;
            }
        }

        String statusText() {
            boolean incompleteName = name.toUpperCase(Locale.US).contains("INCOMPLETA");
            boolean closed = endSession || endSummary;
            StringBuilder sb = new StringBuilder();
            if (closed && incompleteName) sb.append("Estado: cerrada por firmware, nombre historico INCOMPLETA.");
            else if (closed) sb.append("Estado: sesion cerrada.");
            else if (incompleteName) sb.append("Estado: incompleta real o sin cierre detectado.");
            else sb.append("Estado: sin footer de cierre.");
            if (timeGaps > 0) sb.append(String.format(Locale.US, " Gaps SD: %d", timeGaps));
            if (maxGapMs > 0) sb.append(String.format(Locale.US, " | max %.1f s", maxGapMs / 1000.0));
            if (sourceRows > 0) sb.append(String.format(Locale.US, " | filas %d", sourceRows));
            return sb.toString();
        }

        double numberAfter(String text, String key, double fallback) {
            int start = text.indexOf(key);
            if (start < 0) return fallback;
            start += key.length();
            int end = start;
            while (end < text.length()) {
                char c = text.charAt(end);
                if ((c >= '0' && c <= '9') || c == '.') end++;
                else break;
            }
            try {
                return Double.parseDouble(text.substring(start, end));
            } catch (Exception e) {
                return fallback;
            }
        }
    }

    private static double sessionDuration(List<Sample> samples) {
        if (samples == null || samples.size() < 2) return 0;
        return Math.max(0, samples.get(samples.size() - 1).t - samples.get(0).t);
    }

    private static String[] splitCsv(String line) {
        ArrayList<String> out = new ArrayList<>();
        StringBuilder cur = new StringBuilder();
        boolean quote = false;
        char separator = detectSeparator(line);
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '"') quote = !quote;
            else if (c == separator && !quote) {
                out.add(cur.toString().trim());
                cur.setLength(0);
            } else cur.append(c);
        }
        out.add(cur.toString().trim());
        return out.toArray(new String[0]);
    }

    private static char detectSeparator(String line) {
        int commas = 0, semis = 0, tabs = 0;
        boolean quote = false;
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '"') quote = !quote;
            else if (!quote && c == ',') commas++;
            else if (!quote && c == ';') semis++;
            else if (!quote && c == '\t') tabs++;
        }
        if (tabs > commas && tabs > semis) return '\t';
        if (semis > commas) return ';';
        return ',';
    }

    private static boolean looksLikeTelemetryLine(String line) {
        String u = line.toUpperCase(Locale.US);
        return line.startsWith("{") || u.startsWith("A:") || u.contains("\"TIME\"") || u.contains("LR:") || u.contains("MAG:");
    }

    private static boolean looksLikeHeader(String[] cells) {
        int hits = 0;
        for (String c : cells) {
            String n = Sample.cleanName(c);
            if (n.equals("TIME") || n.equals("TIME_S") || n.equals("TIME_MS") || n.equals("LR") || n.equals("FB")
                    || n.equals("ELAPSED_S") || n.equals("ELAPSED_MS") || n.equals("UD") || n.equals("MAG") || n.equals("ROLL") || n.equals("PITCH")
                    || n.equals("LAT") || n.equals("GPS_LAT") || n.equals("LON") || n.equals("GPS_LON")) hits++;
        }
        return hits >= 2;
    }

    private View metric(String label, String value, String note) {
        LinearLayout box = panelBox();
        box.setPadding(dp(12), dp(10), dp(12), dp(10));
        box.addView(text(label, 13, MUTED, false));
        TextView v = text(value, 24, TEXT, true);
        v.setPadding(0, dp(4), 0, 0);
        box.addView(v);
        box.addView(text(note, 12, MUTED, false));
        return box;
    }

    private View panel(String label, View content) {
        LinearLayout box = panelBox();
        box.addView(text(label, 13, MUTED, false));
        LinearLayout.LayoutParams cp = new LinearLayout.LayoutParams(-1, content instanceof TextView ? -2 : 0);
        if (!(content instanceof TextView)) cp.weight = 1;
        cp.setMargins(0, dp(8), 0, 0);
        box.addView(content, cp);
        return box;
    }

    private LinearLayout panelBox() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(12), dp(12), dp(12), dp(12));
        box.setBackgroundColor(PANEL);
        return box;
    }

    private LinearLayout row() {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER);
        return row;
    }

    private Button button(String label, boolean secondary) {
        Button b = new Button(this);
        b.setText(label);
        b.setTextSize(13);
        b.setAllCaps(false);
        b.setTextColor(secondary ? TEXT : Color.rgb(3, 33, 38));
        b.setBackgroundColor(secondary ? PANEL_2 : CYAN);
        return b;
    }

    private TextView text(String value, int sp, int color, boolean bold) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(sp);
        t.setTextColor(color);
        t.setIncludeFontPadding(true);
        if (bold) t.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
        return t;
    }

    private TextView pill(String value, boolean live) {
        TextView t = text(value, 12, live ? GREEN : MUTED, true);
        t.setGravity(Gravity.CENTER);
        t.setPadding(dp(10), 0, dp(10), 0);
        t.setBackgroundColor(PANEL_2);
        return t;
    }

    private LinearLayout.LayoutParams paramsTop(int topDp, int height) {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, height);
        lp.setMargins(0, dp(topDp), 0, 0);
        return lp;
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private static class Sample {
        static double baselineRotationDeg = 0;
        static double baselineAlignmentDeg = 0;
        static double baselineMag = 9.81;
        double t, lr, fb, ud, mag, roll, pitch, rotAxis, alignAxis, rotDeg, alignDeg, lat, lon, speedKmh;
        double rawRotationDeg, rawAlignmentDeg;
        double rotation, alignment, impulse;
        String body = "";
        boolean hasGps;

        Sample() {
            t = Double.NaN;
            lr = Double.NaN;
            fb = Double.NaN;
            ud = Double.NaN;
            mag = Double.NaN;
            roll = Double.NaN;
            pitch = Double.NaN;
            rotAxis = Double.NaN;
            alignAxis = Double.NaN;
            rotDeg = Double.NaN;
            alignDeg = Double.NaN;
            lat = Double.NaN;
            lon = Double.NaN;
            speedKmh = Double.NaN;
        }

        static void resetBaseline() {
            baselineRotationDeg = 0;
            baselineAlignmentDeg = 0;
            baselineMag = 9.81;
        }

        static Sample fromLine(String raw) {
            Sample compact = fromCompactA(raw);
            if (compact != null) return compact;

            Sample s = new Sample();
            s.t = get(raw, "TIME", "TIME_S", "t");
            s.lr = get(raw, "LR", "lr");
            s.fb = get(raw, "FB", "fb");
            s.ud = get(raw, "UD", "ud");
            s.mag = get(raw, "MAG", "mag");
            s.roll = get(raw, "ROLL", "roll");
            s.pitch = get(raw, "PITCH", "pitch");
            s.rotAxis = get(raw, "ROT", "rot");
            s.alignAxis = get(raw, "ALIGN", "align");
            s.rotDeg = get(raw, "ROT_DEG", "rot_deg");
            s.alignDeg = get(raw, "ALIGN_DEG", "align_deg");
            s.body = getText(raw, "BODY", "body");
            s.lat = get(raw, "LAT", "lat");
            s.lon = get(raw, "LON", "lon");
            s.speedKmh = get(raw, "SPEED_KMH", "GPS_SPEED_KMH", "speedKmh");
            if (!hasMotion(raw) || (Double.isNaN(s.mag) && Double.isNaN(s.lr))) return null;
            normalize(s);
            if (!saneMotion(s)) return null;
            return s;
        }

        static Sample fromCompactA(String raw) {
            try {
                if (raw == null) return null;
                String clean = raw.trim();
                int start = clean.indexOf("A:");
                if (start < 0) start = clean.indexOf("a:");
                if (start < 0) return null;
                String payload = clean.substring(start + 2);
                int stop = payload.indexOf('\n');
                if (stop < 0) stop = payload.indexOf('\r');
                if (stop < 0) stop = payload.indexOf(';');
                if (stop >= 0) payload = payload.substring(0, stop);
                String[] parts = payload.split(",");
                if (parts.length < 4) return null;

                int offset = parts.length >= 5 ? 1 : 0;
                double lr = parseNumber(parts[offset], 0);
                double fb = parseNumber(parts[offset + 1], 0);
                double ud = parseNumber(parts[offset + 2], 0);
                double mag = parseNumber(parts[offset + 3], 0);
                boolean encodedX10 = Math.abs(lr) > 30 || Math.abs(fb) > 30 || Math.abs(ud) > 30 || Math.abs(mag) > 30;
                double scale = encodedX10 ? 10.0 : 1.0;

                Sample s = new Sample();
                s.t = 0;
                s.lr = lr / scale;
                s.fb = fb / scale;
                s.ud = ud / scale;
                s.mag = mag / scale;
                normalize(s);
                return saneMotion(s) ? s : null;
            } catch (Exception e) {
                return null;
            }
        }

        static Sample fromCsv(String[] h, String[] v) {
            Sample s = new Sample();
            s.t = val(h, v, "TIME", "TIME_S", "ELAPSED_S", "SECONDS", "SEC", "TIME_MS", "ELAPSED_MS", "MILLIS", "MS", "t");
            s.lr = val(h, v, "LR", "lr");
            s.fb = val(h, v, "FB", "fb");
            s.ud = val(h, v, "UD", "ud");
            s.mag = val(h, v, "MAG", "mag");
            s.roll = val(h, v, "ROLL", "roll");
            s.pitch = val(h, v, "PITCH", "pitch");
            s.rotAxis = val(h, v, "ROT", "rot");
            s.alignAxis = val(h, v, "ALIGN", "align");
            s.rotDeg = val(h, v, "ROT_DEG", "ROTATION_DEG", "rot_deg");
            s.alignDeg = val(h, v, "ALIGN_DEG", "ALIGNMENT_DEG", "align_deg");
            s.body = textVal(h, v, "BODY", "BODY_STATE", "body");
            s.lat = val(h, v, "LAT", "GPS_LAT", "LATITUDE", "GPS_LATITUDE", "lat");
            s.lon = val(h, v, "LON", "GPS_LON", "LONGITUDE", "GPS_LONGITUDE", "lng", "lon");
            s.speedKmh = val(h, v, "SPEED_KMH", "GPS_SPEED_KMH", "GPS_SPEED", "SPEED", "speedKmh");
            if (Double.isNaN(s.t) && Double.isNaN(s.mag) && Double.isNaN(s.lr)) return null;
            if (hasHeader(h, "TIME_MS", "ELAPSED_MS", "MILLIS", "MS") && s.t > 10000) s.t = s.t / 1000.0;
            normalize(s);
            if (!saneMotion(s)) return null;
            return s;
        }

        static void normalize(Sample s) {
            if (Double.isNaN(s.t)) s.t = 0;
            if (Double.isNaN(s.lr)) s.lr = 0;
            if (Double.isNaN(s.fb)) s.fb = 0;
            if (Double.isNaN(s.ud)) s.ud = 0;
            if (Double.isNaN(s.mag)) s.mag = Math.sqrt(s.lr * s.lr + s.fb * s.fb + s.ud * s.ud);
            if (Double.isNaN(s.roll)) s.roll = Math.toDegrees(Math.atan2(s.lr, Math.max(0.01, Math.abs(s.ud))));
            if (Double.isNaN(s.pitch)) s.pitch = Math.toDegrees(Math.atan2(-s.fb, Math.sqrt(s.lr * s.lr + s.ud * s.ud)));
            if (Double.isNaN(s.speedKmh)) s.speedKmh = 0;
            if (Double.isNaN(s.rotAxis)) s.rotAxis = s.fb;
            if (Double.isNaN(s.alignAxis)) s.alignAxis = -s.lr;
            s.rawRotationDeg = Double.isNaN(s.rotDeg) ? Math.toDegrees(Math.atan2(s.fb, safeUd(s.ud))) : s.rotDeg;
            s.rawAlignmentDeg = Double.isNaN(s.alignDeg) ? Math.toDegrees(Math.atan2(-s.lr, safeUd(s.ud))) : s.alignDeg;
            s.rotation = clampAngle(s.rawRotationDeg - baselineRotationDeg);
            s.alignment = clampAngle(s.rawAlignmentDeg - baselineAlignmentDeg);
            s.impulse = Math.max(0, Math.abs(s.mag - baselineMag));
            s.hasGps = !Double.isNaN(s.lat) && !Double.isNaN(s.lon) && Math.abs(s.lat) > 0.0001 && Math.abs(s.lon) > 0.0001;
        }

        static double safeUd(double ud) {
            if (Math.abs(ud) < 0.01) return ud < 0 ? -0.01 : 0.01;
            return ud;
        }

        static double clampAngle(double degrees) {
            while (degrees > 180) degrees -= 360;
            while (degrees < -180) degrees += 360;
            return Math.max(-90, Math.min(90, degrees));
        }

        static boolean hasMotion(String raw) {
            String u = raw == null ? "" : raw.toUpperCase(Locale.US);
            return u.startsWith("A:") || u.contains("\"LR\"") || u.contains("\"FB\"") || u.contains("\"UD\"") || u.contains("\"MAG\"")
                    || u.contains("LR:") || u.contains("FB:") || u.contains("UD:") || u.contains("MAG:")
                    || u.contains("LR=") || u.contains("FB=") || u.contains("UD=") || u.contains("MAG=");
        }

        static boolean saneMotion(Sample s) {
            if ("NO_SENSOR".equalsIgnoreCase(s.body)) return false;
            return Math.abs(s.lr) <= 80 && Math.abs(s.fb) <= 80 && Math.abs(s.ud) <= 80
                    && s.mag >= 2 && s.mag <= 120
                    && Math.abs(s.roll) <= 180 && Math.abs(s.pitch) <= 180;
        }

        static double val(String[] h, String[] v, String... keys) {
            for (int i = 0; i < h.length && i < v.length; i++) {
                String name = cleanName(h[i]);
                for (String k : keys) if (name.equals(cleanName(k))) return parse(v[i]);
            }
            return Double.NaN;
        }

        static String textVal(String[] h, String[] v, String... keys) {
            for (int i = 0; i < h.length && i < v.length; i++) {
                String name = cleanName(h[i]);
                for (String k : keys) if (name.equals(cleanName(k))) return v[i].replace("\"", "").trim();
            }
            return "";
        }

        static boolean hasHeader(String[] h, String... keys) {
            for (String cell : h) {
                String name = cleanName(cell);
                for (String k : keys) if (name.equals(cleanName(k))) return true;
            }
            return false;
        }

        static String cleanName(String raw) {
            if (raw == null) return "";
            return raw.replace("\uFEFF", "").replace("\"", "").trim().toUpperCase(Locale.US);
        }

        static double get(String raw, String... keys) {
            for (String k : keys) {
                double d = getJson(raw, k);
                if (!Double.isNaN(d)) return d;
                d = getKeyValue(raw, k);
                if (!Double.isNaN(d)) return d;
            }
            return Double.NaN;
        }

        static String getText(String raw, String... keys) {
            for (String key : keys) {
                String mark = "\"" + key + "\"";
                int i = raw.indexOf(mark);
                if (i >= 0) {
                    int colon = raw.indexOf(':', i + mark.length());
                    if (colon >= 0) {
                        int start = colon + 1;
                        while (start < raw.length() && (raw.charAt(start) == ' ' || raw.charAt(start) == '"')) start++;
                        int end = start;
                        while (end < raw.length() && raw.charAt(end) != '"' && raw.charAt(end) != ',' && raw.charAt(end) != '}') end++;
                        return raw.substring(start, end).trim();
                    }
                }
            }
            return "";
        }

        static double getJson(String raw, String key) {
            String mark = "\"" + key + "\"";
            int i = raw.indexOf(mark);
            if (i < 0) return Double.NaN;
            int colon = raw.indexOf(':', i + mark.length());
            if (colon < 0) return Double.NaN;
            return parseNumber(raw, colon + 1);
        }

        static double getKeyValue(String raw, String key) {
            int i = raw.indexOf(key + ":");
            if (i < 0) i = raw.indexOf(key + "=");
            if (i < 0) return Double.NaN;
            return parseNumber(raw, i + key.length() + 1);
        }

        static double parseNumber(String raw, int start) {
            int i = start;
            while (i < raw.length() && (raw.charAt(i) == ' ' || raw.charAt(i) == '"')) i++;
            int j = i;
            while (j < raw.length()) {
                char c = raw.charAt(j);
                if ((c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.') j++;
                else break;
            }
            return parse(raw.substring(i, j));
        }

        static double parse(String s) {
            try {
                s = s.replace("\"", "").trim();
                if (s.isEmpty() || s.equalsIgnoreCase("NO_LAT") || s.equalsIgnoreCase("NO_LON")) return Double.NaN;
                if (s.indexOf(',') >= 0 && s.indexOf('.') < 0) s = s.replace(',', '.');
                return Double.parseDouble(s);
            } catch (Exception e) {
                return Double.NaN;
            }
        }
    }

    private static class SessionStats {
        String rotationLabel = "--", rotationValue = "sin datos";
        String alignmentLabel = "--", alignmentValue = "sin datos";
        String impulseLabel = "--", impulseValue = "sin datos";
        String motionLabel = "--", motionValue = "sin datos";
        String advanceLabel = "--", advanceValue = "sin datos";
        String impactLabel = "--", impactValue = "sin datos";
        String rhythmLabel = "--", rhythmValue = "sin datos";
        String durationLabel = "--", distanceLabel = "--", gpsLabel = "sin GPS";
        String efficiencyLabel = "--", efficiencyValue = "sin datos";
        String changeLabel = "--", changeValue = "sin datos";
        String strokeLabel = "--", strokeValue = "sin datos";
        String reachLabel = "--", reachValue = "sin datos";
        String breathLabel = "--", breathValue = "sin datos";
        String constancyLabel = "--";
        String sessionType = "NO_CLASIFICADO";
        String dominantSide = "--";
        String bestWindowLabel = "sin tramo claro";
        String bestWindowWhy = "faltan datos";
        String summary = "Esperando datos.";
        String why = "Conecta BLE o carga un CSV para interpretar.";
        double avgRot, avgAlign, avgImpulse, startSpeed, endSpeed, avgSpeed, maxSpeed, distanceM;
        double latestRot, latestAlign, latestImpulse;
        int impactCount = 0;
        double rightRot, leftRot;
        SideStats rightSide = new SideStats();
        SideStats leftSide = new SideStats();

        static SessionStats from(List<Sample> input, boolean live) {
            SessionStats st = new SessionStats();
            if (input == null || input.size() < 2) return st;

            ArrayList<Sample> samples = new ArrayList<>(input);
            double startT = samples.get(0).t;
            double endT = samples.get(samples.size() - 1).t;
            double duration = Math.max(0, endT - startT);
            List<Sample> recent = live ? window(samples, endT - 30) : samples;
            List<Sample> first = windowEnd(samples, startT + Math.min(30, Math.max(5, duration * .2)));
            List<Sample> last = window(samples, endT - Math.min(30, Math.max(5, duration * .2)));
            Sample latest = samples.get(samples.size() - 1);

            st.avgRot = avgAbs(recent, "rot");
            st.avgAlign = avgAbs(recent, "align");
            st.avgImpulse = avg(recent, "imp");
            st.latestRot = latest.rotation;
            st.latestAlign = latest.alignment;
            st.latestImpulse = latest.impulse;
            st.rightRot = avgPositive(live ? recent : samples);
            st.leftRot = Math.abs(avgNegative(live ? recent : samples));
            st.rightSide = sideStats(live ? recent : samples, true);
            st.leftSide = sideStats(live ? recent : samples, false);
            st.startSpeed = avg(first, "speed");
            st.endSpeed = avg(last, "speed");
            st.avgSpeed = avg(samples, "speed");
            st.maxSpeed = max(samples, "speed");
            st.distanceM = distance(samples);
            st.impactCount = impactCount(samples);
            BestWindow best = bestWindow(samples);
            st.bestWindowLabel = best.label;
            st.bestWindowWhy = best.why;

            double symmetry = Math.abs(st.rightRot - st.leftRot);
            st.rotationLabel = labelRotation(st.avgRot, symmetry);
            st.dominantSide = st.rightRot > st.leftRot + 4 ? "DER" : (st.leftRot > st.rightRot + 4 ? "IZQ" : "parejo");
            st.rotationValue = live
                    ? String.format(Locale.US, "DER %.1f / IZQ %.1f deg", st.rightRot, st.leftRot)
                    : String.format(Locale.US, "DER %.0f / IZQ %.0f deg", st.rightRot, st.leftRot);
            st.alignmentLabel = st.avgAlign < 8 ? "estable" : (st.avgAlign < 16 ? "variable" : "irregular");
            st.alignmentValue = String.format(Locale.US, "%.1f deg", st.avgAlign);
            st.impulseLabel = st.avgImpulse < 0.8 ? "bajo" : (st.avgImpulse < 2.5 ? "normal" : "alto");
            st.impulseValue = String.format(Locale.US, "%.2f", st.avgImpulse);
            st.motionLabel = st.avgImpulse < 0.8 ? "suave" : (st.avgImpulse < 2.5 ? "estable" : "alto");
            st.motionValue = String.format(Locale.US, "MAG %.2f", st.avgImpulse);
            st.impactLabel = labelImpact(st.impactCount, duration);
            st.impactValue = st.impactCount == 0 ? "sin picos" : String.format(Locale.US, "%d picos", st.impactCount);
            ArrayList<Double> peaks = peakTimes(samples);
            st.sessionType = classifySession(duration, st.avgRot, st.avgImpulse, st.rightRot, st.leftRot, symmetry, peaks.size());
            double rhythm = cycleSeconds(peaks);
            st.rhythmLabel = rhythm > 0 && "NADO_PROBABLE".equals(st.sessionType) ? "ciclo aprox" : "sin nado confirmado";
            st.rhythmValue = rhythm > 0 ? String.format(Locale.US, "%.1f s", rhythm) : "pendiente";
            st.strokeLabel = peaks.size() > 0 ? String.valueOf(peaks.size()) : "--";
            st.strokeValue = "NADO_PROBABLE".equals(st.sessionType)
                    ? (rhythm > 0 ? String.format(Locale.US, "%.1f s promedio", rhythm) : "deteccion inicial")
                    : "movimientos, no brazadas";
            st.constancyLabel = labelConstancy(peaks);
            st.durationLabel = fmtTime(duration);
            st.distanceLabel = st.distanceM > 3 ? String.format(Locale.US, "%.0f m", st.distanceM) : "--";
            st.gpsLabel = gpsCount(samples) > 2 ? "GPS valido" : "sin GPS suficiente";
            st.advanceLabel = labelAdvance(samples, st.avgSpeed, st.maxSpeed, st.distanceM);
            st.advanceValue = valueAdvance(samples, st.avgSpeed, st.maxSpeed, st.distanceM);
            st.reachLabel = labelReach(st.avgRot, symmetry, st.avgImpulse, st.avgAlign);
            st.reachValue = valueReach(st.reachLabel);
            st.breathLabel = labelBreath(samples, st.avgAlign);
            st.breathValue = valueBreath(st.breathLabel);

            double speedDelta = st.endSpeed - st.startSpeed;
            double impulseStart = avg(first, "imp");
            double impulseEnd = avg(last, "imp");
            double impulseDelta = impulseEnd - impulseStart;
            double alignStart = avgAbs(first, "align");
            double alignEnd = avgAbs(last, "align");
            double alignDelta = alignEnd - alignStart;

            if (Math.abs(speedDelta) < 0.15) {
                st.changeLabel = "estable";
                st.changeValue = "sin cambio fuerte";
            } else if (speedDelta > 0) {
                st.changeLabel = "subio";
                st.changeValue = String.format(Locale.US, "+%.2f km/h", speedDelta);
            } else {
                st.changeLabel = "bajo";
                st.changeValue = String.format(Locale.US, "%.2f km/h", speedDelta);
            }

            if (speedDelta > 0.15 && Math.abs(impulseDelta) < 0.3 && alignDelta <= 1.5) {
                st.efficiencyLabel = "mejoro";
                st.efficiencyValue = "mas avance sin mas movimiento";
            } else if (speedDelta > 0.15 && impulseDelta > 0.3) {
                st.efficiencyLabel = "por energia";
                st.efficiencyValue = "subio movimiento";
            } else if (speedDelta < -0.15 && impulseDelta > 0.3) {
                st.efficiencyLabel = "perdio";
                st.efficiencyValue = "mas movimiento, menos avance";
            } else {
                st.efficiencyLabel = "observando";
                st.efficiencyValue = "faltan tramos";
            }

            st.summary = buildSummary(st, speedDelta, impulseDelta, alignDelta, live);
            st.why = buildWhy(st, speedDelta, impulseDelta, alignDelta);
            return st;
        }

        static String labelRotation(double rot, double symmetry) {
            if (symmetry > 12) return "asimetria";
            if (rot < 20) return "baja";
            if (rot < 35) return "moderada";
            if (rot <= 55) return "funcional";
            if (rot <= 65) return "alta contextual";
            return "muy alta";
        }

        static String classifySession(double duration, double avgRot, double avgImpulse,
                                      double rightRot, double leftRot, double symmetry, int peaks) {
            boolean enoughTime = duration >= 12;
            boolean alternating = rightRot >= 12 && leftRot >= 12 && symmetry <= 28;
            boolean usefulEnergy = avgImpulse >= 0.25;
            if (!enoughTime || (avgRot < 6 && avgImpulse < 0.25)) return "SIN_NADO";
            if (alternating && usefulEnergy && peaks >= 4) return "NADO_PROBABLE";
            if ((rightRot >= 12 || leftRot >= 12) && peaks >= 2) return "PRUEBA_TECNICA";
            return "NO_CLASIFICADO";
        }

        static String buildSummary(SessionStats st, double speedDelta, double impulseDelta, double alignDelta, boolean live) {
            StringBuilder sb = new StringBuilder();
            sb.append(live ? "Ahora\n" : "Resumen\n");
            sb.append("Rotacion: ");
            if ("asimetria".equals(st.rotationLabel)) sb.append(st.dominantSide).append(" giro mas que el otro lado.");
            else if ("baja".equals(st.rotationLabel)) sb.append("giraste poco el cuerpo.");
            else if ("moderada".equals(st.rotationLabel)) sb.append("giro moderado, comparar con tu base.");
            else if ("funcional".equals(st.rotationLabel)) sb.append("giro funcional para analizar tecnica.");
            else if ("alta contextual".equals(st.rotationLabel)) sb.append("giro alto; puede ser normal con respiracion si la linea es estable.");
            else if ("muy alta".equals(st.rotationLabel)) sb.append("giro muy alto, revisar linea y colocacion.");
            else sb.append("faltan datos.");

            sb.append("\nAlineacion: ");
            if ("estable".equals(st.alignmentLabel)) sb.append("cuerpo estable.");
            else if ("variable".equals(st.alignmentLabel)) sb.append("cambio por momentos.");
            else if ("irregular".equals(st.alignmentLabel)) sb.append("se movio mucho.");
            else sb.append("faltan datos.");

            sb.append("\nMovimiento: ");
            if ("suave".equals(st.motionLabel)) sb.append("suave, poca energia relativa.");
            else if ("estable".equals(st.motionLabel)) sb.append("parejo, energia controlada.");
            else if ("alto".equals(st.motionLabel)) sb.append("alto, revisar picos o golpes.");
            else sb.append("faltan datos.");

            sb.append("\nPicos/contexto: ").append(st.impactLabel).append(".");

            sb.append("\nSesion: ").append(st.sessionType).append(".");
            sb.append("\n").append("NADO_PROBABLE".equals(st.sessionType) ? "Brazadas" : "Movimientos").append(": ").append(st.strokeLabel).append(" detectados");
            if (!"--".equals(st.constancyLabel)) sb.append(", constancia ").append(st.constancyLabel);
            sb.append(".");

            sb.append("\nPreparacion: ").append(st.reachLabel).append(".");
            sb.append("\nRespiracion: ").append(st.breathLabel).append(".");

            sb.append("\nAvance: ");
            sb.append(st.advanceLabel).append(" | ").append(st.advanceValue).append(".");

            sb.append("\nTu mejor tramo: ").append(st.bestWindowLabel).append(" por ").append(st.bestWindowWhy).append(".");
            return sb.toString();
        }

        static String buildWhy(SessionStats st, double speedDelta, double impulseDelta, double alignDelta) {
            StringBuilder sb = new StringBuilder();
            sb.append("La app miro el inicio, el final y tramos de 30 segundos. ");
            if ("asimetria".equals(st.rotationLabel)) sb.append(st.dominantSide).append(" marco mas giro que el otro lado. ");
            else if ("baja".equals(st.rotationLabel)) sb.append("El giro promedio quedo bajo. ");
            else if ("moderada".equals(st.rotationLabel)) sb.append("El giro promedio fue moderado. ");
            else if ("funcional".equals(st.rotationLabel)) sb.append("El giro promedio entro en una zona funcional inicial. ");
            else if ("alta contextual".equals(st.rotationLabel)) sb.append("El giro promedio fue alto, compatible con respiracion o atletas entrenados si la alineacion acompana. ");
            else if ("muy alta".equals(st.rotationLabel)) sb.append("El giro promedio fue muy alto y requiere revisar contexto. ");
            if ("suave".equals(st.motionLabel)) sb.append("MAG tuvo poca diferencia contra la base; puede ser nado tranquilo o mesa con poco movimiento. ");
            if (speedDelta > 0.15 && Math.abs(impulseDelta) < 0.3) sb.append("La velocidad subio sin mucho mas movimiento: puede ser mejor posicion del cuerpo. ");
            else if (speedDelta > 0.15) sb.append("La velocidad subio, pero tambien subio la energia MAG: parece mas intensidad o contexto externo. ");
            else if (speedDelta < -0.15 && impulseDelta > 0.3) sb.append("Hubo mas movimiento pero menos avance: puede haber perdida de tecnica, golpe o cambio de entorno. ");
            else sb.append("La velocidad no cambio mucho o no hay GPS suficiente. ");
            if (st.impactCount > 0) sb.append("Los picos sirven para ubicar golpes, oleaje, frenadas o contacto del dispositivo; son contexto tecnico y de seguridad, no avance. ");
            if (alignDelta > 2) sb.append("La alineacion cambio mas al final.");
            else sb.append("La alineacion se mantuvo parecida.");
            sb.append(" El mejor tramo es una referencia para comparar, no una nota final.");
            return sb.toString();
        }

        static BestWindow bestWindow(List<Sample> samples) {
            BestWindow out = new BestWindow();
            if (samples == null || samples.size() < 5) return out;
            double firstT = samples.get(0).t;
            double lastT = samples.get(samples.size() - 1).t;
            double duration = Math.max(0, lastT - firstT);
            double size = duration < 30 ? Math.max(5, duration) : 30;
            if (size <= 0) return out;

            double bestScore = -999;
            double bestStart = firstT;
            double bestRot = 0;
            double bestAlign = 0;
            double bestImp = 0;
            double bestSpeed = 0;
            boolean bestHasGps = false;

            for (double start = firstT; start <= lastT - Math.max(1, size * .5); start += Math.max(5, size / 3)) {
                List<Sample> part = between(samples, start, start + size);
                if (part.size() < 4) continue;
                double rot = avgAbs(part, "rot");
                double align = avgAbs(part, "align");
                double imp = avg(part, "imp");
                double speed = avg(part, "speed");
                boolean hasGps = gpsCount(part) > 2;

                double rotScore = rotationScore(rot);
                double alignScore = 100 - align * 4.0;
                double impScore = imp < 0.3 ? 35 : 100 - Math.abs(1.6 - Math.min(5, imp)) * 16.0;
                double speedScore = hasGps ? Math.min(100, speed * 35.0) : 55;
                double score = rotScore * .30 + alignScore * .30 + impScore * .25 + speedScore * .15;

                if (score > bestScore) {
                    bestScore = score;
                    bestStart = start;
                    bestRot = rot;
                    bestAlign = align;
                    bestImp = imp;
                    bestSpeed = speed;
                    bestHasGps = hasGps;
                }
            }

            out.label = fmtTime(bestStart - firstT) + " a " + fmtTime(Math.min(duration, bestStart - firstT + size));
            if (bestHasGps && bestSpeed > 0.2) out.why = "mejor mezcla de avance, cuerpo y movimiento";
            else if (bestAlign < 8 && bestRot >= 20 && bestRot <= 55) out.why = "giro funcional y cuerpo estable";
            else if (bestImp >= 0.8 && bestImp <= 2.5) out.why = "movimiento mas parejo";
            else out.why = "tramo mas ordenado de la sesion";
            return out;
        }

        static List<Sample> between(List<Sample> samples, double minT, double maxT) {
            ArrayList<Sample> out = new ArrayList<>();
            for (Sample s : samples) if (s.t >= minT && s.t <= maxT) out.add(s);
            return out;
        }

        static class BestWindow {
            String label = "sin tramo claro";
            String why = "faltan datos";
        }

        static List<Sample> window(List<Sample> samples, double minT) {
            ArrayList<Sample> out = new ArrayList<>();
            for (Sample s : samples) if (s.t >= minT) out.add(s);
            return out.isEmpty() ? samples : out;
        }

        static List<Sample> windowEnd(List<Sample> samples, double maxT) {
            ArrayList<Sample> out = new ArrayList<>();
            for (Sample s : samples) if (s.t <= maxT) out.add(s);
            return out.isEmpty() ? samples : out;
        }

        static double avg(List<Sample> s, String f) {
            double sum = 0; int n = 0;
            for (Sample x : s) {
                double v = "imp".equals(f) ? x.impulse : ("speed".equals(f) ? x.speedKmh : 0);
                if (!Double.isNaN(v)) { sum += v; n++; }
            }
            return n == 0 ? 0 : sum / n;
        }

        static double max(List<Sample> s, String f) {
            double out = 0;
            for (Sample x : s) {
                double v = "speed".equals(f) ? x.speedKmh : x.impulse;
                if (!Double.isNaN(v)) out = Math.max(out, v);
            }
            return out;
        }

        static int impactCount(List<Sample> samples) {
            if (samples == null || samples.size() < 3) return 0;
            int count = 0;
            double lastImpactT = -999;
            for (int i = 1; i < samples.size(); i++) {
                Sample prev = samples.get(i - 1);
                Sample cur = samples.get(i);
                double dt = Math.max(0.05, cur.t - prev.t);
                double magJump = Math.abs(cur.mag - prev.mag);
                double rotJump = Math.abs(cur.rotation - prev.rotation);
                double alignJump = Math.abs(cur.alignment - prev.alignment);
                boolean abrupt = cur.impulse > 8.0 || magJump > 7.0 || (rotJump > 38 && alignJump > 18 && dt < 1.2);
                if (abrupt && cur.t - lastImpactT > 1.5) {
                    count++;
                    lastImpactT = cur.t;
                }
            }
            return count;
        }

        static String labelImpact(int count, double duration) {
            if (count <= 0) return "sin picos";
            double perMin = duration <= 0 ? count : count / Math.max(1.0, duration / 60.0);
            if (perMin < 1.5) return "pocos";
            if (perMin < 4.0) return "revisar";
            return "muchos";
        }

        static String labelAdvance(List<Sample> samples, double avgSpeed, double maxSpeed, double distanceM) {
            int gps = gpsCount(samples);
            if (gps <= 2) {
                if (maxSpeed < 0.25 && distanceM < 3) return "0 mesa/sin GPS";
                return "sin GPS fiable";
            }
            if (maxSpeed < 0.25 && distanceM < 3) return "sin desplazamiento";
            if (avgSpeed < 0.8) return "casi detenido";
            if (avgSpeed < 1.8) return "lento/oleaje";
            if (avgSpeed < 3.2) return "ritmo base";
            if (avgSpeed < 5.0) return "ritmo fuerte";
            return "vehiculo/no nado";
        }

        static String valueAdvance(List<Sample> samples, double avgSpeed, double maxSpeed, double distanceM) {
            int gps = gpsCount(samples);
            if (gps <= 2 && maxSpeed < 0.25) return "0.0 km/h";
            String base = baselineHint(avgSpeed);
            return String.format(Locale.US, "prom %.1f | max %.1f km/h | %s", avgSpeed, maxSpeed, base);
        }

        static String baselineHint(double avgSpeed) {
            if (avgSpeed < 0.8) return "bajo base";
            if (avgSpeed < 1.8) return "comparar oleaje";
            if (avgSpeed < 3.2) return "base inicial";
            if (avgSpeed < 5.0) return "sobre base";
            return "descartar nado";
        }

        static double avgAbs(List<Sample> s, String f) {
            double sum = 0; int n = 0;
            for (Sample x : s) {
                double v = "rot".equals(f) ? x.rotation : x.alignment;
                sum += Math.abs(v); n++;
            }
            return n == 0 ? 0 : sum / n;
        }

        static double avgPositive(List<Sample> s) {
            double sum = 0; int n = 0;
            for (Sample x : s) if (x.rotation > 0) { sum += x.rotation; n++; }
            return n == 0 ? 0 : sum / n;
        }

        static double avgNegative(List<Sample> s) {
            double sum = 0; int n = 0;
            for (Sample x : s) if (x.rotation < 0) { sum += x.rotation; n++; }
            return n == 0 ? 0 : sum / n;
        }

        static SideStats sideStats(List<Sample> samples, boolean right) {
            SideStats out = new SideStats();
            if (samples == null || samples.size() < 2) return out;
            double sum = 0; int n = 0;
            double currentStreak = 0;
            for (int i = 1; i < samples.size(); i++) {
                Sample prev = samples.get(i - 1);
                Sample cur = samples.get(i);
                double rot = cur.rotation;
                boolean isSide = right ? rot > 0 : rot < 0;
                double dt = Math.max(0, Math.min(1.5, cur.t - prev.t));
                if (!isSide) {
                    currentStreak = 0;
                    continue;
                }
                double abs = Math.abs(rot);
                if (abs > 90) {
                    currentStreak = 0;
                    continue;
                }
                sum += abs;
                n++;
                out.maxObservedDeg = Math.max(out.maxObservedDeg, abs);
                boolean functional = abs >= 35 && abs <= 55;
                boolean competitive = abs > 55 && abs <= 65;
                boolean useful = functional || competitive;
                if (useful) {
                    out.zoneSec += dt;
                    out.maxUsefulDeg = Math.max(out.maxUsefulDeg, abs);
                    currentStreak += dt;
                    out.maxStreakSec = Math.max(out.maxStreakSec, currentStreak);
                } else {
                    currentStreak = 0;
                }
                if (functional) {
                    out.functionalSec += dt;
                    out.maxFunctionalDeg = Math.max(out.maxFunctionalDeg, abs);
                }
                if (competitive) {
                    out.competitiveSec += dt;
                    out.maxCompetitiveDeg = Math.max(out.maxCompetitiveDeg, abs);
                }
            }
            out.generalAvgDeg = n == 0 ? 0 : sum / n;
            return out;
        }

        static class SideStats {
            double generalAvgDeg = 0;
            double maxObservedDeg = 0;
            double maxUsefulDeg = 0;
            double maxFunctionalDeg = 0;
            double maxCompetitiveDeg = 0;
            double zoneSec = 0;
            double functionalSec = 0;
            double competitiveSec = 0;
            double maxStreakSec = 0;
        }

        static ArrayList<Double> peakTimes(List<Sample> s) {
            ArrayList<Double> peaks = new ArrayList<>();
            double right = avgPositive(s);
            double left = Math.abs(avgNegative(s));
            double threshold = Math.max(8, Math.min(55, ((right + left) / 2.0) * 0.60));
            for (int i = 1; i < s.size() - 1; i++) {
                double a = Math.abs(s.get(i - 1).rotation);
                double b = Math.abs(s.get(i).rotation);
                double c = Math.abs(s.get(i + 1).rotation);
                if (b >= threshold && b > a && b >= c && s.get(i).impulse > 0.25) {
                    if (peaks.isEmpty() || s.get(i).t - peaks.get(peaks.size() - 1) > 0.8) peaks.add(s.get(i).t);
                }
            }
            return peaks;
        }

        static double rotationScore(double rot) {
            if (rot < 20) return 45 + rot;
            if (rot <= 55) return 95 - Math.abs(42 - rot) * 0.6;
            if (rot <= 65) return 82 - (rot - 55) * 1.2;
            return 62 - Math.min(25, (rot - 65) * 2.0);
        }

        static double cycleSeconds(List<Double> peaks) {
            if (peaks.size() < 3) return -1;
            double sum = 0; int n = 0;
            for (int i = 1; i < peaks.size(); i++) {
                double d = peaks.get(i) - peaks.get(i - 1);
                if (d > 0.4 && d < 6) { sum += d; n++; }
            }
            return n == 0 ? -1 : sum / n;
        }

        static String labelConstancy(List<Double> peaks) {
            if (peaks == null || peaks.size() < 5) return "--";
            ArrayList<Double> diffs = new ArrayList<>();
            for (int i = 1; i < peaks.size(); i++) {
                double d = peaks.get(i) - peaks.get(i - 1);
                if (d > 0.4 && d < 6) diffs.add(d);
            }
            if (diffs.size() < 4) return "--";
            double avg = 0;
            for (double d : diffs) avg += d;
            avg /= diffs.size();
            double var = 0;
            for (double d : diffs) var += Math.abs(d - avg);
            double dev = var / diffs.size();
            if (dev < 0.18) return "buena";
            if (dev < 0.38) return "media";
            return "irregular";
        }

        static String labelReach(double rot, double symmetry, double impulse, double align) {
            if (rot < 18) return "alcance corto probable";
            if (symmetry > 12) return "un lado prepara mejor";
            if (rot >= 20 && rot <= 55 && align < 12 && impulse >= 0.6 && impulse <= 3.2) return "buena preparacion";
            if (rot > 55 && rot <= 65) return "alta por contexto";
            if (rot > 65) return "revisar exceso";
            if (impulse > 3.2) return "rapida por fuerza";
            return "en observacion";
        }

        static String valueReach(String label) {
            if ("buena preparacion".equals(label)) return "torso acompana";
            if ("alcance corto probable".equals(label)) return "poca rotacion";
            if ("un lado prepara mejor".equals(label)) return "asimetria DER/IZQ";
            if ("alta por contexto".equals(label)) return "mirar respiracion";
            if ("revisar exceso".equals(label)) return "giro muy alto";
            if ("rapida por fuerza".equals(label)) return "movimiento alto";
            return "faltan sesiones";
        }

        static String labelBreath(List<Sample> samples, double avgAlign) {
            if (samples == null || samples.size() < 20) return "no detectable";
            int spikes = 0;
            for (Sample s : samples) {
                if (Math.abs(s.alignment) > Math.max(14, avgAlign * 1.8) && s.impulse > 0.8) spikes++;
            }
            double ratio = spikes / (double) samples.size();
            if (ratio > 0.10) return "posible cabeza alta";
            if (ratio > 0.04) return "puede romper linea";
            return "sin senal fuerte";
        }

        static String valueBreath(String label) {
            if ("posible cabeza alta".equals(label)) return "revisar respiracion";
            if ("puede romper linea".equals(label)) return "mirar tramos";
            if ("sin senal fuerte".equals(label)) return "linea estable";
            return "faltan datos";
        }

        static int gpsCount(List<Sample> s) {
            int n = 0;
            for (Sample x : s) if (x.hasGps) n++;
            return n;
        }

        static double distance(List<Sample> s) {
            double total = 0;
            Sample prev = null;
            for (Sample x : s) {
                if (!x.hasGps) continue;
                if (prev != null) total += hav(prev.lat, prev.lon, x.lat, x.lon);
                prev = x;
            }
            return total;
        }

        static double hav(double lat1, double lon1, double lat2, double lon2) {
            double r = 6371000;
            double dLat = Math.toRadians(lat2 - lat1);
            double dLon = Math.toRadians(lon2 - lon1);
            double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                    + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                    * Math.sin(dLon / 2) * Math.sin(dLon / 2);
            return 2 * r * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        }

        static String fmtTime(double sec) {
            int s = (int) Math.max(0, sec);
            return String.format(Locale.US, "%02d:%02d", s / 60, s % 60);
        }
    }

    public static class MultiLineView extends View {
        Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        List<Sample> all;
        float windowSeconds;
        double fixedStart = Double.NaN;
        boolean showSpeed = false;

        public MultiLineView(android.content.Context c, List<Sample> samples, float windowSeconds) {
            super(c);
            setBackgroundColor(Color.rgb(7, 29, 37));
            all = samples == null ? Collections.emptyList() : new ArrayList<>(samples);
            this.windowSeconds = windowSeconds;
        }

        public MultiLineView(android.content.Context c, List<Sample> samples, float windowSeconds, double fixedStart) {
            this(c, samples, windowSeconds);
            this.fixedStart = fixedStart;
        }

        public MultiLineView(android.content.Context c, List<Sample> samples, float windowSeconds, double fixedStart, boolean showSpeed) {
            this(c, samples, windowSeconds, fixedStart);
            this.showSpeed = showSpeed;
        }

        @Override
        protected void onDraw(Canvas c) {
            super.onDraw(c);
            int w = getWidth(), h = getHeight();
            float left = 62f;
            float right = w - 18f;
            float rotTop = 52f;
            float rotBottom = h * 0.38f;
            float alignTop = h * 0.48f;
            float alignBottom = h * 0.68f;
            float magTop = h * 0.78f;
            float magBottom = h - 48f;
            float rotZero = (rotTop + rotBottom) / 2f;
            float alignZero = (alignTop + alignBottom) / 2f;
            float magZero = magBottom - 6f;

            p.setStyle(Paint.Style.FILL);
            p.setColor(Color.rgb(7, 29, 37));
            c.drawRect(0, 0, w, h, p);

            drawPanelGrid(c, left, right, rotTop, rotBottom, rotZero, true);
            drawPanelGrid(c, left, right, alignTop, alignBottom, alignZero, false);
            drawPanelGrid(c, left, right, magTop, magBottom, magZero, false);

            if (all.size() < 2) {
                p.setColor(MUTED); p.setTextSize(18);
                c.drawText("esperando muestras", 42, h / 2f, p);
                return;
            }
            double maxT = all.get(all.size() - 1).t;
            ArrayList<Sample> s = new ArrayList<>();
            if (!Double.isNaN(fixedStart) && windowSeconds > 0) {
                double start = all.get(0).t + fixedStart;
                double end = start + windowSeconds;
                for (Sample x : all) if (x.t >= start && x.t <= end) s.add(x);
            } else {
                for (Sample x : all) if (windowSeconds <= 0 || x.t >= maxT - windowSeconds) s.add(x);
            }
            if (s.size() < 2) s.addAll(all);
            double minT = s.get(0).t;
            double span = Math.max(1, s.get(s.size() - 1).t - minT);

            double rotScale = showSpeed ? 65.0 : 90.0;
            drawDegreeGuides(c, left, right, rotZero, (rotBottom - rotTop) * 0.42f, rotScale);
            drawLine(c, s, minT, span, "rot", CYAN, left, right, rotZero, (rotBottom - rotTop) * 0.42f, rotScale, true);
            drawLine(c, s, minT, span, "align", Color.rgb(130, 170, 255), left, right, alignZero, (alignBottom - alignTop) * 0.42f, 30.0, true);

            double bottomScale = showSpeed ? robustSpeedScale(s) : robustImpulseScale(s);
            drawLine(c, s, minT, span, showSpeed ? "speed" : "imp", GREEN, left, right, magZero, (magBottom - magTop) * 0.80f, bottomScale, false);

            p.setStyle(Paint.Style.FILL);
            p.setTextSize(17);
            p.setColor(CYAN); c.drawText("ROTACION ESTIMADA FB/UD", left, rotTop - 12, p);
            p.setColor(Color.rgb(130, 170, 255)); c.drawText("ALINEACION ESTIMADA -LR/UD", left, alignTop - 12, p);
            p.setColor(GREEN); c.drawText(showSpeed ? "VELOCIDAD GPS | km/h" : "MOVIMIENTO MAG | picos", left, magTop - 12, p);
            p.setColor(MUTED);
            p.setTextSize(18);
            c.drawText(showSpeed ? "+65" : "+90", 10, rotZero - (rotBottom - rotTop) * 0.36f, p);
            c.drawText(showSpeed ? "-65" : "-90", 10, rotZero + (rotBottom - rotTop) * 0.43f, p);
            c.drawText("+30", 10, alignZero - (alignBottom - alignTop) * 0.36f, p);
            c.drawText("-30", 10, alignZero + (alignBottom - alignTop) * 0.43f, p);
            c.drawText(String.format(Locale.US, "+%.1f", bottomScale), 8, magTop + 18f, p);
            c.drawText("0", 18, magBottom - 8f, p);
            String label = windowSeconds > 0 ? String.format(Locale.US, "%.0f-%.0f s", minT, minT + span) : "sesion completa";
            c.drawText(label, right - 92, h - 16, p);
        }

        private void drawPanelGrid(Canvas c, float left, float right, float top, float bottom, float zero, boolean withTicks) {
            p.setPathEffect(null);
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(2);
            p.setColor(LINE);
            c.drawLine(left, zero, right, zero, p);
            for (int i = 0; i <= 4; i++) {
                float x = left + (right - left) * i / 4f;
                c.drawLine(x, top, x, bottom, p);
                if (withTicks) {
                    p.setStyle(Paint.Style.FILL);
                    p.setTextSize(15);
                    p.setColor(MUTED);
                    c.drawText(String.format(Locale.US, "%ds", i * 5), x - 8, bottom + 22, p);
                    p.setStyle(Paint.Style.STROKE);
                    p.setColor(LINE);
                }
            }
        }

        private void drawDegreeGuides(Canvas c, float left, float right, float zero, float height, double scale) {
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(2);
            p.setPathEffect(new DashPathEffect(new float[]{10, 8}, 0));
            p.setColor(Color.argb(150, 69, 224, 137));
            drawDegreeLine(c, left, right, zero, height, 35, scale);
            drawDegreeLine(c, left, right, zero, height, -35, scale);
            drawDegreeLine(c, left, right, zero, height, 55, scale);
            drawDegreeLine(c, left, right, zero, height, -55, scale);
            p.setColor(Color.argb(145, 255, 106, 24));
            drawDegreeLine(c, left, right, zero, height, 65, scale);
            drawDegreeLine(c, left, right, zero, height, -65, scale);
            p.setPathEffect(null);
            p.setStyle(Paint.Style.FILL);
            p.setTextSize(16);
            p.setColor(Color.rgb(69, 224, 137));
            c.drawText("funcional 35-55", left + 6, zero - height * 0.56f, p);
            p.setColor(ORANGE);
            c.drawText("alto 55-65", right - 94, zero - height * 0.72f, p);
        }

        private void drawDegreeLine(Canvas c, float left, float right, float zero, float height, double degree, double scale) {
            float y = (float) (zero - clamp(degree / scale, -1, 1) * height);
            c.drawLine(left, y, right, y, p);
        }

        private void drawLine(Canvas c, List<Sample> s, double minT, double span, String f, int color,
                              float left, float right, float zero, float height, double scale, boolean signed) {
            Path path = new Path();
            for (int i = 0; i < s.size(); i++) {
                Sample x = s.get(i);
                float px = (float) (left + (right - left) * ((x.t - minT) / span));
                double raw = "rot".equals(f) ? x.rotation : ("align".equals(f) ? x.alignment : ("speed".equals(f) ? x.speedKmh : x.impulse));
                double v = signed ? clamp(raw / scale, -1, 1) : clamp(raw / scale, 0, 1);
                float py = (float) (zero - v * height);
                if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
            }
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(4);
            p.setColor(color);
            c.drawPath(path, p);
            p.setStyle(Paint.Style.FILL);
        }

        private double robustImpulseScale(List<Sample> s) {
            ArrayList<Double> values = new ArrayList<>();
            for (Sample x : s) values.add(Math.max(0, x.impulse));
            Collections.sort(values);
            if (values.isEmpty()) return 1.0;
            int idx = Math.min(values.size() - 1, Math.max(0, (int) Math.round(values.size() * 0.90) - 1));
            return Math.max(0.6, values.get(idx));
        }

        private double robustSpeedScale(List<Sample> s) {
            ArrayList<Double> values = new ArrayList<>();
            for (Sample x : s) values.add(Math.max(0, x.speedKmh));
            Collections.sort(values);
            if (values.isEmpty()) return 5.0;
            int idx = Math.min(values.size() - 1, Math.max(0, (int) Math.round(values.size() * 0.90) - 1));
            double p90 = values.get(idx);
            if (p90 <= 5.0) return 5.0;
            if (p90 <= 12.0) return 12.0;
            return Math.ceil(p90 / 10.0) * 10.0;
        }

        private double clamp(double value, double min, double max) {
            return Math.max(min, Math.min(max, value));
        }
    }

    public static class XAngleView extends View {
        Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        SessionStats stats;
        boolean live;

        public XAngleView(android.content.Context c, SessionStats stats, boolean live) {
            super(c);
            setBackgroundColor(Color.rgb(7, 29, 37));
            this.stats = stats == null ? new SessionStats() : stats;
            this.live = live;
        }

        @Override
        protected void onDraw(Canvas c) {
            super.onDraw(c);
            int w = getWidth(), h = getHeight();

            p.setStyle(Paint.Style.FILL);
            p.setColor(Color.rgb(7, 29, 37));
            c.drawRect(0, 0, w, h, p);

            boolean stacked = w < 900;
            float gap = 16f;
            float top = 18f;
            float footerTop = h - 104f;
            if (stacked) {
                float cardH = (footerTop - top - gap) / 2f;
                drawSide(c, "IZQ", stats.leftRot, stats.leftSide, false, 14f, top, w - 14f, top + cardH, ORANGE, true);
                drawSide(c, "DER", stats.rightRot, stats.rightSide, true, 14f, top + cardH + gap, w - 14f, footerTop, CYAN, true);
            } else {
                float mid = w / 2f;
                drawSide(c, "IZQ", stats.leftRot, stats.leftSide, false, 14f, top, mid - gap / 2f, footerTop, ORANGE, false);
                drawSide(c, "DER", stats.rightRot, stats.rightSide, true, mid + gap / 2f, top, w - 14f, footerTop, CYAN, false);
                p.setStyle(Paint.Style.STROKE);
                p.setStrokeWidth(2);
                p.setColor(LINE);
                c.drawLine(mid, top + 4, mid, footerTop - 4, p);
            }
            p.setStyle(Paint.Style.FILL);
            p.setTextAlign(Paint.Align.LEFT);
            p.setTextSize(stacked ? 17 : 18);
            p.setColor(MUTED);
            c.drawText("prom util: promedio de picos. util 35-65. competitivo 55-65.", 18, h - 68, p);
            p.setTextSize(stacked ? 17 : 16);
            c.drawText(live ? "ventana viva: ultimos 30 s" : "sesion completa: comparar con base", 18, h - 42, p);
            p.setTextSize(stacked ? 22 : 24);
            p.setFakeBoldText(true);
            p.setColor(TEXT);
            c.drawText(stats.rotationLabel + " | " + stats.rotationValue, 18, h - 12, p);
            p.setFakeBoldText(false);
            p.setStyle(Paint.Style.FILL);
            p.setTextAlign(Paint.Align.LEFT);
        }

        private void drawSide(Canvas c, String label, double peakAvg, SessionStats.SideStats side,
                              boolean right, float left, float top, float rightX, float bottom, int color, boolean stacked) {
            float width = rightX - left;
            float height = bottom - top;
            float cx = left + width * (stacked ? .38f : .50f);
            float lineY = top + height * (stacked ? .50f : .46f);
            float arm = Math.min(width * (stacked ? .24f : .34f), height * .27f);
            float body = Math.min(width * .23f, height * .18f);
            double displayDeg = live ? Math.abs(stats.latestRot) : peakAvg;
            double d = Math.max(0, Math.min(75, displayDeg));
            double rad = Math.toRadians(d);
            float dir = right ? 1f : -1f;
            float activeX = (float) (cx + dir * Math.cos(rad) * arm);
            float activeY = (float) (lineY - Math.sin(rad) * arm);
            float passiveX = cx - dir * body;
            float passiveY = lineY + 10f;
            float handX = activeX + dir * 18f;
            float handY = activeY - 8f;

            p.setStyle(Paint.Style.FILL);
            p.setColor(Color.rgb(6, 24, 32));
            c.drawRoundRect(left, top, rightX, bottom, 10f, 10f, p);

            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(2);
            p.setColor(LINE);
            c.drawLine(left + 20, lineY, rightX - 20, lineY, p);
            c.drawLine(cx, top + 22, cx, bottom - 38, p);
            p.setPathEffect(new DashPathEffect(new float[]{9, 8}, 0));
            p.setColor(Color.argb(145, 69, 224, 137));
            drawGuide(c, left + 18, rightX - 18, lineY, arm * .70f, 35);
            drawGuide(c, left + 18, rightX - 18, lineY, arm * .70f, 55);
            p.setColor(Color.argb(150, 255, 106, 24));
            drawGuide(c, left + 18, rightX - 18, lineY, arm * .70f, 65);
            p.setPathEffect(null);

            p.setStrokeWidth(stacked ? 8 : 7);
            p.setColor(Color.argb(145, 207, 229, 235));
            c.drawLine(passiveX, passiveY, cx, lineY, p);
            p.setStrokeWidth(stacked ? 11 : 9);
            p.setColor(color);
            c.drawLine(cx, lineY, activeX, activeY, p);
            p.setStrokeWidth(stacked ? 7 : 6);
            c.drawLine(activeX, activeY, handX, handY, p);

            p.setStyle(Paint.Style.FILL);
            p.setColor(TEXT);
            c.drawCircle(cx, lineY - 3, stacked ? 20f : 17f, p);
            p.setStrokeWidth(3);
            p.setColor(Color.rgb(6, 24, 32));
            c.drawLine(cx - (stacked ? 19 : 16), lineY, cx + (stacked ? 19 : 16), lineY, p);
            p.setColor(color);
            c.drawCircle(activeX, activeY, stacked ? 10f : 8f, p);

            p.setTextAlign(Paint.Align.LEFT);
            p.setFakeBoldText(true);
            p.setTextSize(stacked ? 30 : 22);
            p.setColor(color);
            c.drawText(String.format(Locale.US, "%s %.1f deg", label, peakAvg), left + 16, top + (stacked ? 38 : 30), p);
            p.setFakeBoldText(false);
            p.setTextSize(stacked ? 18 : 15);
            p.setColor(zoneColor(peakAvg));
            c.drawText("prom util | " + zoneLabel(peakAvg), left + 16, top + (stacked ? 64 : 52), p);

            float infoX = stacked ? left + width * .62f : left + 16;
            float infoY = stacked ? top + 48f : bottom - 70f;
            p.setTextSize(stacked ? 17 : 15);
            p.setColor(TEXT);
            c.drawText(String.format(Locale.US, "max util %.0f | obs %.0f | prom %.0f",
                    side.maxUsefulDeg, side.maxObservedDeg, side.generalAvgDeg), infoX, infoY, p);
            p.setColor(GREEN);
            c.drawText(String.format(Locale.US, "35-65: %.1fs | racha %.1fs",
                    side.zoneSec, side.maxStreakSec), infoX, infoY + (stacked ? 28 : 24), p);
            p.setColor(ORANGE);
            c.drawText(String.format(Locale.US, "55-65: %.1fs | max %.0f",
                    side.competitiveSec, side.maxCompetitiveDeg), infoX, infoY + (stacked ? 56 : 48), p);
            p.setTextAlign(Paint.Align.LEFT);
        }

        private void drawGuide(Canvas c, float left, float right, float zero, float height, double degree) {
            float y = (float) (zero - Math.sin(Math.toRadians(degree)) * height);
            c.drawLine(left, y, right, y, p);
        }

        private String zoneLabel(double deg) {
            if (deg < 20) return "baja";
            if (deg < 35) return "moderada";
            if (deg <= 55) return "funcional";
            if (deg <= 65) return "alta contextual";
            return "muy alta";
        }

        private int zoneColor(double deg) {
            if (deg < 35) return MUTED;
            if (deg <= 55) return GREEN;
            if (deg <= 65) return ORANGE;
            return RED;
        }
    }
}
