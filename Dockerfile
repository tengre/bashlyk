#
# $Git: Dockerfile 1.96-7-941 2023-05-10 08:56:51+00:00 yds $
#
# Docker-based way to debianize packages
#
## try using any derived distribution of the Debian family
FROM debian:bullseye
##
USER root
ENV TERM linux
ENV SHELL /bin/bash
ENV DEBIAN_FRONTEND noninteractive
RUN apt update -y && apt install software-properties-common -y --no-install-recommends
RUN apt install autoconf automake autotools-dev bash build-essential bsdmainutils bsdutils cdbs coreutils devscripts dh-make dnsutils docbook-xsl dpkg-dev equivs fakeroot findutils gpg grep git hostname libc-bin lintian locales make mawk net-tools patch procps rsync sed sipcalc sudo util-linux xsltproc -y --no-install-recommends
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN groupadd -r -g 1000 toor
RUN useradd -rm -d /home/toor -s /bin/bash -g root -G sudo -u 1000 toor
RUN mkdir -p /etc/sudoers.d || true
RUN echo "%sudo  ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/20-build
USER toor
WORKDIR /home/toor
RUN mkdir -p /home/toor/src
RUN mkdir -p /home/toor/builds
RUN mkdir -p /home/toor/.gnupg
##
# set NAME and EMAIL
##
ENV NAME Damir Sh. Yakupov
ENV EMAIL yds@bk.ru
##
##
# install builder tool and dependencies
##
### robodoc optional
RUN git clone https://github.com/gumpu/ROBODoc.git /home/toor/src/robodoc
RUN cd /home/toor/src/robodoc && ./build_robodoc.sh && sudo make install
###
RUN git clone https://github.com/tengre/bashlyk.git /home/toor/src/bashlyk
RUN cd /home/toor/src/bashlyk && ./setup.sh && sudo make install
RUN git clone https://github.com/tengre/kolchan.git /home/toor/src/kolchan
RUN cd /home/toor/src/kolchan && touch VERSION && src/kolchan-automake && sudo make install
##
## or use prepared packages "bashlyK" and "kolchan" for some Ubuntu distros
#RUN add-apt-repository ppa:yds/bashlyk -y
#RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 773461F3 || true
#RUN apt update -y && apt-get install bashlyk kolchan -y --no-install-recommends
##
# usage:
# docker build --tag=<package builder container name> .
# docker run -v <src>:/home/toor/src -v <builds>:/home/toor/builds -v <gnupg>:</home/toor/.gnupg> -i -t <package builder container name>
#
# cd ~/src/<project with valid debian files>
### if a prepared "configure" is used, then you need to replace the kolchan-automake call with something like "./configure && make"
### if autotools is not used for assembly at all, then kolchan-automake can be omitted
### see help (--help) for each kolchan-* tool
# kolchan-automake && kolchan-up2deb && kolchan-builddeb && kolchan-builddeb --mode source
# exit
# cd <builds>
# dput <..>
#