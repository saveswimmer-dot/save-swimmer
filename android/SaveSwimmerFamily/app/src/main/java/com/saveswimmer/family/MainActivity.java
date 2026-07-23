package com.saveswimmer.family;

import android.app.Activity;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

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

    private static final String APP_VERSION = "FAMILY V0.1.2 NUEVA";

    private LinearLayout root;
    private int state = 0; // 0 normal, 1 observar, 2 sos, 3 fuera del agua

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(build());
        render();
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

    private void render() {
        root.removeAllViews();

        LinearLayout header = row();
        header.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout titleBox = new LinearLayout(this);
        titleBox.setOrientation(LinearLayout.VERTICAL);
        TextView title = text("SAVE SWIMMER\nFAMILIA NUEVA", 22, TEXT, true);
        title.setLetterSpacing(0.10f);
        TextView version = text(APP_VERSION, 12, CYAN, true);
        version.setLetterSpacing(0.16f);
        titleBox.addView(title);
        titleBox.addView(version);
        header.addView(titleBox, new LinearLayout.LayoutParams(0, -2, 1));
        header.addView(pill("incluida", true), new LinearLayout.LayoutParams(dp(118), dp(40)));
        root.addView(header);

        TextView sub = text("Contacto familiar activo durante la sesion. Sin datos tecnicos innecesarios.", 14, MUTED, false);
        sub.setPadding(dp(2), dp(8), dp(2), dp(4));
        root.addView(sub);

        root.addView(statusHero(), paramsTop(10, -2));

        FamilyMapView map = new FamilyMapView(this, state);
        root.addView(panel("Ubicacion autorizada", map), paramsTop(10, 420));

        LinearLayout grid1 = row();
        grid1.addView(metric("Ultima senal", state == 2 ? "18 s" : "2 s", "seguimiento activo"), new LinearLayout.LayoutParams(0, dp(108), 1));
        grid1.addView(metric("Agua", state == 3 ? "NO" : "SI", state == 3 ? "salio del agua" : "sesion activa"), new LinearLayout.LayoutParams(0, dp(108), 1));
        root.addView(grid1, paramsTop(9, -2));

        LinearLayout grid2 = row();
        grid2.addView(metric("Senal", state == 2 ? "vigilar" : "activa", state == 2 ? "ultima ubicacion disponible" : "datos recientes"), new LinearLayout.LayoutParams(0, dp(108), 1));
        grid2.addView(metric("Coach", "opcional", "solo si el atleta comparte"), new LinearLayout.LayoutParams(0, dp(108), 1));
        root.addView(grid2, paramsTop(9, -2));

        root.addView(panel("Que significa", text(explanation(), 18, TEXT, true)), paramsTop(9, -2));

        LinearLayout actions = row();
        Button call = button("Llamar contacto", state != 2);
        Button share = button("Compartir ubicacion", true);
        actions.addView(call, new LinearLayout.LayoutParams(0, dp(54), 1));
        actions.addView(share, new LinearLayout.LayoutParams(0, dp(54), 1));
        root.addView(actions, paramsTop(9, -2));

        root.addView(panel("Contactos de emergencia", text("Principal: pendiente\nSecundario: pendiente\nCoach/responsable: opcional\nRecomendado: 2 a 5 contactos\nEsta app no se desconecta durante una sesion real.", 16, TEXT, true)), paramsTop(9, -2));

        LinearLayout demo = row();
        Button normal = button("Normal", state != 0);
        normal.setOnClickListener(v -> { state = 0; render(); });
        Button watch = button("Observar", state != 1);
        watch.setOnClickListener(v -> { state = 1; render(); });
        Button sos = button("SOS", state != 2);
        sos.setOnClickListener(v -> { state = 2; render(); });
        demo.addView(normal, new LinearLayout.LayoutParams(0, dp(48), 1));
        demo.addView(watch, new LinearLayout.LayoutParams(0, dp(48), 1));
        demo.addView(sos, new LinearLayout.LayoutParams(0, dp(48), 1));
        root.addView(demo, paramsTop(9, -2));

        Button out = button("Simular salida del agua", state != 3);
        out.setOnClickListener(v -> { state = 3; render(); });
        root.addView(out, paramsTop(7, dp(48)));
    }

    private View statusHero() {
        LinearLayout box = panelBox();
        int color = state == 2 ? RED : (state == 1 ? YELLOW : GREEN);
        String title;
        String msg;
        if (state == 2) {
            title = "ALERTA SOS";
            msg = "Se activo una alerta critica. Contacta al atleta o responsable y revisa la ultima ubicacion.";
        } else if (state == 1) {
            title = "Observar";
            msg = "Hay senal, pero el sistema detecta una condicion que requiere atencion.";
        } else if (state == 3) {
            title = "Salio del agua";
            msg = "Sesion finalizada. Ultima ubicacion registrada cerca de la costa.";
        } else {
            title = "Vitto esta nadando";
            msg = "Seguimiento activo. Dentro de zona segura demo y con senal reciente.";
        }
        TextView t = text(title, state == 2 ? 34 : 30, color, true);
        TextView d = text(msg, 16, MUTED, false);
        box.addView(t);
        box.addView(d);
        return box;
    }

    private String explanation() {
        if (state == 2) return "Accion sugerida: llamar al atleta, contacto principal o responsable del evento. Save Swimmer muestra la ultima ubicacion conocida y mantiene la alerta visible.";
        if (state == 1) return "Accion sugerida: observar. Puede ser baja senal, pausa, salida de zona o falta de avance.";
        if (state == 3) return "El atleta salio del agua. Si no regreso al punto esperado, la ubicacion de salida ayuda a buscarlo.";
        return "Todo normal. La familia no necesita interpretar datos tecnicos; solo saber que la sesion sigue activa y sin alerta.";
    }

    private View metric(String label, String value, String note) {
        LinearLayout box = panelBox();
        box.addView(text(label, 13, MUTED, false));
        TextView v = text(value, 25, TEXT, true);
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

    public static class FamilyMapView extends View {
        Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        int state;

        public FamilyMapView(android.content.Context c, int state) {
            super(c);
            this.state = state;
            setBackgroundColor(Color.rgb(7, 29, 37));
        }

        @Override
        protected void onDraw(Canvas c) {
            super.onDraw(c);
            int w = getWidth();
            int h = getHeight();
            p.setStrokeWidth(2);
            p.setColor(LINE);
            for (int i = 1; i < 5; i++) {
                float x = w * i / 5f;
                c.drawLine(x, 28, x, h - 28, p);
            }
            for (int i = 1; i < 4; i++) {
                float y = h * i / 4f;
                c.drawLine(28, y, w - 28, y, p);
            }

            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(4);
            p.setColor(Color.argb(190, 40, 215, 236));
            Path route = new Path();
            route.moveTo(44, h - 54);
            route.lineTo(w * .25f, h * .66f);
            route.lineTo(w * .48f, h * .58f);
            route.lineTo(w * .66f, h * .42f);
            route.lineTo(w * .78f, h * .36f);
            c.drawPath(route, p);

            p.setStyle(Paint.Style.FILL);
            p.setColor(ORANGE);
            c.drawCircle(48, h - 54, 14, p);
            p.setColor(state == 2 ? RED : (state == 1 ? YELLOW : CYAN));
            c.drawCircle(w * .78f, h * .36f, 22, p);
            p.setColor(Color.WHITE);
            c.drawCircle(w * .78f, h * .36f, 9, p);

            p.setTextSize(18);
            p.setFakeBoldText(true);
            p.setColor(TEXT);
            c.drawText("BASE", 34, h - 24, p);
            c.drawText("ATLETA", w * .70f, h * .36f - 34, p);
            p.setFakeBoldText(false);
            p.setTextSize(16);
            p.setColor(MUTED);
            c.drawText("Mapa demo: luego usara ubicacion real autorizada", 34, 42, p);
            p.setStyle(Paint.Style.FILL);
        }
    }
}
