##
## $Id: Makefile.am 868 2018-08-17 17:54:10+04:00 toor $
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

	ln -sf ${bindir}/bashlyk ${syslibdir}/bashlyk
