#!/usr/bin/env bash
#
# $Git: automake.sh 1.94-49-939 2019-12-13 12:21:17+04:00 yds $
#
udfMain() {
 local fn sPkg sInit sVer sAuthor
 #
 sVer=0.1
 sAuthor='Damir Sh. Yakupov <yds@bk.ru>'
 #
 [[ -s AUTHORS ]] || echo $sAuthor > AUTHORS
 #
 for fn in ChangeLog AUTHORS NEWS README; do [[ -f $fn ]] || touch $fn; done
 #
 sPkg=$(basename $(pwd))
 sVer=$(grep -i version ChangeLog | head -n 1 | xargs | cut -f 2 -d' ')
 sPkg=${sPkg/-$sVer/}
 sEmail="$(grep -o -E '<.*>' AUTHORS | tr -d '<|>' | head -n 1)"
 [[ $sVer ]] || sVer=0.001
 [[ -f VERSION ]] || echo $sVer > VERSION
 #
 autoscan
 mv configure.scan configure.ac
 autoheader
 cat configure.ac | \
  sed -e "s/AC_INIT.*/AC_INIT(${sPkg}, ${sVer}, ${sEmail})\nAM_INIT_AUTOMAKE/ig" >> $$ \
  && mv $$ configure.ac
 aclocal
 autoconf
 autoreconf
 automake --add-missing --copy
 ./configure --prefix=/usr && make
 return 0
}
#
#
#
udfMain
#
