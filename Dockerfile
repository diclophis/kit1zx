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
RUN cd /var/tmp/kit1zx/mruby && MRUBY_CONFIG=../config/emscripten.rb make

COPY . /var/tmp/kit1zx

COPY iterate.sh /var/tmp/iterate.sh
RUN /var/tmp/iterate.sh
