##
## $Id: Makefile.am 907 2019-03-11 22:40:54+04:00 yds $
##
#
AUTOMAKE_OPTIONS	= -Wno-portability
#
SHAREDOC		= /usr/share/doc
docdir			= ${SHAREDOC}/${PACKAGE}/html
doc_DATA		= $(wildcard *.html) $(wildcard *.css)
man1_MANS		= bashlyk.1
man7_MANS		= bashlyk.7
DESTDIR			=
DOCBOOK_REDHAT		= /usr/share/sgml/docbook/xsl-stylesheets/manpages/docbook.xsl
DOCBOOK_DEBIAN		= /usr/share/sgml/docbook/stylesheet/xsl/docbook-xsl/manpages/docbook.xsl
DOCBOOK_2_MAN		= $(shell test -f $(DOCBOOK_REDHAT) && echo $(DOCBOOK_REDHAT) || echo $(DOCBOOK_DEBIAN))
XLSTPROC		= xsltproc -''-nonet -''-param man.charmap.use.subset "0"

bashlyk.1: bashlyk1.xml
	$(XLSTPROC) $(DOCBOOK_2_MAN) $<

bashlyk.7: bashlyk7.xml
	$(XLSTPROC) $(DOCBOOK_2_MAN) $<

all:
	$(shell) cd .. && robodoc && cd ./doc && patch < ${PACKAGE}.html.patch
	@echo "DOCBOOK_2_MAN = \"$(DOCBOOK_2_MAN)\""
