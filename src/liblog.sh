#
# $Id$
#
#
aRequiredBin="basename date echo printf logger mail sleep tee true false"
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
 local b=0
 local s=
 local c=
 [ -z "$_bashlyk_bUseSyslog" -o ${_bashlyk_bUseSyslog} -eq 0 ] && c=':'
 udfIsTerm && b=1 || b=0
 [ $b -eq 0 ] && s="$HOSTNAME ${_bashlyk_s0}[$(printf "%05d" $$)]${c} "
 [ $b -ne 0 -o -n "$c" ] && echo "$(udfDate "${s}$*")" || logger -s -t "${s}" $* 2>&1
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
 udfLog $* | mail -s "${_bashlyk_emailSubj}" ${_bashlyk_emailRcpt}
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
 for s in ${_bashlyk_pathLOG} ${_bashlyk_fnLog} ${_bashlyk_emailRcpt} ${_bashlyk_emailSubj}
 do
  echo "dbg $s"
 done
 for fn in udfLog udfWarn udfFinally udfThrow; do
  sleep 1
  $fn "$fn $1"
 done
fi
