#!/bin/bash

set -x
set -e

# vc -> vertex colors,  vf -> vertex flags,
# vq -> vertex quality, vn-> vertex normals,
# vt -> vertex texture coords,
# fc -> face colors,  ff -> face flags,
# fq -> face quality, fn-> face normals,
# wc -> wedge colors, wn-> wedge normals,
# wt -> wedge texture coords

#OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
#MESHLAB="DYLD_FRAMEWORK_PATH=/Applications/meshlab.app/Contents/Frameworks /Applications/meshlab.app/Contents/MacOS/meshlabserver"

OPENSCAD=openscad
MESHLAB=meshlabserver
FILTERS=color-4.mlx

for I in `seq 0 15`
do
  $OPENSCAD -D shape=${I} -o resources/shape-${I}.stl openscad/map-parts.scad

#data to save in the output files:
#vc -> vertex colors, vf -> vertex flags, vq -> vertex quality, vn-> vertex normals,
#vt -> vertex texture coords,  fc -> face colors, ff -> face flags, 
#fq -> face quality, fn-> face normals,  wc -> wedge colors, wn-> wedge normals, wt -> wedge texture coords 

  #FOO="-m vn vc fc wt"
  FOO="-om vc vf vq vn vt fc ff fq fn wc wn wt"
  MESHARGS="-i resources/shape-${I}.stl -o resources/shape-${I}.obj $FOO -s openscad/$FILTERS"
  MESHARGS_TWO="-i resources/shape-${I}-mid.obj -o resources/shape-${I}.obj $FOO -s openscad/foop.mlx"

  #MESHARGS="-d /var/tmp/d.log -l /var/tmp/l.log -i resources/shape-${I}.stl -o resources/shape-${I}.obj $FOO"

  $MESHLAB ${MESHARGS}

  cp resources/shape-null_tex.png resources/shape-${I}_tex.png
done
