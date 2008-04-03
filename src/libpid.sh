#
# $Id$
#
[ -n "$_BASHLYK_LIBPID" ] && return 0
#
# global variables
#
_bashlyk_aBin+=" cat date echo grep head mkdir ps rm sed sleep"
_bashlyk_pathRun=${_bashlyk_pathRun:=/tmp}
     _bashlyk_s0=${_bashlyk_s0:=$(basename $0)}
   _bashlyk_sArg="$*"
_bashlyk_pathPid=${_bashlyk_pathPid:="${_bashlyk_pathRun}/${_bashlyk_s0}"}
  _bashlyk_fnPid=${_bashlyk_fnPid:="${_bashlyk_pathRun}/${_bashlyk_s0}.pid"}
_bashlyk_pathLib=${_bashlyk_pathLib:=$(pwd)}
#
# link section
#
[ -s "$_bashlyk_pathLib/liblog.sh" ] && . "${_bashlyk_pathLib}/liblog.sh"
[ -s "$_bashlyk_pathLib/libmd5.sh" ] && . "${_bashlyk_pathLib}/libmd5.sh"
#
# function section
#
udfCheckStarted() {
 [ -n "$1" ] || return -1
 local pid=$1
 local cmd=${2:-""}
 shift 2
 [ -n "$(ps -p $pid -o pid= -o args= | grep -vw $$ | grep -w "$cmd" | grep "$*" | head -n 1)" ] && return 0 || return 1
}

udfSetPid() {
 if [ -n "$1" ]; then
  mkdir -p ${_bashlyk_pathPid} || return -1
  _bashlyk_fnPid="${_bashlyk_pathPid}/$(udfGetMd5 ${_bashlyk_s0} $*).pid"
 fi
 [ -f "$_bashlyk_fnPid" ] && local pid=$(head -n 1 ${_bashlyk_fnPid})
 if [ -n "$pid" ]; then 
  udfCheckStarted $pid ${_bashlyk_s0} $* && echo "$pid" && return 1
 fi
 echo $$ | tee ${_bashlyk_fnPid} || return -1
 echo "$0 $*" >> ${_bashlyk_fnPid}
 return 0
}

udfExitIfAlreadyStarted() {
 local pid=$(udfSetPid $*)
 case $? in
  -1)
     udfWarn "Warn: Pid file ${_bashlyk_fnPid} not created...";
     exit -1
    ;;
   0)
     return 0
    ;;
   1)
    udfLog "$0 : Already started with pid = $pid"
    exit 0
    ;;
 esac
}

udfClean() {
 local fn=
 for fn in $*; do rm -f $1 "$fn"; done
 return $?
}
#
# main section
#
#Test Block
if [ -n "$(echo "${_bashlyk_aTest}" | grep -w pid)" ]; then
 echo "Check udfExitIfAlreadyStarted:"
 udfExitIfAlreadyStarted
 echo "${_bashlyk_fnPid} contain:"
 cat ${_bashlyk_fnPid}
 sleep 1
 udfClean --verbose ${_bashlyk_fnPid}
 udfExitIfAlreadyStarted $*
 echo "${_bashlyk_fnPid} contain:"
 cat ${_bashlyk_fnPid}
 sleep 1
 udfClean --verbose ${_bashlyk_fnPid}
fi
#Test Block

_BASHLYK_LIBPID=1
true