##
## $Id: Makefile.am 944 2023-05-09 14:11:17+00:00 yds $
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
DOCBOOK_REDHAT = /usr/share/sgml/docbook/xsl-stylesheets/manpages/docbook.xsl
DOCBOOK_DEBIAN = /usr/share/sgml/docbook/stylesheet/xsl/docbook-xsl/manpages/docbook.xsl
DOCBOOK_2_MAN  = $(shell test -f $(DOCBOOK_REDHAT) && echo $(DOCBOOK_REDHAT) || echo $(DOCBOOK_DEBIAN))
XLSTPROC       = xsltproc -''-nonet -''-param man.charmap.use.subset "0"
#BUILD_DATE     = $(shell test -f ../VERSION && cut -f 3 -d' ' ../VERSION || date '+%Y-%m-%d')

bashlyk.1: bashlyk1.xml
	$(XLSTPROC) $(DOCBOOK_2_MAN) $<

bashlyk.7: bashlyk7.xml
	$(XLSTPROC) $(DOCBOOK_2_MAN) $<

## robodoc may not be installed, documentation generation has been moved to the kolchan-robodoc tool
#all:
#	$(shell) cd .. && robodoc && cd ./doc && patch < ${PACKAGE}.html.patch && sed -i -re "s/^(<p>Generated.from.*V.*on).*/\1 ${BUILD_DATE}/ig" bashlyk.html
#	@echo "DOCBOOK_2_MAN = \"$(DOCBOOK_2_MAN)\""
##