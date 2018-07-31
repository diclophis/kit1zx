set background #111

{ color white b 0.7} ship

 
rule ship{

6 * {rz 60 } 10 * { s 0.9 1.1 1.09}a2half // body 1

6 * {rz 60 } 10 * { s 0.9 1.1 1.09}a3half // body 2

2 * {rz 180 } 10 * { s 0.8 1.4 1.04 }a2half // long straight wing

2 * {rz 180 } 10 * { s 0.8 1.4 1.04}a3half // long straigt wing 2

 
// 2 extra bubbles

1 * { rz 0 y 4 } 10 * { s 0.8 1.1 1.04 }a2half // right

1 * {rz 180 y -4 } 10 * { s 0.8 1.1 1.04}a3half // right

1 * {rz 180 y 4 } 10 * { s 0.8 1.1 1.04}a3half

1 * { rz 0 y -4 } 10 * { s 0.8 1.1 1.04 }a2half

 
// wing extensions 1

//2 * {rz 180} 1 * {y 12 z 2 rz 40 } 10 * { s 0.8 0.9 1.05 }a2half

//2 * {rz 180} 1 * {y 12 z 2 rz -40 } 10 * { s 0.8 0.9 1.05 }a3half

 
// wing extensions 2

//1 * {y 25 z 2 rz 40 } 10 * { s 0.8 0.9 1.08 }a2half

//1 * {y 25 z 2 rz 220 } 10 * { s 0.8 0.9 1.08 }a3half

//1 * {y -25 z 2 rz -40 } 10 * { s 0.8 0.9 1.08 }a2half

//1 * {y -25 z 2 rz -220 } 10 * { s 0.8 0.9 1.08 }a3half

 
// wing extensions 3

1 * {y 25 z 2 rz 0 } 10 * { s 0.8 1.1 1.06 }a2half

1 * {y 25 z 2 rz 180 } 10 * { s 0.8 1.1 1.06 }a3half

1 * {y -25 z 2 rz 0 } 10 * { s 0.8 1.1 1.06 }a2half

1 * {y -25 z 2 rz -180 } 10 * { s 0.8 1.1 1.06 }a3half

}

 
rule Part{

{ s 1.75 0.1 2 y 4 }box

}

 
rule a2half md 16 {

{ ry -5.5 rx -20 s 1.15 1.1 1.1}Part

{ ry -11.25 x 1.7 } a2half

}

  
rule a3half md 16 {

{ ry 5.5 rx -20 s 1.15 1.1 1.1}Part

{ ry 11.25 x -1.7 } a3half

}