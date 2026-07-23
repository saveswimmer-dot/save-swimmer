// Save Swimmer Lite - mockup conceptual V002
// Unidad: mm. Lenguaje visual tipo tracker dorsal compacto.
// No es carcasa estanca final: sirve para imprimir volumen y conversar con diseno industrial.

$fn = 64;

body_len = 74;
body_w = 56;
body_h = 18;
corner_r = 12;

module rounded_box(size=[10,10,10], r=2) {
    hull() {
        for (x=[-size[0]/2+r, size[0]/2-r])
        for (y=[-size[1]/2+r, size[1]/2-r])
        for (z=[-size[2]/2+r, size[2]/2-r])
            translate([x,y,z]) sphere(r=r);
    }
}

module main_shell() {
    difference() {
        scale([1,1,0.62]) rounded_box([body_len, body_w, body_h], corner_r);
        // Curva inferior suave para que no apoye con aristas.
        translate([0, 0, -body_h*0.50])
            scale([1.05, 0.90, 0.20])
                cylinder(h=body_h, r=body_w*0.60, center=true);
    }
}

module top_lid() {
    translate([0, 0, body_h*0.30])
        scale([1,1,0.12])
            rounded_box([54, 38, 3.2], 9);
}

module lower_clip() {
    // Guia inferior para correa/base flexible. En final debe resolverse con sello/clip real.
    translate([0, -body_w*0.40, -body_h*0.05])
        rounded_box([42, 7, 7], 3);
    translate([0, body_w*0.40, -body_h*0.05])
        rounded_box([42, 7, 7], 3);
}

module side_grips() {
    for (x=[-body_len*0.49, body_len*0.49]) {
        translate([x, -12, -1]) rounded_box([5, 13, 8], 2);
        translate([x, 12, -1]) rounded_box([5, 13, 8], 2);
    }
}

module front_led() {
    translate([0, -body_w*0.515, body_h*0.07])
        rounded_box([34, 3.4, 3.0], 1.6);
}

module sos_button() {
    translate([0, body_w*0.18, body_h*0.46])
        scale([1,1,0.22])
            cylinder(h=3.2, r=6.0, center=true);
}

module screw_markers() {
    for (x=[-body_len*0.34, body_len*0.34])
    for (y=[-body_w*0.31, body_w*0.31])
        translate([x,y,body_h*0.42])
            cylinder(h=2.0, r=1.7, center=true);
}

module top_logo_plate() {
    translate([0, 0, body_h*0.49])
        scale([1,1,0.08])
            rounded_box([28, 18, 1.3], 4);
}

module save_swimmer_lite_v002() {
    union() {
        main_shell();
        top_lid();
        lower_clip();
        side_grips();
        front_led();
        sos_button();
        screw_markers();
        top_logo_plate();
    }
}

save_swimmer_lite_v002();
