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
 [ -n "$1" ] || return -1
 #
 local aconf chIFS conf fn i=0 pathCnf=$_bashlyk_pathCnf
 #
 [ "$1"  = "$(basename $1)" -a -f ${pathCnf}/$1 ] || pathCnf=
 [ "$1"  = "$(basename $1)" -a -f $1 ] && pathCnf=$(pwd)
 [ "$1" != "$(basename $1)" -a -f $1 ] && pathCnf=$(dirname $1)
 #
 if [ -z "$pathCnf" ]; then
  [ -f "/etc${_bashlyk_pathPrefix}/$1" ] && pathCnf="/etc${_bashlyk_pathPrefix}" || return -1
 fi
 #
 chIFS=$IFS
 IFS='.'
 for fn in $(basename "$1"); do
  aconf[++i]=$fn
 done
 IFS=$chIFS
 conf=
 for ((i=$((${#aconf[*]}-1)); $i; --i)); do
  [ -n "$conf" ]                  && conf="${aconf[$i]}.${conf}" || conf=${aconf[$i]}
  [ -s "${pathCnf}/${conf}" ]     && . "${pathCnf}/${conf}"
 done
 return 0
}
#
udfSetConfig() {
 [ -n "$1" -a -n "$2" ] || return -1
 #
 local conf sKeyValue chIFS=$IFS pathCnf=$_bashlyk_pathCnf
 #
 [ "$1" != "$(basename $1)" ] && pathCnf=$(dirname $1)
 conf="${pathCnf}/$(basename $1)"
 IFS=';'
 {
  LANG=C date "+#Created %c by $USER $0 ($$)"
  for sKeyValue in $2; do
   [ -n "${sKeyValue}" ] && echo "${sKeyValue}"
  done
 } >> $conf 2>/dev/null
 IFS=$chIFS
 return 0
}
#
udfLibCnf() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -e "--bashlyk-test" | grep -w "cnf")" ] && return 0
 local s conf="$$.testlib.conf"
 echo "--- libcnf.sh tests --- start"
 printf "#\n# Relative path to config config file (${_bashlyk_pathCnf}/${conf})\n#\n"
 udfAddFile2Clean "${_bashlyk_pathCnf}/${conf}"
 for s in udfSetConfig udfGetConfig; do
  echo "check $s:"
  $s $conf "a=b;sDate=\"$(date)\""
  sleep 1
 done
 echo "see ${_bashlyk_pathCnf}/${conf}:"
 cat "${_bashlyk_pathCnf}/${conf}"
 #
 conf=$(mktemp -t "XXXXXXXX.${conf}") || udfThrow "Error: temporary file $conf do not created..."
 udfAddFile2Clean $conf
 printf "#\n# Absolute path to config file ($conf))\n#\n"
 for s in udfSetConfig udfGetConfig; do
  sleep 1
  echo "check $s:"
  $s $conf "a=b;sDate=\"$(date)\""
 done
 echo "see ${conf}:"
 cat "${conf}"
 echo "--- libcnf.sh tests ---  done"
 return 0
}
#
# main section
#
udfLibCnf
