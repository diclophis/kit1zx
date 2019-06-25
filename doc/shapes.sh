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

THIS_WORKING_DIR=`pwd`

rm resources/shape* || true

for I in `seq 0 15`
do
  $OPENSCAD -D shape=${I} -o resources/shape-${I}.stl doc/openscad/map-parts.scad

#data to save in the output files:
#vc -> vertex colors, vf -> vertex flags, vq -> vertex quality, vn-> vertex normals,
#vt -> vertex texture coords,  fc -> face colors, ff -> face flags, 
#fq -> face quality, fn-> face normals,  wc -> wedge colors, wn-> wedge normals, wt -> wedge texture coords 

  #FOO="-m vn vc fc wt"
  #FOO="-om vc vf vq vn fc ff fq fn"
  #FOO="-om vc vf vq vn"
  #FOO=""
  #FOO="-om vc vf vq vn fc ff fq fn wc wn"
  #FOO2="-om vc vf vq vn vt fc ff fq fn"

  #FOO="-om vc vf vn fc ff fq fn"
  #MESHARGS="-i resources/shape-${I}.stl -o resources/shape-${I}-mid.obj $FOO -s doc/openscad/$FILTERS"
  #
  #FOO2="-om vc vf vq vn vt fc ff fq fn wc wn wt"
  #MESHARGS_TWO="-i resources/shape-${I}-mid.obj -o resources/shape-${I}.obj $FOO2 -s doc/openscad/foop.mlx"

  FOO="-om vn"
  MESHARGS="-l /var/tmp/mllog -i resources/shape-${I}.stl -o resources/shape-${I}-mid.obj $FOO -s doc/openscad/$FILTERS"

  FOO2="-om vc vn vt fc wt"
  MESHARGS_TWO="-l /var/tmp/mllog -i resources/shape-${I}-mid.obj -o resources/shape-${I}.obj $FOO2 -s doc/openscad/foop.mlx"

  $MESHLAB ${MESHARGS}
  $MESHLAB ${MESHARGS_TWO}
  rm resources/shape-${I}-mid.obj*

  (test -e resources/shape-null_tex.png && cp resources/shape-null_tex.png resources/shape-${I}_tex.png) || true


  sed -i -e "s~mtllib\ \./~mtllib\ $THIS_WORKING_DIR/resources/~" resources/shape-${I}.obj
  sed -i -e "s~map_Kd\ ~map_Kd\ $THIS_WORKING_DIR/resources/~" resources/shape-${I}.obj.mtl
  sed -i -e "s~shape-null~shape-$I~" resources/shape-${I}.obj.mtl
done
