// OpenClaw mascot: 3D version of icon.png
// Units: mm. Z is up, the mascot faces -Y.
//
// ./export.sh writes all print sets into stl/<set>/. Export a single part with e.g.
//   openscad -D 'part="front"' -o front.stl openclaw.scad
//
// part =
//   "all"           assembled preview (colored)
//   "plate"         all printable parts laid out in print orientation (preview)
//   -- split print (recommended, almost no supports) --
//   "front"         front half with antennae, lying on its back, cut face down
//   "back"          back half, cut face down
//   -- eyes, separate pieces glued in (single-material printers) --
//   "eyes_glued"    two eye pieces, flat back down
//   "pupils_glued"  two pupil pieces, flat back down
//   -- eyes, multi-material (load together with "front" as one object) --
//   "front_eyes"    eyes placed to match "front"
//   "front_pupils"  pupils placed to match "front"
//   -- one-piece print (needs supports under the body) --
//   "body"          whole body with base, antennae and eye recesses
//   "eyes"          eye pieces in assembled position
//   "pupils"        pupil pieces in assembled position
//
// Halves are aligned with 1.75 mm filament pieces as dowels (pin_d holes,
// pin_depth deep on each side) and glued.
//
// Eyes sit in flat-bottomed recesses in the face; pupils sit in shallow pockets
// in the eyes. For multi-material prints set glue_gap = 0 so parts touch.

part = "all";

$fn = 96;

// ---------- Dimensions ----------
base_h     = 3;                // stand under the feet
base_rx    = 26;
base_ry    = 20;

leg_h      = 11;               // visible leg height between base and body
body_rx    = 32;               // half width
body_ry    = 27;               // half depth
body_rz    = 31;               // half height
body_z     = base_h + leg_h + body_rz - 3;  // body center (legs tuck into the body a bit)

eye_r      = 4.6;
eye_dx     = 11.5;             // half distance between eyes
eye_z      = body_z + 15;
pupil_r    = 2.0;
eye_sink   = 1.2;              // eye recess depth below the face surface
eye_dome   = 1.4;              // how far the eye dome rises above the face
pupil_depth = 0.8;             // pupil pocket depth in the eye
pupil_dome = 0.6;              // how far the pupil rises above the eye
glue_gap   = 0.15;             // radial gap around glued eyes and pupils

claw_dx    = 35;               // claw center distance from the axis
claw_z     = body_z + 1;

leg_w      = 9;
leg_d      = 9;
leg_dx     = 9;                // half distance between legs

ant_r      = 1.8;              // antenna thickness (radius)
ant_dx     = 11;               // antenna root distance from the axis
ant_flat   = 0.4;              // flat shaved off the back of the antennae by the cut
ant_y      = -(ant_r - ant_flat);  // antennae sit just in front of the cut plane, so they
                               // print lying flat on the bed as part of the front half

pin_d      = 2.0;              // dowel holes (1.75 mm filament)
pin_depth  = 7;                // per half
pin_chamfer = 0.6;             // 45 deg lead-in at the hole mouth (first layer squish)
pins       = [[16, 0], [-16, 0], [0, 16], [0, -16]];  // [x, z - body_z] on the cut plane

// ---------- Colors (preview only) ----------
// Brand colors from https://openclaws.io/logo/
c_red   = "#FF5A50";   // Claw Red
c_black = "#050810";   // Space Dark
c_teal  = "#00E5CC";   // Reef Teal
// Deep Shell #991B1B is the brand's darker red accent (not used yet)

// ---------- Helpers ----------
module ellipsoid(r) { scale(r) sphere(1); }

// Body is slightly egg-shaped: fuller at the top, like the icon.
module body_shell() {
    translate([0, 0, body_z])
        hull() {
            translate([0, 0, 3])  ellipsoid([body_rx, body_ry, body_rz - 3]);
            translate([0, 0, -4]) ellipsoid([body_rx - 3, body_ry - 2, body_rz - 4]);
        }
}

// Point on the body surface in front direction at height z and x offset.
function front_y(x, z) =
    let(dz = (z - body_z - 3) / (body_rz - 3),
        dx = x / body_rx,
        t  = 1 - dx*dx - dz*dz)
    -body_ry * sqrt(max(t, 0));

// Height of the top of the head at (x, y).
function top_z(x, y) =
    let(dx = x / body_rx, dy = y / body_ry, t = 1 - dx*dx - dy*dy)
    body_z + 3 + (body_rz - 3) * sqrt(max(t, 0));

// Smooth tube following a list of points.
module tube(pts, r) {
    for (i = [0 : len(pts) - 2])
        hull() {
            translate(pts[i])     sphere(r, $fn = 24);
            translate(pts[i + 1]) sphere(r, $fn = 24);
        }
}

// Antenna root on the head, slightly sunk so no gap shows.
function ant_root(side) = [side * ant_dx, ant_y, top_z(ant_dx, ant_y) - 0.8];

// Antenna (arc in the XZ plane): rises straight up out of the head, then
// curls outward. Starts a little inside the head so it fuses cleanly.
module antenna(side) {
    n = 12;
    pts = [for (i = [0 : n])
        let(a = i / n * 120)
        [side * 9 * (1 - cos(a)), 0, 7 * sin(a)]];
    translate(ant_root(side)) {
        tube(concat([[0, 0, -3]], pts), ant_r);
        translate(pts[n]) sphere(ant_r + 0.2, $fn = 24);
    }
}

// Smooth mitten-shaped claw.
module claw(side) {
    translate([side * claw_dx, 0, claw_z])
        rotate([0, side * -15, 0])
        hull() {
            translate([side * 1.5, 0, 1.5]) ellipsoid([8, 7, 7]);
            translate([side * -4, 0, -2])   ellipsoid([5, 6, 5.5]);
        }
}

module leg(side) {
    // overlaps the base and extends up into the body so it fuses cleanly
    translate([side * leg_dx, 0, base_h - 0.5])
        scale([leg_w / 2, leg_d / 2, 1])
        cylinder(r = 1, h = leg_h + 6.5);
}

// Oval stand with a small bottom chamfer against elephant's foot.
module base() {
    hull() {
        scale([base_rx - 0.6, base_ry - 0.6, 1]) cylinder(r = 1, h = 0.6);
        translate([0, 0, 0.6]) scale([base_rx, base_ry, 1]) cylinder(r = 1, h = base_h - 0.6);
    }
}

// Eyes are domes placed on the front of the face.
module eye_pos(side) {
    x = side * eye_dx;
    y = front_y(x, eye_z);
    // aim the eye along the body surface normal so it sits flush
    n = [x / (body_rx * body_rx),
         y / (body_ry * body_ry),
         (eye_z - body_z - 3) / ((body_rz - 3) * (body_rz - 3))];
    ax = atan2(n[2], -n[1]);
    az = atan2(n[0], -n[1]);
    translate([x, y, eye_z])
        rotate([-ax, 0, az])
        translate([0, eye_sink, 0])
        children();
}

// Eye and pupil pieces in eye-local coordinates: origin on the recess floor,
// -Y points out of the face. Both have a flat back for printing.
module half_dome(r, h) {
    intersection() {
        scale([r, h, r]) sphere(1);
        translate([-r, -h, -r]) cube([2 * r, h, 2 * r]);
    }
}

pupil_floor = eye_sink + eye_dome - pupil_depth;  // pocket floor, from recess floor

module eye_local() {
    difference() {
        union() {
            rotate([90, 0, 0]) cylinder(r = eye_r, h = eye_sink);
            translate([0, -eye_sink, 0]) half_dome(eye_r, eye_dome);
        }
        translate([0, -pupil_floor, 0])
            rotate([90, 0, 0]) cylinder(r = pupil_r + glue_gap, h = 5, $fn = 48);
    }
}

module pupil_local() {
    translate([0, -pupil_floor, 0]) {
        rotate([90, 0, 0]) cylinder(r = pupil_r, h = pupil_depth, $fn = 48);
        translate([0, -pupil_depth, 0]) half_dome(pupil_r, pupil_dome);
    }
}

module eye_socket_local() {
    rotate([90, 0, 0]) cylinder(r = eye_r + glue_gap, h = 10);
}

module eyes()        { for (s = [-1, 1]) eye_pos(s) eye_local(); }
module pupils()      { for (s = [-1, 1]) eye_pos(s) pupil_local(); }
module eye_sockets() { for (s = [-1, 1]) eye_pos(s) eye_socket_local(); }

// Flat on the bed: local -Y (outward) becomes +Z.
module eyes_flat() {
    for (s = [-1, 1]) translate([s * (eye_r + 2), 0, 0]) rotate([-90, 0, 0]) eye_local();
}
module pupils_flat() {
    for (s = [-1, 1])
        translate([s * (pupil_r + 2), 0, 0])
        rotate([-90, 0, 0]) translate([0, pupil_floor, 0]) pupil_local();
}

// Everything except the antennae.
module body_core() {
    difference() {
        union() {
            base();
            body_shell();
            for (s = [-1, 1]) {
                claw(s);
                leg(s);
            }
        }
        eye_sockets();
    }
}

// Antennae clipped at the cut plane so they belong to the front half only.
module antennae() {
    intersection() {
        for (s = [-1, 1]) antenna(s);
        front_cut();
    }
}

module body() { union() { body_core(); antennae(); } }

// ---------- Split into front / back halves ----------
big = 200;

module front_cut() { translate([-big/2, -big, -1]) cube([big, big, big]); }   // y <= 0
module back_cut()  { translate([-big/2, 0, -1])    cube([big, big, big]); }   // y >= 0

module pin_holes() {
    for (p = pins)
        translate([p[0], 0, body_z + p[1]])
            rotate([90, 0, 0])
            union() {
                cylinder(d = pin_d, h = 2 * pin_depth, center = true, $fn = 24);
                // lead-in chamfer on both sides of the cut plane
                for (m = [0, 1]) mirror([0, 0, m])
                    cylinder(d1 = pin_d + 2 * pin_chamfer, d2 = pin_d,
                             h = pin_chamfer, $fn = 24);
            }
}

module front_half() { difference() { intersection() { body(); front_cut(); } pin_holes(); } }
// The back half is cut from body_core(): intersecting the antennae with back_cut()
// would leave zero-thickness faces on the cut plane.
module back_half()  { difference() { intersection() { body_core(); back_cut(); } pin_holes(); } }

// Print orientation: cut face (y = 0) on the bed.
module as_front() { rotate([-90, 0, 0]) children(); }  // lying on its back, face up
module as_back()  { rotate([90, 0, 180]) children(); }  // also extends along +Y, like the front

// ---------- Output ----------
if (part == "all") {
    color(c_red)   body();
    color(c_black) eyes();
    color(c_teal)  pupils();
} else if (part == "plate") {
    // halves extend along +Y from the cut-face base; small parts sit below
    translate([-47, 0, 0])   color(c_red)   as_front() front_half();
    translate([47, 0, 0])    color(c_red)   as_back() back_half();
    translate([-10, -12, 0]) color(c_black) eyes_flat();
    translate([15, -12, 0])  color(c_teal)  pupils_flat();
} else if (part == "front") {
    as_front() front_half();
} else if (part == "back") {
    as_back() back_half();
} else if (part == "front_eyes") {
    as_front() eyes();
} else if (part == "front_pupils") {
    as_front() pupils();
} else if (part == "body") {
    body();
} else if (part == "eyes_glued") {
    eyes_flat();
} else if (part == "pupils_glued") {
    pupils_flat();
} else if (part == "eyes") {
    eyes();
} else if (part == "pupils") {
    pupils();
}
