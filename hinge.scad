// A library to create print-in-place horizontal hinges.
//
// Example:
module bottomWedge(r, d, rodH, tolerance, other) {
  wedgeH = (r + tolerance) * sin(45);
  wedgeBottom = max(r + tolerance, d);
  wedgeFlip = other ? 1 : -1;
  linear_extrude(height = rodH)
  polygon(points=[
    [wedgeH,wedgeFlip*-r],
    [wedgeH,wedgeFlip*wedgeH],
    [wedgeBottom,wedgeFlip*(wedgeH - (wedgeBottom - wedgeH))],
    [wedgeBottom,wedgeFlip*-r]
  ]);
}

module hingeRodNegative(r, d, h, tolerance, tip, other) {
  difference() {
    translate([0,0,d])
    rotate([0,90,0]) {
      translate([0, 0, -tolerance/2]) {
        rodH = h  + (tip ? tolerance/2 : 0) + tolerance/2;
        cylinder(r = r + tolerance, h = rodH);
        bottomWedge(r, d, rodH, tolerance, other);
      }
      if (tip) {
        translate([0,0,h])
        cylinder(r = r, h = tolerance + 0.01);
        translate([0,0,h + tolerance])
        cylinder(r1 = r, r2 = 0, h = r + tolerance);
      } else {
        translate([0,0,h])
        cylinder(r = r + tolerance, h = tolerance / 2);
      }
    }
    translate([
      -tolerance/2 - 0.01,
      other ? -r - tolerance : 0,
      -0.01])
    cube([h + tolerance + + 0.02 + (tip ? r + tolerance * 1.5 : 0), r + tolerance, d + r + tolerance + 0.02]);
  }
}

module hingeRod(r, d, h, tip, dip, tolerance, negative, other) {
  if (negative) {
    hingeRodNegative(r, d, h, tolerance, tip, other);
  } else {
    toleranceTip = tip ? tolerance/2 : 0;
    toleranceDip = dip ? tolerance/2 : 0;
    translate([0,0,d])
    rotate([0,90,0])
    difference() {
      union() {
        rodH = h - toleranceTip - toleranceDip;
        translate([0,0,toleranceDip]) {
          cylinder(r = r, h = rodH);
          bottomWedge(r, d, rodH, 0, !other);
        }
        if (tip) {
          translate([0,0,h - toleranceTip - 0.01])
          cylinder(r1 = r, r2 = 0, h = r + 0.01);
        }
      }
      if (dip) {
        translate([0,0,toleranceDip-0.01])
        cylinder(r1 = r, r2 = 0, h = r + tolerance);
      }
    }
  }
}

function xor(a, b) = (a && !b) || (b && !a);

module hingeCorner(r, cornerHeight, hingeLength, pieces, other, negative, tolerance) {
  startAtFirst = xor(other, negative);
  for (i = [1:pieces]) {
    if (i % 2 == (startAtFirst ? 0 : 1)) {
      translate([hingeLength / pieces * (i - 1),0,0])
      hingeRod(r, cornerHeight, hingeLength / pieces, i != pieces || cornerHeight > (hingeLength / pieces), i != 1, tolerance, negative, other);
    }
  }
}

module applyHingeCorner(position = [0,0,0], rotation = [0,0,0], r = 3, cornerHeight = 5, hingeLength = 15, pieces = 3, tolerance = 0.3) {
  translate(position)
  for (i = [0:1]) {
    difference() {
      translate(-position)
      children(i);
      rotate(rotation)
      hingeCorner(r, cornerHeight, hingeLength, pieces, i == 0, true, tolerance);
    }
    rotate(rotation)
    hingeCorner(r, cornerHeight, hingeLength, pieces, i == 0, false, tolerance);
  }
  if ($children > 2) {
    children([2:$children-1]);
  }
}

module applyHinges(positions, rotations, r, cornerHeight, hingeLength, pieces, tolerance) {
  difference() {
    children();
    for (j = [0 : 1 : len(positions) - 1]) {
      translate(positions[j])
      rotate([0,0, rotations[j]])
      for (b = [0, 1]) {
        hingeCorner(r, cornerHeight, hingeLength, pieces, b == 0, true, tolerance);
      }
    }
  }
  for (j = [0 : 1 : len(positions) - 1]) {
    translate(positions[j])
    rotate([0,0, rotations[j]])
    for (b = [0, 1]) {
      hingeCorner(r, cornerHeight, hingeLength, pieces, b == 0, false, tolerance);
    }
  }
}

module negativeExtraAngle(position, rotation, cornerHeight, centerHeight, hingeLength, pieces, tolerance, other, angle) {
  translate(position)
  rotate(rotation) {
    startAtFirst = !other;
    l = (cornerHeight + tolerance - centerHeight) / tan(90-angle / 2);
    for (i = [1 : pieces]) {
      if (i % 2 == (startAtFirst ? 0 : 1)) {
        dip = i != 1;
        w = hingeLength / pieces + (dip ? 1 : 0.5) * tolerance;
        positionX = (i - 1) * hingeLength / pieces + (dip ? -tolerance / 2 : 0);
        difference() {
          translate([ positionX, 0, centerHeight])
          rotate([other ? -angle : angle, 0, 0])
          translate([0, other ? -l : 0, -centerHeight])
          cube([w, l, cornerHeight + tolerance]);
          
          translate([positionX - 0.01, other ? -cornerHeight + 0.01 : -0.01, 0])
          cube([w + 0.02, cornerHeight, 2 * cornerHeight]);
          
          diffY = norm([l, cornerHeight + tolerance]);
          translate([positionX - 0.01, other? -0.01 : -diffY - 2 * tolerance + 0.01, cornerHeight + 0.01])
          cube([w + 0.02, diffY + 2 * tolerance, diffY]);
        }
      }    
    }
  }
}

module applyExtraAngle(positions, rotations, cornerHeight, centerHeight, hingeLength, pieces, tolerance, angle) {
  difference() {
    children();
    for (j = [0 : 1 : len(positions) - 1]) {
      negativeExtraAngle(positions[j], rotations[j], cornerHeight, centerHeight, hingeLength, pieces, tolerance, false, angle);
      negativeExtraAngle(positions[j], rotations[j], cornerHeight, centerHeight, hingeLength, pieces, tolerance, true, angle);
    }
  }
}
/*
difference() {
  union() {
    translate([-5,0.5,0])
    cube([70,60,7]);
    translate([-5,-60.5,0])
    cube([70,60,7]);
  }
  hingeCorner(7/2, 7/2, 60, 6, true, true, 0.5);
  negativeExtraAngle([0,0,0], [0,0,0], 7/2, 7/2, 50, 5, 0.5, false, 30);
  hingeCorner(7/2, 7/2, 60, 6, false, true, 0.5);
  negativeExtraAngle([0,0,0], [0,0,0], 6/2, 6/2, 50, 5, 0.5, false, 30);
}
hingeCorner(7/2, 7/2, 60, 6, true, false, 0.5);
hingeCorner(7/2, 7/2, 60, 6, false, false, 0.5);
*/

/*
difference() {
  translate([-5,-60.5,0])
  cube([70,60,7]);
  negativeExtraAngle([0,0,0], [0,0,0], 7, 3.5, 60, 5, 0.5, false, 120);
  hingeCorner(3.5, 3.5, 60, 5, false, true, 0.5);
}
*/