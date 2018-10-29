#!/bin/bash

for I in `seq 0 15`
do
  openscad -D 'shape=${I}' -o resources/shape-${I}.stl openscad/map-parts.scad
done
