#
# $Git: Dockerfile 1.94-47-937 2019-12-03 00:36:03+04:00 yds $
#
FROM ubuntu:18.04
USER root
RUN groupadd -r -g 1000 toor
RUN useradd -rm -d /home/toor -s /bin/bash -g root -G sudo -u 1000 toor
USER toor
WORKDIR /home/toor
RUN mkdir -p /home/toor/builds
RUN mkdir -p /home/toor/src
USER root
ENV NAME Damir Sh. Yakupov
ENV EMAIL yds@bk.ru
ENV PROJECT bashlyk
ENV TERM linux
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV SHELL /bin/bash
RUN apt update -y && apt install software-properties-common -y
RUN add-apt-repository ppa:yds/bashlyk -y
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 773461F3 || true
RUN apt update -y && apt-get install bashlyk kolchan -y
RUN apt install autoconf automake bc devscripts dh-make docbook-xsl git make patch robodoc rsync xsltproc -y
ENV PATH=/home/toor/bin:${PATH}
