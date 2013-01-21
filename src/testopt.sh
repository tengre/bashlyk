#
# $Id$
#
#****h* bashlyk/testopt
#  DESCRIPTION
#    bashlyk OPT test unit
#    Тестовый модуль библиотеки OPT
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****** bashlyk/testopt/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/libopt.sh" ] && . "${_bashlyk_pathLib}/libopt.sh"
#******
#****u* bashlyk/testopt/udfTestOpt
#  SYNOPSIS
#    udfTestOpt
# DESCRIPTION
#   bashlyk OPT library test unit
#   Запуск проверочных операций модуля
#  SOURCE
udfTestOpt() {
 local optTest1 optTest2 optTest3 s="$(date -R)" b=1
 printf "\n- libopt.sh tests: "
 udfGetOpt "optTest1:,optTest2,optTest3:" --optTest1 $(uname) --optTest2\
 --optTest3 $(udfWSpace2Alias $s) 2>/dev/null
 [ "$optTest1" = "$(uname)" ] && echo -n '.' || { echo -n '?'; b=0; } 
 [ "$optTest2" = "1"        ] && echo -n '.' || { echo -n '?'; b=0; } 
 [ "$optTest3" = "$s"       ] && echo -n '.' || { echo -n '?'; b=0; } 
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 echo "--"
 return 0
}
#******
#****** bashlyk/testopt/Main section
# DESCRIPTION
#   Running OPT library test unit
#  SOURCE
udfTestOpt
#******
