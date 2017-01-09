#
# $Id: libopt.sh 654 2017-01-09 16:09:13+04:00 toor $
#
#****h* BASHLYK/libopt
#  DESCRIPTION
#    Анализ параметров командной строки, сериализация и инициализация
#    соответствующих переменных с именами опций и значениями согласно опций
#    командной строки
#  USES
#    libstd libcnf
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* liberr/BASH Compability
#  DESCRIPTION
#    BASH version 4.xx or more required for this script
#  SOURCE
[ -n "$BASH_VERSION" ] && (( ${BASH_VERSINFO[0]} >= 4 )) || eval '             \
                                                                               \
    echo "[!] BASH shell version 4.xx required for ${0}, abort.."; exit 255    \
                                                                               \
'
#******
#  $_BASHLYK_LIBOPT provides protection against re-using of this module
[[ $_BASHLYK_LIBOPT ]] && return 0 || _BASHLYK_LIBOPT=1
#****L* libopt/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libcnf.sh ]] && . "${_bashlyk_pathLib}/libcnf.sh"
#******
#****G* libopt/Global variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
: ${_bashlyk_sArg:="$@"}

declare -r _bashlyk_aRequiredCmd_opt="getopt rm"
declare -r _bashlyk_aExport_opt="                                              \
                                                                               \
    udfExcludePairFromHash udfGetOpt udfGetOptHash udfSetOptHash               \
                                                                               \
"
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
#  ERRORS
#    MissingArgument  - аргумент не задан
#    NonValidArgument - неправильная опция
#    EmptyResult      - пустой результат
#  EXAMPLE
#   udfGetOptHash 'job:,force' --job main --force >| grep "^job=main;force=1;$" #? true
#   udfGetOptHash                                                               #? ${_bashlyk_iErrorEmptyOrMissingArgument}
#   udfGetOptHash 'bar:,foo' --job main --force                                 #? ${_bashlyk_iErrorNonValidArgument}
#  SOURCE
udfGetOptHash() {

  udfOn MissingArgument $* || return $?

  local k v csvKeys csvHash sOpt bFound IFS=$' \t\n'

  csvKeys="$1"
  shift

  sOpt="$( getopt -l $csvKeys -n $0 -- $0 $@ 2>/dev/null )" \
    || eval $( udfOnError return NotValidArgument $@ )

  eval set -- "$sOpt"

  while true; do

    [[ $1 ]] || break
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
  [[ $csvHash ]] && echo "$csvHash" || eval $( udfOnError return EmptyResult )

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
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    local job bForce
#    udfSetOptHash "job=main;bForce=1;"                                         #? true
#    echo "$job :: $bForce" >| grep "^main :: 1$"                               #? true
#    udfSetOptHash                                                              #? $_bashlyk_iErrorEmptyOrMissingArgument
#    ## TODO коды возврата проверить
#  SOURCE
udfSetOptHash() {

  udfOn MissingArgument $* || return $?

  local _bashlyk_udfGetOptHash_confTmp IFS=$' \t\n'

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
#  ERRORS
#    MissingArgument - аргумент не задан
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
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    local s="job=main;bForce=1"
#    udfExcludePairFromHash 'save=1' "${s};save=1;" >| grep "^${s}$"            #? true
#  SOURCE
udfExcludePairFromHash() {

  udfOn MissingArgument $* || return $?

  local s="$1" IFS=$' \t\n'

  shift

  echo "${*//;$s;/}"

}
#******
