#
# $Id$
#
[ -n "$_BASHLYK_LIBCNF" ] && return 0
_BASHLYK_LIBCNF=1
#
aRequiredBin="cat date echo sleep"
_bashlyk_pathLIB=${_bashlyk_pathLIB:=.}
_bashlyk_pathCNF=${_bashlyk_pathCNF:=.}
[ -s "$_bashlyk_pathLIB/liblog.sh" ] && . "${_bashlyk_pathLIB}/liblog.sh"
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
 [ -d ${_bashlyk_pathCNF} ] || eval 'udfThrow "Error: Config files folder (${_bashlyk_pathCNF}) not exist..."; exit 1'
 #
 local conf=
 for ((i=$((${#aconf[*]}-1)); $i; --i)); do
  [ -n "$conf" ] && conf=${aconf[$i]}".$conf" || conf=${aconf[$i]}
  [ -s "${_bashlyk_pathCNF}/$conf" ] && . ${_bashlyk_pathCNF}/$conf
  [ -s "$HOME/.bashlyk/$conf" ]      && . $HOME/.bashlyk/$conf
  [ -s "$conf" ]                     && . $conf
 done
 return 0
}
#
udfSetConfig() {
 [ -n "$1" -a -n "$2" ] || return -1
 date "+#Created %Y.%m.%d %H:%M:%S by $USER $0 ($$)" > $_bashlyk_pathCNF/$1
 local chIFS=$IFS
 IFS=';'
 for sKeyValuePair in $2; do echo "${sKeyValuePair}" >> $_bashlyk_pathCNF/$1; done
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
