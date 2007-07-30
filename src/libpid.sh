#
# $Id$
#
[ -z "$_bashlyk_pathRUN" ] && _bashlyk_pathRUN=/tmp
#
udfCheckProcess(){
 [ -n "$1" ] || return -1
 /bin/ps ax | /bin/grep -w $1 | /bin/grep -w "$2" | /bin/grep -v "grep"
} 
#
udfExitIfAlreadyStarted(){
 [ -z "$_bashlyk_s0"    ] && _bashlyk_s0=$(basename $0 .sh)
 [ -z "$_bashlyk_fnPID" ] && _bashlyk_fnPID=$pathRUN/${_bashlyk_s0}.pid
 [ -f "$_bashlyk_fnPID" ] && local iPid=$(/usr/bin/head -n 1 ${_bashlyk_fnPID})
 if [ -n "$iPid" -a -n "$(udfCheckProcess $iPid "${_bashlyk_s0}")" ]; then
  udfLog "$0 : Already runned with PID = $iPid"
  exit 0
 else
  /bin/echo $$ > ${_bashlyk_fnPID} \
  || eval 'udfWarn "Warn: PID file (${_bashlyk_fnPID}) not created..."; return -1'
 fi
 return 0
}

udfClean(){
 local fn=
 for fn in $*
 do
  [ -f "$fn" ] && /bin/rm -f "$fn"
 done
 return 0
}
