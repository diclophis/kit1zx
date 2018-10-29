#!/bin/bash

set -x
set -e

for I in `seq 0 15`
do
  /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD -D shape=${I} -o resources/shape-${I}.stl openscad/map-parts.scad
done
