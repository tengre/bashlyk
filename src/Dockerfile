#
# $Id: Dockerfile 914 2019-03-25 01:10:16+04:00 yds $
#
FROM ubuntu:18.04
RUN apt update
WORKDIR /opt
COPY . /opt
ENV NAME BASHLYK
ENV TERM linux
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV SHELL /bin/bash
RUN dpkg -i robodoc_4.99.43-1_amd64.deb || apt-get install -f -y
CMD bashlyk --bashlyk-test && bash





