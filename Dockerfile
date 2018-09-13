FROM ubuntu:bionic-20180526

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ENV DEBIAN_FRONTEND noninteractive

USER root

COPY bootstrap.sh /var/tmp/bootstrap.sh
RUN /var/tmp/bootstrap.sh

COPY emscripten.sh /var/tmp/emscripten.sh
RUN /var/tmp/emscripten.sh

COPY emscripten-warmup.sh /var/tmp/emscripten-warmup.sh
RUN /var/tmp/emscripten-warmup.sh

COPY config /var/tmp/kit1zx/config
COPY mruby /var/tmp/kit1zx/mruby
RUN cd /var/tmp/kit1zx/mruby && rm -Rf build && make clean && MRUBY_CONFIG=../config/emscripten.rb make

COPY raylib /var/tmp/kit1zx/raylib
COPY resources /var/tmp/kit1zx/resources
COPY lib /var/tmp/kit1zx/lib
COPY Makefile.emscripten main.c config.ru iterate.sh lib shell.html /var/tmp/kit1zx/

RUN /var/tmp/kit1zx/iterate.sh
