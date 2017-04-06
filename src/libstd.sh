#
# $Id: libstd.sh 724 2017-04-06 17:29:28+04:00 toor $
#
#****h* BASHLYK/libstd
#  DESCRIPTION
#    стандартный набор функций, включает автоматически управляемые функции
#    вывода сообщений, контроля корректности входных данных, создания временных
#    объектов и автоматического их удаления после завершения сценария или
#    фонового процесса, обработки ошибок
#  USES
#    liberr libmsg
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libstd/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBSTD provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBSTD" ] && return 0 || _BASHLYK_LIBSTD=1
[ -n "$_BASHLYK" ] || . bashlyk || eval '                                      \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* libstd/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libmsg.sh ]] && . "${_bashlyk_pathLib}/libmsg.sh"
#******
#****v* libstd/Global Variables
#  DESCRIPTION
#    Global variables of the library
#    Блок инициализации глобальных переменных
#    * $_bashlyk_sArg - аргументы командной строки вызова сценария
#    * $_bashlyk_sWSpaceAlias - заменяющая пробел последовательность символов
#    * $_bashlyk_aRequiredCmd_opt - список используемых в данном модуле внешних
#    утилит
#  SOURCE
: ${TMPDIR:=/tmp}
#: ${_bashlyk_afoClean:=}
#: ${_bashlyk_afdClean:=}
#: ${_bashlyk_ajobClean:=}
#: ${_bashlyk_apidClean:=}
#: ${_bashlyk_pidLogSock:=}
#: ${_bashlyk_envXSession:=}
: ${_bashlyk_sWSpaceAlias:=___}
: ${HOSTNAME:=$( exec -c hostname 2>/dev/null )}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}
#: ${_bashlyk_reMetaRules:='34=":40=(:41=):59=;:91=[:92=\\:93=]:61=='}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}

declare -rg _bashlyk_iMaxOutputLines=1000

declare -rg _bashlyk_aRequiredCmd_std="                                        \
                                                                               \
    chgrp chmod chown date echo expr hostname kill logname md5sum mkdir mkfifo \
    pgrep pwd rm rmdir sed sleep touch                                         \
    mktemp|tempfile                                                            \
                                                                               \
"

declare -rg _bashlyk_aExport_std="                                             \
                                                                               \
    _ udfAddFD2Clean udfAddFile2Clean udfAddFO2Clean udfAddFObj2Clean          \
    udfAddJob2Clean udfAddPath2Clean udfAddPid2Clean udfAlias2WSpace udfCat    \
    udfCleanQueue udfFinally udfGetFreeFD udfGetMd5 udfGetPathMd5              \
    udfGetTimeInSec udfIsHash udfIsNumber udfIsValidVariable udfMakeTemp       \
    udfMakeTempV udfOnTrap udfPrepareByType udfQuoteIfNeeded udfShowVariable   \
    udfTrim udfWSpace2Alias udfXml                                             \
                                                                               \
"
#******
#****f* libstd/udfIsNumber
#  SYNOPSIS
#    udfIsNumber <number> [<tag>]
#  DESCRIPTION
#    Проверка аргумента на то, что он является натуральным числом
#    Аргумент считается числом, если он содержит цифры и может иметь в конце
#    символ - признак порядка, например, k M G T (kilo-, Mega-, Giga-, Terra-)
#  INPUTS
#    number - проверяемое значение
#    tag    - набор символов, один из которых можно применить
#             после цифр для указания признака числа, например,
#             порядка. (регистр не имеет значения)
#  RETURN VALUE
#    0               - аргумент является натуральным числом
#    NotNumber - аргумент не является натуральным числом
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    udfIsNumber 12                                                             #? true
#    udfIsNumber 34k k                                                          #? true
#    udfIsNumber 67M kMGT                                                       #? true
#    udfIsNumber 89G G                                                          #? true
#    udfIsNumber 12,34                                                          #? $_bashlyk_iErrorNotNumber
#    udfIsNumber 12T                                                            #? $_bashlyk_iErrorNotNumber
#    udfIsNumber 1O2                                                            #? $_bashlyk_iErrorNotNumber
#    udfIsNumber                                                                #? $_bashlyk_iErrorMissingArgument
#  SOURCE
udfIsNumber() {

  local s

  [[ $2 ]] && s="[$2]?"

  [[ $1 =~ ^[0-9]+${s}$ ]] && return 0

  udfOn MissingArgument $1 || return $?

  return $_bashlyk_iErrorNotNumber

}
#******
#****f* libstd/udfTimeStamp
#  SYNOPSIS
#    udfTimeStamp <text>
#  DESCRIPTION
#    Show input <text> with time stamp in format 'Mar 28 10:03:40' (LC_ALL=C)
#  INPUTS
#    <text> - suffix to the header
#  OUTPUT
#    input <text> with time stamp in format 'Mar 28 10:03:40' (LC_ALL=C)
#  EXAMPLE
#    local re
#    re='^[ADFJMNOS][abceglnoprtuyv]{2} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} AB$'
#    udfTimeStamp AB >| grep -E "$re"                                           #? true
#  SOURCE

if (( _bashlyk_ShellVersion > 4002000 )); then

  udfTimeStamp() { LC_ALL=C printf -- '%(%b %d %H:%M:%S)T %s\n' '-1' "$*"; }

  udfDateR() { LC_ALL=C printf -- '%(%a, %d %b %Y %T %z)T\n' '-1'; }

  udfUptime() { echo $(( $(printf '%(%s)T' '-1') - $(printf '%(%s)T' '-2') )); }

else

  readonly _bashlyk_iStartTimeStamp=$( exec -c date "+%s" )

  udfTimeStamp() { LC_ALL=C date "+%b %d %H:%M:%S $*"; }

  udfDateR() { exec -c date -R; }

  udfUptime() { echo $(( $(exec -c date "+%s") - _bashlyk_iStartTimeStamp )); }

fi

#******
#****f* libstd/udfDateR
#  SYNOPSIS
#    udfDateR
#  DESCRIPTION
#    show 'date -R' like output
#  EXAMPLE
#    udfDateR >| grep -P "^\S{3}, \d{2} \S{3} \d{4} \d{2}:\d{2}:\d{2} .\d{4}$"  #? true
#  SOURCE
#******
#****f* libstd/udfUptime
#  SYNOPSIS
#    udfUptime
#  DESCRIPTION
#    show uptime value in the seconds
#  EXAMPLE
#    udfUptime >| grep "^[[:digit:]]*$"                                         #? true
#  SOURCE
#******
#****f* libstd/udfFinally
#  SYNOPSIS
#    udfFinally <text>
#  DESCRIPTION
#    show uptime with input text
#  INPUTS
#    <text> - prefix text before " uptime <number> sec"
#  EXAMPLE
#    udfFinally $RANDOM >| grep "^[[:digit:]]* uptime [[:digit:]]* sec$"        #? true
#  SOURCE
udfFinally() { echo "$@ uptime $( udfUptime ) sec"; }
#******
#****f* libstd/udfShowVariable
#  SYNOPSIS
#    udfShowVariable args
#  DESCRIPTION
#    Вывод листинга значений аргументов, если они являются именами переменными. Допускается
#    разделять имена переменных знаками ',' и ';', однако, необходимо помнить, что знак ';'
#    (или аргументы целиком) необходимо экранировать кавычками, иначе интерпретатор воспримет
#    аргумент как следующую команду!
#    Если аргумент не является валидным именем переменной, то выводится соответствующее сообщение.
#    Функцию можно использовать для формирования строк инициализации переменных, при этом
#    информационные строки за счет экранирования командой ':' не выполняют никаких действий
#    при разборе интерпретатором, их также можно отфильтровать командой "grep -v '^:'"
#  INPUTS
#    args - ожидаются имена переменных
#  OUTPUT
#    служебные строки выводятся с начальным ':' для автоматической подавления возможности выполнения
#    Валидное имя переменной и значение в виде <Имя>=<Значение>
#  EXAMPLE
#    local s='text' b='true' i=2015 a='true 2015 text'
#    udfShowVariable "a,b; i" s  >| grep -w "a=true 2015 text\|b=true\|i=2015\|s=text"                                    #? true
#    udfShowVariable a b i s 12w >| grep '^:.*12w.* not valid'                                                            #? true                                                                             #? true
#  SOURCE
udfShowVariable() {

  local bashlyk_udfShowVariable_a bashlyk_udfShowVariable_s IFS=$'\t\n ,;'

  for bashlyk_udfShowVariable_s in $*; do

    if udfIsValidVariable $bashlyk_udfShowVariable_s; then

      bashlyk_udfShowVariable_a+="\t${bashlyk_udfShowVariable_s}=${!bashlyk_udfShowVariable_s}\n"

    else

      bashlyk_udfShowVariable_a+=": Variable name \"${bashlyk_udfShowVariable_s}\" is not valid!\n"

    fi

  done

  printf -- ": Variable listing>\n${bashlyk_udfShowVariable_a}"

  return 0

}
#******
#****f* libstd/udfIsValidVariable
#  SYNOPSIS
#    udfIsValidVariable <arg>
#  DESCRIPTION
#    Проверка аргумента на то, что он может быть валидным идентификатором
#    переменной
#  INPUTS
#    arg - проверяемое значение
#  RETURN VALUE
#    0               - аргумент валидный идентификатор
#    InvalidVariable - аргумент невалидный идентификатор (или не задан)
#  EXAMPLE
#    udfIsValidVariable                                                         #? $_bashlyk_iErrorMissingArgument
#    udfIsValidVariable "12w"                                                   #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable "a"                                                     #? true
#    udfIsValidVariable "k1"                                                    #? true
#    udfIsValidVariable "&w1"                                                   #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable "#k12s"                                                 #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable ":v1"                                                   #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable ";q1"                                                   #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable ",g99"                                                  #? $_bashlyk_iErrorInvalidVariable
#  SOURCE
udfIsValidVariable() {

  [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]] && return 0

  udfOn MissingArgument $1 || return $?

  return $_bashlyk_iErrorInvalidVariable

}
#******
#****f* libstd/udfQuoteIfNeeded
#  SYNOPSIS
#    udfQuoteIfNeeded <arg>
#  DESCRIPTION
#   Аргумент, содержащий пробел(ы) отмечается кавычками
#  INPUTS
#    arg - argument
#  OUTPUT
#    аргумент с кавычками, если есть пробелы
#  EXAMPLE
#    udfQuoteIfNeeded "word" >| grep '^word$'                                   #? true
#    udfQuoteIfNeeded two words >| grep '^".*"$'                                #? true
#  SOURCE
udfQuoteIfNeeded() {

  if [[ "$*" =~ [[:space:]] && ! "$*" =~ ^\".*\"$ ]]; then

    echo "\"$*\""

  else

    echo "$*"

  fi

}
#******
#****f* libstd/udfWSpace2Alias
#  SYNOPSIS
#    udfWSpace2Alias -|<arg>
#  DESCRIPTION
#   Пробел в аргументе заменяется "магической" последовательностью символов,
#   определённых в глобальной переменной $_bashlyk_sWSpaceAlias
#  INPUTS
#    arg - argument
#    "-" - ожидается ввод в конвейере
#  OUTPUT
#   Аргумент с заменой пробелов на специальную последовательность символов
#  EXAMPLE
#    udfWSpace2Alias 'a b  cd' >| grep  '^a___b______cd$'                       #? true
#    echo 'a b  cd' | udfWSpace2Alias - >| grep '^a___b______cd$'               #? true
#  SOURCE
udfWSpace2Alias() {

  case $* in

    -) sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
    *) echo "${*// /$_bashlyk_sWSpaceAlias}";;

  esac

}
#******
#****f* libstd/udfAlias2WSpace
#  SYNOPSIS
#    udfAlias2WSpace -|<arg>
#  DESCRIPTION
#    Последовательность символов, определённых в глобальной переменной
#    $_bashlyk_sWSpaceAlias заменяется на пробел в заданном аргументе.
#    Причём, если появляются пробелы, то вывод обрамляется кавычками.
#    В случае ввода в конвейере вывод не обрамляется кавычками
#  INPUTS
#    arg - argument
#  OUTPUT
#    Аргумент с заменой специальной последовательности символов на пробел
#  EXAMPLE
#    udfAlias2WSpace a___b______cd >| grep '^"a b  cd"$'                        #? true
#    echo a___b______cd | udfAlias2WSpace - >| grep '^a b  cd$'                 #? true
#  SOURCE
udfAlias2WSpace() {

  case "$1" in

    -) sed -e "s/$_bashlyk_sWSpaceAlias/ /g";;
    *) udfQuoteIfNeeded "${*//$_bashlyk_sWSpaceAlias/ }";;

  esac
}
#******
#****f* libstd/udfMakeTemp
#  SYNOPSIS
#    udfMakeTemp [ [-v] <valid variable> ] <named options>...
#  DESCRIPTION
#    make temporary file object - file, pipe or directory
#  INPUTS
#    [-v] <variable>    - the output assigned to the <variable> (as bash printf)
#                         option -v can be omitted, variable must be correct and
#                         this options must be first
#    path=<path>        - place the temporary filesystem objects in the <path>
#    prefix=<prefix>    - prefix (up to 5 characters for compatibility) for the
#                         generated name
#    suffix=<suffix>    - suffix for the generated name of temporary object
#    mode=<octal>       - the right of access to the temporary facility in octal
#    owner=<owner>      - owner of temporary object
#    group=<group>      - group of temporary object
#    type=file|pipe|dir - object type: file (the default), pipe or directory
#    keep=true|false    - temporary object is deleted by default at the end if
#                         its name is stored in a variable.
#                         true  - do not remove
#                         false - delete
#  OUTPUT
#    if -v option or valid variable is omitted then name of created temporary
#    filesystem object being printed to the standard output
#
#  ERRORS
#    NotExistNotCreated - temporary file system object is not created
#    InvalidVariable    - used invalid variable name
#    EmptyResult        - name for temporary object missing
#
#  EXAMPLE
#    ## TODO improve tests
#    local foTemp s=$RANDOM
#    _ onError return
#    udfMakeTemp foTemp path=/tmp prefix=pre. suffix=.${s}1                     #? true
#    ls -1 /tmp/pre.*.${s}1 2>/dev/null >| grep "/tmp/pre\..*\.${s}1"           #? true
#    rm -f $foTemp
#    udfMakeTemp foTemp path=/tmp type=dir mode=0751 suffix=.${s}2              #? true
#    ls -ld $foTemp 2>/dev/null >| grep "^drwxr-x--x.*${s}2$"                   #? true
#    rmdir $foTemp
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.${s}3)
#    ls -1 $foTemp 2>/dev/null >| grep "pre\..*\.${s}3$"                        #? true
#    rm -f $foTemp
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.${s}4 keep=false)                 #? true
#    echo $foTemp >| grep "${TMPDIR}/pre\..*\.${s}4"                            #? true
#    test -f $foTemp                                                            #? false
#    rm -f $foTemp
#    $(udfMakeTemp foTemp path=/tmp prefix=pre. suffix=.${s}5 keep=true)
#    ls -1 /tmp/pre.*.${s}5 2>/dev/null >| grep "/tmp/pre\..*\.${s}5"           #? true
#    rm -f /tmp/pre.*.${s}5
#    $(udfMakeTemp foTemp path=/tmp prefix=pre. suffix=.${s}6)
#    ls -1 /tmp/pre.*.${s}6 2>/dev/null >| grep "/tmp/pre\..*\.${s}6"           #? false
#    unset foTemp
#    foTemp=$(udfMakeTemp)                                                      #? true
#    ls -1l $foTemp 2>/dev/null                                                 #? true
#    test -f $foTemp                                                            #? true
#    rm -f $foTemp
#    udfMakeTemp foTemp type=pipe                                               #? true
#    test -p $foTemp                                                            #? true
#    rm -f $foTemp
#    udfMakeTemp invalid+variable                                               #? ${_bashlyk_iErrorInvalidVariable}
#    udfMakeTemp path=/proc                                                     #? ${_bashlyk_iErrorNotExistNotCreated}
#  SOURCE
udfMakeTemp() {

  if [[ "$1" == "-v" ]] || udfIsValidVariable $1; then

    [[ "$1" == "-v" ]] && shift

    udfIsValidVariable $1 || eval $( udfOnError InvalidVariable "$1" )

    eval 'export $1="$( shift; udfMakeTemp stdout-mode ${@//keep=false/} )"'

    [[ ${!1} ]] || eval $( udfOnError EmptyResult "$1" )

    [[ $* =~ keep=false || ! $* =~ keep=true ]] && udfAddFO2Clean ${!1}

    return 0

  fi

  local bPipe cmd IFS octMode optDir path s sGroup sPrefix sSuffix sUser

  cmd=direct
  IFS=$' \t\n'

  for s in $*; do

    case "$s" in

        path=*) path=${s#*=};;
      prefix=*) sPrefix=${s#*=};;
      suffix=*) sSuffix=${s#*=};;
        mode=*) octMode=${s#*=};;
       type=d*) optDir='-d';;
       type=f*) optDir='';;
       type=p*) bPipe=1;;
        user=*) sUser=${s#*=};;
       group=*) sGroup=${s#*=};;
        keep=*) continue;;
      stdout-*) continue;;
             *)

                if [[ $1 == $s ]]; then

      		  udfIsValidVariable $1 || eval $(udfOnError InvalidVariable $s)

                fi

      	        if udfIsNumber "$2" && [[ -z "$3" ]] ; then

      		  # compatibility with ancient version
      		  octMode="$2"
      		  sPrefix="$1"

      	        fi
      	     ;;
    esac

  done

  sPrefix=${sPrefix//\//}
  sSuffix=${sSuffix//\//}

  if   hash mktemp   2>/dev/null; then

    cmd=mktemp

  elif hash tempfile 2>/dev/null; then

    [[ $optDir ]] && cmd=direct || cmd=tempfile

  fi

  if [[ ! $path ]]; then

    [[ $bPipe ]] && path=$( _ pathRun ) || path="$TMPDIR"

  fi

  mkdir -p $path || eval $( udfOnError NotExistNotCreated "$path" )

  case "$cmd" in

    direct)

      s="${path}/${sPrefix:0:5}${RANDOM}${sSuffix}"

      [[ $optDir ]] && mkdir -p $s || touch $s

    ;;

    mktemp)

      s=$( mktemp --tmpdir=${path} $optDir --suffix=${sSuffix} "${sPrefix:0:5}XXXXXXXX" )

    ;;

    tempfile)

      [[ $sPrefix ]] && sPrefix="-p ${sPrefix:0:5}"
      [[ $sSuffix ]] && sSuffix="-s $sSuffix"

      s=$( tempfile -d $path $sPrefix $sSuffix )

    ;;

  esac

  if [[ $bPipe ]]; then

    rm -f  $s
    mkfifo $s
    : ${octMode:=0600}

  fi >&2

  [[ $octMode ]] && chmod $octMode $s

  ## TODO обработка ошибок
  if (( $UID == 0 )); then

    [[ $sUser  ]] && chown $sUser  $s
    [[ $sGroup ]] && chgrp $sGroup $s

  fi >&2

  if ! [[ -f "$s" || -p "$s" || -d "$s" ]]; then

    eval $( udfOnError NotExistNotCreated $s )

  fi

  [[ $* =~ keep=false ]] && udfAddFO2Clean $s

  [[ $s ]] || return $( _ iErrorEmptyResult )

  echo $s

}
#******
#****f* libstd/udfMakeTempV
#  SYNOPSIS
#    udfMakeTempV <var> [file|dir|keep|keepf[ile*]|keepd[ir]] [<prefix>]
#  DESCRIPTION
#    Create a temporary file or directory with automatic removal upon completion
#    of the script, the object name assigned to the variable.
#    Obsolete - replaced by a udfMakeTemp
#  INPUTS
#    <var>      - the output assigned to the <variable> (as bash printf)
#                 option -v can be omitted, variable must be correct and this
#                 options must be first
#    file       - create file
#    dir        - create directory
#    keep[file] - create file, keep after done
#    keepdir    - create directory, keep after done
#    prefix     - prefix for name (5 letters)
#  ERRORS
#    NotExistNotCreated - temporary file system object is not created
#    InvalidVariable    - used invalid variable name
#    EmptyResult        - name for temporary object missing
#  EXAMPLE
#    local foTemp
#    udfMakeTempV foTemp file prefix                                            #? true
#    ls $foTemp >| grep "prefi"                                                 #? true
#    udfMakeTempV foTemp dir                                                    #? true
#    ls -ld $foTemp >| grep "^drwx------.*${foTemp}$"                           #? true
#    echo $(udfAddFO2Clean $foTemp)
#    test -d $foTemp                                                            #? false
#  SOURCE
udfMakeTempV() {

  udfOn MissingArgument throw $1 || return $?

  local sKeep sType sPrefix IFS=$' \t\n'

  udfIsValidVariable $1 || eval $( udfOnError throw InvalidVariable "$1" )

  [[ $3 ]] && sPrefix="prefix=$3"

  case $2 in

            dir) sType="type=dir" ; sKeep="keep=false" ;;
           file) sType="type=file"; sKeep="keep=false" ;;
    keep|keepf*) sType="type=file"; sKeep="keep=true"  ;;
         keepd*) sType="type=dir" ; sKeep="keep=true"  ;;
             '') sType="type=file"; sKeep="keep=false" ;;
              *) sPrefix="prefix=$2";;

  esac

  udfMakeTemp $1 $sType $sKeep $sPrefix

}
#******
udfAddJob2Clean() { return 0; }
#****f* libstd/udfAddPid2Clean
#  SYNOPSIS
#    udfAddPid2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных процессов к списку очистки при
#    завершении текущего процесса.
#  INPUTS
#    args - идентификаторы процессов
#  EXAMPLE
#    sleep 99 &
#    udfAddPid2Clean $!
#    test "${_bashlyk_apidClean[$BASHPID]}" -eq "$!"                            #? true
#    ps -p $! -o pid= >| grep -w $!                                             #? true
#    echo $(udfAddPid2Clean $!; echo "$BASHPID : $! ")
#    ps -p $! -o pid= >| grep -w $!                                             #? false
#
#  SOURCE
udfAddPid2Clean() {

  [[ $1 ]] || return 0

  _bashlyk_apidClean[$BASHPID]+=" $*"

  trap "udfOnTrap" EXIT

}
#******
#****f* libstd/udfAddFD2Clean
#  SYNOPSIS
#    udfAddFD2Clean <args>
#  DESCRIPTION
#    add list of filedescriptors for cleaning on exit
#  ARGUMENTS
#    <args> - file descriptors
#  SOURCE
udfAddFD2Clean() {

  udfOn MissingArgument $* || return $?

  _bashlyk_afdClean[$BASHPID]+=" $*"

  trap "udfOnTrap" EXIT

}
#******
#****f* libstd/udfAddFO2Clean
#  SYNOPSIS
#    udfAddFO2Clean <args>
#  DESCRIPTION
#    add list of filesystem objects for cleaning on exit
#  INPUTS
#    args - files or directories for cleaning on exit
#  EXAMPLE
#    local a fnTemp1 fnTemp2 pathTemp1 pathTemp2 s=$RANDOM
#    udfMakeTemp fnTemp1 keep=true suffix=.${s}1
#    test -f $fnTemp1
#    echo $(udfAddFO2Clean $fnTemp1 )
#    ls -l ${TMPDIR}/*.${s}1 2>/dev/null >| grep ".*\.${s}1"                    #? false
#    echo $(udfMakeTemp fnTemp2 suffix=.${s}2)
#    ls -l ${TMPDIR}/*.${s}2 2>/dev/null >| grep ".*\.${s}2"                    #? false
#    echo $(udfMakeTemp fnTemp2 suffix=.${s}3 keep=true)
#    ls -l ${TMPDIR}/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                    #? true
#    a=$(ls -1 ${TMPDIR}/*.${s}3)
#    echo $(udfAddFO2Clean $a )
#    ls -l ${TMPDIR}/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                    #? false
#    udfMakeTemp pathTemp1 keep=true suffix=.${s}1 type=dir
#    test -d $pathTemp1
#    echo $(udfAddFO2Clean $pathTemp1 )
#    ls -1ld ${TMPDIR}/*.${s}1 2>/dev/null >| grep ".*\.${s}1"                  #? false
#    echo $(udfMakeTemp pathTemp2 suffix=.${s}2 type=dir)
#    ls -1ld ${TMPDIR}/*.${s}2 2>/dev/null >| grep ".*\.${s}2"                  #? false
#    echo $(udfMakeTemp pathTemp2 suffix=.${s}3 keep=true type=dir)
#    ls -1ld ${TMPDIR}/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                  #? true
#    a=$(ls -1ld ${TMPDIR}/*.${s}3)
#    echo $(udfAddFO2Clean $a )
#    ls -1ld ${TMPDIR}/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                  #? false
#  SOURCE
udfAddFO2Clean() {

  udfOn MissingArgument return $*

  _bashlyk_afoClean[$BASHPID]+=" $*"

  trap "udfOnTrap" EXIT

}
#******
udfCleanQueue()    { udfAddFO2Clean $@; }
udfAddFObj2Clean() { udfAddFO2Clean $@; }
udfAddFile2Clean() { udfAddFO2Clean $@; }
udfAddPath2Clean() { udfAddFO2Clean $@; }
#****f* libstd/udfOnTrap
#  SYNOPSIS
#    udfOnTrap
#  DESCRIPTION
#    The cleaning procedure at the end of the calling script.
#    Suitable for trap command call.
#    Produced deletion of files and empty directories; stop child processes,
#    closure of open file descriptors listed in the corresponding global
#    variables. All processes must be related and descended from the working
#    script process. Closes the socket script log if it was used.
#  EXAMPLE
#    local fd fn1 fn2 path pid pipe
#    udfMakeTemp fn1
#    udfMakeTemp fn2
#    udfMakeTemp path type=dir
#    udfMakeTemp pipe type=pipe
#    fd=$( udfGetFreeFD )
#    eval "exec ${fd}>$fn2"
#    (sleep 1024)&
#    pid=$!
#    test -f $fn1
#    test -d $path
#    ps -p $pid -o pid= >| grep -w $pid
#    ls /proc/$$/fd >| grep -w $fd
#    udfAddFD2Clean $fd
#    udfAddPid2Clean $pid
#    udfAddFO2Clean $fn1
#    udfAddFO2Clean $path
#    udfAddFO2Clean $pipe
#    udfOnTrap
#    ls /proc/$$/fd >| grep -w $fd                                              #? false
#    ps -p $pid -o pid= >| grep -w $pid                                         #? false
#    test -f $fn1                                                               #? false
#    test -d $path                                                              #? false
#  SOURCE
udfOnTrap() {

  local i IFS=$' \t\n' re s
  local -a a

  a=( ${_bashlyk_apidClean[$BASHPID]} )

  for (( i=${#a[@]}-1; i>=0 ; i-- )) ; do

    re="\\b${a[i]}\\b"

    for s in 15 9; do

      if [[  "$( pgrep -d' ' -P $$ )" =~ $re ]]; then

        if ! kill -${s} ${a[i]} >/dev/null 2>&1; then

          udfSetLastError NotPermitted "${a[i]}"
          sleep 0.1

        fi

      fi

    done

  done

  for s in ${_bashlyk_afdClean[$BASHPID]}; do

    udfIsNumber $s && eval "exec ${s}>&-"

  done

  for s in ${_bashlyk_afoClean[$BASHPID]}; do

    [[ -f $s ]] && rm -f $s && continue
    [[ -p $s ]] && rm -f $s && continue
    [[ -d $s ]] && rmdir --ignore-fail-on-non-empty $s 2>/dev/null && continue

  done

  if [[ -n "${_bashlyk_pidLogSock}" ]]; then

    exec >/dev/null 2>&1
    wait ${_bashlyk_pidLogSock}

  fi

}
#******
#****f* libstd/udfPrepareByType
#  SYNOPSIS
#    udfPrepareByType <arg>
#  DESCRIPTION
#    present argument 'Array[item]' as '{Array[item]}'
#  INPUTS
#    <arg> - valid name of variable or valid name item of array
#  OUTPUT
#    converted input string, if necessary
#  ERRORS
#    MissingArgument - аргумент не задан
#    InvalidVariable - не валидный идентификатор
#  EXAMPLE
#    _bashlyk_onError=return
#    udfPrepareByType                                                           #? $_bashlyk_iErrorMissingArgument
#    udfPrepareByType 12a                                                       #? $_bashlyk_iErrorInvalidVariable
#    udfPrepareByType 12a[te]                                                   #? $_bashlyk_iErrorInvalidVariable
## TODO - do not worked    udfPrepareByType a12[]                               #? $_bashlyk_iErrorInvalidVariable
#    udfPrepareByType _a >| grep '^_a$'                                         #? true
#    udfPrepareByType _a[1234] >| grep '^\{_a\[1234\]\}$'                       #? true
#  SOURCE
udfPrepareByType() {

  [[ $1 ]] || eval $( udfOnError return MissingArgument )

  [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*(\[.*\])?$ ]] \
    || eval $( udfOnError return InvalidVariable '$1' )

  [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*\[.*\]$ ]] && echo "{$1}" || echo "$1"

}
#******
#****f* libstd/_
#  SYNOPSIS
#    _ [[<get>]=]<subname> [<value>]
#  DESCRIPTION
#    Получить или установить (get/set) значение глобальной переменной
#    $_bashlyk_<subname>
#  INPUTS
#    <get>     - переменная для приема значения (get) ${_bashlyk_<subname>},
#                может быть опущена (знак "=" не опускается), в этом случае
#                предполагается, что она имеет имя <subname>
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#    <value>   - новое значение (set) для ${_bashlyk_<subname>}. Имеет приоритет
#                перед режимом "get"
#    Важно! Если используется переменная в качестве <value>, то она обязательно
#    должна быть в двойных кавычках, иначе в случае принятия пустого значения
#    смысл операции поменяется с "set" на "get" c выводом значения на STDOUT
#  OUTPUT
#    Вывод значения переменной $_bashlyk_<subname> в режиме get, если не указана
#    приемная переменная и нет знака "="
#  ERRORS
#    MissingArgument - аргумент не задан
#    InvalidVariable - не валидный идентификатор
#  EXAMPLE
#    local sS sWSpaceAlias pid=$BASHPID k=key1 v=val1
#    _ k=sWSpaceAlias
#    echo "$k" >| grep "^${_bashlyk_sWSpaceAlias}$"                             #? true
#    _ sS=sWSpaceAlias
#    echo "$sS" >| grep "^${_bashlyk_sWSpaceAlias}$"                            #? true
#    _ =sWSpaceAlias
#    echo "$sWSpaceAlias" >| grep "^${_bashlyk_sWSpaceAlias}$"                  #? true
#    _ sWSpaceAlias >| grep "^${_bashlyk_sWSpaceAlias}$"                        #? true
#    _ sWSpaceAlias _-_
#    _ sWSpaceAlias >| grep "^_-_$"                                             #? true
#    _ sWSpaceAlias ""
#    _ sWSpaceAlias >| grep "^$"                                                #? true
#    _ sWSpaceAlias "two words"
#    _ sWSpaceAlias >| grep "^two words$"                                       #? true
#    _ sWSpaceAlias "$sWSpaceAlias"
#    _ sWSpaceAlias
#    _ sLastError[$pid] "_ sLastError settings test"                            #? true
#    _ sLastError[$pid] >| grep "^_ sLastError settings test$"                  #? true
#  SOURCE
_(){

  udfOn MissingArgument $1 || return $?

  if (( $# > 1 )); then

    ## TODO check for valid required
    eval "_bashlyk_${1##*=}=\"$2\""

  else

    case "$1" in

      *=*)

        if [[ -n "${1%=*}" ]]; then

          udfOn InvalidVariable ${1%=*} || return $?
          eval "export ${1%=*}=\$$( udfPrepareByType "_bashlyk_${1##*=}" )"

        else

          udfOn InvalidVariable $( udfPrepareByType "${1##*=}" ) || return $?
          eval "export $( udfPrepareByType "${1##*=}" )=\$$( udfPrepareByType "_bashlyk_${1##*=}" )"

        fi

      ;;

        *) eval "echo \$$( udfPrepareByType "_bashlyk_${1}" )";;

    esac

  fi

  return 0

}
#******
#****f* libstd/udfGetMd5
#  SYNOPSIS
#    udfGetMd5 [-]|--file <filename>|<args>
#  DESCRIPTION
#   Получить дайджест MD5 указанных данных
#  INPUTS
#    "-"  - использовать поток данных "input"
#    --file <filename> - использовать в качестве данных указанный файл
#    <args> - использовать строку аргументов
#  OUTPUT
#    Дайджест MD5
#  EXAMPLE
#    local fn
#    udfMakeTemp fn
#    echo test > $fn                                                            #-
#    echo test | udfGetMd5 -      >| grep -w 'd8e8fca2dc0f896fd7cb4cb0031ba249' #? true
#    udfGetMd5 --file "$fn"       >| grep -w 'd8e8fca2dc0f896fd7cb4cb0031ba249' #? true
#    udfGetMd5 test               >| grep -w 'd8e8fca2dc0f896fd7cb4cb0031ba249' #? true
#  SOURCE
udfGetMd5() {

  local s

  case "$1" in

         -)                s="$( exec -c md5sum - < <( udfCat ) )";;
    --file) [[ -f $2 ]] && s="$( exec -c md5sum "$2" )"           ;;
         *) [[    $* ]] && s="$( exec -c md5sum - <<< "$*" )"     ;;

  esac

  [[ $s ]] && echo ${s%% *} || return $_bashlyk_iErrorEmptyResult

}
#******
#****f* libstd/udfGetPathMd5
#  SYNOPSIS
#    udfGetPathMd5 <path>
#  DESCRIPTION
#   Получить дайджест MD5 всех нескрытых файлов в каталоге <path>
#  INPUTS
#    <path>  - начальный каталог
#  OUTPUT
#    Список MD5-сумм и имён нескрытых файлов в каталоге <path> рекурсивно
#  ERRORS
#    MissingArgument - аргумент не задан
#    NoSuchFileOrDir - путь не доступен
#    NotPermitted    - нет прав
#  EXAMPLE
#    local path=$(udfMakeTemp type=dir)
#    echo "digest test 1" > ${path}/testfile1                                   #-
#    echo "digest test 2" > ${path}/testfile2                                   #-
#    echo "digest test 3" > ${path}/testfile3                                   #-
#    udfAddFO2Clean ${path}/testfile1
#    udfAddFO2Clean ${path}/testfile2
#    udfAddFO2Clean ${path}/testfile3
#    udfAddFO2Clean ${path}
#    udfGetPathMd5 $path >| grep ^[[:xdigit:]]*.*testfile.$                     #? true
#    udfGetPathMd5                                                              #? ${_bashlyk_iErrorMissingArgument}
#    udfGetPathMd5 /notexist/path                                               #? ${_bashlyk_iErrorNoSuchFileOrDir}
#  SOURCE
udfGetPathMd5() {

  local pathSrc="$( exec -c pwd )" pathDst s IFS=$' \t\n'

  udfOn NoSuchFileOrDir "$@" || return $?

  cd "$@" 2>/dev/null || eval $( udfOnError retwarn NotPermitted '$@' )

  pathDst="$( exec -c pwd )"

  while read s; do

    [[ -d $s ]] && udfGetPathMd5 $s

    md5sum "${pathDst}/${s}" 2>/dev/null

  done< <(eval "ls -1drt * 2>/dev/null")

  cd "$pathSrc" || eval $( udfOnError retwarn NotPermitted '$@' )

  return 0

}
#******
#****f* libstd/udfXml
#  SYNOPSIS
#    udfXml tag [property] data
#  DESCRIPTION
#    Generate XML code to stdout
#  INPUTS
#    tag      - XML tag name (without <>)
#    property - XML tag property
#    data     - XML tag content
#  OUTPUT
#    Show compiled XML code
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    local sTag='date TO="+0400" TZ="MSK"' sContent='Mon, 22 Apr 2013 15:55:50'
#    local sXml='<date TO="+0400" TZ="MSK">Mon, 22 Apr 2013 15:55:50</date>'
#    udfXml "$sTag" "$sContent" >| grep "^${sXml}$"                             #? true
#  SOURCE
udfXml() {

  udfOn MissingArgument $1 || return $?

  local IFS=$' \t\n' s

  s=($1)
  shift
  echo "<${s[*]}>${*}</${s[0]}>"

}
#******
#****f* libstd/udfGetTimeInSec
#  SYNOPSIS
#    udfGetTimeInSec [-v <var>] <number>[sec|min|hour|...]
#  DESCRIPTION
#    get a time value in the seconds from a string in the human-readable format
#  OPTIONS
#    -v <var>                    - set the result to valid variable <var>
#  ARGUMENTS
#    <numbers>[sec,min,hour,...] - human-readable string of date&time
#  ERRORS
#    InvalidArgument - invalid or missing arguments, number with a time suffix
#                      expected
#    EmptyResult     - no result
#  EXAMPLE
#    local v s=${RANDOM:0:2} #-
#    udfGetTimeInSec                                                            #? $_bashlyk_iErrorInvalidArgument
#    udfGetTimeInSec SeventenFourSec                                            #? $_bashlyk_iErrorInvalidArgument
#    udfGetTimeInSec 59seconds >| grep -w 59                                    #? true
#    udfGetTimeInSec -v v ${s}minutes                                           #? true
#    echo $v >| grep -w $(( s * 60 ))                                           #? true
#    udfGetTimeInSec -v 123s                                                    #? $_bashlyk_iErrorInvalidVariable
#    udfGetTimeInSec -v -v                                                      #? $_bashlyk_iErrorInvalidVariable
#    udfGetTimeInSec -v v -v v                                                  #? $_bashlyk_iErrorInvalidArgument
#    udfGetTimeInSec $RANDOM                                                    #? true
#  SOURCE
udfGetTimeInSec() {

  if [[ "$1" == "-v" ]]; then

    udfIsValidVariable "$2" || eval $( udfOnError InvalidVariable "$2" )

    [[ "$3" == "-v" ]] \
      && eval $( udfOnError InvalidArgument "$3 - number with time suffix expected" )

    eval 'export $2="$( udfGetTimeInSec $3 )"'

    [[ ${!2} ]] || eval 'export $2="$( udfGetTimeInSec $4 )"'
    [[ ${!2} ]] || eval $( udfOnError EmptyResult "$2" )

    return $?

  fi

  local i=${1%%[[:alpha:]]*}

  udfIsNumber $i || eval $( udfOnError InvalidArgument "$i - number expected" )

  case ${1##*[[:digit:]]} in

    seconds|second|sec|s|'') echo $i;;
       minutes|minute|min|m) echo $(( i*60 ));;
            hours|hour|hr|h) echo $(( i*3600 ));;
                 days|day|d) echo $(( i*3600*24 ));;
               weeks|week|w) echo $(( i*3600*24*7 ));;
           months|month|mon) echo $(( i*3600*24*30 ));;
               years|year|y) echo $(( i*3600*24*365 ));;
                          *) echo ""
                             eval $( udfOnError InvalidArgument "$1 - number with time suffix expected" )
                          ;;

  esac

  return $?

}
#******
#****f* libstd/udfGetFreeFD
#  SYNOPSIS
#    udfGetFreeFD
#  DESCRIPTION
#    get unused filedescriptor
#  OUTPUT
#    show given filedescriptor
#  TODO
#    race possible
#  EXAMPLE
#    udfGetFreeFD | grep -P "^\d+$"                                             #? true
#  SOURCE
udfGetFreeFD() {

  local i=0 iMax=$( ulimit -n )

  : ${iMax:=255}

  for (( i = 3; i < iMax; i++ )); do

    if [[ -e /proc/$$/fd/$i ]]; then

      continue

    else

      echo $i
      break

    fi

  done

}
#******
#****f* libstd/udfIsHash
#  SYNOPSIS
#    udfIsHash <variable>
#  DESCRIPTION
#    treated a variable as global associative array
#  ARGUMENTS
#    <variable> - variable name
#  RETURN VALUE
#    InvalidVariable - argument is not valid variable name
#    InvalidHash     - argument is not hash variable
#    Success         - argument is name of the associative array
#  EXAMPLE
#    declare -Ag -- hh='()' s5
#    udfIsHash 5s                                                               #? $_bashlyk_iErrorInvalidVariable
#    udfIsHash s5                                                               #? $_bashlyk_iErrorInvalidHash
#    udfIsHash hh                                                               #? true
#  SOURCE
udfIsHash() {

  udfOn InvalidVariable $1 || return $?

  [[ $( declare -pA $1 2>/dev/null ) =~ ^declare.*-A ]] \
    && return 0 || return $( _ iErrorInvalidHash )

}
#******
#****f* libstd/udfTrim
#  SYNOPSIS
#    udfTrim <arg>
#  DESCRIPTION
#    remove leading and trailing spaces
#  ARGUMENTS
#    <arg> - input data
#  OUTPUT
#    show input without leading and trailing spaces
#  EXAMPLE
#    local s=" a  b c  "
#    udfTrim "$s" >| grep "^a  b c$"                                            #? true
#    udfTrim  $s  >| grep "^a b c$"                                             #? true
#    udfTrim      >| grep ^$                                                    #? true
#    udfTrim '  ' >| grep ^$                                                    #? true
#  SOURCE
udfTrim() {

  local s="$*"

  [[ $s =~ ^\+$ ]] && s+=" "

  echo "$( expr "$s" : "^\ *\(.*[^ ]\)\ *$" )"

}
#******
#****f* libstd/udfCat
#  SYNOPSIS
#    udfCat
#  DESCRIPTION
#    show input by line
#  OUTPUT
#    show input by line
#  EXAMPLE
#    local s fn
#    udfMakeTemp -v fn
#    for s in $( seq 0 12 ); do printf -- '\t%s\n' "$RANDOM"; done > $fn        #-
#    udfCat < $fn | grep -E '^[[:space:]][0-9]{1,5}$'                           #? true
#  SOURCE
udfCat() { while IFS= read -t 32 || [[ $REPLY ]]; do echo "$REPLY"; done; }
#******
