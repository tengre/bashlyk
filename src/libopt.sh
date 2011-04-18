#!/bin/bash
#
# $Id$
#
#****h* bashlyk/libopt
#  DESCRIPTION
#    bashlyk OPT library
#    Обслуживание параметров командной строки
#    Автоматическое создание переменных с именами опций и значениями согласно
#    опций командной строки
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/libopt/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#  SOURCE
[ -n "$_BASHLYK_LIBOPT" ] && return 0 || _BASHLYK_LIBOPT=1
#******
#****** bashlyk/libopt/External modules
#  DESCRIPTION
#    Using modules section
#    Здесь указываются модули, код которых используется данной библиотекой
#  SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/libcnf.sh" ] && . "${_bashlyk_pathLib}/libcnf.sh"
#******
#****v*  bashlyk/libopt/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#    * $_bashlyk_sArg - аргументы командной строки вызова сценария
#    * $_bashlyk_sWSpaceAlias - заменяющая пробел последовательность символов
#    * $_bashlyk_aRequiredCmd_opt - список используемых в данном модуле внешних утилит
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_sWSpaceAlias:=___}
: ${_bashlyk_aRequiredCmd_opt:="echo getopt grep mktemp tr sed umask ["}
#******
#****f* bashlyk/libopt/udfQuoteIfNeeded
#  SYNOPSIS
#    udfQuoteIfNeeded <arg>
#  DESCRIPTION
#   Аргумент, содержащий пробел(ы) отмечается кавычками
#  INPUTS
#    arg - argument
#  OUTPUT
#    аргумент с кавычками, если есть пробелы
#  EXAMPLE
#    udfQuoteIfNeeded $(date)
#  SOURCE
udfQuoteIfNeeded() {
 [ -n "$(echo "$*" | grep -e [[:space:]])" ] && echo "\"$*\"" || echo "$*"
}
#******
#****f* bashlyk/libopt/udfWSpace2Alias
#  SYNOPSIS
#    udfWSpace2Alias <arg>
#  DESCRIPTION
#   Пробел в аргументе заменяется "магической" последовательностью символов,
#   определённых в глобальной переменной $_bashlyk_sWSpaceAlias
#  INPUTS
#    arg - argument
#  OUTPUT
#   Аргумент с заменой пробелов на специальную последовательность символов
#  EXAMPLE
#    udfWSpace2Alias a b  cd
#    show a___b______cd
#  SOURCE
udfWSpace2Alias() {
 echo "$*" | sed -e "s/ /$_bashlyk_sWSpaceAlias/g"
}
#******
#****f* bashlyk/libopt/udfAlias2WSpace
#  SYNOPSIS
#    udfAlias2WSpace <arg>
#  DESCRIPTION
#   Последовательность символов, определённых в глобальной переменной
#   $_bashlyk_sWSpaceAlias заменяется на пробел в заданном аргументе.
#   Причём, если появляются пробелы, то результат обрамляется кавычками.
#  INPUTS
#    arg - argument
#  OUTPUT
#   Аргумент с заменой специальной последовательности символов на пробел
#  EXAMPLE
#    udfWSpace2Alias a___b______cd
#    show "a b  cd"
#  SOURCE
udfAlias2WSpace() {
 udfQuoteIfNeeded $(echo "$*" | sed -e "s/$_bashlyk_sWSpaceAlias/ /g")
}
#******
#****f* bashlyk/libopt/udfGetOptHash
#  SYNOPSIS
#    udfGetOptHash <csvopt> <args>
#  DESCRIPTION
#    Разбор строки аргументов в формате "longoptions" и 
#    формирование ассоциативного массива в виде CSV строки с 
#    парами "ключ=значение", разделенные символом ";"
#  INPUTS
#    csvopt - список ожидаемых опций
#    args   - опции с аргументами
#  OUTPUT
#   Ассоциативный массив в виде CSV строки
#  EXAMPLE
#    udfGetOptHash uname:,force --uname $(uname) --force
#    show "uname=Linux;force=1;"
#  SOURCE
udfGetOptHash() {
 [ -n "$*" ] || return -1
 local k v csvKeys csvHash=';' sOpt bFound
 csvKeys=$1
 shift
 sOpt="$(getopt -l $csvKeys -n $0 -- $0 $@)" || return 1
 eval set -- "$sOpt"
 while true; do
  [ -n "$1" ] || break
  bFound=
  for k in $(echo $csvKeys | tr ',' ' '); do
   v=$(echo $k | tr -d ':')
   [ "--$v" == "$1" ] && bFound=1 || continue
   if [ -n "$(echo $k | grep ':$')" ]; then
    csvHash+="$v=$(udfAlias2WSpace $2);"
    shift 2
   else
    csvHash+="$v=1;"
    shift
   fi
  done
  [ -z "$bFound" ] && shift
 done
 shift
 echo "$csvHash"
 return 0
}
#******
#****f* bashlyk/libopt/udfSetOptHash
#  SYNOPSIS
#    udfSetOptHash <arg>
#  DESCRIPTION
#    Разбор аргумента в виде CSV строки, представляющего
#    собой ассоциативный массив с парами "ключ=значение" и формирование
#    соответствующих переменных.
#  INPUTS
#    arg - CSV строка
#  RETURN VALUE
#    0  - Переменные сформированы
#    1  - Ошибка, переменные не сформированы
#   255 - Ошибка, отсутствует аргумент
#  EXAMPLE
#    udfSetOptHash "uname=Linux;force=1;"
#    Устанавливаются переменные $uname ("Linux") и $force (1)
#  SOURCE
udfSetOptHash() {
 [ -n "$*" ] || return 255
 local confTmp iRC
 confTmp=$(udfMakeTemp setopt 0077) && {
  udfAddFile2Clean $confTmp
  udfSetConfig $confTmp "$*"
  udfGetConfig $confTmp
  rm -f $confTmp >/dev/null 2>&1
  iRC=0
 } || iRC=1
 return $iRC
}
#******
#****f* bashlyk/libopt/udfGetOpt
#  SYNOPSIS
#    udfGetOpt <csvopt> <args>
#  DESCRIPTION
#    Разбор строки аргументов в формате "longoptions" и 
#    формирование соответствующих опциям переменных 
#    с установленными значениями.
#  INPUTS
#    csvopt - список ожидаемых опций
#    args   - опции с аргументами
#  RETURN VALUE
#    0 - Переменные сформированы
#    1 - Ошибка, переменные не сформированы
#   255 - Ошибка, отсутствует аргумент
#  EXAMPLE
#    udfGetOpt uname:,force --uname $(uname) --force
#    устанавливает переменные $uname ("Linux") и $force (1)
#  SOURCE
udfGetOpt() {
 udfSetOptHash $(udfGetOptHash $*)
}
#******
#****f* bashlyk/libopt/udfExcludePairFromHash
#  SYNOPSIS
#    udfExcludePairFromHash <pair> <hash>
#  DESCRIPTION
#    Из второго аргумента <hash> исключаются подстроки ";<pair>;"
#    Ожидается, что второй аргумент является CSV-строкой с полями "ключ=значение"
#    и разделителем ";", а первый аргумент является одним из таких полей.
#  INPUTS
#    pair - строка в виде "ключ=значение"
#    hash - ассоциативный массив в виде CSV строки c разделителем ";"
#  OUTPUT
#    аргумент <hash> без подстрок ";<pair>;"
#  EXAMPLE
#    udfExcludePairFromHash save=1 "uname=Linux;force=1;save=1;"
#    выводит "uname=Linux;force=1;"
#  SOURCE
udfExcludePairFromHash() {
 [ -n "$*" ] || return 1
 local s=$1
 shift
 local csv="$*"
 echo "$csv" | sed -e "s/;$s;//g"
 return 0
}
#******
#****u* bashlyk/libopt/udfLibOpt
#  SYNOPSIS
#    udfLibOpt
# DESCRIPTION
#   bashlyk OPT library test unit
#   Запуск проверочных операций модуля выполняется если только аргументы 
#   командной строки cодержат строку вида "--bashlyk-test=[.*,]opt[,.*]",
#   где * -ярлыки на другие тестируемые библиотеки
#  SOURCE
udfLibOpt() {
 local optTest1 optTest2 optTest3 s=$(date -R) b=1
 [ -z "$(echo "${_bashlyk_sArg}" | grep -E -e "--bashlyk-test=.*opt")" ] \
 && return 0
 printf "\n- libopt.sh tests:\n\n"
 echo -n "Check udfGetOpt: "
 udfGetOpt "optTest1:,optTest2,optTest3:" --optTest1 $(uname) --optTest2\
 --optTest3 $(udfWSpace2Alias $s) 2>/dev/null
 [ "$optTest1" = "$(uname)" ] && echo -n '.' || { echo -n '?'; b=0; } 
 [ "$optTest2" = "1"        ] && echo -n '.' || { echo -n '?'; b=0; } 
 [ "$optTest3" = "$s"       ] && echo -n '.' || { echo -n '?'; b=0; } 
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 printf "\n--\n\n"
 return 0
}
#******
#****** bashlyk/libopt/Main section
# DESCRIPTION
#   Running OPT library test unit if $_bashlyk_sArg ($*) contains
#   substrings "--bashlyk-test=" and "opt" - command for test using
#  SOURCE
udfLibOpt
#******
