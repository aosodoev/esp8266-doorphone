include<MCAD/units.scad>
include<MCAD/boxes.scad>
include<fillets.scad>
include<scad-utils/morphology.scad>
include<scad-utils/mirror.scad>

e = epsilon;
fitting_tolerance = 0.1;

tube_diameter = 13;


     inner_size = [26, 50, 25];
    
     base_thickness = 3;
     thickness = 1.6;
     outer_radius = 5;
     inner_radius = outer_radius - thickness;

     cover_depth = 5;


if (false) {
// door_magnet();
     reed_switch_box();
     translate ([50, 0, 0]) {
	  reed_switch_box_cover();
     }
} else {
     power_box();
     translate ([50, 0, 0]) {
	  power_box_cover();
     }
     
}

module door_magnet() {
     magnet_size = [15, 12, 8.3];
     difference() {
	  minkowski() {
	       translate([0, 0, magnet_size[2]/2]) {
		    cube(magnet_size + [2*10, 0, 0], center = true);
	       }
	       sphere(r = 1.6 + fitting_tolerance, $fn = 64);
	  }
	  translate([0, 0, magnet_size[2]/2 + fitting_tolerance - e]) {
	       cube(magnet_size + [fitting_tolerance, fitting_tolerance, fitting_tolerance]*2, center = true);
	  }
	  translate([-20, -10, -2]) {
	       cube([40, 20, 2]);
	  }
	  mirror_x() {
	       total_height = magnet_size[2] + 1.6 + fitting_tolerance;
	       translate([magnet_size[0]/2 + 6, 0, -e]) {
		    cylinder(total_height + e*2, r = 2, $fn = 32);
		    translate([0, 0, total_height - 2]) {
			 cylinder(2 + 2*e, r1 = 2, r2 = 4, $fn = 32);
		    }
	       }
	  }
     }
     mirror_y() {
	  translate([0, magnet_size[1]/2 + fitting_tolerance + 0.15, 2]) {
	       rotate([0, 90, 0]) {
		    cylinder(5, r = 0.3, center = true, $fn = 20);
	       }
	  }
     }
}


module reed_switch_box() {
     difference() {
	  union() {
	       linear_extrude(inner_size[2] + base_thickness - cover_depth) {
		    rounding(outer_radius, $fn = 64) {
			 square(inner_size + [thickness, thickness]*2, center = true);
		    }
	       }
	       translate([0, 0, inner_size[2] + base_thickness - cover_depth - e]) {
		    linear_extrude(cover_depth + e) {
			 rounding(inner_radius, $fn = 64) {
			      square(inner_size + [0, 0], center = true);
			 }
		    }
	       }
	       translate([0, 0, inner_size[2] + base_thickness - cover_depth/2]) {
		    minkowski() {
			 linear_extrude(e) {
			      rounding(inner_radius - 0.2, $fn = 64) {
				   square(inner_size - [0.2, 0.2]*2, center = true);
			      }
			 }
			 sphere(r = 0.4, $fn = 20);
		    }
	       }

	  }
	  translate([0, 0, base_thickness]) {
	       hull() {
		    linear_extrude(inner_size[2] - cover_depth - 3*thickness) {
			 rounding(inner_radius, $fn = 32) {
			      square(inner_size + [0, 0], center = true);
			 }
		    }
		    translate([0, 0, inner_size[2] - cover_depth]) {
			 linear_extrude(e) {
			      rounding(inner_radius - thickness, $fn = 32) {
				   square(inner_size - [thickness, thickness]*2, center = true);
			      }
			 }
		    }
	       }
	       translate([0, 0, inner_size[2] - cover_depth]) {
		    linear_extrude(cover_depth + e) {
			 rounding(inner_radius - thickness, $fn = 32) {
			      square(inner_size - [thickness, thickness]*2, center = true);
			 }
		    }
	       }
	  }
	  translate([0, -inner_size[1]/2 - thickness - e, (inner_size[2] + base_thickness + thickness)/2]) {
	       rotate([-90, 0, 0]) {
		    hull() {
			 for (pos = [0, -50]) {
			      translate([0, pos, 0]) {
				   cylinder(2*thickness + 2*e, r = tube_diameter/2);
			      }
			 }
		    }
		    hull() {
			 for (pos = [0, -50]) {
			      translate([0, pos, 0]) {
				   translate([0, 0, -1]) {
					cylinder(thickness + 2*e, r = 16.5/2);
				   }

			      }
			 }
		    }
	       }
	  }
	  mirror_x() {
	       mirror_y() {
		    union() {
		    translate([inner_size[0]/2 - 5, inner_size[1]/2 - 5, base_thickness - 1]) {
			 cylinder(1 + e, r1 = 1.7, r2 = 3, $fn = 16);
		    }
		    translate([inner_size[0]/2 - 5, inner_size[1]/2 - 5, -e]) {
			 cylinder(base_thickness + 2*e, r = 1.7, $fn = 16);
		    }
		    }
	       }
	  }
	  translate([inner_size[0]/2 - 5, -inner_size[1]/2 - thickness - e, base_thickness + 4]) {
	       rotate([-90, 0, 0]) {
		    cylinder(2*thickness + 2*e, r = 2, $fn = 12);
	       }
	  }

     }
     reed_width = 2.6 + 2*fitting_tolerance;
     mirror_y() {
	  translate([-inner_size[0]/2, 7 - 2, base_thickness + inner_size[2]/2]) {
	       rotate([90, 0, 0]) {
		    linear_extrude(4, center = true) {
			 polygon([[-e, 0], [reed_width, 0], [reed_width, reed_width], [reed_width - 0.4, reed_width + 0.4], [reed_width, reed_width + 0.4*3], [reed_width + 1.2, reed_width + 0.4*3], [reed_width + 1.2, -reed_width], [-e, -reed_width*3]]);
		    }
	       }
	  }
     }
}

module reed_switch_box_cover() {
     
     difference() {
	  union() {
	       linear_extrude(cover_depth + thickness) {
		    rounding(outer_radius, $fn = 64) {
			 square(inner_size + [thickness, thickness]*2, center = true);
		    }
	       }
	       translate([-tube_diameter/2 + 0.5, -inner_size[1]/2 - thickness, 0]) {
		    cube([tube_diameter - 0.5*2, thickness, inner_size[2]/2]);
	       }
	  }
	  translate([0, 0, thickness]) {
	       linear_extrude(cover_depth + e) {
		    rounding(inner_radius + fitting_tolerance, $fn = 32) {
			 square(inner_size + [fitting_tolerance, fitting_tolerance]*2, center = true);
		    }
	       }
	  }
	  translate([0, 0, thickness + cover_depth/2]) {
	       minkowski() {
		    linear_extrude(e) {
			 rounding(inner_radius - 0.2, $fn = 64) {
			      square(inner_size - [0.2, 0.2]*2, center = true);
			 }
		    }
		    sphere(r = 0.5, $fn = 20);
	       }
	  }
	  translate([0, -inner_size[1]/2 - thickness - e, (inner_size[2] + base_thickness + thickness)/2]) {
	       rotate([-90, 0, 0]) {
		    cylinder(2*thickness + 2*e, r = tube_diameter/2);
		    translate([0, 0, -1]) {
			 cylinder(thickness + 2*e, r = 16.5/2);
		    }
	       }
	  }
     }
}

module power_box() {

     inner_size = [35, 45, 20];
    
     base_thickness = 3;
     thickness = 1.6;
     outer_radius = 5;
     inner_radius = outer_radius - thickness;

     cover_depth = 5;

     tube_diameter = 12;
     
     difference() {
	  union() {
	       linear_extrude(inner_size[2] + base_thickness - cover_depth) {
		    rounding(outer_radius, $fn = 64) {
			 square(inner_size + [thickness, thickness]*2, center = true);
		    }
	       }
	       translate([0, 0, inner_size[2] + base_thickness - cover_depth - e]) {
		    linear_extrude(cover_depth + e) {
			 rounding(inner_radius, $fn = 64) {
			      square(inner_size + [0, 0], center = true);
			 }
		    }
	       }
	       translate([0, 0, inner_size[2] + base_thickness - cover_depth/2]) {
		    minkowski() {
			 linear_extrude(e) {
			      rounding(inner_radius - 0.2, $fn = 64) {
				   square(inner_size - [0.2, 0.2]*2, center = true);
			      }
			 }
			 sphere(r = 0.5, $fn = 20);
		    }
	       }

	  }
	  translate([0, 0, base_thickness]) {
	       hull() {
		    linear_extrude(inner_size[2] - cover_depth - 3*thickness) {
			 rounding(inner_radius, $fn = 32) {
			      square(inner_size + [0, 0], center = true);
			 }
		    }
		    translate([0, 0, inner_size[2] - cover_depth]) {
			 linear_extrude(e) {
			      rounding(inner_radius - thickness, $fn = 32) {
				   square(inner_size - [thickness, thickness]*2, center = true);
			      }
			 }
		    }
	       }
	       translate([0, 0, inner_size[2] - cover_depth]) {
		    linear_extrude(cover_depth + e) {
			 rounding(inner_radius - thickness, $fn = 32) {
			      square(inner_size - [thickness, thickness]*2, center = true);
			 }
		    }
	       }
	  }
	  translate([-4, -inner_size[1]/2 - thickness - e, (inner_size[2] + thickness)/2]) {
	       rotate([-90, 0, 0]) {
		    cylinder(2*thickness + 2*e, r = tube_diameter/2);
	       }
	  }
	  mirror_x() {
	       mirror_y() {
		    union() {
		    translate([inner_size[0]/2 - 5, inner_size[1]/2 - 5, base_thickness - 1]) {
			 cylinder(1 + e, r1 = 1.7, r2 = 3, $fn = 16);
		    }
		    translate([inner_size[0]/2 - 5, inner_size[1]/2 - 5, -e]) {
			 cylinder(base_thickness + 2*e, r = 1.7, $fn = 16);
		    }
		    }
	       }
	  }
	  translate([inner_size[0]/2 - 9, -inner_size[1]/2 - thickness - e, base_thickness + 4]) {
	       rotate([-90, 0, 0]) {
		    cylinder(2*thickness + 2*e, r = 2, $fn = 12);
	       }
	  }

     }
}

module power_box_cover() {

     inner_size = [35, 45, 20];
    
     base_thickness = 3;
     thickness = 1.6;
     outer_radius = 5;
     inner_radius = outer_radius - thickness;

     cover_depth = 5;
     
     difference() {
	  union() {
	       linear_extrude(cover_depth + thickness) {
		    rounding(outer_radius, $fn = 64) {
			 square(inner_size + [thickness, thickness]*2, center = true);
		    }
	       }
	  }
	  translate([0, 0, thickness]) {
	       linear_extrude(cover_depth + e) {
		    rounding(inner_radius + fitting_tolerance, $fn = 32) {
			 square(inner_size + [fitting_tolerance, fitting_tolerance]*2, center = true);
		    }
	       }
	  }
	  translate([0, 0, thickness + cover_depth/2]) {
	       minkowski() {
		    linear_extrude(e) {
			 rounding(inner_radius - 0.2, $fn = 64) {
			      square(inner_size - [0.2, 0.2]*2, center = true);
			 }
		    }
		    sphere(r = 0.6, $fn = 20);
	       }
	  }
     }
}
