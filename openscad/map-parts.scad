// CSG.scad - Basic example of CSG usage
outer_size = 2.0;
cut_size = outer_size * 0.5;
inner_size = outer_size / 1.125;
core_size = outer_size / 1.015;
path_size = outer_size * 0.25;
inner_path_size = path_size * 0.75;
fudge = 0.1;
    
module pathway(direction) {
    intersection() {
        translate([-cut_size,0,0]) {
            cube(inner_size, center=true);
        }
        
//        difference() {
//            cube(outer_size, center=true);
//            
//            translate([0,0,0]) {
//                cube(core_size, center=true);
//            }
//            
//            translate([cut_size,0,0]) {
//                cube(inner_size, center=true);
//            }
//            
//            translate([0,cut_size,0]) {
//                cube(inner_size, center=true);
//            }
//            
//            translate([0,0,cut_size]) {
//                cube(inner_size, center=true);
//            }
//            
//            translate([-cut_size,0,0]) {
//                cube(inner_size, center=true);
//            }
//            
//            translate([0,-cut_size,0]) {
//                cube(inner_size, center=true);
//            }
//            
//            translate([0,0,-cut_size]) {
//                cube(inner_size, center=true);
//            }
//        }
        
        difference() {
            union() {
                cube(size=[path_size, outer_size, path_size], center=true);
                cube(size=[outer_size, path_size, path_size], center=true);
            }
         
            translate([0,0,path_size * 0.5]) {
                if (direction == 0) {
                    cube(size=[inner_path_size, outer_size+fudge, inner_path_size], center=true);
                    cube(size=[outer_size+fudge, inner_path_size, inner_path_size], center=true);
                }
                
                if (direction == 1) {
                    translate([0,outer_size*0.5,0]) {
                        cube(size=[inner_path_size, outer_size+fudge, inner_path_size], center=true);
                    }
                    cube(size=[outer_size+fudge, inner_path_size, inner_path_size], center=true);
                }
                
                if (direction == 2) {
                    translate([0,-outer_size*0.5,0]) {
                        cube(size=[inner_path_size, outer_size+fudge, inner_path_size], center=true);
                    }
                    cube(size=[outer_size+fudge, inner_path_size, inner_path_size], center=true);
                }
                
                if (direction == 3) {
                    cube(size=[inner_path_size, outer_size+fudge, inner_path_size], center=true);
                    translate([outer_size*0.5,0,0]) {
                       cube(size=[outer_size+fudge, inner_path_size, inner_path_size], center=true);
                    }
                }
                
                if (direction == 4) {
                    cube(size=[inner_path_size, outer_size+fudge, inner_path_size], center=true);
                    translate([-outer_size*0.5,0,0]) {
                        cube(size=[outer_size+fudge, inner_path_size, inner_path_size], center=true);
                    }
                }
                
                if (direction == 5) {
                    //cube(size=[inner_path_size, outer_size+fudge, inner_path_size], center=true);
                    translate([-outer_size*0.5,0,0]) {
                        cube(size=[outer_size+fudge, inner_path_size, inner_path_size], center=true);
                    }
                }
            }
            
            translate([0,0,-path_size * (inner_path_size*1.6)]) {
                //cube([path_size*3, path_size*3, path_size], center=true);
                union() {
                    cube(size=[path_size+fudge, outer_size+fudge, path_size+fudge], center=true);
                    cube(size=[outer_size+fudge, path_size+fudge, path_size+fudge], center=true);
                }
            }
        }
    }
}

//for (offset=[0:15]) {
//    translate([offset*outer_size,0,0]) {
//        pathway(offset);
//    }
//}

pathway(5);