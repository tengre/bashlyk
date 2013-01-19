#
# $Id$
#
#****h* bashlyk/testpid
#  DESCRIPTION
#    bashlyk PID test unit
#    Тестовый модуль библиотеки PID
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****** bashlyk/testpid/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
#[ -s "${_bashlyk_pathLib}/libpid.sh" ] && . "${_bashlyk_pathLib}/libpid.sh"
. ./libpid.sh
#******
#****u* bashlyk/testpid/udfTestPid
#  SYNOPSIS
#    udfTestPid
# DESCRIPTION
#   bashlyk PID library test unit
#   Запуск проверочных операций модуля
#  SOURCE
udfTestPid() {
 local sArg="${_bashlyk_sArg}" b=1
 printf "\n- libpid.sh tests: "
 udfExitIfAlreadyStarted
 echo -n '.'
 [ "$$" -eq "$(head -n 1 ${_bashlyk_fnPid})" ] \
  && echo -n "." || { echo -n '?'; b=0; } 
 #printf "Pid file: ${_bashlyk_fnPid}\n\n"
 _bashlyk_sArg=
 udfExitIfAlreadyStarted
 _bashlyk_sArg="$sArg"
 echo -n '.'
 [ "$$" -eq "$(head -n 1 ${_bashlyk_fnPid})" ] \
  && echo -n "." || { echo -n '?'; b=0; } 
 #printf "Pid file: ${_bashlyk_fnPid}\n"
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 echo "--"
 return 0
}
#******
#****** bashlyk/testpid/Main section
# DESCRIPTION
#   Running PID library test unit
#  SOURCE
udfTestPid
#******
