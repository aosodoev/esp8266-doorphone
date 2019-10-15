include<fillets.scad>
include<MCAD/units.scad>
use<MCAD/boxes.scad>
use<scad-utils/morphology.scad>
use<scad-utils/mirror.scad>

e = epsilon;
fitting_tolerance = 0.2;
boards_tolerance = 0.2;

shell_thickness = 1.6;
front_panel_thickness = 2;
inner_width = 46;
inner_height = 150;
inner_depth = 15;
inner_radius = 3;
outer_back_radius = 7.6;
front_cover_brim_depth = 4;

esp_board_width = 32;
esp_board_height = 28;
esp_board_thickness = 5.6;

speaker_radius = 14.9/2;
speaker_brim_height = 2.2;

mic_board_height = 14.1;
mic_radius = 9.6/2;
mic_height = 6.5;

ringtone_amp_height = 17.3;
ringtone_amp_width = 25.1;

outer_width = inner_width + 2*(shell_thickness + fitting_tolerance);
outer_height = inner_height + 2*(shell_thickness + fitting_tolerance);
outer_depth = inner_depth + front_panel_thickness + 2*shell_thickness;
outer_radius = inner_radius + shell_thickness + fitting_tolerance;


view = "explode";

if (view == "explode") {
     translate([0, 0, outer_depth - front_panel_thickness + 20]) {
	  rotate([0, 180, 0]) {
	       front_cover();
	  }
     }
     translate([0, 0, outer_depth - front_panel_thickness + 40]) {
	  %color([0.5, 0.5, 0.8, 0.5]) {
	       front_panel();
	  }
     }
     %color([0.5, 0.8, 0.5, 0.5]) {
	  back_cover();
     }
} else if (view == "handset-front-cover") {
     front_cover();
} else if (view == "handset-back-cover") {
     back_cover();
} else if (view == "handset-front-panel") {
     front_panel();
} else if (view == "handset-stand") {
     stand();
}

* union() {

    // test mic mount
    * test([20, 14, outer_height], 2) {
        front_cover();
    }

    // test speaker mount
    *test([20, 20, 7], inner_height - inner_width/2 - 10) {
        front_cover();
    }

    // test usb and reed switch
    * test([20, 26, 10], -3) {
        back_cover();
    }


    * test([inner_width, inner_width - 2, inner_depth], 90 - inner_width/2) {
	 back_cover();
    }

    // test button 
    * union() {
        button(negative = "top");
        test([30, 35, outer_height], inner_height/2 - 28) { front_cover(); }
    }
}


function x(v) = v[0]; function y(v) = v[1]; function z(v) = v[2];

module stand() {
     stand_size = [outer_width + 2*14, 80, 50];
     handset_angle = 12;
     handset_offset = y(stand_size) - outer_depth - 8;
     cutout_width = outer_width + 4;
     cutout_height = outer_depth + 1 + 4;

     difference() {
	  intersection() {
	       linear_extrude(z(stand_size)) {
		    rounding(10, $fn = 64) {
			 square(stand_size + [0, y(stand_size)], center = true);			 
		    }
	       }
	       rotate([0, -90, 0]) {
		    linear_extrude(x(stand_size) + 2*e, center = true) {
			 polygon([
				      [0, 0],
				      [z(stand_size), 0],
				      [15, y(stand_size)],
				      [0, y(stand_size)]

					   ]);
		    }
	       }
	  }

	  translate([0, handset_offset, 0]) {
	       rotate([handset_angle, 0, 0]) {
		    translate([0, 0, 3/cos(handset_angle)]) {
			 linear_extrude(outer_height) {
			      intersection() {
				   translate([0, cutout_height]) {
					rounding(outer_back_radius + 1, $fn = 32) {
					     square([cutout_width, cutout_height*2], center = true);
					}
				   }
				   square([cutout_width, cutout_height*2], center = true);
			      }
			 }
		    }
	       }
	  }

	  translate([0, -e, -e]) {
	       intersection() {
		    rotate([-90 - 20, 0, 0]) {
			 linear_extrude(y(stand_size)*2, center = true) {
			      rounding(20-e, $fn = 64) {
				   square([40, 2*z(stand_size) - 15], center = true);
			      }
			 }
		    }
		    rotate([0, -90, 0]) {
			 linear_extrude(x(stand_size), center = true) {
			      polygon([
					   [0, 0],
					   [z(stand_size), 0],
					   [z(stand_size), handset_offset - 1.6/cos(handset_angle) - z(stand_size)*tan(handset_angle)],
					   [0, handset_offset - 2]
					   
					   ]);
			 }
		    }
	       }
	  }
	  translate([0, y(stand_size), -e]) {
	       linear_extrude(z(stand_size)) {
		    rounding(6, $fn = 16) {
			 square([cutout_width - 6*2, (y(stand_size) - handset_offset - 6) * 2], center = true);
		    }
	       }
	  }
	  mirror_x() {
	       rotate([-90, 0, 0]) {
		    translate([(x(stand_size) + 40)/4, -z(stand_size) + 18, -e]) {
			 translate([-6, -14, 3]) {
			      cube([12, 20, 4]);
			 }
			 cylinder(4, r = 4);
			 hull() {
			      cylinder(4, r = 2);
			      translate([0, -8, 0]) {
				   cylinder(4, r = 2);
			      }
			 }
		    }
	       }
	  }
     }

     reed_switch_position = 15 + 2 + shell_thickness;
     magnet_radius = 14.6/2;
     magnet_height = 3;

     translate([0, handset_offset - 1.6/cos(handset_angle), 0]) {
	  rotate([handset_angle, 0, 0]) {
	       translate([0, 0, reed_switch_position + 3/cos(handset_angle)]) {
		    rotate([90, 0, 0]) {
			 difference() {
			      hull() {
				   cylinder(6, r = magnet_radius + fitting_tolerance + 2);
				   translate([0, -6*1.2, 0]) {
					cylinder(e, r = magnet_radius + fitting_tolerance + 2);
				   }
			      }
			      difference() {
				   cylinder(6 + e, r = magnet_radius + fitting_tolerance, $fn = 64);
				   mirror_x(){
					mirror_y() {
					     translate([(magnet_radius + fitting_tolerance)*cos(45), (magnet_radius + fitting_tolerance)*cos(45), magnet_height + 0.4]) {
						  sphere(0.4, $fn = 64);
					     }
					}
				   }					
			      }
			 }
		    }
	       }
	  }
     }

     	  *translate([0, handset_offset, 0]) {
	       rotate([handset_angle, 0, 0]) {
		    translate([0, 0, 3/cos(handset_angle)]) {
			 color([0, 1, 0, 0.3]) {
			      linear_extrude(outer_height) {
				   intersection() {
					translate([0, outer_depth + 1]) {
					     rounding(outer_back_radius, $fn = 32) {
						  square([outer_width, outer_depth*2 + 1], center = true);
					     }
					}
					square([outer_width, outer_depth*2 + 1], center = true);
				   }
			      }
			 }
		    }
	       }
	  }

     
}
    
module front_panel() {

     front_panel_thickness = front_panel_thickness + 1;
     
     difference() {
	  union() {
	       translate([0, inner_height/2, 0]) {
		    linear_extrude(front_panel_thickness) {
                        rounding(r = inner_radius, $fn = 32) {
                            square([inner_width, inner_height], center = true);
                        }
                    }
	       }
	       front_panel_latches(negative = false);

	       translate([0, inner_height - inner_width/2 - fitting_tolerance, 0]) {
		    /* speaker(); */
	       }
            
	       // mic cutout
	       translate([0, shell_thickness + mic_board_height/2 + boards_tolerance, 0]) {
		    /* microphone(); */
	       }
            
	       
	  } // main union

	  // cut outs

	  translate([0, inner_height - inner_width/2 - fitting_tolerance, -e]) {
	       mirror_y() {
		    hull() {
			 mirror_x() {
			      translate([5, 2, 0]) {
				   cylinder(front_panel_thickness + 2*e, r = 1, top = 0.8, bottom = 0, $fn = 16, fillet_fn = 16);
			      }
			 }
		    }
	       }
	       /* speaker(); */
	  }
	  
	  // mic cutout
	  translate([0, shell_thickness + mic_board_height/2 + boards_tolerance, -e]) {
	       cylinder(front_panel_thickness + e*2, r = 1.25, $fn = 16);
	       /* microphone(); */
	  }
	  
	  // button cutout
	  translate([0, inner_height / 2 - 5, -e]) {
	       cylinder_fillet_outside(front_panel_thickness + e*2, r = 6 + 0.5, top = 0.8, bottom = 0, $fn = 64, fillet_fn = 64);
	  }
	  
	  
     } // main difference

     // button
     translate([0, inner_height / 2 - 5, 0]) {
	  difference() {
	       cylinder_fillet_inside(front_panel_thickness, r = 6, top = 0.5, bottom = 0, $fn = 128, fillet_fn = 64);
	       sphere_r  = 20;
	       translate([0, 0, front_panel_thickness + sphere_r - 0.76]) {
		    sphere(sphere_r, $fn = 256);
	       }
	  }
     }

}

module front_panel_latches(negative = false) {
     mirror_x() {
	  for (pos = [20, inner_height/2, inner_height - 20]) {
	       translate([inner_width/2 + (negative ? fitting_tolerance : 0), pos, 0.6 + (negative ? outer_depth - front_panel_thickness : 0)]) {
		    rotate([90, 0, 0]) {
			 cylinder(8 + (negative ? fitting_tolerance*2 : 0), r = 0.6 + (negative ? fitting_tolerance : 0), $fn = 10, center = true);
		    }
	       }
	  }
     }
}

module front_cover() {
    difference() {
        union() {
            translate([0, inner_height/2, 0]) {
                difference() {
                    linear_extrude(front_cover_brim_depth) {
                        rounding(r=inner_radius, $fn = 32) {
                            square([inner_width, inner_height], center = true);
                        }
                    }
                    translate([0, 0, shell_thickness]) {
                        linear_extrude(front_cover_brim_depth - shell_thickness + epsilon) {
                            rounding(r=inner_radius - shell_thickness, $fn = 32) {
                                square([inner_width - shell_thickness*2, inner_height - shell_thickness*2], center = true);
                            }
                        }
                    }
                }
            }
            // additions to main shape
            
            // esp module
            difference() {
                esp_support_height = inner_depth + shell_thickness - esp_board_thickness - fitting_tolerance + 1.6 + 1.6;
                for (pos = [-1, 1]) {
                    translate([pos*(esp_board_width/2 + 1), inner_height - esp_board_height - boards_tolerance, 0]) {
                        cylinder(esp_support_height, r = 3);
                    }
                    translate([pos*(esp_board_width/2 + 1), inner_height - 5, 0]) {
                        cylinder(esp_support_height, r = 3);
                    }
                }
                translate([-esp_board_width/2, inner_height - esp_board_height, inner_depth + shell_thickness - esp_board_thickness]) {
                    hull() {
                        cube([esp_board_width, esp_board_height, 1.6]);
                        translate([1.6, 1.6, 1.6]) {
                            cube([esp_board_width - 1.6*2, esp_board_height - 1.6, 1.6]);
                        }
                    }
                }
            }
            
            // ringtone amp
            
            ringtone_amp();
            
            // main board
            
            translate([0, inner_height/4 - 4, shell_thickness - e]) {
                for (pos = [-1, 1]) {
                    translate([pos*31/2, 0, 0]) {
                        rotate([0, 0, 90 - pos*90])
                            board_latch(6);
                    }
                    translate([-4, pos*31.1/2, 0]) {
                        rotate([0, 0, pos*90])
                            board_latch(6);
                    }

                }
            }

            
            translate([0, inner_height - inner_width/2 - fitting_tolerance, 0]) {
                speaker();
            }
            
            // mic cutout
            translate([0, shell_thickness + mic_board_height/2 + boards_tolerance, 0]) {
                microphone();
            }
            
            // button cutout
            translate([0, inner_height / 2 - 5, 0]) {
                button();
            }
            
        } // main shape union
        
        // cutouts from main shape
        
        // speaker cutout
        translate([0, inner_height - inner_width/2 - fitting_tolerance, 0]) {
            speaker(negative = true);
        }
        
        // mic cutout
        translate([0, shell_thickness + mic_board_height/2 + boards_tolerance, 0]) {
            microphone(negative = true);
        }
        
        // button cutout
        translate([0, inner_height / 2 - 5, 0]) {
            button(negative = true);
        }
        
    } // difference
}

module back_cover() {
    
    speaker_position = 90;
    
    difference() {
        union() {
            translate([0, -(shell_thickness + fitting_tolerance), 0]) {
                // back - middle
                translate([-outer_width/2 + outer_back_radius - epsilon, 0, outer_back_radius]) {
                    rotate([0, 90, 0]) {
                        linear_extrude(outer_width - outer_back_radius*2 + 2*epsilon) {
                            back_cover_rounded_profile();
                        }
                    }
                }
                // back - sides
                for (pos = [-1, 1]) {
                    translate([pos*(outer_width/2 - outer_back_radius), 0, outer_back_radius]) {
                        rotate([90, 90 + 45 + pos*45, 180]) {
                            rotate_extrude(angle=90, $fn = 80) {
                                back_cover_rounded_profile();
                            }
                        }
                    }
                }
                translate([-outer_width/2, 0, outer_back_radius - epsilon]) {
                    linear_extrude(outer_depth - outer_back_radius) {
                        difference() {
                            rounding(r=outer_radius, $fn = 64)
                                square([outer_width, outer_height]);
                            translate([shell_thickness, shell_thickness]) {
                                rounding(r=outer_radius - shell_thickness, $fn = 32)
                                    square([outer_width - 2*shell_thickness, outer_height - 2*shell_thickness]);
                            }
                        }
                    }
                }
            }
            // speaker holder
            translate([0, speaker_position, shell_thickness - epsilon]) {
                ringtone_speaker();
            }
            
            // TODO latches
            
            // microUSB
            usb_board_width = 14;
	    difference() {
		 translate([-usb_board_width/2 - 1.2 - boards_tolerance, 0, shell_thickness]) {
		      cube([usb_board_width + 1.2*2 + boards_tolerance*2, 15 + boards_tolerance*2 + 2, 1.6 + e]);
		      translate([0, 15 + boards_tolerance*2, 0]) {
			   cube([usb_board_width + 1.2*2 + boards_tolerance*2, 2, 1.6 + 3]);
		      }
		 }
		 for (pos = [-1, 1]) {
		      translate([pos*(usb_board_width/2 + boards_tolerance - 0.6), 15 - 3.5, shell_thickness]) {
			   rotate([0, 0, 90 - 90*pos]) {
				scale([2, 2, 1]) {
				     board_latch(5, 1.6 + 2*e);
				}
			   }
		      }
		 }
	    }
            for (pos = [-1, 1]) {
                translate([pos*(usb_board_width/2 + boards_tolerance), 15 - 3.5, shell_thickness]) {
                    rotate([0, 0, 90 - 90*pos])
                    board_latch(5, 1.6 + 1.6);
                }
            }

	    // reed switch holder
	    width = 14 + 2*fitting_tolerance;
	    height = 2.6 + 2*fitting_tolerance;
	    translate([-width/2 - shell_thickness, 15 + boards_tolerance*2 + 2 - shell_thickness, shell_thickness -e]) {
		 difference() {
		      cube([width + 2*shell_thickness, shell_thickness + height/3, height]);
		      translate([shell_thickness, 0, 0]) {
			   cube([width, height, height + e]);
		      }
		 }
	    }
	    translate([0, 15 + boards_tolerance*2 + 2 + height, shell_thickness - e]) {
		 rotate([0, 0, 90]) {
		      board_latch(5, height);
		 }
	    }

	    // stiffening ribs
	    back_cover_stiffening();

        } // union
        
        // cutouts
        translate([0, speaker_position, -e]) {
            ringtone_speaker(negative = true);
        }
        
        // microusb cutout
        translate([0, e, shell_thickness + 1.6 + 1.6 - 0.2]) {
            rotate([90, 0, 0]) {
                linear_extrude(shell_thickness + fitting_tolerance + 2*e) {
                    w1 = 5.8; h1 = 2 - 0.5; h2 = h1 + 1.4 + 0.5; w2 = w1 + h1*2; 
                    polygon([[-w1/2, 0], [-w2/2, h1], [-w2/2, h2], [w2/2, h2], [w2/2, h1], [w1/2, 0]]);
                }
            }
        }
	        
        // volume wheel cutout
        translate([0, 0, outer_depth - front_panel_thickness]) {
            rotate([0, 180, 0]) {
                ringtone_amp(negative = true);
            }
        }

	// front panel latches
	front_panel_latches(negative = true);

    }
}

module back_cover_stiffening() {
     rib_height = outer_depth - front_panel_thickness - front_cover_brim_depth - shell_thickness - fitting_tolerance;
     for (pos = [30, inner_height/2 - 7, inner_height - 36]) {
	  translate([0, pos, 0]) {
	       rotate([90, 0, 0]) {
		    linear_extrude(shell_thickness) {
			 translate([-e, rib_height + shell_thickness - e]) {
			      difference() {
				   rounding(outer_back_radius - shell_thickness - fitting_tolerance + e, $fn = 32) {
					rib_height = outer_depth - front_panel_thickness - front_cover_brim_depth - shell_thickness;
					square([outer_width - 2*shell_thickness + 2*e, 2*rib_height + 2*e], center = true);			 
				   }
				   rounding(outer_back_radius - shell_thickness - fitting_tolerance + e - 3) {
					square([outer_width - 2*shell_thickness + 2*e - 3*2, 2*rib_height + 2*e - 5*2], center = true);			 
				   }
				   translate([-outer_width/2, 0]) {
					square([outer_width, outer_depth]);
				   }
			      }
			 }
		    } //extrude
	       } // rotate
	  } // translate
     } // for
}

module ringtone_amp(negative = false) {
    position = inner_height - inner_width - ringtone_amp_height;
    if (negative) {
	 translate([-inner_width/2 + shell_thickness + boards_tolerance, position, front_cover_brim_depth - 1.6]) {
            cube([ringtone_amp_width, ringtone_amp_height, 1.6]);
            translate([4.2, 10.3, 2.9 - 1]) {
                cylinder(4, r = 15.9/2 + 1.2);
            }
        }
	translate([-outer_width/2 - 80, position, front_cover_brim_depth - 1.6]) {
            translate([shell_thickness/2, 10.3, 2.9 - 2]) {
                cylinder(6, r = 80, $fn = 200);
            }
        }
    } else {
        translate([-inner_width/2 + shell_thickness, position - 1.2 - boards_tolerance, 0]) {
            cube([ringtone_amp_width + 1.2 + boards_tolerance*2, ringtone_amp_height + 1.2*2 + boards_tolerance*2, front_cover_brim_depth - 1.6]);
                translate([8, 1.2, front_cover_brim_depth - 1.6]) {
                    rotate([0, 0, -90])
                        board_latch(14);
                }
                translate([17, 1.2 + ringtone_amp_height + 2*boards_tolerance, front_cover_brim_depth - 1.6]) {
                    rotate([0, 0, 90])
                        board_latch(8);
                }
                translate([ringtone_amp_width + 2*boards_tolerance, ringtone_amp_height/2, front_cover_brim_depth - 1.6]) {
                    board_latch(9);
                }
        }
        %translate([-inner_width/2 + shell_thickness + boards_tolerance, position, front_cover_brim_depth - 1.6]) {
            cube([ringtone_amp_width, ringtone_amp_height, 1.6]);
            translate([4.2, 10.3, 2.9]) {
                color([0, 1, 0, 0.2])
                cylinder(2, r=15.9/2);
            }
        }
	
	// second amp board
	translate([inner_width/2 - shell_thickness - boards_tolerance - 14.6, position, shell_thickness]) {
            
            %cube([14.6, 18, 1.6]);
            translate([14/2, -boards_tolerance, 0]) {
                rotate([0, 0, -90]) 
                    board_latch(12);
            }
            translate([14/2, 18 + boards_tolerance, 0]) {
                rotate([0, 0, 90]) 
                    board_latch(7);
            }
        }
        
    }
}

module ringtone_speaker(negative = false) {
    speaker_radius = 39.9/2;
    speaker_brim_height = 2.2;
    if (negative) {
        for (a = [0:30:359], o = [6:6:speaker_radius - 6]) {
            rotate([0, 0, a])
                translate([o, 0, 0])
                    cylinder(shell_thickness + 2*e, r = o/6, $fn = 20);
        }
        translate([0, 0, shell_thickness - e]) {
            cylinder(1 + 2*e, r = speaker_radius - 2);
        }
    } else {
        difference() {
	    cylinder(2, r = speaker_radius + fitting_tolerance*2 + 1.2);
            translate([0, 0, 1]) {
		 cylinder(2, r = speaker_radius + fitting_tolerance*2, $fn = 64);
            }
        }
	for (angle = [45:90:359]) {
	     rotate([0, 0, angle]) {
		  translate([speaker_radius + fitting_tolerance, 0, 1 - e]) {
		       board_latch(6, speaker_brim_height);
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
        for (pos = [-1, 1]) {
            translate([pos*mic_board_height/2, 0, mic_height]) {
                rotate([0, 0, 90 - 90*pos]) {
                    board_latch(8);
                }
            }
            translate([pos*(mic_board_height/2 + 1.2/2) - 2/2, -4, 0]) {
                cube([2, 8, mic_height + e]);
            }
        }
    }
}

module speaker(negative = false) {
    compartment_thickness = 2;
    compartment_radius = speaker_radius + 5 + compartment_thickness;
    compartment_depth = inner_depth + shell_thickness - esp_board_thickness - fitting_tolerance;

    if (negative) {
        $fn = 32;
        translate([0, 0, -e]) {
            difference() {
                cylinder(shell_thickness + 2*e, r = speaker_radius + fitting_tolerance, $fn = 64);
                difference() {
                    for (angle = [45 - 30/2:360/4:359]) {
                        rotate([0, 0, angle]) {
                            rotate_extrude(angle = 30, $fn = 64) {
                                polygon([[speaker_radius + fitting_tolerance - shell_thickness*0.2, shell_thickness + 3*e], [speaker_radius + fitting_tolerance + e, shell_thickness + 3*e], [speaker_radius + fitting_tolerance + e, 0]]);
                            }
                        }
                    }
                }
            }
        }
    } else {
        // speaker holder
        difference() {
            cylinder(speaker_brim_height + 2.2*shell_thickness, r = speaker_radius + fitting_tolerance + 1.2);
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
                rotate([0, 0, 180]) {
                    translate([-7, 0, 0]) {
                        cube([14, speaker_radius + fitting_tolerance, speaker_brim_height + 3*shell_thickness + epsilon]);
                    }
                }
                cylinder(speaker_brim_height + 3*shell_thickness + epsilon, r = speaker_radius + fitting_tolerance);
            }
        }
        difference() {
            cylinder(compartment_depth, r = compartment_radius);
            translate([0, 0, compartment_thickness]) {
                cylinder(compartment_depth - 2*compartment_thickness, r = compartment_radius - compartment_thickness);
            }
            translate([0, 0, -e]) {
                cylinder(compartment_thickness + 2*e, r = speaker_radius + fitting_tolerance);
                translate([0, -compartment_radius + compartment_thickness + 1.5], 0) {
                    cylinder(compartment_thickness + 2*e, r = 1.5, $fn = 32);
                }            
            }
            translate([0, 0, compartment_depth - compartment_thickness - 1.7]) {
                rotate([90, 0, 30]) {
                    cylinder(compartment_radius + e, r=1.7);
                }
            }
        }
    }
}

module button(negative = false) {
    width = 12 + fitting_tolerance*2;
    height = 14;
    button_radius = 16/2;
    if (negative == true) {
        translate([0, 0, -e]) {
            difference() {
                union() {
                    cylinder(shell_thickness + 2*e, r = button_radius + 1);
                    translate([-3, -18, 0]) {
                        cube([6, 12, shell_thickness + 2*e]);
                    }
                }
                translate([0, 0, -e]) {
                    cylinder(shell_thickness + 4*e, r = button_radius);
                    translate([-2, -18 - e, 0]) {
                        cube([4, 12, shell_thickness + 4*e]);
                    }
                }
            }
            translate([-3, -3, 0]) {
                cube([6, 6, shell_thickness + 2*e]);
            }
            translate([-2.5/2, 3 - e, 0]) {
                cube([2.5, 2.5, shell_thickness + 2*e]);
            }
        }
    } else if (negative == false) {
        mirror_x() {
            difference() {
                translate([21/2, -5, 0]) {
                    cube([shell_thickness, 10, 2*shell_thickness + 4.7 + 0.5 + shell_thickness*1.5]);
                    translate([shell_thickness, 10, shell_thickness]) {
                        rotate([90, 0, 0])
                        fillet_linear_i(10, 3, fillet_angle=90, fillet_fn=0, add=0.02);
                    }
                }
                translate([21/2 - e, -2.5 - fitting_tolerance, shell_thickness + 4.7 + 0.5]) {
                    cube([shell_thickness + 2*e, 5 + 2*fitting_tolerance, shell_thickness*1.5 + fitting_tolerance]);
                }
            }
        }
        *translate([-21/2 - shell_thickness, -5, 0]) {
            difference() {
                cube([21 + shell_thickness*2, 10, 2*shell_thickness + 4.1 + 0.5]);
                translate([shell_thickness, -e, 0]) {
                    cube([21, 10 + 2*e, shell_thickness + 4.5]);                   
                }
            }
        }

    } else if (negative == "top") {
        translate([-21/2, -5, 0]) {
            cube([21, 10, shell_thickness*1.5]);
        }
        translate([0, 2, shell_thickness*1.5]) {
            scale([1, 1, 1/5]) {
                sphere(3, $fn = 64);
            }
        }
        mirror_x() {
            translate([0, 2.5, 0]) {
                rotate([90, 0, 0]) {
                    linear_extrude(5) {
                       polygon([[21/2, 0], [21/2 + shell_thickness*3/4, 0], [21/2, shell_thickness*1.5]]);
                    }
                }
            }
        }
    }
}


module ringtone_speaker_test() {
    translate([0, 0, shell_thickness - e]) {
        ringtone_speaker();
    }
    difference() {
        translate([0, 0, 17/2]) {
            difference() {
                roundedBox([40, 50, 17], 5, true);
                translate([0, 0, shell_thickness]) {
                    roundedBox([40 - shell_thickness*2, 50 - shell_thickness*2, 17], 5 - shell_thickness, true);
                }
                rotate([90, 0, 0]) {
                    cylinder(28, r = 2);
                }
            }
        }
        translate([0, 0, -e]) {
            ringtone_speaker(true);
        }
    }
}

module back_cover_rounded_profile() {
    intersection() {
        translate([0, outer_height/2]) {
            difference() {
                rounding(r=outer_radius, $fn = 64) {
                    square([2*outer_back_radius, outer_height], center = true); 
                }
                rounding(outer_radius - shell_thickness, $fn = 32) {
                    square([2*(outer_back_radius - shell_thickness), outer_height - 2*shell_thickness], center = true);
                }
            }
        }
        square([outer_back_radius, outer_height]);
    }
}

module board_latch(width = 4, thickness = 1.6) {
    boards_tolerance = 0.4;
    rotate([90, 0, 0]) {
        translate([0, 0, -width/2]) {
            linear_extrude(width) {
                polygon([[0, 0], [0, thickness], [-2*boards_tolerance, thickness + 2*boards_tolerance], [0, thickness + 6*boards_tolerance], [1.2, thickness + 6*boards_tolerance], [1.2, 0]]) {
                }
            }
        }
    }
}



module test(dim, pos) {
    intersection() {
        translate([-dim[0]/2, pos, 0]) {
            cube(dim);
        }
        translate([0, 0, 0])
            children();
    }
}
