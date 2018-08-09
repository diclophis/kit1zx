#!/bin/bash

set -e
set -x

####

cd /root/emsdk

. ./emsdk_env.sh

cd /var/tmp/kit1zx

make clean

make
