#
# $Id$
#
#****h* bashlyk/testlog
#  DESCRIPTION
#    bashlyk LOG test unit
#    Тестовый модуль библиотеки LOG
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****** bashlyk/testlog/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
#[ -s "${_bashlyk_pathLib}/liblog.sh" ] && . "${_bashlyk_pathLib}/liblog.sh"
. ./libstd.sh
. ./liblog.sh
#******
#****u* bashlyk/testlog/udfTestLog
#  SYNOPSIS
#    udfTestLog
# DESCRIPTION
#   bashlyk LOG library test unit
#   Запуск проверочных операций модуля
#  SOURCE
udfTestLog() {
 local s pathLog fnLog emailRcpt emailSubj b=1 sS
 printf "\n- liblog.sh tests:\n\n"
 : ${_bashlyk_bInteract:=1}
 : ${_bashlyk_bTerminal:=1}
 : ${_bashlyk_bNotUseLog:=1}
 echo -n "Global variable testing: "
 for s in                \
  "$_bashlyk_bUseSyslog" \
  "$_bashlyk_pathLog"    \
  "$_bashlyk_fnLog"      \
  "$_bashlyk_emailRcpt"  \
  "$_bashlyk_emailSubj"  \
  "$_bashlyk_bTerminal"  \
  "$_bashlyk_pathDat"    \
  "$_bashlyk_bInteract"
  do
   [ -n "$s" ] && echo -n '.' || { echo -n '?'; b=0; }
 done
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 mkdir -p ${_bashlyk_pathDat}
 udfAddPath2Clean ${_bashlyk_pathDat} 2>/dev/null
 echo -n "function testing on control terminal: "
 _bashlyk_bTerminal=1
 _bashlyk_bNotUseLog=1
 b=1
 for s in udfLog udfUptime udfFinally; do
  sS=$($s testing liblog $s)
  [ -n "$(echo "$sS" | grep "testing liblog $s")" ] && echo -n '.' || { echo -n '?'; b=0; }
 done

 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 echo "test without control terminal (cat $_bashlyk_fnLog ): "
 _bashlyk_bTerminal=0
 _bashlyk_bNotUseLog=0
 b=1
 udfSetLog 2>/dev/null && echo -n '.' || { echo -n '?'; b=0; }
 [ $b -eq 1 ] && {
  echo 'ok.'
  for s in udfLog udfUptime udfFinally; do
   $s testing liblog $s; echo "return code ... $?"
  done
 } || echo 'fail.'
 _bashlyk_bTerminal=0
 _bashlyk_bUseSyslog=1
  echo "--- test without control terminal and syslog using: ---"
 for s in udfLog udfUptime udfFinally udfIsTerminal udfIsInteract; do
  echo "--- check $s: ---"
  $s testing liblog $s; echo "return code ... $?"
 done
 _bashlyk_bTerminal=1
 for s in                             \
  bUseSyslog=$_bashlyk_bUseSyslog     \
  pathLog=$_bashlyk_pathLog           \
  fnLog=$_bashlyk_fnLog               \
  emailRcpt=$_bashlyk_emailRcpt       \
  emailSubj=$_bashlyk_emailSubj       \
  bTerminal=$_bashlyk_bTerminal       \
  bInteract=$_bashlyk_bInteract
  do
   echo "$s"
 done
 echo "--"
 return 0
}
#******
#****** bashlyk/testlog/Main section
# DESCRIPTION
#   Running LOG library test unit
#  SOURCE
udfTestLog
#******
