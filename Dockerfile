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

COPY . /var/tmp/kit1zx

COPY iterate.sh /var/tmp/iterate.sh
RUN /var/tmp/iterate.sh
