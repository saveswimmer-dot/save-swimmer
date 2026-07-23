package com.saveswimmer.coachlive;

import android.app.Activity;
import android.content.SharedPreferences;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.DashPathEffect;
import android.graphics.Paint;
import android.graphics.Path;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

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

    private static final String PREFS = "coach_live_prefs";
    private static final String PREF_URL = "backend_url";
    private static final String DEFAULT_BACKEND = "https://palace-oxidizing-dust.ngrok-free.dev";
    private static final int POLL_MS = 5000;
    private static final int HTTP_TIMEOUT_MS = 5000;
    private static final String APP_VERSION = "V0.1.18 NUEVA";
    private static final int LIMIT = 600;

    private final Handler ui = new Handler(Looper.getMainLooper());
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final List<Sample> telemetry = new ArrayList<>();

    private SharedPreferences prefs;
    private EditText backendInput;
    private TextView backendStatusView;
    private TextView connectionView;
    private TextView athleteView;
    private TextView signalView;
    private TextView distanceView;
    private TextView speedView;
    private TextView motionView;
    private TextView riskView;
    private TextView coachReadView;
    private TextView bodyView;
    private TextView gpsView;
    private TextView rowsView;
    private TextView groupSummaryView;
    private TextView selectedAthleteView;
    private TextView rosterView;
    private TextView accessPolicyView;
    private WebView mapWebView;
    private StrokeWindowView strokeWindowView;
    private TrackView trackView;
    private TrendView trendView;
    private boolean polling = false;
    private boolean busy = false;
    private String selectedSerial = "";

    private final Runnable pollRunnable = new Runnable() {
        @Override
        public void run() {
            refresh();
            ui.postDelayed(this, POLL_MS);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        setContentView(buildUi());
        renderEmpty("Coach autorizado listo.\nConecta el servicio para ver solo atletas que compartieron su sesion.");
        setConnection("sin conectar", false);
    }

    @Override
    protected void onDestroy() {
        ui.removeCallbacks(pollRunnable);
        executor.shutdownNow();
        super.onDestroy();
    }

    private View buildUi() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackgroundColor(BG);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(14), dp(10), dp(14), dp(18));
        scroll.addView(root, new ScrollView.LayoutParams(-1, -2));

        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        root.addView(header, new LinearLayout.LayoutParams(-1, -2));

        LinearLayout titleBox = new LinearLayout(this);
        titleBox.setOrientation(LinearLayout.VERTICAL);
        TextView title = text("SAVE SWIMMER\nCOACH NUEVO", 21, TEXT, true);
        title.setLetterSpacing(0.12f);
        TextView version = text(APP_VERSION, 12, CYAN, true);
        version.setLetterSpacing(0.18f);
        version.setPadding(0, dp(2), 0, 0);
        titleBox.addView(title, new LinearLayout.LayoutParams(-1, -2));
        titleBox.addView(version, new LinearLayout.LayoutParams(-1, -2));
        header.addView(titleBox, new LinearLayout.LayoutParams(0, -2, 1));

        connectionView = pill("conectando", false);
        header.addView(connectionView, new LinearLayout.LayoutParams(dp(118), dp(38)));

        backendInput = new EditText(this);
        backendInput.setSingleLine(true);
        backendInput.setInputType(InputType.TYPE_TEXT_VARIATION_URI);
        backendInput.setText(prefs.getString(PREF_URL, DEFAULT_BACKEND));
        backendInput.setTextColor(TEXT);
        backendInput.setHintTextColor(MUTED);
        backendInput.setTextSize(13);
        backendInput.setHint("https://tu-ngrok/api");
        backendInput.setPadding(dp(10), 0, dp(10), 0);
        backendInput.setBackgroundColor(PANEL);
        root.addView(labeled("Backend / ngrok", backendInput), paramsTop(10, 72));

        backendStatusView = text("URL: " + normalizeBackend(), 12, MUTED, false);
        backendStatusView.setPadding(dp(4), dp(6), dp(4), 0);
        root.addView(backendStatusView, new LinearLayout.LayoutParams(-1, -2));

        LinearLayout buttons = row();
        Button connect = button("Conectar", false);
        connect.setOnClickListener(v -> {
            saveBackend();
            connectNow();
        });
        Button clear = button("Limpiar vista", true);
        clear.setOnClickListener(v -> resetBackend());
        buttons.addView(connect, new LinearLayout.LayoutParams(0, dp(50), 1));
        buttons.addView(clear, new LinearLayout.LayoutParams(0, dp(50), 1));
        root.addView(buttons, paramsTop(9, -2));

        accessPolicyView = text("MODO COACH: solo sesiones compartidas por el atleta.\nFamilia/contacto de emergencia queda siempre separado.", 18, CYAN, true);
        root.addView(panel("Permiso del atleta", accessPolicyView), paramsTop(9, -2));

        LinearLayout status = row();
        athleteView = card(status, "Atleta activo", "--", 1);
        signalView = card(status, "Ultima senal", "--", 1);
        root.addView(status, paramsTop(9, -2));

        groupSummaryView = text("--", 18, TEXT, true);
        root.addView(panel("Atletas compartidos", groupSummaryView), paramsTop(9, -2));

        mapWebView = new WebView(this);
        setupMapWebView();
        root.addView(panel("Mapa en vivo", mapWebView), paramsTop(9, 560));

        trackView = new TrackView(this);
        root.addView(panel("Ruta esquematica | respaldo sin mapa", trackView), paramsTop(9, 430));

        selectedAthleteView = text("--", 18, TEXT, true);
        root.addView(panel("Atleta seleccionado", selectedAthleteView), paramsTop(9, -2));

        LinearLayout grid1 = row();
        distanceView = card(grid1, "Distancia a base", "--", 1);
        speedView = card(grid1, "Velocidad GPS", "--", 1);
        root.addView(grid1, paramsTop(9, -2));

        LinearLayout grid2 = row();
        motionView = card(grid2, "Movimiento", "--", 1);
        riskView = card(grid2, "Estado", "--", 1);
        root.addView(grid2, paramsTop(9, -2));

        coachReadView = text("Esperando una sesion compartida.", 18, TEXT, true);
        root.addView(panel("Lectura para entrenador", coachReadView), paramsTop(9, -2));

        rosterView = text("--", 14, TEXT, false);
        root.addView(panel("Atletas autorizados", rosterView), paramsTop(9, -2));

        strokeWindowView = new StrokeWindowView(this);
        root.addView(panel("Tecnica compartida | ventana movil 30 s", strokeWindowView), paramsTop(9, 1160));

        bodyView = text("--", 26, TEXT, true);
        root.addView(panel("Lectura tecnica basica", bodyView), paramsTop(9, -2));

        trendView = new TrendView(this);
        root.addView(panel("Lectura completa LR / FB / UD", trendView), paramsTop(9, 170));

        gpsView = text("--", 15, TEXT, true);
        root.addView(panel("Ubicacion actual", gpsView), paramsTop(9, -2));

        rowsView = text("--", 12, MUTED, false);
        root.addView(panel("Ultimas muestras", rowsView), paramsTop(9, -2));

        return scroll;
    }

    private void startPolling() {
        if (polling) return;
        polling = true;
        ui.removeCallbacks(pollRunnable);
        ui.post(pollRunnable);
    }

    private void connectNow() {
        polling = true;
        busy = false;
        ui.removeCallbacks(pollRunnable);
        setConnection("conectando", false);
        refresh();
        ui.postDelayed(pollRunnable, POLL_MS);
    }

    private void saveBackend() {
        String normalized = normalizeBackend();
        if (backendInput != null) backendInput.setText(normalized);
        if (backendStatusView != null) backendStatusView.setText("URL: " + normalized);
        prefs.edit().putString(PREF_URL, normalized).apply();
    }

    private void refresh() {
        if (busy) return;
        busy = true;
        setConnection("actualizando", false);
        executor.execute(() -> {
            try {
                String base = normalizeBackend();
                if (base.isEmpty() || !base.startsWith("http")) {
                    throw new Exception("URL invalida. Usa https://URL_NGROK");
                }
                JSONObject live = apiGet(base + "/api/coach-live?limit=" + LIMIT);
                JSONArray devices = live.optJSONArray("devices");
                JSONObject active = live.optJSONObject("active");
                if (active == null) active = latestDevice(devices);
                if (active == null) {
                    ui.post(() -> {
                        telemetry.clear();
                        renderEmpty("Sin sesiones compartidas activas. Inicia una sesion en la app del atleta y autoriza Coach.");
                    });
                    return;
                }

                selectedSerial = active.optString("serial", "");
                JSONArray rows = live.optJSONArray("telemetry");
                List<Sample> parsed = parseRows(rows);
                List<Sample> session = currentSessionRows(parsed);

                ui.post(() -> {
                    telemetry.clear();
                    telemetry.addAll(session);
                    render();
                    setConnection("en vivo", true);
                });
            } catch (Exception e) {
                ui.post(() -> {
                    setConnection("sin conexion", false);
                    coachReadView.setText("No se pudo leer el servicio Coach: " + e.getMessage() + "\nURL: " + normalizeBackend());
                });
            } finally {
                busy = false;
            }
        });
    }

    private void resetBackend() {
        saveBackend();
        busy = false;
        setConnection("limpiando", false);
        executor.execute(() -> {
            try {
                apiPost(normalizeBackend() + "/api/reset", "{}");
                ui.post(() -> {
                    telemetry.clear();
                    selectedSerial = "";
                    renderEmpty("Vista limpia. Cuando un atleta comparta una sesion activa, aparecera aqui.");
                    setConnection("limpio", false);
                });
            } catch (Exception e) {
                ui.post(() -> {
                    setConnection("sin conexion", false);
                    coachReadView.setText("No se pudo limpiar la vista. Revisa que backend/ngrok esten abiertos.\n" + e.getMessage() + "\nURL: " + normalizeBackend());
                });
            }
        });
    }

    private void renderEmpty(String message) {
        athleteView.setText("--");
        signalView.setText("--");
        distanceView.setText("--");
        speedView.setText("--");
        motionView.setText("--");
        riskView.setText("--");
        coachReadView.setText(message);
        bodyView.setText("--");
        gpsView.setText("--");
        rowsView.setText("--");
        if (accessPolicyView != null) {
            accessPolicyView.setText("MODO COACH: solo sesiones compartidas por el atleta.\nFamilia/contacto de emergencia queda siempre separado.");
        }
        groupSummaryView.setText("0 atletas compartidos | 0 normal | 0 observar | 0 alerta\nCoach: sin autorizaciones activas | Familia: canal independiente");
        selectedAthleteView.setText("Sin atleta seleccionado.\nEsta app no muestra al nadador si el atleta no autorizo Coach.");
        rosterView.setText("Sin atletas autorizados.\nAqui apareceran solo sesiones compartidas por el atleta.");
        if (strokeWindowView != null) strokeWindowView.setSamples(Collections.emptyList());
        trackView.setSamples(Collections.emptyList());
        trendView.setSamples(Collections.emptyList());
        updateMap(Collections.emptyList(), null);
    }

    private void render() {
        if (telemetry.isEmpty()) {
            renderEmpty("Esperando una sesion compartida.");
            return;
        }

        Sample latest = telemetry.get(telemetry.size() - 1);
        List<Sample> points = validTrackPoints(telemetry);
        Sample base = sessionBase(points);
        int age = secondsAgo(latest.receivedAt);

        athleteView.setText(empty(latest.user) ? "--" : latest.user);
        signalView.setText(age < 0 ? "--" : age + "s");
        signalView.setTextColor(age > 20 ? RED : TEXT);
        motionView.setText(motionLabel(latest.motion));
        riskView.setText(riskLabel(latest.risk));
        riskView.setTextColor(riskColor(latest.risk));

        if (!points.isEmpty() && base != null) {
            Sample lastPoint = points.get(points.size() - 1);
            double meters = distanceMeters(base.lat, base.lon, lastPoint.lat, lastPoint.lon);
            distanceView.setText(meters < 1000 ? Math.round(meters) + " m" : String.format(Locale.US, "%.2f km", meters / 1000.0));
            speedView.setText(speedText(points));
            gpsView.setText(String.format(Locale.US, "%.6f, %.6f\nBase %.6f, %.6f", lastPoint.lat, lastPoint.lon, base.lat, base.lon));
        } else {
            distanceView.setText("--");
            speedView.setText("--");
            gpsView.setText("Sin GPS valido todavia.");
        }

        coachReadView.setText(coachReadout(latest, points, base, age));
        bodyView.setText(bodyReadout(latest));
        rowsView.setText(rowsText());
        groupSummaryView.setText(groupSummary(latest, points, age));
        selectedAthleteView.setText(selectedAthlete(latest, points, base, age));
        rosterView.setText(rosterText(latest, age));
        strokeWindowView.setSamples(telemetry);
        trackView.setSamples(points);
        trendView.setSamples(telemetry);
        updateMap(points, base);
    }

    private void setupMapWebView() {
        mapWebView.setBackgroundColor(PANEL);
        mapWebView.setWebViewClient(new WebViewClient());
        WebSettings settings = mapWebView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);
        mapWebView.loadDataWithBaseURL(
                "https://saveswimmer.local/",
                mapHtml(),
                "text/html",
                "UTF-8",
                null
        );
    }

    private String mapHtml() {
        return "<!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'>"
                + "<link rel='stylesheet' href='https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'>"
                + "<style>html,body,#map{height:100%;margin:0;background:#0d2530}.leaflet-control-attribution{font-size:9px}"
                + ".dotA{width:20px;height:20px;border-radius:50%;background:#28d7ec;border:4px solid #fff;box-shadow:0 0 0 8px rgba(40,215,236,.22)}"
                + ".dotB{width:16px;height:16px;border-radius:50%;background:#ff6a18;border:3px solid #fff;box-shadow:0 0 0 6px rgba(255,106,24,.18)}"
                + "#empty{position:absolute;z-index:999;left:12px;top:12px;color:#eef8fb;font:700 14px Arial;background:rgba(4,16,22,.72);padding:8px 10px;border-radius:6px}</style></head>"
                + "<body><div id='map'></div><div id='empty'>Esperando GPS del atleta</div>"
                + "<script src='https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'></script>"
                + "<script>var map=L.map('map',{zoomControl:true}).setView([-12.1609,-77.0309],15);"
                + "L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19,attribution:'OpenStreetMap'}).addTo(map);"
                + "var route=L.polyline([],{color:'#28d7ec',weight:5,opacity:.9}).addTo(map);"
                + "var baseLine=L.polyline([],{color:'#ff6a18',weight:3,dashArray:'8 10',opacity:.75}).addTo(map);"
                + "var fence=L.circle([-12.1609,-77.0309],{radius:300,color:'#ffd166',weight:2,fill:false,dashArray:'8 10',opacity:.6}).addTo(map);"
                + "var ai=L.divIcon({className:'',html:\"<div class='dotA'></div>\",iconSize:[20,20],iconAnchor:[10,10]});"
                + "var bi=L.divIcon({className:'',html:\"<div class='dotB'></div>\",iconSize:[16,16],iconAnchor:[8,8]});"
                + "var am=L.marker([-12.1609,-77.0309],{icon:ai}).addTo(map);var bm=L.marker([-12.1609,-77.0309],{icon:bi}).addTo(map);"
                + "function updateTrack(data){try{var pts=data.points||[];var base=data.base;if(!pts.length){document.getElementById('empty').style.display='block';route.setLatLngs([]);baseLine.setLatLngs([]);return;}"
                + "document.getElementById('empty').style.display='none';route.setLatLngs(pts);var last=pts[pts.length-1];am.setLatLng(last);"
                + "if(base){bm.setLatLng(base);baseLine.setLatLngs([base,last]);fence.setLatLng(base);var b=L.latLngBounds(pts.concat([base])).pad(.22);map.fitBounds(b,{maxZoom:17,animate:false});}"
                + "else{map.setView(last,16,{animate:false});}}catch(e){document.getElementById('empty').innerHTML='Mapa: '+e.message;}}</script></body></html>";
    }

    private void updateMap(List<Sample> points, Sample base) {
        if (mapWebView == null) return;
        StringBuilder json = new StringBuilder();
        json.append("{\"points\":[");
        for (int i = 0; i < points.size(); i++) {
            if (i > 0) json.append(',');
            Sample p = points.get(i);
            json.append('[').append(num(p.lat)).append(',').append(num(p.lon)).append(']');
        }
        json.append(']');
        if (base != null && finite(base.lat) && finite(base.lon)) {
            json.append(",\"base\":[").append(num(base.lat)).append(',').append(num(base.lon)).append(']');
        }
        json.append('}');
        String script = "javascript:updateTrack(" + json + ")";
        mapWebView.post(() -> mapWebView.loadUrl(script));
    }

    private String coachReadout(Sample latest, List<Sample> points, Sample base, int age) {
        if (age > 30) return "Senal del atleta compartido desactualizada. Revisar cobertura, telefono del atleta o cierre de sesion.";
        if (!"NORMAL".equalsIgnoreCase(latest.risk)) return "Alerta compartida activa. El entrenador debe observar y coordinar; el contacto familiar/emergencia sigue siendo el canal principal.";
        if (points.size() >= 4) {
            List<Sample> recent = points.subList(Math.max(0, points.size() - 4), points.size());
            Sample first = recent.get(0);
            Sample last = recent.get(recent.size() - 1);
            double moved = distanceMeters(first.lat, first.lon, last.lat, last.lon);
            if (moved < 8) return "Sin avance GPS reciente. Revisar contexto visual: pausa, boya, corriente, fatiga o posible dificultad.";
            if (base != null) {
                double meters = distanceMeters(base.lat, base.lon, last.lat, last.lon);
                return "Sesion compartida en vivo. Distancia desde comienzo: " + (meters < 1000 ? Math.round(meters) + " m." : String.format(Locale.US, "%.2f km.", meters / 1000.0));
            }
        }
        return "Atleta compartiendo datos. Esperando mas puntos para calcular avance.";
    }

    private String groupSummary(Sample latest, List<Sample> points, int age) {
        int active = age >= 0 && age <= 20 ? 1 : 0;
        int normal = "NORMAL".equalsIgnoreCase(latest.risk) && active == 1 ? 1 : 0;
        int watch = age > 20 || "WATCH".equalsIgnoreCase(latest.risk) ? 1 : 0;
        int alert = ("WARNING".equalsIgnoreCase(latest.risk) || "SOS".equalsIgnoreCase(latest.risk) || "EMERGENCY".equalsIgnoreCase(latest.risk)) ? 1 : 0;
        double meters = 0;
        Sample base = sessionBase(points);
        if (!points.isEmpty() && base != null) {
            Sample last = points.get(points.size() - 1);
            meters = distanceMeters(base.lat, base.lon, last.lat, last.lon);
        }
        if (accessPolicyView != null) {
            accessPolicyView.setText("Sesion autorizada por el atleta: " + (empty(latest.user) ? "atleta sin nombre" : latest.user)
                    + ". El permiso Coach puede retirarse sin afectar el contacto familiar/emergencia.");
        }
        return active + " compartido | " + normal + " normal | " + watch + " observar | " + alert + " alerta"
                + "\nGeocerca: pendiente | Tiempo: control manual | Familia: independiente"
                + "\nAvance del atleta compartido: " + (points.isEmpty() ? "sin GPS" : (Math.round(meters) + " m desde base"));
    }

    private String selectedAthlete(Sample latest, List<Sample> points, Sample base, int age) {
        String name = empty(latest.user) ? "SIN_USUARIO" : latest.user;
        String signal = age < 0 ? "sin hora" : "ultima senal " + age + " s";
        String zone = "zona pendiente";
        if (!points.isEmpty() && base != null) {
            Sample last = points.get(points.size() - 1);
            double meters = distanceMeters(base.lat, base.lon, last.lat, last.lon);
            zone = meters <= 300 ? "dentro de zona referencial" : "fuera de zona referencial";
        }
        return name + "\n" + signal + " | " + zone
                + "\nMovimiento: " + motionLabel(latest.motion) + " | Estado: " + riskLabel(latest.risk);
    }

    private String rosterText(Sample latest, int age) {
        String name = empty(latest.user) ? "SIN_USUARIO" : latest.user;
        String live = age >= 0 && age <= 20 ? "LIVE" : "SIN SENAL";
        return "01  " + name + "  " + live + "  autorizado\n"
                + "Serial: " + (empty(selectedSerial) ? "--" : selectedSerial) + "\n\n"
                + "Multiatleta pendiente: cuando el backend reciba varios dispositivos, esta lista debe filtrar solo atletas que compartieron con este coach.";
    }

    private String bodyReadout(Sample latest) {
        double rotation = Math.sqrt(latest.lr * latest.lr + latest.fb * latest.fb);
        String posture;
        if (latest.ud > 8.0) posture = "Espalda arriba / estable";
        else if (latest.ud < -6.0) posture = "Boca abajo / revisar";
        else posture = "Transicion corporal";

        String energy;
        if (latest.mag >= 11.5) energy = "impulso alto";
        else if (latest.mag >= 9.2) energy = "impulso normal";
        else energy = "impulso bajo";

        String rot;
        if (rotation >= 3.0) rot = "rotacion marcada";
        else if (rotation >= 1.1) rot = "rotacion media";
        else rot = "rotacion baja";

        return posture + "\n" + rot + " | " + energy;
    }

    private String rowsText() {
        StringBuilder out = new StringBuilder();
        int start = Math.max(0, telemetry.size() - 8);
        for (int i = telemetry.size() - 1; i >= start; i--) {
            Sample s = telemetry.get(i);
            out.append(timeText(s.receivedAt)).append("  ")
                    .append(motionLabel(s.motion)).append("  ")
                    .append(finite(s.lat) ? String.format(Locale.US, "%.5f, %.5f", s.lat, s.lon) : "sin GPS")
                    .append("\n");
        }
        return out.toString().trim();
    }

    private JSONObject latestDevice(JSONArray devices) {
        JSONObject best = null;
        long bestTime = Long.MIN_VALUE;
        if (devices == null) return null;
        for (int i = 0; i < devices.length(); i++) {
            JSONObject item = devices.optJSONObject(i);
            if (item == null) continue;
            long time = parseTime(item.optString("lastSeenAt", ""));
            if (best == null || time > bestTime) {
                best = item;
                bestTime = time;
            }
        }
        return best;
    }

    private List<Sample> parseRows(JSONArray rows) {
        List<Sample> list = new ArrayList<>();
        if (rows == null) return list;
        for (int i = 0; i < rows.length(); i++) {
            JSONObject obj = rows.optJSONObject(i);
            if (obj == null) continue;
            Sample sample = Sample.from(obj);
            sample.timeMs = parseTime(sample.receivedAt);
            if (sample.timeMs <= 0) sample.timeMs = System.currentTimeMillis();
            list.add(sample);
        }
        return list;
    }

    private List<Sample> currentSessionRows(List<Sample> rows) {
        if (rows.isEmpty()) return rows;
        Sample latest = rows.get(rows.size() - 1);
        List<Sample> filtered = new ArrayList<>();
        long latestTime = parseTime(latest.receivedAt);
        for (Sample row : rows) {
            if (!empty(latest.sessionId) && latest.sessionId.equals(row.sessionId)) {
                filtered.add(row);
                continue;
            }
            long rowTime = parseTime(row.receivedAt);
            boolean sameRun = latest.user.equals(row.user)
                    && latest.mode.equals(row.mode)
                    && Math.abs(latestTime - rowTime) <= 30L * 60L * 1000L;
            if (sameRun) filtered.add(row);
        }
        return filtered;
    }

    private List<Sample> validTrackPoints(List<Sample> rows) {
        List<Sample> clean = new ArrayList<>();
        for (Sample point : rows) {
            if (!finite(point.lat) || !finite(point.lon)) continue;
            if (Math.abs(point.lat) > 90 || Math.abs(point.lon) > 180) continue;
            if (!clean.isEmpty()) {
                Sample prev = clean.get(clean.size() - 1);
                double jump = distanceMeters(prev.lat, prev.lon, point.lat, point.lon);
                double dt = Math.max(1, Math.abs(parseTime(point.receivedAt) - parseTime(prev.receivedAt)) / 1000.0);
                double mps = jump / dt;
                if (jump > 5000 && mps > 20) continue;
            }
            clean.add(point);
        }
        return clean;
    }

    private Sample sessionBase(List<Sample> points) {
        if (points.isEmpty()) return null;
        for (int i = points.size() - 1; i >= 0; i--) {
            Sample s = points.get(i);
            if (finite(s.baseLat) && finite(s.baseLon)) return Sample.base(s.baseLat, s.baseLon);
        }
        Sample first = points.get(0);
        return Sample.base(first.lat, first.lon);
    }

    private String speedText(List<Sample> points) {
        if (points.size() < 2) return "--";
        Sample a = points.get(points.size() - 2);
        Sample b = points.get(points.size() - 1);
        double dt = Math.max(1, (parseTime(b.receivedAt) - parseTime(a.receivedAt)) / 1000.0);
        double mps = distanceMeters(a.lat, a.lon, b.lat, b.lon) / dt;
        return String.format(Locale.US, "%.2f m/s", mps);
    }

    private JSONObject apiGet(String url) throws Exception {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setConnectTimeout(HTTP_TIMEOUT_MS);
        conn.setReadTimeout(HTTP_TIMEOUT_MS);
        conn.setRequestMethod("GET");
        conn.setRequestProperty("ngrok-skip-browser-warning", "true");
        conn.setRequestProperty("User-Agent", "SaveSwimmerCoachLive/0.1.1");
        int code = conn.getResponseCode();
        String body = readAll(code >= 400 ? conn.getErrorStream() : conn.getInputStream());
        if (code >= 400) throw new Exception(body);
        return new JSONObject(body);
    }

    private JSONArray apiGetArray(String url, String key) throws Exception {
        JSONObject obj = apiGet(url);
        JSONArray array = obj.optJSONArray(key);
        return array == null ? new JSONArray() : array;
    }

    private JSONObject apiPost(String url, String body) throws Exception {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setConnectTimeout(HTTP_TIMEOUT_MS);
        conn.setReadTimeout(HTTP_TIMEOUT_MS);
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("ngrok-skip-browser-warning", "true");
        conn.setRequestProperty("User-Agent", "SaveSwimmerCoachLive/0.1.1");
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        try (OutputStream os = conn.getOutputStream()) {
            os.write(bytes);
        }
        int code = conn.getResponseCode();
        String text = readAll(code >= 400 ? conn.getErrorStream() : conn.getInputStream());
        if (code >= 400) throw new Exception(text);
        return new JSONObject(text);
    }

    private String readAll(java.io.InputStream in) throws Exception {
        if (in == null) return "";
        BufferedReader reader = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8));
        StringBuilder out = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) out.append(line);
        return out.toString();
    }

    private String normalizeBackend() {
        String value = backendInput == null ? "" : backendInput.getText().toString().trim();
        if (value.isEmpty()) value = DEFAULT_BACKEND;
        while (value.endsWith("/")) value = value.substring(0, value.length() - 1);
        if (value.endsWith("/coach.html")) value = value.substring(0, value.length() - "/coach.html".length());
        if (value.endsWith("/dashboard.html")) value = value.substring(0, value.length() - "/dashboard.html".length());
        if (value.endsWith("/api/telemetry")) value = value.substring(0, value.length() - "/api/telemetry".length());
        if (value.endsWith("/api/devices")) value = value.substring(0, value.length() - "/api/devices".length());
        if (value.endsWith("/api")) value = value.substring(0, value.length() - "/api".length());
        return value;
    }

    private String encode(String value) {
        try {
            return java.net.URLEncoder.encode(value, "UTF-8").replace("+", "%20");
        } catch (Exception e) {
            return value;
        }
    }

    private void setConnection(String text, boolean live) {
        connectionView.setText(text);
        connectionView.setTextColor(live ? GREEN : MUTED);
    }

    private TextView card(LinearLayout parent, String label, String value, float weight) {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(12), dp(10), dp(12), dp(10));
        box.setBackgroundColor(PANEL);
        TextView l = text(label, 12, MUTED, false);
        TextView v = text(value, 23, TEXT, true);
        v.setPadding(0, dp(5), 0, 0);
        box.addView(l);
        box.addView(v);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, dp(82), weight);
        lp.setMargins(dp(4), 0, dp(4), 0);
        parent.addView(box, lp);
        return v;
    }

    private View panel(String label, View content) {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(12), dp(10), dp(12), dp(10));
        box.setBackgroundColor(PANEL);
        box.addView(text(label, 12, MUTED, false));
        boolean fillPanel = !(content instanceof TextView);
        LinearLayout.LayoutParams cp = new LinearLayout.LayoutParams(-1, fillPanel ? 0 : -2);
        if (fillPanel) cp.weight = 1;
        cp.setMargins(0, dp(6), 0, 0);
        box.addView(content, cp);
        return box;
    }

    private View labeled(String label, View content) {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(12), dp(8), dp(12), dp(8));
        box.setBackgroundColor(PANEL);
        box.addView(text(label, 12, MUTED, false));
        box.addView(content, new LinearLayout.LayoutParams(-1, 0, 1));
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
        t.setPadding(dp(12), 0, dp(12), 0);
        t.setBackgroundColor(PANEL);
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

    private boolean finite(double value) {
        return !Double.isNaN(value) && !Double.isInfinite(value);
    }

    private boolean empty(String value) {
        return value == null || value.trim().isEmpty();
    }

    private int secondsAgo(String value) {
        long t = parseTime(value);
        if (t <= 0) return -1;
        return Math.max(0, Math.round((System.currentTimeMillis() - t) / 1000f));
    }

    private long parseTime(String value) {
        if (empty(value)) return 0;
        try {
            String normalized = value.endsWith("Z") ? value : value.replaceFirst("([+-]\\d\\d):(\\d\\d)$", "$1$2");
            SimpleDateFormat fmt = normalized.endsWith("Z")
                    ? new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
                    : new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US);
            fmt.setTimeZone(TimeZone.getTimeZone("UTC"));
            return fmt.parse(normalized).getTime();
        } catch (Exception ignored) {
            try {
                SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US);
                fmt.setTimeZone(TimeZone.getTimeZone("UTC"));
                return fmt.parse(value).getTime();
            } catch (Exception ignoredAgain) {
                return 0;
            }
        }
    }

    private String timeText(String value) {
        long t = parseTime(value);
        if (t <= 0) return "--";
        return new SimpleDateFormat("HH:mm:ss", Locale.US).format(new Date(t));
    }

    private String motionLabel(String value) {
        String v = value == null ? "" : value.toUpperCase(Locale.US);
        if ("SWIMMING".equals(v) || "MOVING".equals(v)) return "movimiento";
        if ("STILL".equals(v) || "STOPPED".equals(v)) return "sin avance";
        return empty(value) ? "--" : value.toLowerCase(Locale.US);
    }

    private String riskLabel(String value) {
        String v = empty(value) ? "NORMAL" : value.toUpperCase(Locale.US);
        if ("NORMAL".equals(v)) return "normal";
        if ("WATCH".equals(v)) return "observar";
        if ("WARNING".equals(v)) return "alerta";
        if ("SOS".equals(v) || "EMERGENCY".equals(v)) return "SOS";
        return v.toLowerCase(Locale.US);
    }

    private int riskColor(String value) {
        String v = empty(value) ? "NORMAL" : value.toUpperCase(Locale.US);
        if ("NORMAL".equals(v)) return GREEN;
        if ("WATCH".equals(v)) return YELLOW;
        return RED;
    }

    private double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
        double r = 6371000.0;
        double p1 = Math.toRadians(lat1);
        double p2 = Math.toRadians(lat2);
        double dp = Math.toRadians(lat2 - lat1);
        double dl = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dp / 2) * Math.sin(dp / 2)
                + Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) * Math.sin(dl / 2);
        return r * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private String num(double value) {
        if (!finite(value)) return "null";
        return String.format(Locale.US, "%.8f", value);
    }

    private static class Sample {
        String id = "";
        String user = "";
        String mode = "";
        String sessionId = "";
        String receivedAt = "";
        String motion = "";
        String risk = "";
        double lr = Double.NaN;
        double fb = Double.NaN;
        double ud = Double.NaN;
        double mag = Double.NaN;
        double lat = Double.NaN;
        double lon = Double.NaN;
        double baseLat = Double.NaN;
        double baseLon = Double.NaN;
        long timeMs = 0L;

        static Sample from(JSONObject obj) {
            Sample s = new Sample();
            s.id = obj.optString("id", "");
            s.user = obj.optString("user", "");
            s.mode = obj.optString("mode", "");
            s.sessionId = obj.optString("sessionId", "");
            s.receivedAt = obj.optString("receivedAt", obj.optString("time", ""));
            s.motion = obj.optString("motion", "");
            s.risk = obj.optString("risk", "NORMAL");
            s.lr = optDouble(obj, "lr");
            s.fb = optDouble(obj, "fb");
            s.ud = optDouble(obj, "ud");
            s.mag = optDouble(obj, "mag");
            s.lat = optDouble(obj, "lat");
            s.lon = optDouble(obj, "lon");
            s.baseLat = optDouble(obj, "baseLat");
            s.baseLon = optDouble(obj, "baseLon");
            return s;
        }

        static Sample base(double lat, double lon) {
            Sample s = new Sample();
            s.lat = lat;
            s.lon = lon;
            return s;
        }

        static double optDouble(JSONObject obj, String key) {
            if (!obj.has(key) || obj.isNull(key)) return Double.NaN;
            return obj.optDouble(key, Double.NaN);
        }
    }

    public static class OrientationView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private Sample latest = null;

        public OrientationView(android.content.Context context) {
            super(context);
            setBackgroundColor(PANEL);
        }

        void setSample(Sample sample) {
            latest = sample;
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int w = getWidth();
            int h = getHeight();

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(Color.rgb(7, 21, 28));
            canvas.drawRect(0, 0, w, h, paint);

            float labelSpace = 34f;
            float bottomTextSpace = 42f;
            float availableW = Math.max(80f, w - 44f);
            float availableH = Math.max(80f, h - labelSpace - bottomTextSpace - 24f);
            float size = Math.min(availableW, availableH);
            float left = (w - size) / 2f;
            float top = labelSpace + (availableH - size) / 2f;
            float right = left + size;
            float bottom = top + size;
            float cx = left + size / 2f;
            float cy = top + size / 2f;

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(LINE);
            canvas.drawLine(left, cy, right, cy, paint);
            canvas.drawLine(cx, top, cx, bottom, paint);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(22);
            paint.setColor(MUTED);
            paint.setTextAlign(Paint.Align.CENTER);
            canvas.drawText("ARRIBA", cx, top - 8, paint);
            canvas.drawText("ABAJO", cx, bottom + 26, paint);
            paint.setTextAlign(Paint.Align.LEFT);
            canvas.drawText("IZQ", left + 4, cy - 10, paint);
            paint.setTextAlign(Paint.Align.RIGHT);
            canvas.drawText("DER", right - 4, cy - 10, paint);
            paint.setTextAlign(Paint.Align.LEFT);

            if (latest == null) {
                paint.setTextSize(24);
                canvas.drawText("Esperando movimiento", left, bottom + 58, paint);
                return;
            }

            float amp = size * 0.42f;
            float x = clamp((float) (cx + latest.lr * (amp / 6f)), left + 14, right - 14);
            float y = clamp((float) (cy - latest.fb * (amp / 6f)), top + 14, bottom - 14);
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(CYAN);
            canvas.drawCircle(x, y, 18, paint);

            paint.setTextSize(20);
            paint.setColor(TEXT);
            canvas.drawText(String.format(Locale.US, "LR %.1f | FB %.1f | UD %.1f", latest.lr, latest.fb, latest.ud), left, h - 18, paint);
        }

        private float clamp(float value, float min, float max) {
            return Math.max(min, Math.min(max, value));
        }
    }

    public static class StrokeWindowView extends View {
        private static final long WINDOW_MS = 30000L;
        private static final long GRID_MS = 5000L;
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final List<Sample> samples = new ArrayList<>();

        public StrokeWindowView(android.content.Context context) {
            super(context);
            setBackgroundColor(PANEL);
        }

        void setSamples(List<Sample> rows) {
            samples.clear();
            if (!rows.isEmpty()) {
                long latest = rows.get(rows.size() - 1).timeMs;
                long start = latest - WINDOW_MS;
                for (Sample row : rows) {
                    if (row.timeMs >= start) samples.add(row);
                }
            }
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int w = getWidth();
            int h = getHeight();
            float left = 58f;
            float right = w - 18f;
            float top = 34f;
            float bottom = h * 0.46f;
            float rotZero = top + (bottom - top) * 0.32f;
            float udZero = top + (bottom - top) * 0.74f;

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(Color.rgb(7, 21, 28));
            canvas.drawRect(0, 0, w, h, paint);

            drawGrid(canvas, left, right, top, bottom, rotZero, udZero);

            if (samples.size() < 2) {
                paint.setStyle(Paint.Style.FILL);
                paint.setTextSize(24);
                paint.setColor(MUTED);
                canvas.drawText("Esperando datos de 30 s", left, h / 2f, paint);
                return;
            }

            long latest = samples.get(samples.size() - 1).timeMs;
            long windowStart = latest - WINDOW_MS;
            double lrScale = Math.max(1.0, maxAbsLr());
            double udBase = meanUd();
            double udScale = Math.max(0.25, maxCenteredUd(udBase));
            double lrMin = minLr();
            double lrMax = maxLr();

            drawRotationGuides(canvas, left, right, rotZero, (bottom - top) * 0.20f, lrScale, lrMin, lrMax);
            drawRotation(canvas, windowStart, latest, left, right, rotZero, (bottom - top) * 0.20f, lrScale);
            drawElevation(canvas, windowStart, latest, left, right, udZero, (bottom - top) * 0.18f, udBase, udScale);
            drawMovingBar(canvas, left, right, bottom + 24f, latest);
            drawBodyGuide(canvas, left, right, bottom + 62f, h - 16f, samples.get(samples.size() - 1), lrScale, lrMin, lrMax);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(19);
            paint.setColor(MUTED);
            canvas.drawText("DER", left, 22, paint);
            paint.setColor(YELLOW);
            canvas.drawText("IZQ", left + 48, 22, paint);
            paint.setColor(Color.rgb(127, 169, 255));
            canvas.drawText("ELEVACION", left + 96, 22, paint);
        }

        private void drawRotationGuides(Canvas canvas, float left, float right, float zero, float amp, double scale, double min, double max) {
            float maxY = (float) (zero - (max / scale) * amp);
            float minY = (float) (zero - (min / scale) * amp);
            maxY = clamp(maxY, zero - amp, zero + amp);
            minY = clamp(minY, zero - amp, zero + amp);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setPathEffect(new DashPathEffect(new float[]{12f, 10f}, 0));
            paint.setColor(Color.argb(185, 40, 215, 236));
            canvas.drawLine(left, maxY, right, maxY, paint);
            paint.setColor(Color.argb(185, 255, 209, 102));
            canvas.drawLine(left, minY, right, minY, paint);
            paint.setPathEffect(null);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(18);
            paint.setColor(CYAN);
            canvas.drawText(String.format(Locale.US, "max %.1f", max), right - 86, maxY - 8, paint);
            paint.setColor(YELLOW);
            canvas.drawText(String.format(Locale.US, "min %.1f", min), right - 86, minY + 22, paint);
        }

        private void drawBodyGuide(Canvas canvas, float left, float right, float top, float bottom, Sample current, double scale, double min, double max) {
            float w = right - left;
            float height = bottom - top;
            float cx = left + w * 0.50f;
            float cy = top + height * 0.54f;
            float radius = Math.min(w * 0.34f, height * 0.42f);
            float shoulderHalf = Math.min(radius * 1.02f, w * 0.36f);
            float amp = (float) Math.max(1.0, scale);
            float phase = clamp((float) (current.lr / amp), -1f, 1f);
            float angleDeg = -phase * 90f;
            float minDeg = clamp((float) (-min / amp) * 90f, -90f, 90f);
            float maxDeg = clamp((float) (-max / amp) * 90f, -90f, 90f);
            float lowDeg = Math.min(minDeg, maxDeg);
            float highDeg = Math.max(minDeg, maxDeg);
            float avgDeg = averageRotationDeg(amp);

            paint.setPathEffect(null);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(LINE);
            canvas.drawLine(cx - radius, cy, cx + radius, cy, paint);
            canvas.drawLine(cx, top + 14f, cx, bottom - 34f, paint);

            paint.setPathEffect(new DashPathEffect(new float[]{9f, 8f}, 0));
            paint.setStrokeWidth(2);
            paint.setColor(Color.argb(150, 255, 106, 24));
            drawAngleGuide(canvas, cx, cy, radius, -90f);
            drawAngleGuide(canvas, cx, cy, radius, 90f);
            paint.setColor(Color.argb(170, 69, 224, 137));
            drawAngleGuide(canvas, cx, cy, radius, -32f);
            drawAngleGuide(canvas, cx, cy, radius, 32f);
            drawAngleGuide(canvas, cx, cy, radius, -45f);
            drawAngleGuide(canvas, cx, cy, radius, 45f);
            paint.setColor(Color.argb(170, 255, 106, 24));
            drawAngleGuide(canvas, cx, cy, radius, -50f);
            drawAngleGuide(canvas, cx, cy, radius, 50f);
            paint.setColor(Color.argb(160, 255, 209, 102));
            drawAngleGuide(canvas, cx, cy, radius, minDeg);
            paint.setColor(Color.argb(180, 40, 215, 236));
            drawAngleGuide(canvas, cx, cy, radius, maxDeg);
            paint.setPathEffect(null);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(18);
            paint.setColor(MUTED);
            canvas.drawText("0 eje espalda-hombros", left, top + 18f, paint);
            paint.setColor(GREEN);
            canvas.drawText("objetivo 32-45", left, top + 42f, paint);
            paint.setColor(ORANGE);
            paint.setTextAlign(Paint.Align.RIGHT);
            canvas.drawText("sobre 50", right, top + 18f, paint);
            paint.setTextAlign(Paint.Align.LEFT);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(8);
            paint.setColor(Color.argb(130, 103, 137, 151));
            drawShoulderLine(canvas, cx, cy, shoulderHalf, 0f);

            drawShoulderHistory(canvas, cx, cy, shoulderHalf, amp);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(9);
            paint.setColor(Color.argb(175, 69, 224, 137));
            drawShoulderLine(canvas, cx, cy, shoulderHalf * 0.96f, avgDeg);

            paint.setStrokeWidth(12);
            paint.setColor(CYAN);
            drawShoulderLine(canvas, cx, cy, shoulderHalf, angleDeg);

            float rad = (float) Math.toRadians(angleDeg);
            float dx = (float) Math.cos(rad) * shoulderHalf;
            float dy = (float) Math.sin(rad) * shoulderHalf;
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(YELLOW);
            canvas.drawCircle(cx - dx, cy - dy, 10, paint);
            paint.setColor(CYAN);
            canvas.drawCircle(cx + dx, cy + dy, 10, paint);
            paint.setColor(TEXT);
            canvas.drawCircle(cx, cy, 8, paint);

            paint.setTextSize(18);
            paint.setColor(YELLOW);
            paint.setTextAlign(Paint.Align.CENTER);
            canvas.drawText("hombro izq", cx - dx, cy - dy - 16f, paint);
            paint.setColor(CYAN);
            canvas.drawText("hombro der", cx + dx, cy + dy - 16f, paint);
            paint.setTextAlign(Paint.Align.LEFT);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(20);
            paint.setColor(MUTED);
            canvas.drawText(String.format(Locale.US, "rotacion %.0f deg | prom %.0f deg | objetivo 32-45 | rango %.0f a %.0f", angleDeg, avgDeg, lowDeg, highDeg), left, bottom - 8, paint);
        }

        private void drawShoulderHistory(Canvas canvas, float cx, float cy, float half, float amp) {
            if (samples.isEmpty()) return;
            int step = Math.max(1, samples.size() / 10);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(4);
            for (int i = 0; i < samples.size(); i += step) {
                Sample s = samples.get(i);
                float deg = clamp((float) (-s.lr / amp) * 90f, -90f, 90f);
                int alpha = 35 + Math.round(75f * i / Math.max(1, samples.size() - 1));
                paint.setColor(Color.argb(alpha, 40, 215, 236));
                drawShoulderLine(canvas, cx, cy, half * 0.92f, deg);
            }
        }

        private float averageRotationDeg(float amp) {
            if (samples.isEmpty()) return 0f;
            double sum = 0;
            int count = 0;
            for (Sample s : samples) {
                if (!Double.isNaN(s.lr)) {
                    sum += clamp((float) (-s.lr / amp) * 90f, -90f, 90f);
                    count++;
                }
            }
            return count == 0 ? 0f : (float) (sum / count);
        }

        private void drawAngleGuide(Canvas canvas, float cx, float cy, float radius, float degrees) {
            float rad = (float) Math.toRadians(degrees);
            float dx = (float) Math.cos(rad) * radius;
            float dy = (float) Math.sin(rad) * radius;
            canvas.drawLine(cx - dx, cy - dy, cx + dx, cy + dy, paint);
        }

        private void drawShoulderLine(Canvas canvas, float cx, float cy, float half, float degrees) {
            float rad = (float) Math.toRadians(degrees);
            float dx = (float) Math.cos(rad) * half;
            float dy = (float) Math.sin(rad) * half;
            canvas.drawLine(cx - dx, cy - dy, cx + dx, cy + dy, paint);
        }

        private void drawGrid(Canvas canvas, float left, float right, float top, float bottom, float rotZero, float udZero) {
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(LINE);
            canvas.drawLine(left, rotZero, right, rotZero, paint);
            canvas.drawLine(left, udZero, right, udZero, paint);
            for (long t = 0; t <= WINDOW_MS; t += GRID_MS) {
                float x = left + (right - left) * t / (float) WINDOW_MS;
                canvas.drawLine(x, top, x, bottom, paint);
            }
            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(20);
            paint.setColor(MUTED);
            canvas.drawText("ROT", 8, rotZero + 6, paint);
            canvas.drawText("UD", 16, udZero + 6, paint);
            canvas.drawText("0s", left, bottom + 24, paint);
            canvas.drawText("30s", right - 36, bottom + 24, paint);
        }

        private void drawRotation(Canvas canvas, long start, long latest, float left, float right, float zero, float amp, double scale) {
            Path rightPath = new Path();
            Path leftPath = new Path();
            boolean hasR = false;
            boolean hasL = false;
            for (Sample s : samples) {
                float x = timeX(s.timeMs, start, latest, left, right);
                float y = (float) (zero - (s.lr / scale) * amp);
                y = clamp(y, zero - amp, zero + amp);
                if (s.lr >= 0) {
                    if (!hasR) rightPath.moveTo(x, y); else rightPath.lineTo(x, y);
                    hasR = true;
                } else {
                    if (!hasL) leftPath.moveTo(x, y); else leftPath.lineTo(x, y);
                    hasL = true;
                }
            }
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(4);
            paint.setColor(CYAN);
            canvas.drawPath(rightPath, paint);
            paint.setColor(YELLOW);
            canvas.drawPath(leftPath, paint);
        }

        private void drawElevation(Canvas canvas, long start, long latest, float left, float right, float zero, float amp, double base, double scale) {
            Path path = new Path();
            boolean started = false;
            for (Sample s : samples) {
                float x = timeX(s.timeMs, start, latest, left, right);
                float y = (float) (zero - ((s.ud - base) / scale) * amp);
                y = clamp(y, zero - amp, zero + amp);
                if (!started) path.moveTo(x, y); else path.lineTo(x, y);
                started = true;
            }
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(4);
            paint.setColor(Color.rgb(127, 169, 255));
            canvas.drawPath(path, paint);
        }

        private void drawMovingBar(Canvas canvas, float left, float right, float y, long latest) {
            float cycle = (latest % WINDOW_MS) / (float) WINDOW_MS;
            float marker = left + (right - left) * cycle;
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(8);
            paint.setColor(Color.rgb(24, 67, 80));
            canvas.drawLine(left, y, right, y, paint);
            paint.setColor(CYAN);
            canvas.drawLine(left, y, marker, y, paint);
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(ORANGE);
            canvas.drawCircle(marker, y, 9, paint);
        }

        private float timeX(long time, long start, long latest, float left, float right) {
            long end = Math.max(start + 1, latest);
            return left + (right - left) * (time - start) / (float) (end - start);
        }

        private double maxAbsLr() {
            double max = 1.0;
            for (Sample s : samples) max = Math.max(max, Math.abs(s.lr));
            return max;
        }

        private double minLr() {
            double min = 0.0;
            boolean seen = false;
            for (Sample s : samples) {
                if (!Double.isNaN(s.lr)) {
                    min = seen ? Math.min(min, s.lr) : s.lr;
                    seen = true;
                }
            }
            return seen ? min : 0.0;
        }

        private double maxLr() {
            double max = 0.0;
            boolean seen = false;
            for (Sample s : samples) {
                if (!Double.isNaN(s.lr)) {
                    max = seen ? Math.max(max, s.lr) : s.lr;
                    seen = true;
                }
            }
            return seen ? max : 0.0;
        }

        private double meanUd() {
            double sum = 0;
            int count = 0;
            for (Sample s : samples) {
                if (!Double.isNaN(s.ud)) {
                    sum += s.ud;
                    count++;
                }
            }
            return count == 0 ? 9.8 : sum / count;
        }

        private double maxCenteredUd(double base) {
            double max = 0.25;
            for (Sample s : samples) max = Math.max(max, Math.abs(s.ud - base));
            return max;
        }

        private float clamp(float value, float min, float max) {
            return Math.max(min, Math.min(max, value));
        }
    }

    public static class TrackView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final List<Sample> samples = new ArrayList<>();

        public TrackView(android.content.Context context) {
            super(context);
            setBackgroundColor(PANEL);
        }

        void setSamples(List<Sample> rows) {
            samples.clear();
            samples.addAll(rows);
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int w = getWidth();
            int h = getHeight();
            int pad = 26;

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(LINE);
            for (int i = 1; i < 4; i++) {
                float x = pad + (w - pad * 2) * i / 4f;
                float y = pad + (h - pad * 2) * i / 4f;
                canvas.drawLine(x, pad, x, h - pad, paint);
                canvas.drawLine(pad, y, w - pad, y, paint);
            }

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(28);
            paint.setColor(MUTED);
            if (samples.isEmpty()) {
                canvas.drawText("Esperando ubicacion", pad, h / 2f, paint);
                return;
            }

            Bounds b = bounds(samples);
            Path route = new Path();
            for (int i = 0; i < samples.size(); i++) {
                float x = x(samples.get(i).lon, b, w, pad);
                float y = y(samples.get(i).lat, b, h, pad);
                if (i == 0) route.moveTo(x, y);
                else route.lineTo(x, y);
            }

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(6);
            paint.setColor(CYAN);
            canvas.drawPath(route, paint);

            Sample first = samples.get(0);
            Sample last = samples.get(samples.size() - 1);
            drawDot(canvas, x(first.lon, b, w, pad), y(first.lat, b, h, pad), ORANGE, 15);
            drawDot(canvas, x(last.lon, b, w, pad), y(last.lat, b, h, pad), CYAN, 20);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(24);
            paint.setColor(TEXT);
            canvas.drawText("BASE", pad, h - pad + 6, paint);
            canvas.drawText("ATLETA", w - pad - 92, h - pad + 6, paint);
        }

        private void drawDot(Canvas canvas, float x, float y, int color, float r) {
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(Color.WHITE);
            canvas.drawCircle(x, y, r + 7, paint);
            paint.setColor(color);
            canvas.drawCircle(x, y, r, paint);
        }

        private Bounds bounds(List<Sample> rows) {
            Bounds b = new Bounds();
            for (Sample s : rows) {
                b.minLat = Math.min(b.minLat, s.lat);
                b.maxLat = Math.max(b.maxLat, s.lat);
                b.minLon = Math.min(b.minLon, s.lon);
                b.maxLon = Math.max(b.maxLon, s.lon);
            }
            if (Math.abs(b.maxLat - b.minLat) < 0.0001) {
                b.maxLat += 0.0001;
                b.minLat -= 0.0001;
            }
            if (Math.abs(b.maxLon - b.minLon) < 0.0001) {
                b.maxLon += 0.0001;
                b.minLon -= 0.0001;
            }
            return b;
        }

        private float x(double lon, Bounds b, int w, int pad) {
            return (float) (pad + ((lon - b.minLon) / (b.maxLon - b.minLon)) * (w - pad * 2));
        }

        private float y(double lat, Bounds b, int h, int pad) {
            return (float) (h - pad - ((lat - b.minLat) / (b.maxLat - b.minLat)) * (h - pad * 2));
        }
    }

    public static class TrendView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final List<Sample> samples = new ArrayList<>();

        public TrendView(android.content.Context context) {
            super(context);
            setBackgroundColor(PANEL);
        }

        void setSamples(List<Sample> rows) {
            samples.clear();
            int start = Math.max(0, rows.size() - 80);
            samples.addAll(rows.subList(start, rows.size()));
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int w = getWidth();
            int h = getHeight();
            int pad = 20;

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            paint.setColor(LINE);
            canvas.drawLine(pad, h / 2f, w - pad, h / 2f, paint);

            paint.setStyle(Paint.Style.FILL);
            paint.setTextSize(20);
            paint.setColor(MUTED);
            canvas.drawText("LR", pad, pad, paint);
            paint.setColor(YELLOW);
            canvas.drawText("FB", pad + 48, pad, paint);
            paint.setColor(Color.rgb(127, 169, 255));
            canvas.drawText("UD", pad + 96, pad, paint);

            if (samples.size() < 2) return;
            drawLine(canvas, "lr", CYAN, -6, 6);
            drawLine(canvas, "fb", YELLOW, -6, 6);
            drawLine(canvas, "ud", Color.rgb(127, 169, 255), 6, 12);
        }

        private void drawLine(Canvas canvas, String field, int color, double min, double max) {
            int w = getWidth();
            int h = getHeight();
            int pad = 20;
            Path path = new Path();
            for (int i = 0; i < samples.size(); i++) {
                Sample s = samples.get(i);
                double value = "lr".equals(field) ? s.lr : "fb".equals(field) ? s.fb : s.ud;
                if (Double.isNaN(value)) continue;
                float x = pad + (w - pad * 2) * i / Math.max(1f, samples.size() - 1f);
                float y = (float) (h - pad - ((value - min) / (max - min)) * (h - pad * 2));
                y = Math.max(pad, Math.min(h - pad, y));
                if (i == 0) path.moveTo(x, y);
                else path.lineTo(x, y);
            }
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(4);
            paint.setColor(color);
            canvas.drawPath(path, paint);
        }
    }

    private static class Bounds {
        double minLat = Double.MAX_VALUE;
        double maxLat = -Double.MAX_VALUE;
        double minLon = Double.MAX_VALUE;
        double maxLon = -Double.MAX_VALUE;
    }
}
