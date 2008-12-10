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
_bashlyk_aBin+=" basename cat date dirname echo grep pwd rm sleep "
: ${_bashlyk_pathCnf:=$(pwd)}
#
# function section
#
udfGetConfig() {
 local aconf chIFS conf fn i=0 
 #
 [ -n "$1" ] || return -1
 [ "$1"  = "$(basename $1)" -a -f ${_bashlyk_pathCnf}/$1 ] || _bashlyk_pathCnf=
 [ "$1"  = "$(basename $1)" -a -f $1 ] && _bashlyk_pathCnf=$(pwd)
 [ "$1" != "$(basename $1)" -a -f $1 ] && _bashlyk_pathCnf=$(dirname $1)
 [ -n "${_bashlyk_pathCnf}" ] || return -1
 #
 chIFS=$IFS
 IFS='.'
 for fn in $(basename "$1"); do
  aconf[++i]=$fn
 done
 IFS=$chIFS
 conf=
 for ((i=$((${#aconf[*]}-1)); $i; --i)); do
  [ -n "$conf" ]                         && conf="${aconf[$i]}.${conf}" || conf=${aconf[$i]}
  [ -s "${_bashlyk_pathCnf}/$conf" ]     && . "${_bashlyk_pathCnf}/$conf"
 done
 return 0
}
#
udfSetConfig() {
 [ -n "$1" -a -n "$2" ] || return -1
 local conf sKeyValue chIFS=$IFS
 [ "$1" != "$(basename $1)" ] && _bashlyk_pathCnf=$(dirname $1)
 conf="${_bashlyk_pathCnf}/$(basename $1)"
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
 [ -z "$(echo "${_bashlyk_sArg}" | grep -e "--bashlyk-test" | grep -w "cnf")" ] && return 0
 local s conf="$$.testlib.conf"
 echo "--- libcnf.sh tests --- start"
 echo "Relative path to config test (pathCnf=$_bashlyk_pathCnf)"
 for s in udfSetConfig udfGetConfig; do
  sleep 1
  echo "check $s:"
  $s $conf "a=b;sDate=\"$(date)\""
  echo "pathCnf $_bashlyk_pathCnf"
 done
 echo "see ${conf}:"
 cat "${_bashlyk_pathCnf}/${conf}"
 rm -fv "${_bashlyk_pathCnf}/${conf}"
 echo "Absolute path to config test (pathCnf=$_bashlyk_pathCnf)"
 for s in udfSetConfig udfGetConfig; do
  sleep 1
  echo "check $s:"
  $s /tmp/$conf "a=b;sDate=\"$(date)\""
  echo "pathCnf $_bashlyk_pathCnf"
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
