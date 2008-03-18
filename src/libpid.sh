#
# $Id$
#
    aRequiredBin="cat date echo grep head mkdir ps rm sed sleep"
_bashlyk_pathRun=${_bashlyk_pathRun:=/tmp}
     _bashlyk_s0=${_bashlyk_s0:=$(basename $0)}
   _bashlyk_sArg="$*"
_bashlyk_pathPid=${_bashlyk_pathPid:="${_bashlyk_pathRun}/${_bashlyk_s0}"}
  _bashlyk_fnPid=${_bashlyk_fnPid:="${_bashlyk_pathRun}/${_bashlyk_s0}.pid"}
_bashlyk_pathLIB=${_bashlyk_pathLIB:=.}
#
[ -s "$_bashlyk_pathLIB/liblog.sh" ] && . "${_bashlyk_pathLIB}/liblog.sh"
[ -s "$_bashlyk_pathLIB/libmd5.sh" ] && . "${_bashlyk_pathLIB}/libmd5.sh"
#
udfCheckStarted() {
 [ -n "$1" ] || return -1
 local pid=$1
 local cmd=${2:-""}
 shift 2
 [ -n "$(ps -p $pid -o args= | grep -vw $$ | grep -w "$cmd" | grep "$*" | head -n 1)" ] && return 0 || return 1
# [ -n "$(ps -p $pid -o args= | grep -vw $$ | grep -w "$cmd" | sed -e 's/.*$cmd//' | grep "$*" | head -n 1)" ] && return 0 || return 1
}

udfSetPid() {
 if [ -n "$1" ]; then
  mkdir -p ${_bashlyk_pathPid} || return -1
  _bashlyk_fnPid="${_bashlyk_pathPid}/$(udfGetMd5 ${_bashlyk_s0} $*).pid"
 fi
 [ -f "$_bashlyk_fnPid" ] && local pid=$(head -n 1 ${_bashlyk_fnPid})
 if [ -n "$pid" ]; then 
  udfCheckStarted $pid ${_bashlyk_s0} $* && return $pid
 fi
 echo $$ > ${_bashlyk_fnPid} || return -1
 echo "$0 $*" >> ${_bashlyk_fnPid}
 return 0
}

udfExitIfAlreadyStarted() {
 udfSetPid $*
 case $? in
  -1)
     udfWarn "Warn: Pid file ${_bashlyk_fnPid} not created...";
     exit -1
    ;;
   0)
     return 0
    ;;
   *)
    udfLog "$0 : Already started with pid = $?"
    exit 0
    ;;
 esac
}

udfClean(){
 local fn=
 for fn in $*; do rm -f$1 "$fn"; done
 return $?
}
#
################################################
################################################
###### Test Block ##############################
################################################
################################################
#
if [ "$1" = "test.libpid.bashlyk" ]; then
 echo "Check udfExitIfAlreadyStarted:"
 udfExitIfAlreadyStarted
 sleep 1
 udfClean "v" ${_bashlyk_fnPid}
 udfExitIfAlreadyStarted $*
 sleep 1
 udfClean "v" ${_bashlyk_fnPid}
fi
