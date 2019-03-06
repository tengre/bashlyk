##
## $Id: Makefile.am 904 2019-03-07 00:22:50+04:00 yds $
##
#
AUTOMAKE_OPTIONS	= -Wno-portability
#
ETC			= /etc
bin_SCRIPTS		= bashlyk
sysconfdir		= ${ETC}/bashlyk
sysconf_DATA		= bashlyk.conf
libdir			= /usr/share/bashlyk
lib_DATA		= $(wildcard lib*.sh) $(wildcard *.awk) testunit.sh ../VERSION
DESTDIR			=

install-exec-hook:

	$(shell) [ -L ${libdir}/bashlyk ] || ln -s ${bindir}/bashlyk ${libdir}/bashlyk
