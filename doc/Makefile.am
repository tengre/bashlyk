##
## $Id: Makefile.am 906 2019-03-07 16:22:10+04:00 yds $
##
#
AUTOMAKE_OPTIONS	= -Wno-portability
#
DOC			= /usr/share/doc
docdir			= ${DOC}/${PACKAGE}/html
doc_DATA		= $(wildcard *.html) $(wildcard *.css)
man1_MANS		= bashlyk.1
man7_MANS		= bashlyk.7
DESTDIR			=
DB2MAN 			= /usr/share/sgml/docbook/stylesheet/xsl/docbook-xsl/manpages/docbook.xsl
## centos ## DB2MAN			= /usr/share/sgml/docbook/xsl-stylesheets/manpages/docbook.xsl
XP     			= xsltproc -''-nonet -''-param man.charmap.use.subset "0"

bashlyk.1: bashlyk1.xml
	$(XP) $(DB2MAN) $<

bashlyk.7: bashlyk7.xml
	$(XP) $(DB2MAN) $<

all:
	$(shell) cd .. && robodoc && cd ./doc && patch < ${PACKAGE}.html.patch
