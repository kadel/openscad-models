// Rugged Box - parametric OpenSCAD port of the Fusion 360 design
// "Rugged Box Parametric V2". Parameter names match the Fusion user parameters.
//
// Based on "Rugged Box (Parametric)" by Whity,
// https://www.printables.com/model/258431-rugged-box-parametric
// Licensed under CC BY-NC-SA 4.0, see LICENSE.
//
// Frame: X = depth (hinge on -X, latches on +X), Y = width, Z = up. Units: mm.
// Parts: box (bottom), lid, latch (x2), seal (TPU). Hardware: 4x M3 screws of ScrewLength.

/* [Output] */
part = "print_plate"; // [assembly, box, lid, latch, seal, print_plate]
// Lid opening angle in the assembly view (0 = closed)
lid_open_angle = 0; // [0:5:180]
// Include the latches / seal in the assembly and print_plate views
show_latches = true;
show_seal = false;

/* [Box] */
// Inner width
InnerBoxWidth = 180;
// Inner depth
InnerBoxDepth = 100;
// Inner height of the bottom part
InnerBoxBottomHeight = 50;
// Inner height of the lid
InnerBoxLidHeight = 10;
// Thickness of the walls
WallThickness = 2.4;
// Corner radius on the bottom (bottom of chamfer)
InnerCornerRadius = 3;
// Size of the chamfer on the top and bottom inside the box
InnerChamferSize = 2;

/* [Ribs] */
// Width of the ribs on the sides
RibWidth = 5;
// Offset of the ribs from inner wall
RibOffset = 18;

/* [Screws] */
// M3 => 3 mm
ScrewDiameter = 3;
// Length of the screw to use
ScrewLength = 30;
// Diameter of the inner holes where you screw in the screw
ScrewThreadDiameter = ScrewDiameter - 0.15;

/* [Hinge and latch] */
// Offset of the hinge and latch from inner wall
HingeLatchOffset = 12;
// Width of the ribs for the hinges and latches
HingeLatchRibWidth = 3.2;
// Outer diameter of the hinge
HingeOuterDiameter = 6.8;
// How much the outer parts of the hinge are extended (only increase with screws >= 30 mm)
HingeOuterExtend = 3;
// Distance between the two screws of the latch
LatchDistance = 16;
// Offset of the big chamfer on the latch rib of the box (smaller = easier to open)
BoxLatchRibChamferOffset = 17;
// Offset of the big chamfer on the latch rib of the lid
LidLatchRibChamferOffset = 10;
// Offset of the big chamfer on the hinge ribs of the box
HingeRibChamferOffset = 5;
// Offset of the big chamfer on the hinge rib of the lid (0 matches the Fusion body)
LidHingeRibChamferOffset = 0;

/* [Tolerances] */
// Tolerance of the hinge (width)
HingeWidthTolerance = 0.25;
// Tolerance of the hinge and latch holes
HingeLatchHolesTolerance = 0.4;
// Tolerance of the latch width
LatchWidthTolerance = 0.4;

/* [Seal] */
// Height of the seal
SealHeight = 1.4;
SealGrooveOffset = 1.23;
SealGrooveWidth = 1.8;
SealGrooveDepth = 2;
// Lid tongue that presses on the seal
TongueClearance = 0.15;
TongueHeight = 0.9;

/* [Advanced profile] */
LipOverhang = 1.86;
LipHeight = 3;
LipChamferHeight = 4.4;
BottomChamfer = 3.406;
RibBottomChamfer = 2.635;
HingeLatchRibDepth = 7;
HingeLatchRibBottomChamfer = 3.073;
LatchRibTopRadius = 5;
LatchHoleInset = 4.5;

/* [Latch] */
LatchBossDiameter = 8;
LatchHoleDiameter = ScrewDiameter + 0.2;
LatchBandWidth = 3.2;
LatchArcRadius = 20.274;
LatchTabLength = 10;
// Tab angle from the pivot line, outward
LatchTabAngle = 18.5;
// Snap mouth: chord offset below the box-side hole center
LatchMouthOffset = 1.25;
LatchSlitAngle = 9.1;

/* [Quality] */
$fn = 64;

/* [Hidden] */
// ---------------------------------------------------------------- derived
eps = 0.01;
c = InnerChamferSize;
w = WallThickness;
hx = InnerBoxDepth / 2 - c;      // sweep path half sizes (bottom of inner chamfer)
hy = InnerBoxWidth / 2 - c;
o_wall = c + w;                  // profile offsets measured outward from the path
o_lip = o_wall + LipOverhang;
o_out = o_lip + HingeLatchRibDepth;
T_box = InnerBoxBottomHeight + w;
T_lid = InnerBoxLidHeight + w;
hinge_o = o_lip + HingeOuterDiameter / 2 + 0.2;
latch_hole_o = o_out - LatchHoleInset;
clear_d = ScrewDiameter + HingeLatchHolesTolerance;
y_out = InnerBoxWidth / 2 - HingeLatchOffset;
y_in = y_out - ScrewLength;
y_mid = (y_out + y_in) / 2;
lid_knuckle_w = ScrewLength - 2 * HingeLatchRibWidth - HingeWidthTolerance - 2 * HingeOuterExtend;
latch_thickness = ScrewLength - 2 * HingeLatchRibWidth - LatchWidthTolerance;
groove_o = c + SealGrooveOffset;

// ---------------------------------------------------------------- helpers
module rrect(ax, ay, r) {
    offset(r = r) square([2 * (ax - r), 2 * (ay - r)], center = true);
}

// Sweep a 2D profile (x = outward offset from path, y = height) around the
// rounded-rectangle path, like Fusion's Sweep1.
module ring_sweep(ax, ay, r) {
    for (s = [[1, 1], [-1, 1], [-1, -1], [1, -1]])
        translate([s[0] * (ax - r), s[1] * (ay - r), 0])
            rotate(atan2(s[1], s[0]) - 45)
                rotate_extrude(angle = 90) translate([r, 0]) children();
    for (k = [0 : 3]) {
        along = (k % 2 == 0) ? ay : ax;
        across = (k % 2 == 0) ? ax : ay;
        rotate(k * 90) translate([across - r, 0, 0]) rotate([90, 0, 0])
            linear_extrude(2 * (along - r) + eps, center = true)
                translate([r, 0]) children();
    }
}

// Place a 2D wall profile on the +X wall, extruded over Y in [y0, y1].
module on_x_wall(y0, y1) {
    translate([hx, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
}

// Place a 2D wall profile on the +Y wall, extruded over X in [x0, x1].
module on_y_wall(x0, x1) {
    rotate(90) translate([hy - hx, 0, 0]) on_x_wall(-x1, -x0) children();
}

// ---------------------------------------------------------------- profiles
module shell_profile(T, lid) {
    polygon(concat(
        [[0, 0], [o_wall - BottomChamfer, 0], [o_wall, BottomChamfer],
         [o_wall, T - LipHeight - LipChamferHeight], [o_lip, T - LipHeight], [o_lip, T]],
        lid ? [] : [[groove_o + SealGrooveWidth, T], [groove_o + SealGrooveWidth, T - SealGrooveDepth],
                    [groove_o, T - SealGrooveDepth], [groove_o, T]],
        [[c, T], [c, w + c], [0, w]]));
    if (lid)
        polygon([[groove_o + TongueClearance, T - eps],
                 [groove_o + SealGrooveWidth / 2, T + TongueHeight],
                 [groove_o + SealGrooveWidth - TongueClearance, T - eps]]);
}

module side_rib_profile(T) {
    polygon([[0, 0], [o_lip - RibBottomChamfer, 0], [o_lip, RibBottomChamfer],
             [o_lip, T - LipHeight], [c, T - LipHeight], [c, w + c], [0, w]]);
}

// Hinge or latch rib: inner rib + outer part above the big 45° chamfer.
module hl_rib_profile(kind, T, chamfer_off, hole_d) {
    hole_pos = kind == "hinge" ? [hinge_o, T] : [latch_hole_o, T - LatchDistance / 2];
    R = LatchRibTopRadius;
    difference() {
        union() {
            side_rib_profile(T);
            intersection() {
                if (kind == "hinge")
                    polygon([[o_lip, 0], [o_out - HingeLatchRibBottomChamfer, 0],
                             [o_out, HingeLatchRibBottomChamfer], [o_out, T], [o_lip, T]]);
                else
                    polygon(concat(
                        [[o_lip, 0], [o_out - HingeLatchRibBottomChamfer, 0],
                         [o_out, HingeLatchRibBottomChamfer]],
                        [for (a = [0 : 5 : 90]) [o_out - R + R * cos(a), T - R + R * sin(a)]],
                        [[o_lip, T]]));
                polygon([[o_lip, T - chamfer_off - (o_out - o_lip)], [o_out, T - chamfer_off],
                         [o_out, T + 1], [o_lip, T + 1]]);
            }
            if (kind == "hinge") translate([hinge_o, T]) circle(d = HingeOuterDiameter);
        }
        translate(hole_pos) circle(d = hole_d);
    }
}

// Extended outer part of the box hinge knuckle with its 45° support.
module hinge_support_profile(T, hole_d) {
    r = HingeOuterDiameter / 2;
    tp = [hinge_o + r * cos(45), T - r * sin(45)];
    difference() {
        union() {
            translate([hinge_o, T]) circle(r = r);
            polygon([tp, [c, tp[1] - (tp[0] - c)], [c, T - LipHeight],
                     [o_lip, T - LipHeight], [o_lip, T], [hinge_o, T]]);
        }
        translate([hinge_o, T]) circle(d = hole_d);
    }
}

// ---------------------------------------------------------------- parts
module shell(T, lid) {
    linear_extrude(w) rrect(hx, hy, InnerCornerRadius);
    ring_sweep(hx, hy, InnerCornerRadius) shell_profile(T, lid);
    // side ribs on the short (+-Y) walls
    x1 = InnerBoxDepth / 2 - RibOffset;
    for (sx = [0, 1], sy = [0, 1]) mirror([sx, 0, 0]) mirror([0, sy, 0])
        on_y_wall(x1 - RibWidth, x1) side_rib_profile(T);
}

module box() {
    rw = HingeLatchRibWidth;
    shell(T_box, false);
    for (sy = [0, 1]) mirror([0, sy, 0]) {
        // latch ribs (+X): clearance hole outside, thread hole inside
        on_x_wall(y_out - rw, y_out) hl_rib_profile("latch", T_box, BoxLatchRibChamferOffset, clear_d);
        on_x_wall(y_in, y_in + rw) hl_rib_profile("latch", T_box, BoxLatchRibChamferOffset, ScrewThreadDiameter);
        // hinge knuckles (-X)
        mirror([1, 0, 0]) {
            on_x_wall(y_out - rw, y_out) hl_rib_profile("hinge", T_box, HingeRibChamferOffset, clear_d);
            on_x_wall(y_in, y_in + rw) hl_rib_profile("hinge", T_box, HingeRibChamferOffset, ScrewThreadDiameter);
            on_x_wall(y_out - rw - HingeOuterExtend, y_out) hinge_support_profile(T_box, clear_d);
            on_x_wall(y_in, y_in + rw + HingeOuterExtend) hinge_support_profile(T_box, ScrewThreadDiameter);
        }
    }
}

module lid() {
    rw = HingeLatchRibWidth;
    shell(T_lid, true);
    for (sy = [0, 1]) mirror([0, sy, 0]) {
        on_x_wall(y_out - rw, y_out) hl_rib_profile("latch", T_lid, LidLatchRibChamferOffset, clear_d);
        on_x_wall(y_in, y_in + rw) hl_rib_profile("latch", T_lid, LidLatchRibChamferOffset, ScrewThreadDiameter);
        mirror([1, 0, 0]) {
            // center knuckle between the box knuckles + its support rib
            on_x_wall(y_mid - lid_knuckle_w / 2, y_mid + lid_knuckle_w / 2)
                translate([hinge_o, T_lid]) difference() {
                    circle(d = HingeOuterDiameter);
                    circle(d = clear_d);
                }
            on_x_wall(y_mid - rw / 2, y_mid + rw / 2)
                hl_rib_profile("hinge", T_lid, LidHingeRibChamferOffset, clear_d);
        }
    }
}

// Latch outline. Origin = box-side (snap) pivot, +Y towards the lid pivot,
// +X = away from the box wall.
module latch_2d() {
    D = LatchDistance;
    R = LatchArcRadius;
    bw = LatchBandWidth;
    ctr = [-sqrt(R * R - D * D / 4), D / 2];
    module band() {
        intersection() {
            translate(ctr) difference() { circle(r = R + bw / 2, $fn = 192); circle(r = R - bw / 2, $fn = 192); }
            polygon([ctr, ctr + 3 * ([0, 0] - ctr), ctr + 3 * ([0, D] - ctr)]);
        }
    }
    hr = LatchHoleDiameter / 2;
    mo = LatchMouthOffset;
    difference() {
        union() {
            band();
            circle(d = LatchBossDiameter);
            translate([0, D]) circle(d = LatchBossDiameter);
            hull() {
                circle(d = bw);
                translate(LatchTabLength * [sin(LatchTabAngle), -cos(LatchTabAngle)]) circle(d = bw);
            }
        }
        circle(d = LatchHoleDiameter);
        translate([0, D]) circle(d = LatchHoleDiameter);
        // snap-in mouth towards the box wall
        difference() {
            intersection() {
                circle(d = LatchBossDiameter + 2 * eps);
                polygon([[0, 0], [-sqrt(hr * hr - mo * mo), -mo], [-10, -mo], [-10, 10],
                         [0, hr] + 12 * [-sin(LatchSlitAngle), cos(LatchSlitAngle)], [0, hr]]);
            }
            band();
        }
    }
}

module latch() { linear_extrude(latch_thickness) latch_2d(); }

module seal() {
    linear_extrude(SealHeight) difference() {
        offset(r = groove_o + SealGrooveWidth) rrect(hx, hy, InnerCornerRadius);
        offset(r = groove_o) rrect(hx, hy, InnerCornerRadius);
    }
}

// ---------------------------------------------------------------- output
module lid_pose() {
    translate([-hx - hinge_o, 0, T_box]) rotate([0, -lid_open_angle, 0])
        translate([hx + hinge_o, 0, -T_box]) children();
}

module assembly() {
    color("firebrick") box();
    if (show_seal) color("black") translate([0, 0, T_box - SealGrooveDepth]) seal();
    lid_pose() {
        color("indianred") translate([0, 0, T_box + T_lid]) rotate([180, 0, 0]) lid();
        if (show_latches)
            for (sy = [-1, 1])
                color("dimgray") translate([hx + latch_hole_o, sy * y_mid, T_box - LatchDistance / 2])
                    rotate([90, 0, 0]) linear_extrude(latch_thickness, center = true) latch_2d();
    }
}

module print_plate() {
    gap = 10;
    dx = 2 * (hx + o_out) + gap;
    box();
    translate([dx, 0, 0]) lid();
    if (show_latches)
        for (i = [0, 1]) translate([-hx - o_out - 25 - i * 25, -10, 0]) latch();
    if (show_seal) translate([0, 2 * (hy + o_out) + gap, 0]) seal();
}

if (part == "assembly") assembly();
else if (part == "box") box();
else if (part == "lid") lid();
else if (part == "latch") latch();
else if (part == "seal") seal();
else if (part == "print_plate") print_plate();
