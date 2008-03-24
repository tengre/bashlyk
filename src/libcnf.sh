#
# $Id$
#
aRequiredBin="cat date echo sleep"
_bashlyk_pathLib=${_bashlyk_pathLib:=$(pwd)}
_bashlyk_pathCnf=${_bashlyk_pathCnf:=$(pwd)}
#
[ -n "$_BASHLYK_LIBCNF" ] && return 0
_BASHLYK_LIBCNF=1
#
[ -s "$_bashlyk_pathLib/liblog.sh" ] && . "${_bashlyk_pathLib}/liblog.sh"
#
udfGetConfig() {
 local aconf=
 local i=0
 local chIFS=$IFS
 #
 IFS='.'
 [ -n "$1" ] && for fn in $1; do aconf[++i]=$fn; done || return -1
 IFS=$chIFS
 #
 [ -d ${_bashlyk_pathCnf} ] || \
  eval 'udfThrow "Error: Config files folder (${_bashlyk_pathCnf}) not exist..."; exit 1'
 #
 local conf=
 for ((i=$((${#aconf[*]}-1)); $i; --i)); do
  [ -n "$conf" ] && conf=${aconf[$i]}".$conf" || conf=${aconf[$i]}
  [ -s "${_bashlyk_pathCnf}/$conf" ] && . ${_bashlyk_pathCnf}/$conf
  [ -s "$HOME/.bashlyk/$conf" ]      && . $HOME/.bashlyk/$conf
  [ -s "$conf" ]                     && . $conf
 done
 return 0
}
#
udfSetConfig() {
 [ -n "$1" -a -n "$2" ] || return -1
 date "+#Created %Y.%m.%d %H:%M:%S by $USER $0 ($$)" > $_bashlyk_pathCnf/$1
 local chIFS=$IFS
 IFS=';'
 for sKeyValuePair in $2; do echo "${sKeyValuePair}" >> $_bashlyk_pathCnf/$1; done
 IFS=$chIFS
 return 0
}
################################################
################################################
###### Test Block ##############################
################################################
################################################
if [ "$1" = "test.libcnf.bashlyk" ]; then
 echo "functionality test:"
 conftest=$1.conf
 for fn in udfSetConfig udfGetConfig; do
  sleep 1
  echo "$fn $conftest $2"
  $fn $conftest "$2"
 done
 echo "see $1.conf:"
 cat $1.conf
fi
