#
# $Id$
#
#****h* bashlyk/libpid
#  DESCRIPTION
#    bashlyk PID library
#    handling processes
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#
#****v* bashlyk/libpid/$_BASHLYK_LIBPID
#  DESCRIPTION
#    If this global variable defined then library already linked
#  SOURCE
[ -n "$_BASHLYK_LIBPID" ] && return 0 || _BASHLYK_LIBPID=1
#******
#
#****** bashlyk/libpid
# DESCRIPTION
#   Link section. Here linked depended library
# SOURCE
[ -s "${_bashlyk_pathLib}/liblog.sh" ] && . "${_bashlyk_pathLib}/liblog.sh"
[ -s "${_bashlyk_pathLib}/libmd5.sh" ] && . "${_bashlyk_pathLib}/libmd5.sh"
#******
#
#****v* bashlyk/libpid/$_bashlyk_aRequiredCmd_pid
#  DESCRIPTION
#    Global variable for used system command list by this library
#  SOURCE
_bashlyk_aRequiredCmd_pid="cat date echo grep head mkdir ps rm sed sleep"
#******
#
#****v*  bashlyk/libpid
#  DESCRIPTION
#    Global variables init section
#  SOURCE
: ${_bashlyk_afnClean:=}
: ${_bashlyk_apathClean:=}
: ${_bashlyk_fnPid:=}
: ${_bashlyk_fnSock:=}
: ${_bashlyk_s0:=$(basename $0)}
: ${_bashlyk_pathRun:=/tmp}
: ${_bashlyk_sArg:=$*}
#******
#
# function section
#
#****f* bashlyk/libpid/udfCheckStarted
#  SYNOPSIS
#    udfCheckStarted pid [command [args]]
#  DESCRIPTION
#    Checking command and pid 
#  INPUTS
#    pid     - PID
#    command - command
#    args    - arguments
#  RETURN VALUE
#    0 - command line with PID (exclude self process) exist
#    1 - command line with PID not exist or self process
#  EXAMPLE
#    udfCheckStarted $pid $0 $* \
#    && eval 'echo "$0 : Already started with pid = $pid"; return 1'
#  SOURCE
udfCheckStarted() {
 [ -n "$*" ] || return -1
 local pid=$1
 local cmd=${2:-}
 shift 2
 [ -n "$(ps -p $pid -o pid= -o args= | grep -vw $$ | grep -w -e "$cmd" | grep -e "$*" | head -n 1)" ] && return 0 || return 1
}
#******
#
#****f* bashlyk/libpid/udfSetPid
#  SYNOPSIS
#    udfSetPid
#  DESCRIPTION
#    Creating PID file for own process with arguments
#    used global variables $_bashlyk_s0 and $_bashlyk_sArg
#  RETURN VALUE
#    0 - PID file for command line successfully created
#    1 - PID file exist and command line process already started
#   -1 - PID file don't created. Error status
#  EXAMPLE
#    udfSetPid
#  SOURCE
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
#******
#
#****f* bashlyk/libpid/udfExitIfAlreadyStarted
#  SYNOPSIS
#    udfExitIfAlreadyStarted
#  DESCRIPTION
#    Alias-wrapper for udfSetPid with extended behavior:
#    If command line process already exist then
#    started current process with identical command line stopped
#    else created pid file and current process don`t stopped.
#  RETURN VALUE
#    0 - PID file for command line successfully created
#    1 - PID file exist and command line process already started,
#        current process stopped
#   -1 - PID file don't created. Error status - current process stopped
#  EXAMPLE
#    udfExitIfAlreadyStarted
#  SOURCE
udfExitIfAlreadyStarted() {
 udfSetPid $*
 case $? in
  -1) exit  -1 ;;
   0) return 0 ;;
   1) exit   0 ;;
 esac
}
#******
#
#****f* bashlyk/libpid/udfClean
#  SYNOPSIS
#    udfClean
#  DESCRIPTION
#    Remove files and folder listed on the variables
#    $_bashlyk_afnClean and  $_bashlyk_apathClean
#  RETURN VALUE
#    Last delete operation status 
#  EXAMPLE
#    udfClean
#  SOURCE
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
#******
#
#****u* bashlyk/libpid/udfLibPid
#  SYNOPSIS
#    udfLibPid --bashlyk-test pid
# DESCRIPTION
#   bashlyk PID library test unit
#  INPUTS
#    --bashlyk-test - command for use test unit
#    pid            - enable test for this library
#  SOURCE
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
#******
#
# main section
#
#****** bashlyk/libpid
# DESCRIPTION
#   Running PID library test unit if $_bashlyk_sArg ($*) contain
#   substring "--bashlyk-test pid" - command for test using
#  SOURCE
udfLibPid
#******