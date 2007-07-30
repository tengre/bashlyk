#
# $Id$
#
aRequiredBin="date echo"
[ -z "$_bashlyk_pathLIB" ] && _bashlyk_pathLIB=.
[ -z "$_bashlyk_pathCNF" ] && _bashlyk_pathCNF=.
[ -s "$_bashlyk_pathLIB/liblog.sh" ] && . "${_bashlyk_pathLIB}/liblog.sh"
#
udfGetConfig() {
 local aconf=
 local i=0
 local chIFS=$IFS
 #
 [ -n "$2" ] && local pathCONF="$2" || local pathCONF=${_bashlyk_pathCONF}
 IFS='.'
 [ -n "$1" ] && for fn in $1; do aconf[++i]=$fn; done || return -1
 IFS=$chIFS
 #
 [ -d $pathCONF ] && eval 'udfThrow "Error: Config files folder ($pathCONF) not exist..."; exit 1'
 #
 local conf=
 for ((i=$((${#aconf[*]}-1)); $i; --i)); do
  [ -n "$conf" ] && conf=${aconf[$i]}".$conf" || conf=${aconf[$i]}
  [ -s "$pathCNF/$conf" ] && . $pathCNF/$conf
 done
 return 0
}
#
udfSetConfig() {
 [ -n "$1" -a -n "$2" ] || return -1
 date "+#Created %Y.%m.%d %H:%M:%S by $USER $0 ($$)" > $1
 local chIFS=$IFS
 IFS=':'
 for sKeyValuePair in $2; do echo $sKeyValuePair >> $1; done
 IFS=$chIFS
 return 0
}
#
#
#
#
if [ "$1" = "bashlyk_test" ]; then
 for fn in udfGetConfig udfSetConfig; do
  sleep 1
  $fn "$fn $1"
 done
fi
