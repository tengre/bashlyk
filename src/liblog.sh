#
# $Id$
#
#

aRequiredBin="basename date echo printf logger mail sleep tee true false"
                HOSTNAME=${$HOSTNAME:-$(hostname)}
_bashlyk_iStartTimeStamp=${_bashlyk_iStartTimeStamp:=$(/bin/date "+%s")}
        _bashlyk_pathLOG=${_bashlyk_pathLOG:=/tmp}
             _bashlyk_s0=${_bashlyk_s0:=$(basename $0 .sh)}
          _bashlyk_fnLog=${_bashlyk_fnLog:="${_bashlyk_pathLOG}/${_bashlyk_s0}.log"}
     _bashlyk_bUseSyslog=${_bashlyk_bUseSyslog:=1}
      _bashlyk_emailRcpt=${_bashlyk_emailRcpt:=postmaster}
      _bashlyk_emailSubj=${_bashlyk_emailSubj:="$HOSTNAME::${_bashlyk_s0}"}
#
udfBaseId() {
 basename $0 .sh
}
#
udfDate() {
# date "+%Y.%m.%d %H:%M:%S $*"
 date "+%b %d %H:%M:%S $*"
}
#
udfLogger() {
 LANG=C
 local bSysLog=0
 local bTermin=0
 local sTagLog="${_bashlyk_s0}[$(printf "%05d" $$)]"
 [ -z "$_bashlyk_bUseSyslog" -o ${_bashlyk_bUseSyslog} -eq 0 ] && bSysLog=0 || bSysLog=1
 udfIsTerm && bTerm=1 || bTerm=0
 case "${bSysLog}${bTerm}" in
  "00")
   echo "$(udfDate "$HOSTNAME $sTagLog: $*")" | tee -a ${_bashlyk_fnLog}
  ;;
  "01")
   echo "$*"
  ;;
  "10")
   echo "$(udfDate "$HOSTNAME $sTagLog: $*")" | tee -a ${_bashlyk_fnLog}
   logger -s -t "$sTagLog" "$*" 2>/dev/null
  ;;
  "11")
   echo "$*"
   logger -s -t "$sTagLog" "$*" 2>/dev/null
  ;;
 esac
}
#
udfLog() {
 if [ -z "$1" -o "$1" = "-" ]; then
  local s
  while read s; do [ -n "$s" ] && udfLogger "$s"; done
 else
  [ -n "$1" ] && udfLogger $*
 fi
 return 0
}
#
udfMail() {
 udfLog $* | mail -e -s "${_bashlyk_emailSubj}" ${_bashlyk_emailRcpt}
 udfLog "mailed with status: $?"
}
#
udfWarn(){
 echo $* | udfMail
}
#
udfThrow(){
 udfWarn $*
 exit -1
}
#
udfIsTerm(){
 local fd=1
 case "$1" in
  0|1|2) fd=$1 ;;
 esac
 [ -t "$fd" ] && true || false
}
#
udfFinally(){
 local iDiffTime=$(($(date "+%s")-${_bashlyk_iStartTimeStamp}))
 [ -n "$1" ] && udfLog "$* ($iDiffTime sec)"
 return $iDiffTime
}
#
#
#
#
if [ "$1" = "test.liblog.bashlyk" ]; then
 for s in ${_bashlyk_bUseSyslog} ${_bashlyk_pathLOG} ${_bashlyk_fnLog} ${_bashlyk_emailRcpt} ${_bashlyk_emailSubj}
 do
  echo "dbg $s"
 done
 for fn in udfLog udfWarn udfFinally udfThrow; do
  sleep 1
  $fn "$fn $1"
 done
fi
