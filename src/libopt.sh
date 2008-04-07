#
# $Id$
#
[ -n "$_BASHLYK_LIBOPT" ] && return 0 || _BASHLYK_LIBOPT=1
#
# link section
#
[ -s "$_bashlyk_pathLib/libcnf.sh" ] && . "${_bashlyk_pathLib}/libcnf.sh"
#
# global variables
#
_bashlyk_aBin+="echo getopt grep tr"
#
# function section
#
udfEscapeSpaces() {
 echo "$*" | tr ' ' '_'
 return 0
}
#
udfRestoreSpaces() {
 echo "$*" | tr '_' ' '
 return 0
}
#
udfGetOpt() {
 local k v b sOpt sLongKeys sPair
 sLongKeys=${1:-$_bashlyk_sLongOptKeys}
 shift
 local sOpt="$(getopt -l $sLongKeys -n $0 -- $0 $@)"
 [ $? != 0 ] && echo error 2 && return 2
 eval set -- "$sOpt"
 for k in $(echo $sLongKeys | tr ',' ' '); do
  v=$(echo $k | tr -d ':')
  while true; do
   [ "--$v" == "$1" ] || continue
   if [ -n "$(echo $k | grep ':$')" ]; then
    sPair+=";$v=\"$(udfRestoreSpaces $2)\""
    shift 2
   else
    sPair+=";$v=\"$v\""
    shift
   fi
   break
  done
 done
 shift
 udfSetConfig "$$.temp.${_bashlyk_s0}.conf" "$sPair"
 udfGetConfig "$$.temp.${_bashlyk_s0}.conf"
 return 0
}
#
# main section
#
#Test Block
if [ -n "$(echo "${_bashlyk_aTest}" | grep -w opt)" ]; then
 echo "--- libopt.sh tests --- start"
 for s in udfGetOpt; do
  echo "check $s with options --_bashlyk_sTest1 $(uname) --_bashlyk_sTest2 --_bashlyk_sTest3 $(udfEscapeSpaces $(date)) :"
  $s "_bashlyk_sTest1:,_bashlyk_sTest2,_bashlyk_sTest3:" --_bashlyk_sTest1 $(uname) --_bashlyk_sTest2 --_bashlyk_sTest3 $(udfEscapeSpaces $(date))
  echo "see variables _bashlyk_sTest1=\"${_bashlyk_sTest1}\" _bashlyk_sTest2=\"${_bashlyk_sTest2}\" _bashlyk_sTest3=\"${_bashlyk_sTest3}\""
 done
 echo "--- libcnf.sh tests ---  done"
fi
#Test Block
true
