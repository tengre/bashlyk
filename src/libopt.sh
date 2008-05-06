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
udfGetOptHash() {
 [ -n "$*" ] || return -1
 local k v csvKeys csvHash sOpt bFound
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
    csvHash+="$v=\"$(udf_2 $2)\";"
    shift 2
   else
    csvHash+="$v=\"$v\";"
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
 local sMask confTmp
 sMask=$(umask)
 umask 0077
 confTmp="/tmp/$$.temp.${_bashlyk_s0}.conf"
 udfSetConfig $confTmp "$*"
 udfGetConfig $confTmp
 #rm -v $confTmp >/dev/null 2>&1
 umask $sMask
 return 0
}
#
udfGetOpt() {
 local s=$(udfGetOptHash $*)
 [ -n "$s" ] && udfSetOptHash $s
 return 0
}
#
#udfExcludeFromHash() {
# [ -n "$*" ] || return -1
# local v=$1
# shift
# local csv="$*"
# if [ -n "$(echo $csv | grep -e "$v")" ]; then
#  echo $csv | sed -e s/$v=.*;//
# fi
#}
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
