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

module hingeRodNegative(r, d, h, tolerance, tip, dip, corner, other) {
  if (corner) {
    translate([0,0,d])
    rotate([0,90,0]) {
      translate([0,0,dip ? -tolerance/2 : 0]) {
        rodH = h  + (tip ? tolerance/2 : 0) + (dip ? tolerance/2 : 0 );
        cylinder(r = r + tolerance, h = rodH);
        bottomWedge(r, d, rodH, tolerance, other);
      }
      if (tip) {
        translate([0,0,h])
        cylinder(r = r, h = tolerance);
        translate([0,0,h + tolerance])
        cylinder(r1 = r, r2 = 0, h = d/2 - tolerance);
      }
    }
  }
}

module hingeRod(r, d, h, tip, dip, tolerance, negative, corner, other) {
  if (negative) {
    hingeRodNegative(r, d, h, tolerance, tip, dip, corner, other);
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
          translate([0,0,h - toleranceTip])
          cylinder(r1 = r, r2 = 0, h = r - tolerance);
        }
      }
      if (dip) {
        translate([0,0,toleranceDip])
        cylinder(r1 = r, r2 = 0, h = r - tolerance);
      }
    }
  }
}

function xor(a, b) = (a && !b) || (b && !a);

module hingeCorner(r, cornerHeight, hingeLength, pieces, other,  negative,tolerance) {
  startAtFirst = xor(other, negative);
  for (i = [1:pieces]) {
    if (i % 2 == (startAtFirst ? 0 : 1)) {
      translate([hingeLength / pieces * (i - 1),0,0])
      hingeRod(r, cornerHeight, hingeLength / pieces, i != pieces || cornerHeight > (hingeLength / pieces), i != 1, tolerance, negative, true, other);
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
