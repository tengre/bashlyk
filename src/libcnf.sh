#
# $Id$
#
aRequiredBin="date echo"
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
 local conf=
 for ((i=$((${#aconf[*]}-1)); $i; --i)); do
  [ -n "$conf" ] && conf=${aconf[$i]}".$conf" || conf=${aconf[$i]}
  [ -s "$conf" ] && . $conf
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

#[ -z "$1" -o "$1" != "test" ] && exit 0
#shift
#udfGetConfig $*
#udfSetConfig "test.conf" $*
#
