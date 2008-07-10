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
 local aconf chIFS conf fn i
 #
 chIFS=$IFS
 IFS='.'
 i=0
 [ -n "$1" ] && for fn in $1; do aconf[++i]=$fn; done || return -1
 IFS=$chIFS
 conf=
 for ((i=$((${#aconf[*]}-1)); $i; --i)); do
  [ -n "$conf" ]                         && conf=${aconf[$i]}".$conf" || conf=${aconf[$i]}
  [ -s "${_bashlyk_pathCnf}/$conf" ]     && . ${_bashlyk_pathCnf}/$conf
  #[ -s "$conf" ]                         && . $conf
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
# main section
#
#Test Block start
if [ -n "$(echo "${_bashlyk_aTest}" | grep -w cnf)" ]; then
 echo "--- libcnf.sh tests --- start"
 _bashlyk_confTest="$$.test.cnf.bashlyk.conf"
 for s in udfSetConfig udfGetConfig; do
  sleep 1
  echo "check $s:"
  $s ${_bashlyk_confTest} "a=b;sDate=\"$(date)\""
 done
 echo "see ${_bashlyk_confTest}:"
 cat "${_bashlyk_pathCnf}/${_bashlyk_confTest}"
 rm -fv "${_bashlyk_pathCnf}/${_bashlyk_confTest}"
 echo "--- libcnf.sh tests ---  done"
fi
#Test Block stop
true
