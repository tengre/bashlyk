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
_bashlyk_aBin+="echo getopt grep tr umask"
#
# function section
#
udf2_() {
 echo "$*" | tr ' ' '_'
 return 0
}
#
udf_2() {
 echo "$*" | tr '_' ' '
 return 0
}
#
udfGetOpt() {
 local k v confTmp csvKeys csvHash sMask sOpt sUnknown
 csvKeys=$1
 shift
 sOpt="$(getopt -l $csvKeys -n $0 -- $0 $@)"
 #[ $? != 0 ] && return 2
 eval set -- "$sOpt"
 while true; do
  [ -n "$1" ] || break
  for k in $(echo $csvKeys | tr ',' ' '); do
   v=$(echo $k | tr -d ':')
   [ "--$v" == "$1" ] || continue
   if [ -n "$(echo $k | grep ':$')" ]; then
    csvHash+=";$v=\"$(udf_2 $2)\""
    shift 2
   else
    csvHash+=";$v=\"$v\""
    shift
   fi
  done
  sUnknown+="$1 "
  shift
 done
 csvHash+=";sUnknown=\"$sUnknown\""
 shift
 sMask=$(umask)
 umask 0077
 confTmp="/tmp/$$.temp.${_bashlyk_s0}.conf"
 udfSetConfig $confTmp "$csvHash"
 udfGetConfig $confTmp
 #rm -v $confTmp >/dev/null 2>&1
 umask $sMask
 return 0
}
#
# main section
#
#Test Block
if [ -n "$(echo "${_bashlyk_aTest}" | grep -w opt)" ]; then
 echo "--- libopt.sh tests --- start"
 for s in udfGetOpt; do
  echo "check $s with options --_bashlyk_sTest1 $(uname) --_bashlyk_sTest2 --_bashlyk_sTest3 $(udf2_ $(date)) :"
  $s "_bashlyk_sTest1:,_bashlyk_sTest2,_bashlyk_sTest3:" --_bashlyk_sTest1 $(uname) --_bashlyk_sTest2 --_bashlyk_sTest3 $(udf2_ $(date))
  echo "see variables _bashlyk_sTest1=\"${_bashlyk_sTest1}\" _bashlyk_sTest2=\"${_bashlyk_sTest2}\" _bashlyk_sTest3=\"${_bashlyk_sTest3}\""
 done
 echo "--- libcnf.sh tests ---  done"
fi
#Test Block
true
