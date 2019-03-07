##
## $Id: Makefile.am 906 2019-03-07 16:23:03+04:00 yds $
##
#
AUTOMAKE_OPTIONS	= -Wno-portability
#
bin_SCRIPTS		= bashlyk
sysconfdir		= /etc/bashlyk
sysconf_DATA		= bashlyk.conf
datadir			= /usr/share/bashlyk
data_DATA		= $(wildcard lib*.sh) $(wildcard *.awk) testunit.sh ../VERSION
DESTDIR			=

install-exec-hook:

	$(shell) [ -d ${datadir}         ] || mkdir -p ${datadir}
	$(shell) [ -L ${datadir}/bashlyk ] || ln -s ${bindir}/bashlyk ${datadir}/bashlyk


uninstall-hook:

	$(shell) [ -L ${datadir}/bashlyk ] && rm -f ${datadir}/bashlyk
	$(shell) [ -d ${datadir}         ] && rmdir ${datadir}
	$(shell) [ -d ${sysconfdir}      ] && rmdir ${sysconfdir}
