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

for I in `seq 0 15`
do
  /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD -D shape=${I} -o resources/shape-${I}.stl openscad/map-parts.scad

  MESHARGS="-i resources/shape-${I}.stl -o resources/shape-${I}.obj -m vn vc fc wt -s openscad/apply-color-5.mlx"

  DYLD_FRAMEWORK_PATH=/Applications/meshlab.app/Contents/Frameworks /Applications/meshlab.app/Contents/MacOS/meshlabserver ${MESHARGS}

  cp resources/shape-null_tex.png resources/shape-${I}_tex.png
done
