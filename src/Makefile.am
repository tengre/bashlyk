##
## $Id: Makefile.am 870 2018-08-20 00:52:27+04:00 toor $
##
#
AUTOMAKE_OPTIONS	= -Wno-portability
#
ETC			= /etc
bin_SCRIPTS		= bashlyk
sysconfdir		= ${ETC}/bashlyk
sysconf_DATA		= bashlyk.conf
syslibdir		= /usr/share/bashlyk
syslib_DATA		= $(wildcard lib*.sh) $(wildcard *.awk) testunit.sh ../VERSION
DESTDIR			=

install-exec-hook:

	$(shell) [ -L ${syslibdir}/bashlyk ] || ln -s ${bindir}/bashlyk ${syslibdir}/bashlyk
