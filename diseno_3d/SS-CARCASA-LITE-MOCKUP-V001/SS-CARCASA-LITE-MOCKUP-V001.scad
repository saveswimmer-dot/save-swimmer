// Save Swimmer Lite - mockup conceptual V001
// Unidad: mm. Pensado para revisar volumen, postura dorsal y paso de correa.
// No es una carcasa estanca final ni reemplaza diseno mecanico industrial.

$fn = 48;

body_len = 95;
body_w = 55;
body_h = 22;
corner_r = 14;
wall_hint = 2.2;

strap_w = 22;
strap_gap = 2.4;
strap_depth = 3.5;

module rounded_box(size=[10,10,10], r=2) {
    hull() {
        for (x=[-size[0]/2+r, size[0]/2-r])
        for (y=[-size[1]/2+r, size[1]/2-r])
        for (z=[-size[2]/2+r, size[2]/2-r])
            translate([x,y,z]) sphere(r=r);
    }
}

module soft_capsule(len, wid, h, r) {
    scale([1,1,0.72])
        rounded_box([len, wid, h], r);
}

module strap_tunnel() {
    // Canal pasante para velcro/correa dorsal. La pieza impresa permite sentir
    // posicion y volumen; en carcasa final deberia resolverse con sello y refuerzo.
    translate([0, 0, -body_h*0.20])
        cube([body_len + 8, strap_w, strap_depth], center=true);
}

module bottom_relief() {
    // Alivio inferior para que apoye mejor sobre gorra/neopreno.
    translate([0, 0, -body_h*0.47])
        scale([1.0, 0.72, 0.22])
            cylinder(h=body_h, r=body_w*0.62, center=true);
}

module top_lid() {
    translate([0, 0, body_h*0.27])
        scale([1,1,0.18])
            rounded_box([72, 36, 4], 8);
}

module antenna_zone() {
    translate([body_len*0.23, 0, body_h*0.45])
        scale([1,1,0.10])
            rounded_box([22, 32, 2.4], 5);
}

module button_led_zone() {
    translate([-body_len*0.31, 0, body_h*0.50]) {
        cylinder(h=2.0, r=4.2, center=true);
        translate([12, 0, 0]) cylinder(h=1.8, r=2.2, center=true);
    }
}

module screw_markers() {
    for (x=[-body_len*0.36, body_len*0.36])
    for (y=[-body_w*0.32, body_w*0.32])
        translate([x,y,body_h*0.43])
            cylinder(h=2.1, r=1.8, center=true);
}

module save_swimmer_mockup() {
    difference() {
        union() {
            soft_capsule(body_len, body_w, body_h, corner_r);
            top_lid();
            antenna_zone();
            button_led_zone();
            screw_markers();
        }
        strap_tunnel();
        bottom_relief();
    }
}

save_swimmer_mockup();
