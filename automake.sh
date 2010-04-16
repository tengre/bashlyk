udfMain() {
 local fn sPkg sInit sVer=0.1 sEmail='yds@bk.ru'
 sInit="AC_INIT(FULL-PACKAGE-NAME, VERSION, BUG-REPORT-ADDRESS)"

 for fn in ChangeLog AUTHORS NEWS README; do [ -f $fn ] || touch $fn; done

 sPkg=$(basename $(pwd) | cut -f 1 -d'-')
 sVer=$(grep -i version ChangeLog | head -n 1 | xargs | cut -f 2 -d' ')
 sEmail="$(head -n 1 AUTHORS)"

 robodoc
 autoscan
 mv configure.scan configure.ac
 autoheader
 cat configure.ac | sed -e "s/${sInit}/AC_INIT(${sPkg}, ${sVer}, \"${sEmail}\")\nAM_INIT_AUTOMAKE/ig" >> $$ \
  && mv $$ configure.ac
 aclocal
 automake --add-missing --copy
 autoconf
 ./configure --prefix=/usr && make
 return 0
}
#
#
#
udfMain $*
