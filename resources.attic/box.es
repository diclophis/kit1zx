set maxobjects 32768

set background white 

{ b 0.99 sat 0.1 hue 0} R1

rule R1 maxdepth 4 > void { { s 1/3 x -0.95 y -0.95 } R2 { s 1/3 x -0.95 y -0.95 z -0.95 } R2 { s 1/3 x -0.95 y -0.95 z +0.95 } R2 { s 1/3 x 0.95 y -0.95 } R2 { s 1/3 x 0.95 y -0.95 z -0.95 } R2 { s 1/3 x 0.95 y -0.95 z +0.95 } R2 { s 1/3 y -0.95 z -0.95 } R2 { s 1/3 y -0.95 z +0.95 } R2 { s 1/3 x -0.95 y 0.95 } R2 { s 1/3 x -0.95 y 0.95 z -0.95 } R2 { s 1/3 x -0.95 y 0.95 z +0.95 } R2 { s 1/3 x 0.95 y 0.95 } R2 { s 1/3 x 0.95 y 0.95 z -0.95 } R2 { s 1/3 x 0.95 y 0.95 z +0.95 } R2 { s 1/3 y 0.95 z -0.95 } R2 { s 1/3 y 0.95 z +0.95 } R2 { s 1/3 x -0.95 z -0.95 } R2 { s 1/3 x -0.95 z +0.95 } R2 { s 1/3 x 0.95 z -0.95 } R2 { s 1/3 x 0.95 z +0.95 } R2 }

rule void { }

rule r2 { { hue 37 s 0.9 } frameR } rule r2 { { hue 8 s 0.9 } frameR }

rule frameR { { rx 0 ry 0 rz 0 } frame } rule frameR { { rx 0 ry 0 rz 0 } frame } rule frameR { { rx 0 ry 0 rz 0 } frame }

rule r2 { { hue 19 } r1 }

rule r2 { { hue 20 } r1 }

rule frame { { s 0.05 1.05 0.05 x 10 z 10 } box { s 0.05 1.05 0.05 x 10 z -10 } box { s 0.05 1.05 0.05 x -10 z 10 } box { s 0.05 1.05 0.05 x -10 z -10 } box

{ s 1 0.05 0.05 y 10 z 10 } box { s 1 0.05 0.05 y 10 z -10 } box { s 1 0.05 0.05 y -10 z 10 } box { s 1 0.05 0.05 y -10 z -10 } box

{ s 0.05 0.05 1 y 10 x 10 } box { s 0.05 0.05 1 y 10 x -10 } box { s 0.05 0.05 1 y -10 x 10 } box { s 0.05 0.05 1 y -10 x -10 } box

{ s 1.04 h 180 b 0.9} sphere }

rule frame { { s 0.05 1.05 0.05 x 10 z 10 } box { s 0.05 1.05 0.05 x 10 z -10 } box { s 0.05 1.05 0.05 x -10 z 10 } box { s 0.05 1.05 0.05 x -10 z -10 } box

{ s 1 0.05 0.05 y 10 z 10 } box { s 1 0.05 0.05 y 10 z -10 } box { s 1 0.05 0.05 y -10 z 10 } box { s 1 0.05 0.05 y -10 z -10 } box

{ s 0.05 0.05 1 y 10 x 10 } box { s 0.05 0.05 1 y 10 x -10 } box { s 0.05 0.05 1 y -10 x 10 } box { s 0.05 0.05 1 y -10 x -10 } box

{ s 1.04 h 240 b 0.9} sphere }
