#
# $Id$
#
#****h* BASHLYK/libopt
#  DESCRIPTION
#    Анализ параметров командной строки, сериализация и инициализация
#    соответствующих переменных с именами опций и значениями согласно опций
#    командной строки
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libopt/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
[[ -n "$_BASHLYK_LIBOPT" ]] && return 0 || _BASHLYK_LIBOPT=1
#******
#****** libopt/External modules
#  DESCRIPTION
#    Using modules section
#    Здесь указываются модули, код которых используется данной библиотекой
#  SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s "${_bashlyk_pathLib}/libstd.sh" ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s "${_bashlyk_pathLib}/libcnf.sh" ]] && . "${_bashlyk_pathLib}/libcnf.sh"
#******
#****v* libopt/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#    * $_bashlyk_sArg - аргументы командной строки вызова сценария
#    * $_bashlyk_sWSpaceAlias - заменяющая пробел последовательность символов
#    * $_bashlyk_aRequiredCmd_std - список используемых в данном модуле внешних
#    утилит
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_bSetOptions:=}
: ${_bashlyk_aRequiredCmd_opt:="[ echo getopt grep rm sed tr"}
: ${_bashlyk_aExport_opt:="udfGetOptHash udfSetOptHash udfGetOpt udfExcludePairFromHash"}
#******
#****f* libopt/udfGetOptHash
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
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#   udfGetOptHash 'job:,force' --job main --force >| grep "^;job=main;force=1;$" #? true
#  SOURCE
udfGetOptHash() {
 local k v csvKeys csvHash=';' sOpt bFound IFS=$' \t\n'
 #
 [[ -n "$*" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 csvKeys="$1"
 shift
 sOpt="$(getopt -l $csvKeys -n $0 -- $0 $@)" || return 1
 eval set -- "$sOpt"
 while true; do
  [[ -n "$1" ]] || break
  bFound=
  for k in $(echo $csvKeys | tr ',' ' '); do
   v=$(echo $k | tr -d ':')
   [[ "--$v" == "$1" ]] && bFound=1 || continue
   if [[ -n "$(echo $k | grep ':$')" ]]; then
    csvHash+="$v=$(udfAlias2WSpace $2);"
    shift 2
   else
    csvHash+="$v=1;"
    shift
   fi
  done
  [[ -z "$bFound" ]] && shift
 done
 shift
 echo "$csvHash"
 return 0
}
#******
#****f* libopt/udfSetOptHash
#  SYNOPSIS
#    udfSetOptHash <arg>
#  DESCRIPTION
#    Разбор аргумента в виде CSV строки, представляющего
#    собой ассоциативный массив с парами "ключ=значение" и формирование
#    соответствующих переменных.
#  INPUTS
#    arg - CSV строка
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    local job bForce
#    udfSetOptHash "job=main;bForce=1;"                                         #? true
#    echo "dbg $job :: $bForce" >| grep "^dbg main :: 1$"                       #? true
#    ## TODO коды возврата проверить
#  SOURCE
udfSetOptHash() {
 local confTmp rc=0 IFS=$' \t\n'
 #
 [[ -n "$*" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 udfMakeTemp confTmp
 udfSetConfig $confTmp "$*" || return $?
 udfGetConfig $confTmp      || return $?
 rm -f $confTmp
 return 0
}
#******
#****f* libopt/udfGetOpt
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
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    local job bForce
#    udfGetOpt job:,bForce --job main --bForce                                  #? true
#    echo "dbg $job :: $bForce" >| grep "^dbg main :: 1$"                       #? true
#  SOURCE
udfGetOpt() {
 udfSetOptHash $(udfGetOptHash $*)
 _bashlyk_bSetOptions=1
}
#******
#****f* libopt/udfExcludePairFromHash
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
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    local s="job=main;bForce=1"
#    udfExcludePairFromHash 'save=1' "${s};save=1;" >| grep "^${s}$"            #? true
#  SOURCE
udfExcludePairFromHash() {
 local s="$1" IFS=$' \t\n'
 #
 [[ -n "$*" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 shift
 local csv="$*"
 echo "$csv" | sed -e "s/;$s;//g"
 return 0
}
#******
