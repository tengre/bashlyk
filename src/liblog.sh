#
# $Id$
#
#
[ -z "$_bashlyk_pathLOG" ]         && _bashlyk_pathLOG=/tmp
[ -z "$_bashlyk_s0" ]              && _bashlyk_s0=$(basename $0 .sh)
[ -z "$_bashlyk_fnLog" ]           && _bashlyk_fnLog="${_bashlyk_pathLOG}/${_bashlyk_s0}.log"
[ -z "$_bashlyk_iStartTimeStamp" ] && _bashlyk_iStartTimeStamp=$(/bin/date "+%s")
[ -z "$_bashlyk_bUseSyslog" ]      && _bashlyk_bUseSyslog=0
#
udfBaseId() {
 basename $0 .sh
}
#
udfDate() {
 date "+%Y.%m.%d %H:%M:%S $*"
}
#
udfEngine() {
 local b=0
 local s=$*
 local c=
 [ -z "$_bashlyk_bUseSyslog" -o "$_bashlyk_bUseSyslog" = "0" ] && c=':'
 udfIsTerm && b=1 || b=0
 [ $b -eq 0 ] && s="[$(printf "%05d" $$)$c $(udfDate ${_bashlyk_s0})]: $s"
 [ $b -ne 0 -o -n "$c" ] && echo $s || logger -s -t $s 2>&1
}
#
udfLog() {
 if [ -z "$1" -o "$1" = "-" ]; then
  local s
  while read s; do [ -n "$s" ] && udfEngine "$s"; done
 else
  [ -n "$1" ] && udfEngine $*
 fi
 return 0
}
#
udfMail() {
 [ -z "$_bashlyk_emailRcpt" ] && local _bashlyk_emailRcpt=postmaster
 [ -z "$_bashlyk_emailSubj" ] && local _bashlyk_emailSubj="$HOSTNAME::${_bashlyk_s0}"
 udfLog $* | /usr/bin/mail -s "${_bashlyk_emailSubj}" ${_bashlyk_emailRcpt}
 return $?
}
#
udfWarn(){
 udfIsTerm && udfLog $* || udfLog $* | tee -a ${_bashlyk_fnLog} | udfMail
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
 udfLog "$* ($(($(date "+%s")-${_bashlyk_iStartTimeStamp})) sec)"
} 
#
#
#
#
if [ "$1" = "bashlyk_test" ]; then
 for fn in udfLog udfWarn udfFinally udfThrow; do
  sleep 1
  $fn "$fn $1"
 done
fi
