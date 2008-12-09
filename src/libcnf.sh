#
# $Id$
#
[ -n "$_BASHLYK_LIBCNF" ] && return 0 || _BASHLYK_LIBCNF=1
#
# link section
#
[ -s "$_bashlyk_pathLib/liblog.sh" ] && . "${_bashlyk_pathLib}/liblog.sh"
#
# global variables
#
_bashlyk_aBin+=" cat date echo grep sleep "
: ${_bashlyk_pathCnf=$(pwd)}
#
# function section
#
udfGetConfig() {
 local aconf chIFS conf fn i path
 #
 i=0
 [ -n "$1" ] && {
  path=$(dirname "$1")
  chIFS=$IFS
  IFS='.'
  for fn in $(basename "$1"); do
   aconf[++i]=$fn
  done
  IFS=$chIFS
 } || return -1
 conf=
 for ((i=$((${#aconf[*]}-1)); $i; --i)); do
  [ -n "$conf" ]                         && conf="${aconf[$i]}.${conf}" || conf=${aconf[$i]}
  [ -s "${_bashlyk_pathCnf}/$conf" ]     && . "${_bashlyk_pathCnf}/$conf"
  [ -s "${path}/$conf" ]                 && . "${path}/${conf}"
 done
 return 0
}
#
udfSetConfig() {
 [ -n "$1" -a -n "$2" ] || return -1
 local conf sKeyValue chIFS=$IFS
 [ "$1" == "$(basename $1)" ] && conf="${_bashlyk_pathCnf}/$1" || conf=$1
 date "+#Created %Y.%m.%d %H:%M:%S by $USER $0 ($$)" >> $conf
 IFS=';'
 for sKeyValue in $2; do
  [ -n "${sKeyValue}" ] && echo "${sKeyValue}" >> $conf
 done
 IFS=$chIFS
 return 0
}
#
udfLibCnf() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -w "test\|libcnf")" ] && return 0
 local s conf="$$.test.cnf.bashlyk.conf"
 echo "--- libcnf.sh tests --- start"
 for s in udfSetConfig udfGetConfig; do
  sleep 1
  echo "check $s:"
  $s $conf "a=b;sDate=\"$(date)\""
 done
 echo "see ${conf}:"
 cat "${_bashlyk_pathCnf}/${conf}"
 rm -fv "${_bashlyk_pathCnf}/${conf}"
 echo "--- libcnf.sh tests ---  done"
 return 0
}
#
# main section
#
udfLibCnf
