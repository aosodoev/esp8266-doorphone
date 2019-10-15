include<MCAD/units.scad>
use<fillets.scad>
use<scad-utils/morphology.scad>

e = epsilon;

speaker_radius = 40/2;
speaker_brim_height = 1.5;

mic_board_height = 14.1;
mic_radius = 9.6/2;
mic_height = 6.5;

connector_width = 12;
connector_height = 7;

mfrc_width = 60;
mfrc_height = 40;

main_board_height = 25;
main_board_width = 30;

boards_tolerance = 0.4;
fitting_tolerance = 0.2;

shell_thickness = 1.6;
front_panel_thickness = 2;

inner_width = mfrc_width + 2*boards_tolerance;
outer_width = inner_width + 2*shell_thickness;

inner_height = 170;
outer_height = inner_height + 2*shell_thickness;

inner_depth = 15;
outer_depth = inner_depth + shell_thickness; // only front shell will add up

outer_radius = 3;
inner_radius = outer_radius - shell_thickness;


amp_pos = inner_height - inner_width - 14;
mfrc_pos = amp_pos - 1.2 - (mfrc_height + 2*boards_tolerance);
main_board_pos = mfrc_pos - 1.2 - (main_board_height + 2*boards_tolerance);

view = "explode";

if (view == "explode") {
     translate([0, 0, shell_thickness + 20]) {
	  %color([0.6, 0.3, 0, 0.5]) {
	       back_cover();
	  }
     }
     %color([0.6, 0.3, 0, 0.5]) {
	  back_cover_brim();
     }
     translate([0, 0, 80]) {
	  rotate([0, 180, 0]) {	       
	       main_shell();
	  }
     }
     translate([0, 0, 100]) {
	  color([0.6, 0.3, 0, 0.3]) {
	       render() {
		    front_panel();
	       }
	  }
     }
} else if (view == "speaker-front-cover") {
     main_shell();
} else if (view == "speaker-back-cover") {
     back_cover();
} else if (view == "speaker-brim") {
     back_cover_brim();
} else if (view == "speaker-front-panel") {
     front_panel();
}


// tests
* intersection () {
    back_cover();
    * translate([-outer_width/2, -shell_thickness, 0]) {
        // mic and cable thingy
        cube([outer_width, 27, outer_depth + 2]);
        // main board
        translate([0, main_board_pos + main_board_height/2 - 4, 0])
            cube([outer_width, 12, outer_depth + 2]);
        
        translate([0, mfrc_pos + mfrc_height/2 - 4, 0])
            cube([outer_width, 12, outer_depth + 2]);
    }
}
* intersection() {
    main_shell();
    mirror([1, 0, 0]) {
        translate([0, -5, 0])
        cube([outer_width, outer_height + 8, outer_depth + 20]);
    }
}

module front_panel() {

     speaker_grill_width = inner_width - 8;
     speaker_grill_height = (speaker_radius + 5) * 2 + 6;
     
     difference() {
	  union() {
	       translate([0, outer_height/2 - shell_thickness, 0]) {
		    linear_extrude(front_panel_thickness) {
			 rounding(outer_radius, $fn = 64) {
			      square([outer_width, outer_height], center = true);

			 }
		    }
		    linear_extrude(front_panel_thickness + 2) {
			 shell(d = -3) {
			      rounding(outer_radius, $fn = 64) {
				   square([outer_width, outer_height], center = true);
			      }
			 }
		    }
	       }
	               
	       // button
	       translate([-5 - 6 - shell_thickness, mfrc_pos - 20 + 7 + shell_thickness, 0]) {
		    cylinder(3, r = 6 + 1.6 + fitting_tolerance, $fn = 64);
		    translate([17, -4, 0]) {
			 rotate([0, 0, -10]) {
			      linear_extrude(2 + 0.6) {
				   outset(d=0.3) {
					text("%", font = "Wingdings:style=Bold", size = 12);
				   }
			      }
			 }
		    }
	       }

	       translate([0, mfrc_pos - 20 + 6 + shell_thickness, 0]) {
		    linear_extrude(3) {
			 shell(d = -2) {
			      rounding(4, $fn = 32) {
				   square([speaker_grill_width, (6 + shell_thickness + fitting_tolerance + 2 + 4) * 2], center = true);
			      }
			 }
		    }
	       }

	       translate([0, mfrc_pos + 28, 0]) {
		    linear_extrude(2.4) {
			 shell(d = -1) {
			      rounding(4, $fn = 32) {
				   square([speaker_grill_width, 40], center = true);
			      }
			 }
		    }		    
	       }

	  } // union

	  // speaker compartment
	  translate([0, inner_height - inner_width/2 - fitting_tolerance - 4, -e]) {
	       linear_extrude(3 + 2*e) {
		    inset(d = 2) {
			 rounding(4, $fn = 64) {
			      square([speaker_grill_width, speaker_grill_height], center = true);
			 }
		    }
	       }

	  }

	  // button cutout
	  translate([-5 - 6 - shell_thickness, mfrc_pos - 20 + 7 + shell_thickness, -e]) {
	       cylinder(3 + 2*e, r = 6 + fitting_tolerance, $fn = 64);
	  }

	  // mic cutout
	  translate([0, shell_thickness + mic_board_height/2 + boards_tolerance, 0]) {
	       translate([0, 0, 0.6/2]) {
		    cube([mic_board_height, mic_board_height, 0.6 + 2*e], center = true);
	       }
	       for (y = [-mic_board_height/2:1.2 + 1:mic_board_height/2 - 2]) {
		    translate([0, y, 0.6]) {
			 rotate([0, -90, 0]) {
			      linear_extrude(mic_board_height, center = true) {
				   polygon([
						[3 + e, -0.5],
						[3 + e, 0.5],
						[3 - 0.6, 0.5],
						[-e, 3 - 0.6 + 0.5],
						[-e, 3 - 0.6 - 0.5],
						[3 - 0.6, -0.5]
						]);
			      }
			 }
		    }
	       }
	  }

	  
     } // main difference

     // speaker
     translate([0, inner_height - inner_width/2 - fitting_tolerance - 4, 0]) {
	  
	  linear_extrude(3) {
	       shell(d = -2) {
		    rounding(4, $fn = 64) {
			 square([speaker_grill_width, speaker_grill_height], center = true);
		    }
	       }
	  }
	  difference() {
	       linear_extrude(3) {
		    inset(d = 3) {
			 rounding(4, $fn = 64) {
			      square([speaker_grill_width, speaker_grill_height], center = true);
			 }
		    }
	       }
	       for (y = [-speaker_grill_height/2 + 7:4:speaker_grill_height/2 - 6]) {
		    translate([0, y, 0]) {
			 rotate([0, -90, 0]) {
			      linear_extrude(inner_width, center = true) {
				   polygon([
						[3 + e, -0.5],
						[3 + e, 0.5],
						[3 - 0.6, 0.5],
						[-e, 3 - 0.6 + 0.5],
						[-e, 3 - 0.6 - 0.5],
						[3 - 0.6, -0.5]
						]);
			      }
			 }
		    }
	       }
	  }
	  linear_extrude(1.6) {
	       difference() {
		    inset(d = 3) {
			 rounding(4, $fn = 64) {
			      square([speaker_grill_width, speaker_grill_height], center = true);
			 }
		    }
		    translate([0, 4]) {
			 circle(r = speaker_radius - 2);
		    }
	       }
	  }

	  
     }

}

module main_shell() {
    mfrc_bottom = 0;
    difference() {
        union() {
            difference() {
                translate([-outer_width/2, -shell_thickness, 0]) {
                    linear_extrude(outer_depth) {
                        rounding(outer_radius, $fn = 64) {
                            square([outer_width, outer_height]);
                        }
                    }
                }
                translate([-inner_width/2, 0, shell_thickness]) {
                    linear_extrude(outer_depth + e) {
                        rounding(inner_radius, $fn = 64) {
                            square([inner_width, inner_height]);
                        }
                    }
                }
            } // main shape
            
            // mounting holes
            
            mounting_holes();
            
            // speaker compartment
            translate([0, inner_height - inner_width/2 - fitting_tolerance, 0]) {
                speaker(negative = false);
            }
                        
            // Compartments
            mfrc_top = inner_height - inner_width - 15;
            for (pos = [amp_pos, mfrc_pos, main_board_pos]) {
                translate([-inner_width/2 - e, pos - 1.2, 0]) {
                    cube([inner_width + 2*e, 1.2, inner_depth - 6]);
                }
            }
                        
            // microphone
            translate([0, shell_thickness + mic_board_height/2 + boards_tolerance, 0]) {
                microphone();
            }
            
            // button
            translate([5, mfrc_pos - 20, 0]) {
                button();
            }


        } // main union
        
        // speaker cutout
        translate([0, inner_height - inner_width/2 - fitting_tolerance, 0]) {
            speaker(negative = true);
        }
        
        // mic cutout
        translate([0, shell_thickness + mic_board_height/2 + boards_tolerance, 0]) {
            microphone(negative = true);
        }
        
        // button cutout
        translate([5, mfrc_pos - 20, 0]) {
            button(negative = true);
        }
        
        
    } // difference
}

module back_cover_brim() {
     brim_width = 3;
     total_width = outer_width + 2*fitting_tolerance + 2*shell_thickness + 2*brim_width;
     total_height = outer_height + 2*fitting_tolerance + 2*shell_thickness + 2*brim_width;
     difference() {
	  union() {
	       hull() {
		    translate([-total_width/2, -2*shell_thickness - brim_width - fitting_tolerance, 0]) {
			 linear_extrude(shell_thickness) {
			      rounding(outer_radius + 2, $fn = 64) {
				   square([total_width, total_height]);
			      }
			 }
		    }
		    translate([-total_width/2 + brim_width, -2*shell_thickness - fitting_tolerance, 0]) {
			 linear_extrude(shell_thickness + 4) {
			      rounding(outer_radius + 1, $fn = 64) {
				   square([total_width - brim_width*2, total_height - brim_width*2]);
			      }
			 }
		    }
		    
	       }
	  }
	  translate([-outer_width/2 - fitting_tolerance, -shell_thickness - fitting_tolerance, shell_thickness]) {
	       linear_extrude(shell_thickness + 4 + e) {
		    rounding(outer_radius, $fn = 64) {
			 square([outer_width + 2*fitting_tolerance, outer_height + 2*fitting_tolerance]);
		    }
	       }	       
	  }
	       
	  mounting_holes(component = "negative");

	  cutout_height = (inner_height - 12*2 - 6*2) / 3;
	  
	  for (pos = [inner_height/2 - (cutout_height + 6), inner_height/2, inner_height/2 + cutout_height + 6] ) {
	       translate([0, pos, -e]) {
		    linear_extrude(shell_thickness + 2*e) {
			 rounding(4, $fn = 32) {
			      square([inner_width - 12, cutout_height], center = true);
			 }
		    }
	       }
	  }
     } // difference
}

module back_cover() {
    difference() {
        union() {
            translate([-outer_width/2, -shell_thickness, 0]) {
                linear_extrude(shell_thickness) {
                    rounding(outer_radius, $fn = 64) {
                        square([outer_width, outer_height]);
                    }
                }
            }
            brim_width = inner_width - fitting_tolerance*2;
            brim_height = inner_height - fitting_tolerance*2;
            translate([-brim_width/2, fitting_tolerance, shell_thickness - e]) {
                linear_extrude(6) {
                    difference() {
                        rounding(inner_radius - fitting_tolerance, $fn = 64) {
                            square([brim_width, brim_height]);
                        }
                        translate([shell_thickness, shell_thickness]) {
                            square([brim_width - 2*shell_thickness, brim_height - 2*shell_thickness]);
                        }
                    }
                }
            } // main shape
            
            // mounting holes      
            mounting_holes(component = "back");
                                    
            // MFRC holder
            translate([-10, mfrc_pos + mfrc_height/2, shell_thickness - e]) {
                difference() {
                    cylinder_fillet_outside(inner_depth - 3, r = 8, top = 0, bottom = 4);
                    translate([0, 0, -e]) {
                        cylinder(inner_depth - 3 + 2*e, r = 8 - 1.2);
                    }
                }
            }
            translate([13, main_board_pos + main_board_height/2, shell_thickness - e]) {
                difference() {
                    cylinder_fillet_outside(inner_depth - 6, r = 6, top = 0, bottom = 3);
                    translate([0, 0, -e]) {
                        cylinder(inner_depth - 6 + 2*e, r = 6 - 1.2);
                    }
                }
            }
                        
            // microphone
            translate([0, shell_thickness + mic_board_height/2 + boards_tolerance, shell_thickness - e]) {
                difference() {
                    cylinder_fillet_outside(inner_depth - (mic_height + 1.6 - shell_thickness) - 3, r = mic_radius, , top = 0, bottom = 2);
                    cylinder(inner_depth - (mic_height + 1.6 - shell_thickness) - 3 + e, r = mic_radius - 1.2);
                }
            }
            
            
            // cable
            translate([- mic_board_height/2 - shell_thickness - connector_width, 0, 0])
                cable_hole();
            
        } // main union
        
        mounting_holes(component = "negative");

        translate([- mic_board_height/2 - shell_thickness - connector_width, 0, 0])
            cable_hole(negative = true);
        
    } // difference
}

module cable_hole(negative = false) {
    angle = -66;
    if (negative) {
        rotate([angle, 0, 0]) {
            translate([shell_thickness, shell_thickness, -30]) {
                cube([connector_width,  connector_height, 60]);
            }
        }        
    } else {
        intersection() {
            rotate([angle, 0, 0]) {
                difference() {
                    cube([connector_width + shell_thickness*2,  connector_height + shell_thickness*2, main_board_pos - 3]);
                    translate([1.2, 1.2, -e]) {
                        cube([connector_width,  connector_height, 20 + 2*e]);
                    }
                    translate([connector_width/2 + shell_thickness, -e, main_board_pos - 8]) {
                        rotate([-90, 0, 0]) {
                            cylinder(shell_thickness + 2*e, r = 3);
                        }
                        translate([-2, 0, 0])
                            cube([4, shell_thickness + 2*e, 8]);
                    }
                }
            }
            cube([connector_width + 1.2*2,  30, 30]);
        }
    }
}

module mounting_holes(component = "front") {
    for (ypos = [-1, 1], xpos = [-1, 1]) {
        translate([xpos*(inner_width/2 - 4 - shell_thickness - fitting_tolerance*2), inner_height/2 + ypos*(inner_height/2 - 4 - shell_thickness - fitting_tolerance*2), 0]) {
            if (component == "front") {
                translate([0, 0, shell_thickness - e]) {
                    difference() {
                        cylinder_fillet_outside(inner_depth - 0.5, r=4, top = 0, bottom = 3);
                        cylinder(inner_depth - 0.5 + e, r = 1/cos(45), $fn = 4);
                    }
                }
            } else if (component == "back") {
                translate([0, 0, shell_thickness - e]) {
                    difference() {
                        cylinder(2, r = 4 + 1.2);
                        cylinder(2 + e, r = 4 + fitting_tolerance, $fn = 32);
                    }
                }                          
            } else if (component == "negative") {
                translate([0, 0, -e]) {
                    cylinder(shell_thickness + 2*e, r = 2);
                }
            }
        }
    }
}

module button(negative = false) {
    width = 12 + fitting_tolerance*2;
    height = 14;
    if (negative) {
        translate([shell_thickness, shell_thickness, -e]) {
            cube([width, height, shell_thickness + 2*e]);
        }
    } else {
        difference() {
            cube([width + shell_thickness*2, height + shell_thickness * 2, 8.8 + shell_thickness]);
            translate([shell_thickness, shell_thickness, -e]) {
                cube([width, height, 8.8]);
                translate([e, height - 2, 8.8 - 2]) {
                    rotate([0, -90, 0]) {
                        cylinder(shell_thickness + 2*e, r = 1.5, $fn = 8);
                    }
                }
            }
        }
    }
}

module microphone(negative = false) {
    if (negative) {
        translate([0, 0, -e]) {
            cylinder(shell_thickness + 2*e, r = mic_radius + fitting_tolerance, $fn = 32);
        }
    } else {
        difference() {
            cylinder(mic_height, r = mic_radius + fitting_tolerance + 1.2);
            translate([0, 0, -e]) {
                cylinder(mic_height + 2*e, r = mic_radius + fitting_tolerance, $fn = 32);
            }
        }
    }
}

module speaker(negative = false) {
    // compartment
    compartment_radius = inner_width/2 - shell_thickness - fitting_tolerance*4;
    compartment_thickness = 3;

    if (negative) {
        $fn = 32;
        translate([0, 0, -e]) {
            difference() {
                cylinder(shell_thickness + 2*e, r = speaker_radius + fitting_tolerance);
                difference() {
                    for (angle = [45 - 30/2:360/4:359]) {
                        rotate([0, 0, angle]) {
                            rotate_extrude(angle = 30, $fn = 64) {
                                polygon([[speaker_radius + fitting_tolerance - shell_thickness*0.4, shell_thickness + 3*e], [speaker_radius + fitting_tolerance + e, shell_thickness + 3*e], [speaker_radius + fitting_tolerance + e, 0]]);
                            }
                        }
                    }
                }
            }
            translate([0, -compartment_radius + compartment_thickness + 1.5, 0]) {
                cylinder(shell_thickness + 2*e, r = 1.5);
            }
        }
    } else {
        // speaker holder
        difference() {
            cylinder(speaker_brim_height + 3*shell_thickness, r = speaker_radius + fitting_tolerance + 1.2);
            translate([0, 0, -e]) {
                $fn = 64;
                cylinder(shell_thickness + speaker_brim_height + e, r = speaker_radius + fitting_tolerance);
                translate([0, 0, shell_thickness + speaker_brim_height]) {
                    cylinder(shell_thickness + e, r1 = speaker_radius + fitting_tolerance, r2 = speaker_radius + fitting_tolerance - shell_thickness*2/3);
                }
                translate([0, 0, shell_thickness + speaker_brim_height + shell_thickness]) {
                    cylinder(shell_thickness + 2*e, r = speaker_radius + fitting_tolerance - shell_thickness*2/3);
                }
            }
            intersection() {
                translate([-10, 0, 0]) {
                    cube([20, speaker_radius + fitting_tolerance, speaker_brim_height + 3*shell_thickness + epsilon]);
                }
                cylinder(speaker_brim_height + 3*shell_thickness + epsilon, r = speaker_radius + fitting_tolerance);
            }
        }
        difference() {
            cylinder(outer_depth - 0.5 - fitting_tolerance, r = compartment_radius);
            translate([0, 0, compartment_thickness]) {
                cylinder(outer_depth - 0.5 - fitting_tolerance - 2*compartment_thickness, r = compartment_radius - compartment_thickness);
            }
            translate([0, 0, -e]) {
                cylinder(compartment_thickness + 2*e, r = speaker_radius + fitting_tolerance);
                translate([0, -compartment_radius + compartment_thickness + 1.5, 0]) {
                    cylinder(compartment_thickness + 2*e, r = 1.5, $fn = 32);
                }            
            }
            translate([0, 0, outer_depth/2]) {
                rotate([0, -90, 30]) {
                    cylinder(compartment_radius + e, r=1.7);
                }
            }
        }
    }
}    
