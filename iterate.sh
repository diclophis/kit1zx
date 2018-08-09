#!/bin/bash

set -e
set -x

#TODO: move to lower step

apt update && apt install -y bison

####

cd /root/emsdk

. ./emsdk_env.sh

cd /var/tmp/kit1zx

make clean

make
