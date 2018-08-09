#!/bin/sh

set -e
set -x

apt-get update \
  && apt-get upgrade --no-install-recommends -y \
  && apt-get install --no-install-recommends -y \
       locales ruby2.5 rake git \
       build-essential make \
       python2.7 nodejs cmake \
       default-jre \
       bison \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

locale-gen --purge en_US.UTF-8 && /bin/echo -e  "LANG=$LANG\nLANGUAGE=$LANGUAGE\n" | tee /etc/default/locale \
  && locale-gen $LANGUAGE \
  && dpkg-reconfigure locales

update-alternatives --install /usr/bin/python python /usr/bin/python2.7 10

