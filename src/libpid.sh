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
   _bashlyk_pathRun=${_bashlyk_pathRun:=/tmp}
        _bashlyk_s0=${_bashlyk_s0:=$(basename $0)}
   _bashlyk_pathPid=${_bashlyk_pathPid:="${_bashlyk_pathRun}/${_bashlyk_s0}"}
    _bashlyk_fnPid0=${_bashlyk_fnPid0:="${_bashlyk_pathPid}.pid"}
    _bashlyk_fnPidA=${_bashlyk_fnPidA:="${_bashlyk_pathPid}/$(udfGetMd5 ${_bashlyk_s0} $*).pid"}
   _bashlyk_pathLib=${_bashlyk_pathLib:=$(pwd)}
      _bashlyk_sArg=$*
  _bashlyk_afnClean=
_bashlyk_apathClean=
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
 local fnPid
 if [ -n "$1" -a "$1" == "-a" ]; then
  fnPid=${_bashlyk_fnPidA}
  mkdir -p ${_bashlyk_pathPid} \
   || eval 'udfWarn "Warn: path for PIDs ${_bashlyk_pathPid} not created..."; return -1'
  #_bashlyk_apathClean+=" ${_bashlyk_pathPid}"
  _bashlyk_fnPid=${_bashlyk_fnPidA}
 else
  fnPid=${_bashlyk_fnPid0}
  _bashlyk_fnPid=${_bashlyk_fnPid0}
 fi
 #_bashlyk_afnClean+=" $fnPid"
 [ -f "$fnPid" ] && local pid=$(head -n 1 ${fnPid})
 if [ -n "$pid" ]; then
  udfCheckStarted $pid ${_bashlyk_s0} ${_bashlyk_sArg} \
   && eval 'udfLog "$0 : Already started with pid = $pid"; return 1'
 fi
 echo $$ > ${fnPid} \
 || eval 'udfWarn "Warn: pid file $fnPid not created..."; return -1'
 echo "$0 ${_bashlyk_sArg}" >> ${fnPid}
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
# main section
#
#Test Block
if [ -n "$(echo "${_bashlyk_aTest}" | grep -w pid)" ]; then
 echo "--- libpid.sh tests --- start"
 echo "Check udfExitIfAlreadyStarted:"
 udfExitIfAlreadyStarted
 echo "${_bashlyk_fnPid} contain:"
 cat ${_bashlyk_fnPid}
 sleep 1
 udfClean --verbose ${_bashlyk_fnPid}
 echo "Check udfExitIfAlreadyStarted for full command line:"
 udfExitIfAlreadyStarted -a
 echo "${_bashlyk_fnPid} contain:"
 cat ${_bashlyk_fnPid}
 sleep 1
 udfClean --verbose ${_bashlyk_fnPid} ${_bashlyk_pathPid}
 echo "--- libpid.sh tests ---  done"
fi
#Test Block
true
