#
# $Id$
#
#****h* bashlyk/liblog
#  DESCRIPTION
#    bashlyk Log library
#    Функции определения режима вывода, ведения логов
#    отправки предупреждений, сообщений об ошибках
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/liblog/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#  SOURCE
[ -n "$_BASHLYK_LIBLOG" ] && return 0 || _BASHLYK_LIBLOG=1
#******
#****** bashlyk/liblog/External modules
#  DESCRIPTION
#    Using modules section
#    Здесь указываются модули, код которых используется данной библиотекой
#  SOURCE
[ -s "${_bashlyk_pathLib}/libmd5.sh" ] && . "${_bashlyk_pathLib}/libmd5.sh"
#******
#****v*  bashlyk/liblog/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_afnClean:=}
: ${_bashlyk_apathClean:=}
: ${_bashlyk_ajobClean:=}
: ${_bashlyk_apidClean:=}
: ${HOSTNAME:=$(hostname)}
: ${_bashlyk_bUseSyslog:=0}
: ${_bashlyk_pathLog:=/tmp}
: ${_bashlyk_s0:=$(basename $0)}
: ${_bashlyk_sId:=$(basename $0 .sh)}
: ${_bashlyk_pathRun:=/tmp}
: ${_bashlyk_pidLogSock:=}
: ${_bashlyk_fnLogSock:=}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_iStartTimeStamp:=$(date "+%s")}
: ${_bashlyk_emailSubj:="$HOSTNAME::$USER::${_bashlyk_s0}"}
: ${_bashlyk_fnLog:="${_bashlyk_pathLog}/${_bashlyk_s0}.log"}
: ${_bashlyk_aRequiredCmd_log:="basename date echo hostname false printf logger \
 mail mkfifo sleep tee true jobs ["}
#******
#****f* bashlyk/liblog/udfBaseId
#  SYNOPSIS
#    udfBaseId
#  DESCRIPTION
#    Alias для команды basename
#  OUTPUT
#    Короткое имя запущенного сценария без расширения ".sh"
#  SOURCE
udfBaseId() {
 basename $0 .sh
}
#******
#****f* bashlyk/liblog/udfDate
#  SYNOPSIS
#    udfDate <args>
#  DESCRIPTION
#    Alias для команды date
#  INPUTS
#    <args> - суффикс к форматной строке текущей даты
#  OUTPUT
#    текущая дата с возможным суффиксом
#  SOURCE
udfDate() {
 date "+%b %d %H:%M:%S $*"
}
#******
#****f* bashlyk/liblog/udfLogger
#  SYNOPSIS
#    udfLogger args
#  DESCRIPTION
#    Селектор вывода строки аргументов в зависимости от режима работы.
#    В зависимости от
#  INPUTS
#    PID     - PID
#    command - command
#    args    - arguments
#  RETURN VALUE
#    0 - Процесс с PID существует для указанной командной строки (command args)
#    1 - Процесс с PID для проверяемой командной строки не обнаружен.
#  EXAMPLE
#    udfCheckStarted $pid $0 $* \
#    && eval 'echo "$0 : Already started with pid = $pid"; return 1'
#  SOURCE
udfLogger() {
 local envLang=$LANG
 LANG=C
 local bSysLog=0
 local bTermin=0
 local sTagLog="${_bashlyk_s0}[$(printf "%05d" $$)]"
 [ -z "$_bashlyk_bUseSyslog" -o ${_bashlyk_bUseSyslog} -eq 0 ] \
  && bSysLog=0 || bSysLog=1
 if [ -z "$_bashlyk_bTerminal" ]; then
  udfIsTerm && bTermin=1 || bTermin=0
 else
  [ ${_bashlyk_bTerminal} -eq 0 ] && bTermin=0 || bTermin=1
 fi
 #[ -d "${_bashlyk_pathLog}" ] || mkdir -p "${_bashlyk_pathLog}" \
 # || udfThrow "Error: do not create path ${_bashlyk_pathLog}"
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
#******

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
udfEcho() {
 if [ "$1" = "-" ]; then
  shift
  [ -n "$1" ] && printf "%s\n----\n" "$*"
  cat
 else
  [ -n "$1" ] && echo $*
 fi
}
#
udfMail() {
 udfEcho $* | mail -e -s "${_bashlyk_emailSubj}" ${_bashlyk_emailRcpt}
}
#
udfWarn() {
 [ "${_bashlyk_bTerminal}" = "1" ] && udfEcho $* || udfMail $*
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
udfOnTrap() {
 local s
 #
 for s in ${_bashlyk_ajobClean}; do
  kill $s 2>/dev/null
 done
 #
 for s in ${_bashlyk_apidClean}; do
  kill $s 2>/dev/null
 done
 #
 for s in ${_bashlyk_afnClean}; do
  rm -f $s
 done
 #
 for s in ${_bashlyk_apathClean}; do
  rmdir $s 2>/dev/null
 done
 #
 [ -n "${_bashlyk_pidLogSock}" ] && {
  exec >/dev/null 2>&1
  wait ${_bashlyk_pidLogSock}
 }
 return 0
}
#
udfAddFile2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_afnClean+=" $*"
 #echo "clean file ${_bashlyk_afnClean}"
 trap "udfOnTrap" 0 1 2 5 15
}
#
udfAddPath2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_apathClean+=" $*"
 #echo "clean path ${_bashlyk_apathClean}"
 trap "udfOnTrap" 0 1 2 5 15
}
#
udfAddJob2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_ajobClean+=" $*"
 #echo "clean job ${_bashlyk_ajobClean}"
 trap "udfOnTrap" 0 1 2 5 15
}
#
udfAddPid2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_apidClean+=" $*"
 #echo "clean job ${_bashlyk_apidClean}"
 trap "udfOnTrap" 0 1 2 5 15
}
#
udfCleanQueue() {
 [ -n "$1" ] || return 0
 _bashlyk_afnClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#
udfFinally() {
 local iDiffTime=$(($(date "+%s")-${_bashlyk_iStartTimeStamp}))
 [ -n "$1" ] && echo "$* ($iDiffTime sec)"
 return $iDiffTime
}
#
udfSetLogSocket() {
 local fnSock
 [ -n "$_bashlyk_sArg" ] \
  && fnSock="${_bashlyk_pathRun}/$(udfGetMd5 ${_bashlyk_s0} ${_bashlyk_sArg}).${$}.socket" \
  || fnSock="${_bashlyk_pathRun}/${_bashlyk_s0}.${$}.socket"
 mkdir -p ${_bashlyk_pathRun} \
  || eval 'udfWarn "Warn: path for Sockets ${_bashlyk_pathRun} not created..."; return -1'
 [ -a $fnSock ] && rm -f $fnSock
 if mkfifo -m 0600 $fnSock >/dev/null 2>&1; then
  ( udfLog - < $fnSock )&
  _bashlyk_pidLogSock=$!
  exec >>$fnSock 2>&1
 else
  udfWarn "Warn: Socket $fnSock not created..."
  exec >>$_bashlyk_fnLog 2>&1
 fi
 _bashlyk_fnLogSock=$fnSock
 udfAddFile2Clean $fnSock
 return 0
}
#
udfSetLog() {
 if [ -n "$1" ]; then
  if [ "$1" = "$(basename $1)" ]; then
   _bashlyk_fnLog="${_bashlyk_pathLog}/$1"
  else
   _bashlyk_fnLog="$1"
   _bashlyk_pathLog=$(dirname ${_bashlyk_fnLog})
  fi
 fi
 [ -d "${_bashlyk_pathLog}" ] || mkdir -p "${_bashlyk_pathLog}" \
  || udfThrow "Error: do not create path ${_bashlyk_pathLog}"
 touch "${_bashlyk_fnLog}" || udfThrow "Error: ${_bashlyk_fnLog} not usable for logging"
 udfSetLogSocket
 return 0
}
#
udfLibLog() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -e "--bashlyk-test" | grep -w "log")" ] && return 0
 local s pathLog fnLog emailRcpt emailSubj
 echo "--- liblog.sh tests --- start"
 for s in bUseSyslog=$_bashlyk_bUseSyslog pathLog=$_bashlyk_pathLog fnLog=$_bashlyk_fnLog emailRcpt=$_bashlyk_emailRcpt emailSubj=$_bashlyk_emailSubj; do
  echo "$s"
 done
 for s in udfSetLog udfLog udfWarn udfFinally; do
  sleep 1
  echo "check $s:"
  $s testing liblog $s
 done
 for s in pathLog=$_bashlyk_pathLog fnLog=$_bashlyk_fnLog emailRcpt=$_bashlyk_emailRcpt emailSubj=$_bashlyk_emailSubj; do
  echo "$s"
 done
 echo "--- liblog.sh tests ---  done"
 return 0
}
#
# main section
#
udfLibLog
