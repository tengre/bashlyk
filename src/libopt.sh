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
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$_BASHLYK_LIBOPT" ] && return 0 || _BASHLYK_LIBOPT=1
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
#******
#****** bashlyk/libopt/External modules
#  DESCRIPTION
#    Using modules section
#    Здесь указываются модули, код которых используется данной библиотекой
#  SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/libstd.sh" ] && . "${_bashlyk_pathLib}/libstd.sh"
[ -s "${_bashlyk_pathLib}/libcnf.sh" ] && . "${_bashlyk_pathLib}/libcnf.sh"
#******
#****v*  bashlyk/libopt/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#    * $_bashlyk_sArg - аргументы командной строки вызова сценария
#    * $_bashlyk_sWSpaceAlias - заменяющая пробел последовательность символов
#    * $_bashlyk_aRequiredCmd_std - список используемых в данном модуле внешних
#    утилит
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_aRequiredCmd_opt:="[ echo getopt grep rm sed tr"}
: ${_bashlyk_aExport_opt:="udfGetOptHash udfSetOptHash udfGetOpt udfExcludePairFromHash"}
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
#    udfGetOptHash 'job:,force' --job main --force | grep "^;job=main;force=1;$"##udfGetOptHash ? true
#  SOURCE
udfGetOptHash() {
 [ -n "$*" ] || return -1
 local k v csvKeys csvHash=';' sOpt bFound
 csvKeys="$1"
 shift
 sOpt="$(getopt -l $csvKeys -n $0 -- $0 $@)" || return 1
 eval set -- "$sOpt"
 while true; do
  [ -n "$1" ] || break
  bFound=
  for k in $(echo $csvKeys | tr ',' ' '); do
   v=$(echo $k | tr -d ':')
   [ "--$v" = "$1" ] && bFound=1 || continue
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
#    local job bForce                                                           ##udfSetOptHash
#    udfSetOptHash "job=main;bForce=1;"                                         ##udfSetOptHash
#    echo "dbg $job :: $bForce" | grep "^dbg main :: 1$"                        ##udfSetOptHash ? true
#  SOURCE
udfSetOptHash() {
 [ -n "$*" ] || return 255
 local confTmp rc
 udfMakeTemp confTmp && {
  udfSetConfig $confTmp "$*"
  udfGetConfig $confTmp
  rm -f $confTmp
  rc=0
 } || rc=1
 return $rc
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
#    local job bForce
#    udfGetOpt job:,bForce --job main --bForce
#    echo "dbg $job :: $bForce" | grep "^dbg main :: 1$"                        ##udfGetOpt ? true
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
#    local s="job=main;bForce=1"                                                ##udfExcludePairFromHash
#    udfExcludePairFromHash 'save=1' "${s};save=1;" | grep "^${s}$"             ##udfExcludePairFromHash ? true
#  SOURCE
udfExcludePairFromHash() {
 [ -n "$*" ] || return 1
 local s="$1"
 shift
 local csv="$*"
 echo "$csv" | sed -e "s/;$s;//g"
 return 0
}
#******
