##
## $Id: Makefile.am 924 2019-05-04 13:33:39+04:00 yds $
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

	$(shell) [ -d ${DESTDIR}${datadir}         ] || mkdir -p ${DESTDIR}${datadir}
	$(shell) [ -L ${DESTDIR}${datadir}/bashlyk ] || ln -s ${DESTDIR}${bindir}/bashlyk ${DESTDIR}${datadir}/bashlyk


uninstall-hook:

	$(shell) [ -L ${DESTDIR}${datadir}/bashlyk ] && rm -f ${DESTDIR}${datadir}/bashlyk
	$(shell) [ -d ${DESTDIR}${datadir}         ] && rmdir ${DESTDIR}${datadir}
	$(shell) [ -d ${DESTDIR}${sysconfdir}      ] && rmdir ${DESTDIR}${sysconfdir}
