#
# $Id$
#
#
[ -z "$pathLOG" ] && pathLOG=/tmp
#
udfBaseId() {
 /usr/bin/basename $0 .sh
}
#
udfDate() {
 /bin/date "+%Y.%m.%d %H:%M:%S $*"
}
#
udfEngine() {
 local b=0
 local s=$*
 local c=
 [ -z "$bUseSyslog" -o "$bUseSyslog" = "0" ] && c=':'
 udfIsTerm && b=1 || b=0
 [ $b -eq 0 ] && s="[$(printf "%05d" $$)$c $(udfDate $s0)]: $s"
 [ $b -ne 0 -o -n "$c" ] && echo $s || logger -s -t $s 2>&1
}
#
udfLog() {
 if [ -z "$1" -o "$1" = "-" ]; then
  local a
  while read -a a; do
   [ -n "${a[*]}" ] && udfEngine ${a[*]}
  done
 else
  [ -n "$1" ] && udfEngine $*
 fi
 return 0 
}
#
udfMail() {
 [ -z "$sMailTo" ]  && local sMailTo=postmaster
 [ -z "$sSubject" ] && local sSubject="$HOSTNAME::$s0"
 udfLog $* | /usr/bin/mail -s "$sSubject" $sMailTo
 return $?
}
#
udfWarn(){
 udfIsTerm && udfLog $* || udfMail $*
}
#
udfThrow(){
 udfWarn $*
 exit -1
}
#
udfIsTerm(){
 case "$1" in
  0|1|2) fd=$1 ;;
      *) fd=1  ;;
 esac
 [ -t "$fd" ] && true || false
}
#
udfFinally(){
 udfLog "$* ($(($(/bin/date "+%s")-$iStartTimeStamp)) sec)"
} 
#
#
#
s0=$(udfBaseId)
[ -z "$pathLOG" ] && pathLOG=/tmp
fnLog=$pathLOG/$s0.log
iStartTimeStamp=$(/bin/date "+%s")
#bUseSyslog=0
#
if [ "$1" = "test" ]; then
 for fn in udfLog udfWarn udfFinally udfThrow; do
  sleep 1
  $fn "$fn test"
 done  
fi
