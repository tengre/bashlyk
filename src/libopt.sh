#
# $Id: libopt.sh 539 2016-08-18 14:20:34+04:00 toor $
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
: ${_bashlyk_aRequiredCmd_opt:="echo getopt rm"}
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
#    0                            - успешная операция
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNonValidArgument       - неправильная опция
#    iErrorEmptyResult            - пустой результат
#  EXAMPLE
#   udfGetOptHash 'job:,force' --job main --force >| grep "^job=main;force=1;$" #? true
#   udfGetOptHash                                                               #? ${_bashlyk_iErrorEmptyOrMissingArgument}
#   udfGetOptHash 'bar:,foo' --job main --force                                 #? ${_bashlyk_iErrorNonValidArgument}
#  SOURCE
udfGetOptHash() {
 local k v csvKeys csvHash sOpt bFound IFS=$' \t\n'
 #
 [[ -n "$*" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 csvKeys="$1"
 shift
 sOpt="$(getopt -l $csvKeys -n $0 -- $0 $@ 2>/dev/null)" || eval $(udfOnError return iErrorNonValidArgument $@)
 eval set -- "$sOpt"
 while true; do
  [[ -n "$1" ]] || break
  bFound=
  for k in ${csvKeys//,/ }; do
   v=${k//:/}
   [[ "--$v" == "$1" ]] && bFound=1 || continue
   if [[ "$k" =~ :$ ]]; then
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
 ## TODO ситуация iErrorEmptyResult недостижима ?
 [[ -n "$csvHash" ]] && echo "$csvHash" || eval $(udfOnError return iErrorEmptyResult)
 #return 0
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
#    echo "$job :: $bForce" >| grep "^main :: 1$"                               #? true
#    udfSetOptHash                                                              #? $_bashlyk_iErrorEmptyOrMissingArgument
#    ## TODO коды возврата проверить
#  SOURCE
udfSetOptHash() {
 local _bashlyk_udfGetOptHash_confTmp IFS=$' \t\n'
 #
 [[ -n "$*" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 udfMakeTemp   _bashlyk_udfGetOptHash_confTmp
 udfSetConfig $_bashlyk_udfGetOptHash_confTmp "$*" || eval $(udfOnError return)
 udfGetConfig $_bashlyk_udfGetOptHash_confTmp      || eval $(udfOnError return)
 rm -f $_bashlyk_udfGetOptHash_confTmp
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
 echo "${*//;$s;/}"
 #return 0
}
#******
