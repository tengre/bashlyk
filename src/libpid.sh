#
# $Id$
#
[ -z "$pathRUN" ] && pathRUN=/tmp
#
udfCheckProcess(){
 [ -n "$1" ] || return -1
 /bin/ps ax | /bin/grep -w $1 | /bin/grep -w "$2" | /bin/grep -v "grep"
} 
#
udfExitIfAlreadyStarted(){
 [ -z "$fnPID" ] && fnPID=$pathRUN/$s0.pid
 [ -f "$fnPID" ] && local iPid=$(/usr/bin/head -n 1 $fnPID)
 if [ -n "$iPid" -a -n "$(udfCheckProcess $iPid $0)" ]; then
  udfLog "$0 : Already runned with PID = $iPid"
  exit 0
 else
  /bin/echo $$ > $fnPID || return -1
 fi
 return 0
}

udfClean(){
 for fn in $*
 do
  [ -f "$fn" ] && /bin/rm -f "$fn"
 done
 return 0
}
