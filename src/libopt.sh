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
_bashlyk_aRequiredCmd_opt="echo getopt grep mktemp tr sed umask"
#
# function section
#
udfQuoteIfNeeded() {
 [ -n "$(echo "$*" | grep -e [[:space:]])" ] && echo "\"$*\"" || echo "$*"
}
#
udf2_() {
 echo "$*" | tr ' ' '_'
 return 0
}
#
udf_2() {
 udfQuoteIfNeeded $(echo "$*" | tr '_' ' ')
 return 0
}
#
udfGetOptHash() {
 [ -n "$*" ] || return -1
 local k v csvKeys csvHash=';' sOpt bFound
 csvKeys=$1
 shift
 sOpt="$(getopt -l $csvKeys -n $0 -- $0 $@)"
 #[ $? != 0 ] && return 2
 eval set -- "$sOpt"
 while true; do
  [ -n "$1" ] || break
  bFound=
  for k in $(echo $csvKeys | tr ',' ' '); do
   v=$(echo $k | tr -d ':')
   [ "--$v" == "$1" ] && bFound=1 || continue
   if [ -n "$(echo $k | grep ':$')" ]; then
    csvHash+="$v=$(udf_2 $2);"
    shift 2
   else
    csvHash+="$v=1;"
    shift
   fi
  done
  [ -z "$bFound" ] && shift
 done
 shift
 echo "$csvHash"
 return 0
}
#
udfSetOptHash() {
 [ -n "$*" ] || return -1
 local sMask confTmp iRC
 sMask=$(umask)
 umask 0077
 confTmp=$(mktemp -t "${_bashlyk_s0}.XXXXXXXX") && {
  udfAddFile2Clean $confTmp
  udfSetConfig $confTmp "$*"
  udfGetConfig $confTmp
  rm -f $confTmp >/dev/null 2>&1
  iRC=0
 } || iRC=1
 umask $sMask
 return $iRC
}
#
udfGetOpt() {
 udfSetOptHash $(udfGetOptHash $*)
}
#
udfExcludePairFromHash() {
 [ -n "$*" ] || return 1
 local s=$1
 shift
 local csv="$*"
 echo "$csv" | sed -e "s/;$s;//"
 return 0
}
#
udfLibOpt() {
 local s
 [ -z "$(echo "${_bashlyk_sArg}" | grep -e "--bashlyk-test" | grep -w "opt")" ] && return 0
 echo "--- libopt.sh tests --- start"
 for s in udfGetOpt; do
  echo "check $s with options --_bashlyk_sTest1 $(uname) --_bashlyk_sTest2 --_bashlyk_sTest3 $(udf2_ $(date)) :"
  $s "_bashlyk_sTest1:,_bashlyk_sTest2,_bashlyk_sTest3:" --_bashlyk_sTest1 $(uname) --_bashlyk_sTest2 --_bashlyk_sTest3 $(udf2_ $(date))
  echo "see variables _bashlyk_sTest1=\"${_bashlyk_sTest1}\" _bashlyk_sTest2=\"${_bashlyk_sTest2}\" _bashlyk_sTest3=\"${_bashlyk_sTest3}\""
 done
 echo "--- libopt.sh tests ---  done"
 return 0
}
#
# main section
#
udfLibOpt
