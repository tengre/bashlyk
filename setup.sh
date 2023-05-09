#!/usr/bin/env bash
#
# $Git: setup.sh 1.96-5-941 2023-05-09 19:23:16+00:00 yds $
#
main() {

  local fn rc sPkg sInit sVer sAuthor sNotFound=''

  for s in aclocal autoconf autoheader automake autoreconf autoscan basename cut date head grep make mv sed sudo tr xargs; do
    hash $s 2>/dev/null || sNotFound+="\"$s\" "
  done

  if [[ $sNotFound ]]; then
    echo "error: required external tool(s) - ${sNotFound}.." >&2
    return 1
  fi

  sVer=0.1
  sAuthor='Damir Sh. Yakupov <yds@bk.ru>'
  [[ -s AUTHORS ]] || echo $sAuthor > AUTHORS

  for fn in ChangeLog AUTHORS NEWS README; do [[ -f $fn ]] || touch $fn; done
  sPkg=$(basename $(pwd))
  sVer=$(grep -i version ChangeLog | head -n 1 | xargs | cut -f 2 -d' ')
  sPkg=${sPkg/-$sVer/}
  sEmail="$(grep -o -E '<.*>' AUTHORS | tr -d '<|>' | head -n 1)"
  [[ $sVer ]] || sVer=0.1
  [[ -f VERSION ]] || echo $sVer > VERSION
  #
  autoscan
  mv configure.scan configure.ac
  autoheader
  if [[ ! -f configure.ac ]]; then
    echo "error: configure.ac not found.." >&2
    return 1
  fi
  sed -i -e "s/AC_INIT.*/AC_INIT(${sPkg}, ${sVer}, ${sEmail})\nAM_INIT_AUTOMAKE/ig" configure.ac
  [[ -x ./bashlyk-robodoc.sh ]] && ./bashlyk-robodoc.sh || true
  aclocal
  autoconf
  autoreconf
  automake --add-missing --copy
  if [[ ! -x ./configure ]]; then
    echo "error: ./configure not found.." >&2
    return 1
  fi
  ./configure --prefix=/usr && make
  rc=$?
  if (( rc == 0 )); then
    echo "Try to install? You will need to elevate the rights to root: [y/n]"
    read -t 32
    if [[ $REPLY =~ ^[Yy] ]]; then
      sudo make install
      return $?
    fi
  fi
  return $rc
}
#
#
#
main
#
