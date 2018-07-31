set translation [-4 -3.5 -20]
set rotation [0 1 0 -1 0 0 0 0 1]
set pivot [0 0 0]
set scale 0.014

set raytracer::size [1920x1200]
//set seed 67
set background #eee

3 * {x -160} 4 * { y 98 color black}base1

rule base1 md 1 > base_f{
{rz 90 color red s 2 } base_0
{x 22 y 0} base1
}

rule base_f md 2 > base{
mybase
{y 13 x -12} base_f
}

rule base md 2{
mybase
{y 12 x 1} base
}

rule base md 2{
mybase
{y 14 x -1} base
}

rule mybase md 4{
{rz 90}base_0
{x 13 y -1}mybase
}

rule mybase md 4{
{rz 90}base_0
{x 12 }mybase
}

rule mybase md 3{
{rz 90}base_0
{x 14 y 1}mybase
}

rule base_0 md 4{
//vertical
2 * {x 1.4} vertical_c
{x 5} vertical
//block_0
3 * {x 1} block_0
}

rule vertical md 2 {
{ y -1 } vertical
block
}

rule vertical_c md 4{
{ y -1 } vertical_c
block
}

rule vertical_c w 0.5 md 3{
{ y -1 } vertical_c
blockh_l
block
}

rule vertical_c w 0.5 md 4{
{ y -1 } vertical_c
blockh_r
block
}

rule block_0 {
{y -5 s 2 0.8 0.01 }box
}

rule block_0{}

//rule block {
//{s 0.8 0.8 0.01}box}

rule block w 3{}

rule block w 4{
{y -0.3 s 0.8 1.4 0.01}box
}

rule blockh_l {
{x -1 s 1.8 0.8 0.01}mybox
}

rule blockh_r {
{x 1 s 1.8 0.8 0.01}mybox
}

rule half_r md 20 {
box
{x 0.4 rz 12 s 0.96 0.9 1} half_r
}

rule half_l md 20 {
box
1 * {rx 180} 1 * { x -0.3 rz -10 s 0.9 0.9 1} half_l
}
rule mybox {
half_r
{s 1 }box
}
rule mybox {
half_l
{s 1 }box
}
rule mybox {
{s 1 }box
}