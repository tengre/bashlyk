#
# $Id: Dockerfile 897 2019-02-25 22:52:34+04:00 yds $
#
from ubuntu:18.04
RUN apt update
WORKDIR /opt
COPY . /opt
ENV NAME BASHLYK
ENV TERM linux
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV SHELL /bin/bash
RUN dpkg -i bashlyk_1.94.896-0ubuntu1_all.deb robodoc_4.99.43-1_amd64.deb || apt-get install -f -y
CMD bashlyk --bashlyk-test && bash





