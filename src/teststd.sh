#
# $Id$
#
#****h* bashlyk/teststd
#  DESCRIPTION
#    bashlyk std test unit
#    Тестовый модуль библиотеки std
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****** bashlyk/teststd/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
#[ -s "${_bashlyk_pathLib}/libstd.sh" ] && . "${_bashlyk_pathLib}/libstd.sh"
. ./libstd.sh
#******
#****u* bashlyk/teststd/udfTestStd
#  SYNOPSIS
#    udfTestStd
# DESCRIPTION
#   bashlyk xXX library test unit
#   Запуск проверочных операций модуля
#  SOURCE
udfTestStd() {
 local s b=1 s0='' s1="test" fnTmp
 printf "\n- libstd.sh tests: "
 fnTmp=/tmp/$$.$(date +%s).tmp
 {
  udfIsNumber "$(date +%S)"      && echo -n '.' || { echo -n '?'; b=0; }
  udfIsNumber "$(date +%S)k" kMG && echo -n '.' || { echo -n '?'; b=0; }
  udfIsNumber "$(date +%S)M"     && { echo -n '?'; b=0; } || echo -n '.'
  udfIsNumber "$(date +%b)G" kMG && { echo -n '?'; b=0; } || echo -n '.'
  udfIsNumber "$(date +%b)"      && { echo -n '?'; b=0; } || echo -n '.'
  udfIsValidVariable "k$(date +%S)" && echo -n '.' || { echo -n '?'; b=0; }
  udfIsValidVariable "_$(date +%S)" && echo -n '.' || { echo -n '?'; b=0; }
  udfIsValidVariable "$(date +%S)M" && { echo -n '?'; b=0; } || echo -n '.'
 [ -n "$(udfShowVariable s1 | grep 's1=test')" ] && echo -n '.' || { echo -n '?'; b=0; }
  udfOnEmptyVariable Warn s0     && { echo -n '?'; b=0; } || echo -n '.' 
  udfOnEmptyVariable Warn s1     && echo -n '.' || { echo -n '?'; b=0; }
 } 2>/dev/null
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 echo "--"
 return 0
}
#******
#****** bashlyk/teststd/Main section
# DESCRIPTION
#   Running STD library test unit
#  SOURCE
udfTestStd
#******
