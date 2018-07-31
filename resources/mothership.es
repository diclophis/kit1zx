set translation [4.61811 0.972644 -20]

set rotation [0.572458 -0.0887457 0.815116 -0.577348 -0.749522 0.323869 0.582206 -0.656008 -0.480308]

set pivot [0 0 0]

set scale 0.452736

set background #777


{ color white} ship

{color white} thrusters


rule ship{

3 * { y -2.5 z -3 s 0.6} 10 * {y 0.1 s 0.9 1.05 1.06}bodywhite

3 * { y -2.5 z -3 s 0.6} 10 * {y 0.1 s 0.9 1.05 1.06}body

}

rule bodywhite md 90 {

{ ry 1 rx 44 s 2.2 0.5 1.6}RingPartWhite

{ ry 4 x 0.58 } bodywhite

}

rule RingPartWhite{

{ s 0.4 0.1 2.4 y 4 z 0.44}box

}

rule body md 32 {

{ ry 5.625 rx 85 s 1 1 1.1}RingPart

{ ry 11.25 x 1.7 } body

}

rule RingPart{

{ b 0.25 y -1.5 rx -90 } roof

{ b 0.4 a 0.5 z 2 y 1.0 s 2.4 1 0.1 } box

}

rule roof{

2 * { z 2 } panel

{ z 3 s 2.5 0.05 1.75 } box

}

rule panel{

{ s 2.2 0.1 0.125 } box

{ y -1 s 0.1 1.75 0.1 } box

{ y -1.925 s 2.3 0.1 0.25} box

}

rule Fbody md 16 {

{ ry 5.625 rx 85 s 1 1 1.1}FRingPart

{ ry 11.25 x 1.7 } Fbody

}

rule FRingPart{

{ b 0.25 y -1.5 rx -90 } Froof

// { b 0.4 a 0.5 z 2 y 1.0 s 2.4 1 0.1 } box

}

rule Froof{

2 * { z 2 } Fpanel

{ z 3 s 2.5 0.05 1.75 } box

}

rule Fpanel{

{ s 2.2 0.1 0.125 } box

{ y -1 s 2.5 1.75 0.1 } box

{ y -1.925 s 2.3 0.1 0.25 } box

{ y -1.9 z -3.2 s 2.3 0.1 3 a 0.5 color #363} box

}

rule thruster{

1 * { x -5 s 0.2 2 0.2} TRing

}

rule TRing md 32

{

{ ry 5.625 rx 33 }TRingPart // different rx produce nice results

2 * {rz 180 y -1} 1 * { ry 5.625 rx -15}TurbineCone

{ ry 11.25 rx 0 x 1.7 } TRing

}

rule TRingPart{

{ b 0.25 y -1.5 rx -90 }troof // with that you get a roof structure

{ b 0.4 a 0.5 y 1.0 s 2.0 1 0.1} box

{ b 0.4 a 0.5 z 2 y 1.0 s 2.4 1 0.1 } box

{ s 2.4 0.1 2.25 y 4 z 0.44 }box // white tiles outward

{z -2 y -0.8 s 8 0.1 5 }box // turbo fan inside out

}

rule troof{

2 * { z 2 } panel

{ z 3 s 0.8 0.1 1.75 } box

{ y -1.9 z 3 s 0.1 0.1 1.925 } box

}

rule turbineCone{

{ s 1 0.1 5.5 y 12 z -1 color #ddd}box

}

rule thrusters{

//sides

1 * {rx 90 x -3.4 y -10 z 4.5 s 0.8 1.2 0.8}thruster

1 * {rx 90 x 11.3 y -10 z 4.5 s 0.8 1.2 0.8 }thruster

//top

1 *{rx 90 s 0.5 0.8 0.5} 1 * { x -0.85 y -8 z 10.5 s 0.1 3 0.2 ry -90} Fbody

//below

1 * {rx 90 x 2.7 y -17 z 3.4 s 0.55 4 0.55}thruster

}