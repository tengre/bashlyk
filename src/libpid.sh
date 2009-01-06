#
# $Id$
#
[ -n "$_BASHLYK_LIBPID" ] && return 0 || _BASHLYK_LIBPID=1
#
# link section
#
[ -s "$_bashlyk_pathLib/liblog.sh" ] && . "${_bashlyk_pathLib}/liblog.sh"
[ -s "$_bashlyk_pathLib/libmd5.sh" ] && . "${_bashlyk_pathLib}/libmd5.sh"
#
# global variables
#
_bashlyk_aBin+=" cat date echo grep head mkdir ps rm sed sleep"
: ${_bashlyk_afnClean:=}
: ${_bashlyk_apathClean:=}
: ${_bashlyk_fnPid:=}
: ${_bashlyk_fnSock:=}
: ${_bashlyk_s0:=$(basename $0)}
: ${_bashlyk_pathRun:=/tmp}
: ${_bashlyk_sArg:=$*}
#
# function section
#
udfCheckStarted() {
 [ -n "$*" ] || return -1
 local pid=$1
 local cmd=${2:-}
 shift 2
 [ -n "$(ps -p $pid -o pid= -o args= | grep -vw $$ | grep -w -e "$cmd" | grep -e "$*" | head -n 1)" ] && return 0 || return 1
}

udfSetPid() {
 local fnPid pid
 [ -n "$_bashlyk_sArg" ] \
  && fnPid="${_bashlyk_pathRun}/$(udfGetMd5 ${_bashlyk_s0} ${_bashlyk_sArg}).pid" \
  || fnPid="${_bashlyk_pathRun}/${_bashlyk_s0}.pid"
 mkdir -p ${_bashlyk_pathRun} \
  || eval 'udfWarn "Warn: path for PIDs ${_bashlyk_pathRun} not created..."; return -1'
 [ -f "$fnPid" ] && pid=$(head -n 1 ${fnPid})
 if [ -n "$pid" ]; then
  udfCheckStarted $pid ${_bashlyk_s0} ${_bashlyk_sArg} \
   && eval 'echo "$0 : Already started with pid = $pid"; return 1'
 fi
 echo $$ > ${fnPid} \
 || eval 'udfWarn "Warn: pid file $fnPid not created..."; return -1'
 echo "$0 ${_bashlyk_sArg}" >> $fnPid
 _bashlyk_fnPid=$fnPid
 udfAddFile2Clean $fnPid
 return 0
}

udfExitIfAlreadyStarted() {
 udfSetPid $*
 case $? in
  -1) exit  -1 ;;
   0) return 0 ;;
   1) exit   0 ;;
 esac
}

udfClean() {
 local fn
 local a="${_bashlyk_afnClean} ${_bashlyk_apathClean} $*"
 for fn in $a
 do 
  [ -n "$fn" -a -f "$fn" ] && rm -f $1 "$fn"
  [ -n "$fn" -a -d "$fn" ] && rmdir "$fn" >/dev/null 2>&1
 done
 return $?
}
#
udfLibPid() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -e "--bashlyk-test" | grep -w "pid")" ] && return 0
 local sArg="${_bashlyk_sArg}"
 echo "--- libpid.sh tests --- start"
 echo "Check udfExitIfAlreadyStarted for full command line:"
 udfExitIfAlreadyStarted
 echo "${_bashlyk_fnPid} contain:"
 cat ${_bashlyk_fnPid}
 sleep 1
 echo "Check udfExitIfAlreadyStarted:"
 _bashlyk_sArg=
 udfExitIfAlreadyStarted
 _bashlyk_sArg="$sArg"
 echo "${_bashlyk_fnPid} contain:"
 cat ${_bashlyk_fnPid}
 sleep 1
 echo "--- libpid.sh tests ---  done"
 return 0
}
#
# main section
#
udfLibPid
