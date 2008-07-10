#
# $Id$
#
[ -n "$_BASHLYK_LIBLOG" ] && return 0 || _BASHLYK_LIBLOG=1
#
# global variables
#
_bashlyk_aBin+=" basename date echo hostname false printf logger mail sleep tee true "
: ${HOSTNAME=$(hostname)}
: ${_bashlyk_bUseSyslog=0}
: ${_bashlyk_pathLog=/tmp}
: ${_bashlyk_s0=$(basename $0)}
: ${_bashlyk_sId=$(basename $0 .sh)}
: ${_bashlyk_emailRcpt=postmaster}
: ${_bashlyk_iStartTimeStamp=$(/bin/date "+%s")}
: ${_bashlyk_emailSubj:="$HOSTNAME::$USER::${_bashlyk_s0}"}
: ${_bashlyk_fnLog:="${_bashlyk_pathLog}/${_bashlyk_s0}.log"}
#
# function section
#
udfBaseId() {
 basename $0 .sh
}
#
udfDate() {
 date "+%b %d %H:%M:%S $*"
}
#
udfLogger() {
 local envLang=$LANG
 LANG=C
 local bSysLog=0
 local bTermin=0
 local sTagLog="${_bashlyk_s0}[$(printf "%05d" $$)]"
 [ -z "$_bashlyk_bUseSyslog" -o ${_bashlyk_bUseSyslog} -eq 0 ] && bSysLog=0 || bSysLog=1
 if [ -z "$_bashlyk_bTerminal" ]; then
  udfIsTerm && bTermin=1 || bTermin=0
 else
  [ ${_bashlyk_bTerminal} -eq 0 ] && bTermin=0 || bTermin=1
 fi
 case "${bSysLog}${bTermin}" in
  "00")
   echo "$(udfDate "$HOSTNAME $sTagLog: $*")" >> ${_bashlyk_fnLog}
  ;;
  "01")
   echo "$*"
  ;;
  "10")
   echo "$(udfDate "$HOSTNAME $sTagLog: $*")" >> ${_bashlyk_fnLog}
   logger -s -t "$sTagLog" "$*" 2>/dev/null
  ;;
  "11")
   echo "$*"
   logger -s -t "$sTagLog" "$*" 2>/dev/null
  ;;
 esac
 LANG=$envLang
}
#
udfLog() {
 if [ "$1" = "-" ]; then
  shift
  local s sPrefix
  [ -n "$*" ] && sPrefix="$* " || sPrefix=
  while read s; do [ -n "$s" ] && udfLogger "${sPrefix}${s}"; done
 else
  [ -n "$*" ] && udfLogger $*
 fi
 return 0
}
#
udfMail() {
 {
  if [ "$1" = "-" ]; then
   shift
   [ -n "$1" ] && printf "%s\n----\n" "$*"
   local s
   while read s; do [ -n "$s" ] && echo "$s"; done
  else
   [ -n "$1" ] && echo $*
  fi
 } 2>&1 | mail -e -s "${_bashlyk_emailSubj}" ${_bashlyk_emailRcpt}
 return $PIPESTATUS
}
#
udfWarn() {
 [ "${_bashlyk_bTerminal}" = "1" ] && udfLog $* || {
  udfMail $*
  udfLog "sent warn or abort message with status: $?"
 }
}
#
udfThrow() {
 udfWarn $*
 exit -1
}
#
udfIsTerm() {
 local fd=1
 case "$1" in
  0|1|2) fd=$1 ;;
 esac
 [ -t "$fd" ] && return 0 || return 1
}
#
udfFinally() {
 local iDiffTime=$(($(date "+%s")-${_bashlyk_iStartTimeStamp}))
 [ -n "$1" ] && udfLog "$* ($iDiffTime sec)"
 return $iDiffTime
}
#
udfSetLog() {
 [ -n "$1" ] || return 1
 _bashlyk_fnLog="$1"
 _bashlyk_pathLog=$(dirname ${_bashlyk_fnLog})
 [ -d "${_bashlyk_pathLog}" ] || mkdir -p "${_bashlyk_pathLog}" \
  || udfThrow "Error: do not create path ${_bashlyk_pathLog}"
 touch "${_bashlyk_fnLog}" || udfThrow "Error: ${_bashlyk_fnLog} not usable for logging"
 return 0
}
#
# main section
#
# Test Block start
if [ -n "$(echo "${_bashlyk_aTest}" | grep -w log)" ]; then
 echo "--- liblog.sh tests --- start"
 for s in pathLog=${_bashlyk_pathLog} fnLog=${_bashlyk_fnLog} emailRcpt=${_bashlyk_emailRcpt} emailSubj=${_bashlyk_emailSubj}
 do
  echo "$s"
 done
 for s in udfLog udfWarn udfFinally; do
  sleep 1
  echo "check $s:"
  $s "$s test"
 done
 echo "--- liblog.sh tests ---  done"
fi
# Test Block end
true
