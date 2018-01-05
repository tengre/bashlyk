#
# $Id: libold.sh 783 2018-01-05 21:24:49+04:00 toor $
#
#****h* BASHLYK/libold
#  DESCRIPTION
#    Deprecated functions
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libold/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBOLD provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBOLD" ] && return 0 || _BASHLYK_LIBOLD=1
[ -n "$_BASHLYK" ] || . bashlyk || eval '                                      \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* libold/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
#******
#****G* libold/Global variables
#  DESCRIPTION
#    global variables of the library
#  SOURCE
#: ${_bashlyk_bSetOptions:=}
#: ${_bashlyk_csvOptions2Ini:=}
: ${TMPDIR:=/tmp}
: ${HOSTNAME:=$( exec -c hostname 2>/dev/null )}
: ${_bashlyk_sWSpaceAlias:=$( printf -- "\u00a0" )}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_ini_void_autoKey_}
: ${_bashlyk_reMetaRules:='34=":40=(:41=):59=;:91=[:92=\\:93=]:61=='}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${HOSTNAME:=localhost}
: ${_bashlyk_sLogin:=$( exec -c logname 2>/dev/null )}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${0##*/}"}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}
: ${_bashlyk_fnLog:="${_bashlyk_pathLog}/${_bashlyk_s0}.log"}
: ${_bashlyk_bUseSyslog:=0}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_sCond4Log:=redirect}

declare -rg _bashlyk_externals_old="                                           \
                                                                               \
    awk cat chgrp chmod chown cut date dirname expr flock getopt grep logger   \
    mawk md5sum mkdir mkfifo mktemp mv pgrep pwd rm rmdir sed sleep sort sudo  \
    tempfile touch tr tty uniq xargs notify-send|kdialog|zenity|xmessage       \
                                                                               \
"
declare -rg _bashlyk_exports_old="                                             \
                                                                               \
    ERR::{__add_throw_to_command,__convert_try_to_func,exception.message}      \
    udfAdd{FD,File,FO,FObj,Job,Path,Pid}2Clean                                 \
    _ _ARGUMENTS _fnLog _gete _getv _pathDat _s0 _set udfAlias2WSpace          \
    udfBashlykUnquote udfCat udfCheck4LogUse udfCheckCsv udfCheckStarted       \
    udfCleanQueue udfCommandNotFound udfCsvHash2Raw udfCsvKeys udfCsvKeys2Var  \
    udfCsvOrder udfCsvOrder2Var udfDateR udfDebug udfEcho udfEmptyArgument     \
    udfEmptyOrMissingArgument udfEmptyResult udfEmptyVariable                  \
    udfExcludePairFromHash udfExitIfAlreadyStarted udfFinally udfGetConfig     \
    udfGetCsvSection udfGetCsvSection2Var udfGetFreeFD udfGetIni udfGetIni2Var \
    udfGetIniSection udfGetIniSection2Var udfGetMd5 udfGetOpt udfGetOptHash    \
    udfGetPathMd5 udfGetTimeInSec udfGetXSessionProperties udfIni udfIni2Csv   \
    udfIni2CsvVar udfIniChange udfIniGroup2Csv udfIniGroup2CsvVar              \
    udfIniGroupSection2Csv udfIniGroupSection2CsvVar udfIniSection2Csv         \
    udfIniSection2CsvVar udfIniWrite udfInvalidVariable udfIsHash              \
    udfIsInteract udfIsNumber udfIsTerminal udfIsValidVariable                 \
    udfLocalVarFromCSV udfLog udfLogger udfMail udfMakeTemp udfMakeTempV       \
    udfMessage udfMissingArgument udfNoSuchFileOrDir udfNotify2X               \
    udfNotifyCommand udfOn udfOnCommandNotFound udfOnEmptyOrMissingArgument    \
    udfOnEmptyVariable udfOnError udfOnError1 udfOnError2 udfOnTrap            \
    udfOptions2Ini udfPrepare2Exec udfPrepareByType udfQuoteIfNeeded           \
    udfReadIniSection udfReadIniSection2Var udfSelectEnumFromCsvHash           \
    udfSerialize udfSetConfig udfSetLastError udfSetLog udfSetLogSocket        \
    udfSetOptHash udfSetPid udfSetVarFromCsv udfSetVarFromIni udfShellExec     \
    udfShowVariable udfStackTrace udfStopProcess udfThrow                      \
    udfThrowOnCommandNotFound udfThrowOnEmptyOrMissingArgument                 \
    udfThrowOnEmptyVariable udfTimeStamp udfTrim udfUptime udfWarn             \
    udfWarnOnCommandNotFound udfWarnOnEmptyOrMissingArgument                   \
    udfWarnOnEmptyVariable udfWSpace2Alias udfXml                              \
"
#******
#****f* libold/udfGetIniSection2Var
#  SYNOPSIS
#    udfGetIniSection2Var <varname> <file> [<section>]
#  DESCRIPTION
#    set <varname> by output of a udfGetIniSection
#  INPUTS
#    <file>    - source INI configuration
#    <section> - INI configuration section name, default - unnamed
#    <varname> - valid variable name (without '$') for result
#  ERRORS
#    InvalidVariable - invalid variable name <varname>
#    MissingArgument - no arguments
#  EXAMPLE
#    #see udfGetIniSection
#  SOURCE
udfGetIniSection2Var() {

  udfOn InvalidVariable $1 || return
  udfOn NoSuchFileOrDir $2 || return

  eval 'export $1="$( udfGetIniSection "$2" $3 )"'

  return 0

}
#******
#****f* libold/udfReadIniSection2Var
#  SYNOPSIS
#    udfReadIniSection2Var <varname> <file> [<section>]
#  DESCRIPTION
#    set <varname> by output of a udfReadIniSection
#  INPUTS
#    <file>    - source INI configuration
#    <section> - INI configuration section name, default - unnamed
#    <varname> - valid variable name (without '$') for result
#  ERRORS
#    InvalidVariable - invalid variable name <varname>
#    MissingArgument - no arguments
#  EXAMPLE
#    #see udfReadIniSection
#  SOURCE
udfReadIniSection2Var() {

  udfOn InvalidVariable $1 || return $?
  udfOn NoSuchFileOrDir $2 || return $?

  eval 'export $1="$( udfReadIniSection "$2" $3 )"'

  return 0

}
#******
#****f* libold/udfCsvOrder2Var
#  SYNOPSIS
#    udfCsvOrder2Var <varname> <csv;>
#  DESCRIPTION
#    set <varname> by output of a udfCsvOrder
#  INPUTS
#    <csv;>    - CSV string with fields like "key=value", splitted by ";"
#    <varname> - valid variable name (without '$') for result
#  ERRORS
#    InvalidVariable - invalid variable name <varname>
#    MissingArgument - no arguments
#  EXAMPLE
#    #see udfCsvOrder
#  SOURCE
udfCsvOrder2Var() {

  udfOn InvalidVariable $1 || return $?
  udfOn MissingArgument $2 || return $?

  eval 'export $1="$( udfCsvOrder "$2" )"'

  return 0

}
#******
#****f* libold/udfCsvKeys2Var
#  SYNOPSIS
#    udfCsvKeys2Var <varname> <csv;>
#  DESCRIPTION
#    set <varname> by output of a udfCsvKeys
#  INPUTS
#    <csv;>    - CSV string with fields like "key=value", splitted by ";"
#    <varname> - valid variable name (without '$') for result
#  ERRORS
#    InvalidVariable - invalid variable name <varname>
#    MissingArgument - no arguments
#  EXAMPLE
#    #see udfCsvKeys
#  SOURCE
udfCsvKeys2Var() {

  udfOn InvalidVariable $1 || return $?
  udfOn MissingArgument $2 || return $?

  eval 'export $1="$( udfCsvKeys "$2" )"'

  return 0

}
#******
#****f* libold/udfGetIni2Var
#  SYNOPSIS
#    udfGetIni2Var <varname> <file> [<sections>] ...
#  DESCRIPTION
#    set <varname> by output of a udfGetIni
#  INPUTS
#    <varname>  - valid variable name (without '$') for result
#                 ( "[section];<key>=<value>;..." )
#    <file>     - source INI configuration
#    <sections> - INI configuration section name list
#  ERRORS
#    InvalidVariable - invalid variable name <varname>
#    MissingArgument - no arguments
#  EXAMPLE
#    #see udfGetIni
#  SOURCE
udfGetIni2Var() {

  udfOn InvalidVariable $1 || return $?
  udfOn NoSuchFileOrDir $2 || return $?

  local bashlyk_GetIni2Var_s="$1"

  shift
  eval 'export $bashlyk_GetIni2Var_s="$( udfGetIni $* )"'

  return 0

}
#******
#****f* libold/udfGetCsvSection2Var
#  SYNOPSIS
#    udfGetCsvSection2Var <varname> <csv> [<tag>]
#  DESCRIPTION
#    set <varname> by output of a udfGetCsvSection
#  INPUTS
#    tag     - section name
#    csv     - строка сериализации данных ini-файлов
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде
#              CSV; строки формата "ключ=значение;" будет помещен в
#              соответствующую переменную.
#  ERRORS
#    InvalidVariable - аргумент не является валидным идентификатором переменной
#    MissingArgument - отсутствует аргумент
#  EXAMPLE
#    local csv='[];a=b;c=d e;[s1];a=f;c=g h;[s2];a=k;c=l m;' csvResult
#    udfGetCsvSection2Var csvResult "$csv"
#    echo $csvResult >| grep '^a=b;c=d e;$'                                     #? true
#    udfGetCsvSection2Var csvResult "$csv" s1
#    echo $csvResult >| grep '^a=f;c=g h;$'                                     #? true
#    udfGetCsvSection2Var csvResult "$csv" s2
#    echo $csvResult >| grep '^a=k;c=l m;$'                                     #? true
#  SOURCE
udfGetCsvSection2Var() {

  udfOn InvalidVariable $1 || return $?
  udfOn MissingArgument $2 || return $?

  eval 'export $1="$( udfGetCsvSection "$2" $3 )"'

  return 0

}
#******
#****f* libold/udfIniSection2CsvVar
#  SYNOPSIS
#    udfIniSection2CsvVar <varname> <file> [<section>]
#  DESCRIPTION
#    поместить результат вызова udfIniSection2Csv в переменную <varname>
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента
#              считываются данные до первого заголовка секции [<...>] данных
#              или до конца конфигурационного файла, если секций нет
#    varname - идентификатор переменной (без "$"). При его наличии результат
#              будет помещен в соответствующую переменную. При отсутствии такого
#              идентификатора результат будет выдан на стандартный вывод
#  ERRORS
#    InvalidVariable - аргумент <varname> не является валидным идентификатором
#                      переменной
#    MissingArgument - аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    #пример приведен в описании udfIniGroupSection2Csv
#  SOURCE
udfIniSection2CsvVar() {

  udfOn InvalidVariable $1 || return $?
  udfOn NoSuchFileOrDir $2 || return $?

  eval 'export $1="$( udfIniSection2Csv "$2" $3 )"'

  return 0

}
#******
#****f* libold/udfIniGroupSection2CsvVar
#  SYNOPSIS
#    udfIniGroupSection2CsvVar <varname> <file> [<section>]
#  DESCRIPTION
#    поместить результат вызова udfIniGroupSection2Csv в переменную <varname>
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента
#              считываются данные до первого заголовка секции [<...>] данных или
#              до конца конфигурационного файла, если секций нет
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде
#              разделенной символом ";" CSV-строки, в полях которого содержатся
#              конфигурационные данные в формате "<key>=<value>;..." будет
#              помещён в соответствующую переменную
#  ERRORS
#    InvalidVariable - аргумент <varname> не является валидным идентификатором
#                      переменной
#    MissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfIniGroupSection2Csv
#  SOURCE
udfIniGroupSection2CsvVar() {

  udfOn InvalidVariable $1 || return $?
  udfOn MissingArgument $2 || return $?

  eval 'export $1="$( udfIniGroupSection2Csv "$2" $3 )"'

  return 0

}
#******
#****f* libold/udfIni2CsvVar
#  SYNOPSIS
#    udfIni2CsvVar <varname> <file>
#  DESCRIPTION
#    поместить результат вызова udfIni2Csv в переменную <varname>
#  INPUTS
#    varname - валидный идентификатор переменной (без "$ "). Результат в  виде
#              CSV; строки формата "[секция];ключ=значение;" будет помещен в
#              соответствующую переменную.
#    file    - имя файла конфигурации
#  ERRORS
#    InvalidVariable - аргумент <varname> не является валидным идентификатором
#                      переменной
#    MissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfIni2Csv
#  SOURCE
udfIni2CsvVar() {

  udfOn InvalidVariable $1 || return $?
  udfOn MissingArgument $2 || return $?

  eval 'export $1="$( udfIni2Csv "$2" )"'

  return 0

}
#******
#****f* libold/udfIniGroup2CsvVar
#  SYNOPSIS
#    udfIniGroup2CsvVar <varname> <file>
#  DESCRIPTION
#    поместить результат вызова udfIniGroup2Csv в переменную <varname>
#  INPUTS
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде
#              CSV; строки формата "[секция];ключ=значение;" будет помещен в
#              соответствующую переменную.
#    file    - имя файла конфигурации
#  ERRORS
#    InvalidVariable - аргумент <varname> не является валидным идентификатором
#                      переменной
#    MissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfIniGroup2Csv
#  SOURCE
udfIniGroup2CsvVar() {

  udfOn InvalidVariable $1 || return $?
  udfOn MissingArgument $2 || return $?

  eval 'export $1="$( udfIniGroup2Csv "$2" )"'

  return 0

}
#******
#****f* libold/_ARGUMENTS
#  SYNOPSIS
#    _ARGUMENTS [args]
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_sArg -
#    командная строка сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  INPUTS
#    args - новая командная строка
#  OUTPUT
#    Вывод значения переменной $_bashlyk_sArg
#  EXAMPLE
#    local ARGUMENTS=$(_ARGUMENTS)
#    _ARGUMENTS >| grep "^${_bashlyk_sArg}$"                                    #? true
#    _ARGUMENTS "test"
#    _ARGUMENTS >| grep -w "^test$"                                             #? true
#    _ARGUMENTS $ARGUMENTS
#  SOURCE
_ARGUMENTS() {

 [[ $1 ]] && _bashlyk_sArg="$*" || echo ${_bashlyk_sArg}

}
#******
#****f* libold/_gete
#  SYNOPSIS
#    _gete <subname>
#  DESCRIPTION
#    Вывести значение глобальной переменной $_bashlyk_<subname>
#  INPUTS
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    _gete sWSpaceAlias >| grep "^${_bashlyk_sWSpaceAlias}$"                    #? true
#  SOURCE
_gete() {

  udfOn MissingArgument $1 || return $?

  local IFS=$' \t\n'

  eval "echo \$_bashlyk_${1}"

}
#******
#****f* libold/_getv
#  SYNOPSIS
#    _getv <subname> [<get>]
#  DESCRIPTION
#    Получить (get) значение глобальной переменной $_bashlyk_<subname> в
#    (локальную) переменную
#  INPUTS
#    <get>     - переменная для приема значения (get) ${_bashlyk_<subname>},
#                может быть опущена, в этом случае приемником становится
#                переменная <subname>
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#  ERRORS
#    MissingArgument - аргумент не задан
#    InvalidVariable - не валидный идентификатор
#  EXAMPLE
#    local sS sWSpaceAlias
#    _getv sWSpaceAlias sS
#    echo "$sS" >| grep "^${_bashlyk_sWSpaceAlias}$"                            #? true
#    _getv sWSpaceAlias
#    echo "$sWSpaceAlias" >| grep "^${_bashlyk_sWSpaceAlias}$"                  #? true
#  SOURCE
_getv() {

  udfOn MissingArgument $1 || return $?

  local IFS=$' \t\n'

  if [[ $2 ]]; then

    udfIsValidVariable $2 || return $?
    eval "export $2=\$_bashlyk_${1}"

  else

    udfIsValidVariable $1 || return $?
    eval "export $1=\$_bashlyk_${1}"

  fi

  return 0

}
#******
#****f* libold/_set
#  SYNOPSIS
#    _set <subname> [<value>]
#  DESCRIPTION
#    установить (set) значение глобальной переменной $_bashlyk_<subname>
#  INPUTS
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#    <value>   - новое значение, в случае отсутствия - пустая строка
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    local sWSpaceAlias=$(_ sWSpaceAlias)
#    _set sWSpaceAlias _-_
#    _ sWSpaceAlias >| grep "^_-_$"                                             #? true
#    _set sWSpaceAlias $sWSpaceAlias
#  SOURCE
_set() {

  udfOn MissingArgument $1 || return $?

  local IFS=$' \t\n'

  [[ $1 ]] || eval $( udfOnError return MissingArgument )

  eval "_bashlyk_$1=$2"

}
#******
#****f* libold/_s0
#  SYNOPSIS
#    _s0
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_s0 -
#    короткое имя сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  OUTPUT
#    Вывод значения переменной $_bashlyk_s0
#  EXAMPLE
#    local s0=$(_s0)
#    _s0 >| grep -w "^${_bashlyk_s0}$"                                          #? true
#    _s0 "test"
#    _s0 >| grep -w "^test$"                                                    #? true
#    _s0 $s0
#  SOURCE
_s0() {

 [[ $1 ]] && _bashlyk_s0="$*" || echo ${_bashlyk_s0}

}
#******
#****f* libold/_pathDat
#  SYNOPSIS
#    _pathDat
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_pathDat -
#    полное имя каталога данных сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  OUTPUT
#    Вывод значения переменной $_bashlyk_pathDat
#  EXAMPLE
#    local pathDat=$(_pathDat)
#    _pathDat >| grep -w "^${_bashlyk_pathDat}$"                                #? true
#    _pathDat "${TMPDIR}/testdat.$$"
#    _pathDat >| grep -w "^${TMPDIR}/testdat.${$}$"                             #? true
#    rmdir $(_pathDat)                                                          #? true
#    _pathDat $pathDat
#  SOURCE
_pathDat() {

  if [[ $1 ]]; then

    _bashlyk_pathDat="$*"
    ## TODO error handling
    mkdir -p $_bashlyk_pathDat

  else

    echo ${_bashlyk_pathDat}

  fi

}
#******
#****f* libold/_fnLog
#  SYNOPSIS
#    _fnLog
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_fnLog -
#    полное имя лог-файла
#  OUTPUT
#    Вывод значения переменной $_bashlyk_fnLog
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)
#    rm -f $fnLog
#    _fnLog $fnLog                                                              #? true
#    ls -l $fnLog                                                               #? true
#    rm -f $fnLog
#  SOURCE
_fnLog() {

  [[ $1 ]] && udfSetLog "$1" || _ fnLog

}
#******
#****f* libold/udfCheckCsv
#  SYNOPSIS
#    udfCheckCsv [[-v] <varname>] "<csv>;"
#  DESCRIPTION
#    Bringing the format "key = value" fields of the CSV-line. If the field does
#    not contain a key or key contains a space, then the field receives key
#    species ${_bashlyk_sUnnamedKeyword_}<increment>, and all the contents of
#    the field becomes the value. The result is printed to stdout or assigned to
#    the <var> if the first argument is listed as -v <var> ( -v can be skipped )
#  INPUTS
#    csv;    - CSV-string, separated by ';'
#    Important! Enclose the string in double quotes if it can contain spaces
#    Important! The string must contain the field sign ";"
#    varname - variable identifier (without the "$"). If present the result will
#    be assigned to this variable, otherwise result will be printed to stdout
#  OUTPUT
#    separated by a ";" CSV-string in fields that contain data in the format
#    "<key> = <value>; ..."
#  ERRORS
#    EmptyResult     - empty result
#    MissingArgument - no arguments
#    InvalidArgument - invalid argument
#    InvalidVariable - invalid variable for output assign
#  EXAMPLE
#    local cmd csv re v1 v2
#    cmd=udfCheckCsv
#    csv="a=b;a=c;s=a b c d e;test value"
#    re="^a=b;a=c;s=\"a b c d e\";${_bashlyk_sUnnamedKeyword}0=\"test value\";$"
#    $cmd "$csv" >| grep "$re"                                                  #? true
#    $cmd -v v1 "$csv"                                                          #? true
#    echo $v1 >| grep "$re"                                                     #? true
#    $cmd  v2 "$csv"                                                            #? true
#    echo $v2 >| grep "$re"                                                     #? true
#    $cmd  v2 ""                                                                #? ${_bashlyk_iErrorEmptyResult}
#    echo $v2 >| grep "$re"                                                     #? false
#    $cmd -v invalid+variable "$csv"                                            #? ${_bashlyk_iErrorInvalidVariable}
#    $cmd    invalid+variable "$csv"                                            #? ${_bashlyk_iErrorInvalidVariable}
#    $cmd invalid+variable                                                      #? ${_bashlyk_iErrorInvalidArgument}
#    $cmd _valid_variable_                                                      #? ${_bashlyk_iErrorInvalidArgument}
#    $cmd 'csv data;' | grep "^${_bashlyk_sUnnamedKeyword}0=.csv.data.;$"       #? true
#    $cmd                                                                       #? ${_bashlyk_iErrorMissingArgument}
#  SOURCE
udfCheckCsv() {

  if (( $# > 1 )); then

    [[ "$1" == "-v" ]] && shift

    udfIsValidVariable $1 || eval $( udfOnError return InvalidVariable "$1" )

    eval 'export $1="$( shift; udfCheckCsv "$1" )"'

    [[ ${!1} ]] || eval $( udfOnError return EmptyResult "$1" )

    return 0

  fi

  udfOn MissingArgument $1 || return $?

  [[ $1 =~ \; ]] || return $( _ iErrorInvalidArgument )

  local csv i IFS k s v

  IFS=';'
  i=0
  csv=''

  for s in $1; do

    s=${s/\[*\][;]/}
    s=${s//[\'\"]/}

    k="$( echo ${s%%=*} )"
    v="$( echo ${s#*=} )"

    [[ -n "$k" ]] || continue

    if [[ "$k" == "$v" || "$k" =~ ^.*[[:space:]]+.*$ ]]; then

      k=${_bashlyk_sUnnamedKeyword}${i}
      i=$((i+1))

    fi

    IFS=' ' csv+="$k=$( udfQuoteIfNeeded $v );"

  done

  IFS=$' \t\n'

  echo "$csv"

  [[ $csv ]] && return 0 || return $( _ iErrorEmptyResult )

}
#******
#****f* libold/udfGetIniSection
#  SYNOPSIS
#    udfGetIniSection <file> [<section>]
#  DESCRIPTION
#    Получить секцию конфигурационных данных <section> из <file> и, при наличии,
#    от "родительских" к нему файлов. Например, если <file> это "a.b.c.ini", то
#    "родительскими" будут считаться файлы "ini", "c.ini" и "b.c.ini" если есть
#    в том же каталоге. Данные наследуются и перекрываются от "старшего" файла к
#    младшему.
#    Поиск конфигурационных файлов выполняется по следующим критериям:
#     1. Если имя файла <file> содержит неполный путь, то в начале проверяется
#     текущий каталог, затем каталог конфигураций по умолчанию
#     2. Если имя файла содержит полный путь, то рабочим каталогом является этот
#     полный путь
#     3. Последняя попытка - найти файл в каталоге /etc
#    Важно: имя <file> не должно начинаться с точки и им заканчиваться!
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента
#              считываются данные до первого заголовка секции [<...>] данных или
#              до конца конфигурационного файла, если секций нет
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся
#              конфигурационные данные в формате "<key>=<value>;..."
#  ERRORS
#   NoSuchFileOrDir - файл конфигурации не найден
#   MissingArgument - аргумент не задан
#   EmptyResult     - результат отсутствует
#  EXAMPLE
#    local csv='b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini
#    echo "simple line" | tee -a $ini
#    printf "$fmt" sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee $iniChild
#    udfGetIniSection $iniChild test >| grep "^${csv}$"                         #? true
#    rm -f $iniChild $ini
#    udfGetIniSection $iniChild test                                            #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO тест пустой результат
#  SOURCE
udfGetIniSection() {

  udfOn MissingArgument $1 || return $?

  local a csv fn path s sTag IFS=$' \t\n' GLOBIGNORE

  path="$_bashlyk_pathIni"

  [[ "$1" == "${1##*/}" && -f "${path}/$1" ]] || path=
  [[ "$1" == "${1##*/}" && -f "$1" ]] && path=$( exec -c pwd )
  [[ "$1" != "${1##*/}" && -f "$1" ]] && path=${1%/*}
  [[ $2 ]] && sTag="$2"

  if [[ ! $path ]]; then

    [[ -f "/etc/${_bashlyk_pathPrefix}/$1" ]] \
      && path="/etc/${_bashlyk_pathPrefix}" \
      || eval $( udfOnError return NoSuchFileOrDir '/etc/${_bashlyk_pathPrefix}/$1' )

  fi

  a=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

  GLOBIGNORE="*:?"

  for s in $a; do

    [[ $s             ]] || continue
    [[ $fn            ]] && fn="${s}.${fn}" || fn="$s"
    [[ -s "$path/$fn" ]] && csv+=";$( udfIniSection2Csv "$path/$fn" "$sTag" );"

  done
  unset GLOBIGNORE

  udfCsvOrder "$csv"

  return $?

}
#******
#****f* libold/udfCsvOrder
#  SYNOPSIS
#    udfCsvOrder <csv;>
#  DESCRIPTION
#    упорядочение CSV-строки, которое заключается в удалении устаревших значений
#    пар "<key>=<value>". Более старыми при повторении ключей считаются более
#    левые поля в строке
#  INPUTS
#    csv;    - CSV-строка, разделённая ";", поля которой содержат данные вида
#              "key=value"
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся
#              данные в формате "<key>=<value>;..."
#  ERRORS
#    MissingArgument - аргумент отсутствует
#    EmptyResult     - пустой результат
#  EXAMPLE
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo bar;b=true;iXo=1920;'
#    local csvResult
#    local csvTest='b=true;iXo=1920;iYo=1080;sTxt="foo bar";'
#    udfCsvOrder "$csv" >| grep "^${csvTest}$"                                  #? true
#    udfCsvOrder                                                                #? $_bashlyk_iErrorMissingArgument
#    ## TODO тест пустой результат
#  SOURCE
udfCsvOrder() {

  udfOn MissingArgument $1 || return $?

  local aKeys csv fnExec IFS=$' \t\n'

  csv="$( udfCheckCsv "$1" )"
  aKeys="$( udfCsvKeys "$csv" | tr ' ' '\n' | sort -u | uniq -u | xargs )"
  csv=$( echo -e "${csv/;/\\n}" )
  #
  udfMakeTemp fnExec
  #
  cat <<- _CsvOrder_EOF > $fnExec
	#!/bin/bash
	#
	# . bashlyk
	#
	udfAssembly() {
	  local $aKeys
	#
	  $csv
	#
	  udfShowVariable $aKeys | grep -v '^:' | tr -d '\t' | \
	   sed -e "s/=\(.*[[:space:]]\+.*\)/=\"\1\"/" | tr '\n' ';' | sed -e "s/;;/;/"
	#
	  return 0
	}
	#
	udfAssembly
	_CsvOrder_EOF

  csv="$( . $fnExec 2>/dev/null )"

  rm -f $fnExec

  [[ $csv ]] && echo "$csv" || eval $( udfOnError return EmptyResult )

}
#******
#****f* libold/udfSetVarFromCsv
#  SYNOPSIS
#    udfSetVarFromCsv <csv;> <keys> ...
#  DESCRIPTION
#    Инициализировать переменные <keys> значениями соответствующих ключей пар
#    "key=value" из CSV-строки <csv;>
#  INPUTS
#    csv; - CSV-строка, разделённая ";", поля которой содержат данные вида
#          "key=value"
#    keys - идентификаторы переменных (без "$ "). При их наличии будет
#           произведена инициализация в соответствующие переменные значений
#           совпадающих ключей CSV-строки
#  ERRORS
#    MissingArgument - аргумент(ы) отсутствуют
#  EXAMPLE
#    local b sTxt iXo iYo
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo = bar;b=true;iXo=1920;'
#    local sResult="true:foo = bar:1920:1080"
#    udfSetVarFromCsv "$csv" b sTxt iXo iYo                                     #? true
#    echo "${b}:${sTxt}:${iXo}:${iYo}" | grep "^${sResult}$"                    #? true
#  SOURCE
udfSetVarFromCsv() {

  udfOn MissingArgument $1 || return $?

  local bashlyk_csvInput_KLokRJky bashlyk_csvResult_KLokRJky bashlyk_k_KLokRJky bashlyk_v_KLokRJky IFS=$' \t\n'

  bashlyk_csvInput_KLokRJky=";$(udfCsvOrder "$1");"
  shift

  for bashlyk_k_KLokRJky in $*; do
    #bashlyk_csvResult_KLokRJky=$(echo $bashlyk_csvInput_KLokRJky | grep -Po ";$bashlyk_k_KLokRJky=.*?;" | tr -d ';')
    bashlyk_v_KLokRJky="$(echo "${bashlyk_csvInput_KLokRJky#*;$bashlyk_k_KLokRJky=}" | cut -f 1 -d ';')"
    if [[ -n "$bashlyk_v_KLokRJky" ]]; then

      eval "$bashlyk_k_KLokRJky=$bashlyk_v_KLokRJky"

    fi

  done

  return 0

}
#******
#****f* libold/udfSetVarFromIni
#  SYNOPSIS
#    udfSetVarFromIni <file> <section> <keys> ...
#  DESCRIPTION
#    Инициализировать переменнные <keys> значениями соответствующих ключей пар
#    "key=value" секции <section> ini файла <file> (и всех его родительских
#    ini-файлов, см. описание udfGetIniSection)
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента
#              считываются данные до первого заголовка секции [<...>] данных или
#              до конца конфигурационного файла, если секций нет
#    keys    - идентификаторы переменных (без "$ "). При их наличии будет
#              произведена инициализация в соответствующие переменные значений
#              совпадающих ключей CSV-строки
#  ERRORS
#    MissingArgument - аргумент(ы) отсутствуют
#  EXAMPLE
#    local sResult='true:foo bar:1024:768'
#    local sTxt b iXo iYo ini
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" sTxt "foo bar" b true iXo 1024 iYo 768 | tee $ini
#    udfSetVarFromIni $ini test sTxt b iXo iYo                                  #? true
#    echo "${b}:${sTxt}:${iXo}:${iYo}" | grep "^${sResult}$"                    #? true
#    rm -f $ini
#  SOURCE
udfSetVarFromIni() {

  udfOn NoSuchFileOrDir $1 || return $?
  udfOn MissingArgument $3 || return $?

  local fn="$1" sSection="$2" IFS=$' \t\n'

  shift 2

  udfSetVarFromCsv ";$(udfIniGroupSection2Csv $fn $sSection);" $*

  return 0

}
#******
#****f* libold/udfCsvKeys
#  SYNOPSIS
#    udfCsvKeys <csv;>
#  DESCRIPTION
#    Получить ключи пар "ключ=значение" из CSV-строки <csv;>
#  INPUTS
#    csv;    - CSV-строка, разделённая ";", поля которой содержат данные вида
#              "key=value"
#  OUTPUT
#              строка ключей
#  ERRORS
#    MissingArgument - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;' sResult
#    udfCsvKeys "$csv" | xargs >| grep "^sTxt b iXo iYo$"                       #? true
#  SOURCE
udfCsvKeys() {

  udfOn MissingArgument $* || return $?

  local csv s IFS=';'

  for s in $*; do

   csv+="${s%%=*} "

  done

  echo "$csv"

}
#******
#****f* libold/udfReadIniSection
#  SYNOPSIS
#    udfReadIniSection <file> [<section>]
#  DESCRIPTION
#    Получить секцию конфигурационных данных <section> из <file> и выдать
#    результат в виде строки CSV, разделенных ';', каждое поле которой содержит
#    данные в формате "<ключ>=<значение>" согласно данных строки секции.
#    В случае если исходная строка не содержит ключ или ключ содержит пробел, то
#    ключом становится выражение "_bashlyk_ini_<секция>_autokey_<инкремент>", а
#    всё содержимое строки - значением - "безымянным", с автоматически
#    формируемым ключом
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента
#              считываются данные до первого заголовка секции [<...>] данных
#              или до конца конфигурационного файла, если секций нет
#  OUTPUT
#              строка CSV;
#  ERRORS
#   NoSuchFileOrDir - аргумент не задан или это не файл конфигурации
#   EmptyResult     - функция не возвращает результат
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_bashlyk_ini_test_autoKey_0="simple line";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult
#    local fmt="[test] \n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini
#    printf "\n\n# comment\nsimple line\n\n" | tee -a $ini
#    udfReadIniSection $ini test >| grep "^${csv}$"                             #? true
#    rm -f $ini
#    udfReadIniSection $ini test                                                #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO тест "пустой результат"
#  SOURCE
udfReadIniSection() {

  udfOn NoSuchFileOrDir $1 || return $?

  local b bOpen csvResult i ini k v s sTag IFS sUnnamedKeyword

  bOpen=false
  i=0
  ini="$1"
  IFS=$' \t\n'
  sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"

  [[ $2 ]] && sTag=$2 || bOpen=true

  while read -t 4 s; do

    [[ "$s" =~ ^#|^$  ]] && continue
    [[ "$s" =~ \[.*\] ]] && b=${s//[\[\]]/} || b=''

    if [[ $b ]]; then

      $bOpen && break
      if [[ $b =~ [[:blank:]]*${sTag}[[:blank:]]* ]]; then

        csvResult=
        bOpen=true

      else

        continue

      fi

    else

      $bOpen || continue
      s="${s//\'/}"
      k="$(echo ${s%%=*} )"
      v="$(echo ${s#*=} )"

      if [[ -z "$k" || "$k" == "$v" || "$k" =~ .*[[:space:]+].* ]]; then

        k=${sUnnamedKeyword}${i}
        i=$((i+1))
        v="$s"

      fi

      csvResult+="$k=$( udfQuoteIfNeeded $v );"

    fi

  done < $ini

  $bOpen || eval $( udfOnError return EmptyResult )
  echo $csvResult

}
#******
#****f* libold/udfIniWrite
#  SYNOPSIS
#    udfIniWrite <file> <csv;>
#  DESCRIPTION
#    сохранить данные из CSV-строки <csv;> в формате [<section>];<key>=<value>;
#    в файл конфигурации <file> c заменой предыдущего содержания. Сохранение
#    производится с форматированием строк, разделитель ";" заменяется на перевод
#    строки
#  INPUTS
#    file - файл конфигурации в стиле "ini". Если он не пустой, то сохраняется
#           в виде копии "<file>.bak"
#    csv; - CSV-строка, разделённая ";", поля которой содержат данные вида
#           "[<section>];<key>=<value>;..."
#  ERRORS
#    NotExistNotCreated - путь не существует и не создан
#    MissingArgument    - аргументы отсутствуют
#  EXAMPLE
#    ## TODO дополнить тесты по второму аргументу
#    local ini csv='[];void=0;[exec]:;"TZ_bashlyk_&#61_UTC date -R --date_bashlyk_&#61_'@12345679'";sUname_bashlyk_&#61_"$_bashlyk_&#40_uname_bashlyk_&#41_";:[exec];[main];sTxt="foo = bar";b=true;iXo=1921;[replace];"after replacing";[unify];*.bak;*.tmp;*~;[acc];;*.bak;*.tmp;;*.bak;*.tmp;*~;'
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    udfIniWrite $ini "$csv"                                                    #? true
#    cat $ini
#    grep -E '^\[unify\]$'                      $ini                            #? true
#    grep -E 'sTxt.*=.*foo.*=.*bar$'            $ini                            #? true
#    grep -E 'b.*=.*true$'                      $ini                            #? true
#    grep -E 'iXo.*=.*1921$'                    $ini                            #? true
#    grep -E 'TZ=UTC date -R --date=@12345679$' $ini                            #? true
#    cat $ini
#    rm -f $ini ${ini}.bak
#  SOURCE
udfIniWrite() {

  udfOn MissingArgument $1 || return $?

  local csv ini="$1" s IFS=$' \t\n'

  [[ $2 ]] && s="$2" || s="$( _ csvOptions2Ini )"

  udfOn MissingArgument $s || return $?

  mkdir -p "${ini%/*}" || eval $( udfOnError NotExistNotCreated "${ini%/*}" )

  [[ -s "$ini" ]] && mv -f "$ini" "${ini}.bak"

  csv="$(echo "$s" | sed -e "s/[;]\+/;/g" -e "s/\(:\?\[\)/;;\1/g" -e "s/\[\]//g" | tr -d '"')"

  IFS=';'

  for s in $csv; do

    k="${s%%=*}"
    v="${s#*=}"
    [[ "$k" == "$v" ]] && echo "$v" || printf -- "\t%s\t=\t%s\n" "$k" "$v"
    ## TODO продумать перенос уничтожения автоключей в udfBashlykUnquote

  done | sed -e "s/\t\?_bashlyk_ini_.*_autoKey_[0-9]\+\t\?=\t\?//g" | udfBashlykUnquote > "$ini"

  return 0

}
#******
#****f* libold/udfIniChange
#  SYNOPSIS
#    udfIniChange <file> <csv;> [<section>]
#  DESCRIPTION
#    Внести изменения в секцию <section> конфигурации <file> согласно данных
#    CSV-строки  <csv;> в формате "<key>=<value>;..."
#  INPUTS
#     file - файл конфигурации формата "*.ini". Если он не пустой, то
#            сохраняется в виде копии "<file>.bak"
#     csv; - CSV-строка, разделённая ";", поля которой содержат данные вида
#            "<key>=<value>;..."
#  section - название секции конфигурации, в которую вносятся изменения. При
#            отсутствии этого аргумента изменения производятся в блоке от
#            начала файла до первого заголовка секции "[<...>]" данных или до
#            конца конфигурационного файла, если секций нет вообще
#  ERRORS
#    MissingArgument - аргументы отсутствуют
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=999;' csvResult
#    local re='b=.*;_b.*auto.*0="= value".*auto.*1=.*key = value".*sTxt=".*ar";'
#    local sTxt="bar foo" b=true iXo=1234 iYo=4321 ini
#    local fmt="[sect%s]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    local md5='a0e4879ea58a1cb5f1889c2de949f485'
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" 1 sTxt foo '' value iXo 720 "non valid key" value | tee $ini
#    echo "simple line" | tee -a $ini
#    printf "$fmt" 2 sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee -a $ini
#    udfIniChange $ini "$csv" sect1                                             #? true
#    udfReadIniSection $ini sect1 >| grep "$re"                                 #? true
#    cat $ini
#    rm -f $ini ${ini}.bak
#  SOURCE
udfIniChange() {

  udfOn NoSuchFileOrDir $1 || return $?
  udfOn MissingArgument $2 || return $?

  local a aKeys aTag csv ini="$1" s csvNew="$2" sTag IFS=$' \t\n'

  [[ $3 ]] && sTag="$3"

  [[ -f "$ini" ]] || touch "$ini"

  aTag="$( exec -c grep -oE '\[.*\]' $ini | tr -d '[]' | sort -u | uniq -u | xargs)"

  [[ $sTag ]] && echo "$aTag" | grep -w "$sTag" >/dev/null || aTag+=" $sTag"

  for s in "" $aTag; do

    csv=$(udfIniSection2Csv $ini $s)

    if [[ "$s" == "$sTag" ]]; then

      csv=$(udfCsvOrder "${csv};${csvNew}")

    fi

    a+=";[${s}];$csv;"

  done

  udfIniWrite $ini "$a"

  return 0

}
#******
#****f* libold/udfIni
#  SYNOPSIS
#    udfIni <file> [<section>]:[<csv;>]|[(=|-|+|!)] ...
#  DESCRIPTION
#    получить данные указанных секций <section> ini-файла <file> (и, возможно,
#    ему родственных, а также, опций командной строки, предварительно полученных
#    функцией udfGetOpt) через инициализацию перечисленных в "csv;"-строке
#    валидных идентификаторов переменных, идентичных соответствующим ключам
#    секции или "сырую" сериализацию всех данных секции в переменную c именем
#    секции
#  INPUTS
#     file    - файл конфигурации в стиле ini
#     section - имена секций. Пустое значение для "безымянной" секции
#     csv;    - список валидных переменных для приема соответствующих значений
#               строк вида "<ключ>=<значение>" секции section, в случае
#               повторения ключей, актуальной становится последняя пара
#     =-+!    - сериализация всех данных секции в переменную c именем секции,
#               модификаторы "=-+!" задают стратегию обработки "сырых" данных:
#     =       - накапливание данные с последующей унификацией
#     -       - замена данных
#     +       - накопление данных
#     !       - замена данных (активная секция)
#
#  ERRORS
#    InvalidVariable - невалидный идентификатор переменной
#    NoSuchFileOrDir - файл конфигурации не найден
#    MissingArgument - аргументы отсутствуют
#  EXAMPLE
#    local sTxt="foo = bar" b=true iXo=1921 iYo=1080 ini iniChild
#    local exec replace unify acc sVoid=void sMain='sTxt;b;iXo'
#    local sRules=":${sVoid} exec:! main:${sMain} replace:- unify:= acc:+"
#
#    ini=$(mktemp --suffix=test.ini || tempfile -s .test.ini)                   #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#
#    cat <<'EOFini' > ${ini}                                                    #-
#    void	=	1                                                       #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt	=	$(date -R)                                              #-
#    b		=	false                                                   #-
#    iXo Xo	=	19                                                      #-
#    iYo	=	80                                                      #-
#    `simple line`                                                              #-
#[replace]                                                                      #-
#    before replacing                                                           #-
#[unify]                                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#[acc]                                                                          #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#                                                                               #-
#    EOFini                                                                     #-
#    cat <<'EOFiniChild' > ${iniChild}                                          #-
#    void	=	0                                                       #-
#    [main]	                                                                #-
#    sTxt	=	foo = bar                                               #-
#    b		=	true                                                    #-
#    iXo	=	1921                                                    #-
#    iYo	=	1080                                                    #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345679'                                          #-
#    sUname="$(uname)"                                                          #-
#:[exec]                                                                        #-
#[replace]                                                                      #-
#	after replacing                                                         #-
#[unify]                                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    *~                                                                         #-
#[acc]                                                                          #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    *~                                                                         #-
#                                                                               #-
#    EOFiniChild                                                                #-
#    udfIni $iniChild $sRules                                                   #? true
#    echo "${sTxt};${b};${iXo}" >| grep -e "^foo = bar;true;1921$"              #? true
#    echo "$exec"     | udfBashlykUnquote >| grep 'TZ=UTC.*@12345679.*$(uname)' #? true
#    echo "$replace" >| grep '"after replacing";$'                              #? true
#    echo "$unify"   >| grep '^\*\.bak;\*\.tmp;\*~;$'                           #? true
#    echo "$acc"     >| grep '^\*\.bak;\*\.tmp;\*\.bak;\*\.tmp;\*~;$'           #? true
#    rm -f $iniChild $ini
#    udfIni $iniChild $sRules                                                   #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO проверка пустых данных (iErrorEmptyOrMissingArgument)
#  SOURCE
udfIni() {

  udfOn MissingArgument $1 || return $?

  local IFS=$' \t\n'
  local bashlyk_udfIni_csv bashlyk_udfIni_s bashlyk_udfIni_sSection
  local bashlyk_udfIni_csvSection bashlyk_udfIni_csvVar bashlyk_udfIni_ini
  local bashlyk_udfIni_cClass

  bashlyk_udfIni_ini="$1"
  shift

  [[ "$_bashlyk_bSetOptions" == 1 ]] && udfOptions2Ini $*
  #
  bashlyk_udfIni_csv=$( udfIniGroup2Csv "$bashlyk_udfIni_ini" )
  bashlyk_udfIni_s=$?
  [[ "$bashlyk_udfIni_s" == 0 ]] || eval $(udfOnError return $bashlyk_udfIni_s)
  #
  for bashlyk_udfIni_s in $*; do

    bashlyk_udfIni_sSection=${bashlyk_udfIni_s%:*}
    bashlyk_udfIni_csvSection=$(udfGetCsvSection "$bashlyk_udfIni_csv" "$bashlyk_udfIni_sSection")

    if [[ "$bashlyk_udfIni_s" == "${bashlyk_udfIni_s%:[=\-+\!]*}" ]]; then

      bashlyk_udfIni_aVar="${bashlyk_udfIni_s#*:}"
      udfSetVarFromCsv "$bashlyk_udfIni_csvSection" ${bashlyk_udfIni_aVar//;/ }

    else

      bashlyk_udfIni_cClass="${bashlyk_udfIni_s#*:}"
      udfIsValidVariable $bashlyk_udfIni_sSection \
        || eval $(udfOnError return InvalidVariable '$bashlyk_udfIni_sSection')

      case "$bashlyk_udfIni_cClass" in

        !|-) bashlyk_udfIni_csvSection="${bashlyk_udfIni_csvSection##*_bashlyk_csv_record=;}" ;;
         #+) bashlyk_udfIni_csvSection="$(echo "$bashlyk_udfIni_csvSection" | sed -e "s/_bashlyk_csv_record=;//g")" ;;
          =) bashlyk_udfIni_csvSection="$(echo "$bashlyk_udfIni_csvSection" | tr ';' '\n' | sort | uniq | tr '\n' ';')" ;;

      esac

      eval 'export $bashlyk_udfIni_sSection="$(udfCsvHash2Raw "$bashlyk_udfIni_csvSection" "$bashlyk_udfIni_sSection")"'

    fi

  done
  ## TODO internal double quoted: " " ""
  return 0

}
#******
#****f* libold/udfGetIni
#  SYNOPSIS
#    udfGetIni <file> [<section>] ...
#  DESCRIPTION
#    Получить опции секций <csvSections> конфигурации <file> в CSV-строку в
#    формате "[section];<key>=<value>;..." на стандартный вывод
#  INPUTS
#     file    - файл конфигурации формата "*.ini".
#     section - любое количество имен секций, данные которых нужно получить.
#               По умолчанию и всегда выполняется сериализация "безымянной"
#               секции
#  ERRORS
#    MissingArgument - аргументы отсутствуют или файл конфигурации не найден
#  EXAMPLE
#    local csv='b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini
#    echo "simple line" | tee -a $ini
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $iniChild
#    udfGetIni $iniChild test >| grep "^\[\];;\[test\];${csv}$"                 #? true
#    rm -f $iniChild $ini
#  SOURCE
udfGetIni() {

  udfOn NoSuchFileOrDir $1 || return $?

  local csv s ini="$1" IFS=$' \t\n'

  shift

  for s in "" $*; do

    csv+="[${s}];$(udfIniGroupSection2Csv $ini $s)"

  done

  echo "$csv"

}
#******
#****f* libold/udfGetCsvSection
#  SYNOPSIS
#    udfGetCsvSection <csv> <tag>
#  DESCRIPTION
#    Выделить из CSV-строки <csv> фрагмент вида "[tag];key=value;...;" до
#    символа [ (очередная секция) или конца строки
#    формате "[section];<key>=<value>;..."  на стандартный вывод
#  INPUTS
#    tag - имя ini-секции
#    csv - строка сериализации данных ini-файлов
#  OUTPUT
#    csv; строка без заголовка секции [tag]
#  EXAMPLE
#    local csv='[];a=b;c=d e;[s1];a=f;c=g h;[s2];a=k;c=l m;'
#    udfGetCsvSection "$csv"    >| grep '^a=b;c=d e;$'                          #? true
#    udfGetCsvSection "$csv" s1 >| grep '^a=f;c=g h;$'                          #? true
#    udfGetCsvSection "$csv" s2 >| grep '^a=k;c=l m;$'                          #? true
#  SOURCE
udfGetCsvSection() {

  echo "${1#*\[$2\];}" | cut -f1 -d'['

  return 0

}
#******
#****f* libold/udfSelectEnumFromCsvHash
#  SYNOPSIS
#    udfSelectEnumFromCsvHash <csv> [<tag>]
#  DESCRIPTION
#     CSV-строку, в полях которых указаны только неименованные значения,
#    из CSV-строки <csv>. Предполагается, что данная <csv> строка является
#    сериализацией ini-файла, неименованные данные которого получают ключи вида
#    "_bashlyk_ini_<секция>_autoKey_<номер>"
#  INPUTS
#    tag - имя ini-секции
#    csv - строка сериализации данных ini-файлов
#  OUTPUT
#    csv; строка без заголовка секции [tag]
#  EXAMPLE
#    local csv='[];a=b;_bashlyk_ini_void_autoKey_0="d = e";[s1];_bashlyk_ini_s1_autoKey_0=f=0;c=g h;[s2];a=k;_bashlyk_ini_s2_autoKey_0=l m;'
#    udfSelectEnumFromCsvHash "$csv"    >| grep '^"d = e";$'                    #? true
#    udfSelectEnumFromCsvHash "$csv" s1 >| grep '^f=0;$'                        #? true
#    udfSelectEnumFromCsvHash "$csv" s2 >| grep '^l m;$'                        #? true
#  SOURCE
udfSelectEnumFromCsvHash() {

  local IFS=';' csv s sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"

  for s in $(echo "${1#*\[$2\];}" | cut -f1 -d'['); do

    echo "$s" | grep "^${sUnnamedKeyword}" >/dev/null 2>&1 && csv+="${s#*=};"

  done

  echo "$csv"

}
#******
#****f* libold/udfCsvHash2Raw
#  SYNOPSIS
#    udfCsvHash2Raw <csv> [<tag>]
#  DESCRIPTION
#    подготовить CSV;-строку для выполнения в качестве сценария, поля которого
#    рассматриваются как строки команд. При этом автоматические ключи вида
#    "_bashlyk_ini_<секция>_autoKey_<номер>" и поля-разделители записей разных
#    источников данных "_bashlyk_csv_record=" будут убраны. Поля вида
#    "ключ=значение" становятся командами присвоения значения переменной.
#    Предполагается, что входная <csv> строка является сериализацией ini-файла.
#  INPUTS
#    tag - имя ini-секции
#    csv - строка сериализации данных ini-файлов
#  OUTPUT
#    csv; строка без заголовка секции [tag]
#  EXAMPLE
#    local csv='[];_bashlyk_csv_record=;a=b;_bashlyk_ini_void_autoKey_0="d = e";[s1];_bashlyk_ini_s1_autoKey_0=f=0;c=g h;[s2];a=k;_bashlyk_ini_s2_autoKey_0=l m;'
#    udfCsvHash2Raw "$csv"    >| grep '^a=b;"d = e";$'                          #? true
#    udfCsvHash2Raw "$csv" s1 >| grep '^f=0;c=g h;$'                            #? true
#    udfCsvHash2Raw "$csv" s2 >| grep '^a=k;l m;$'                              #? true
#  SOURCE
udfCsvHash2Raw() {

  local IFS=';' csv s sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"

  for s in $(echo "${1#*\[$2\];}" | cut -f1 -d'['); do

    s="${s#${sUnnamedKeyword}[0-9]*=}"
    s="${s##*_bashlyk_csv_record=}"

    [[ $s ]] || continue

    csv+="${s};"

  done

  echo "$csv"

}
#******
#****f* libold/udfIniSection2Csv
#  SYNOPSIS
#    udfIniSection2Csv <file> [<section>]
#  DESCRIPTION
#    Получить секцию конфигурационных данных <section> из файла <file> и выдать
#    результат в виде строки CSV, разделенных ';', каждое поле которой содержит
#    данные в формате "<ключ>=<значение>" согласно данных строки секции.
#    В случае если исходная строка не содержит ключ или ключ содержит пробел, то
#    ключом становится выражение ${_bashlyk_sUnnamedKeyword}_<инкремент>, а всё
#    содержимое строки - значением.
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента
#              считываются данные до первого заголовка секции [<...>] данных
#              или до конца конфигурационного файла, если секций нет
#  OUTPUT
#    строки CSV, разделенных ';', каждое поле которой содержит данные в формате
#    "<ключ>=<значение>" согласно данных строки секции
#  ERRORS
#    MissingArgument - аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_bashlyk_ini_test_autoKey_0="simple line";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini
#    echo "simple line" | tee -a $ini
#    udfIniSection2Csv $ini test >| grep "^${csv}$"                             #? true
#    rm -f $ini
#  SOURCE
udfIniSection2Csv() {

  udfOn NoSuchFileOrDir $1 || return $?

  local IFS=$' \t\n'

  mawk -f ${_bashlyk_pathLib}/inisection2csv.awk -v "sTag=$2" -- $1

  return 0

}
#******
#****f* libold/udfIniGroupSection2Csv
#  SYNOPSIS
#    udfIniGroupSection2Csv <file> [<section>]
#  DESCRIPTION
#    Получить конфигурационные данные секции <section> из <file> и, при наличии,
#    от группы "родительских" к нему файлов. Например, если <file> это
#    "a.b.c.ini", то "родительскими" будут считаться файлы "ini", "c.ini" и
#    "b.c.ini" если они есть в том же каталоге. Данные наследуются и
#    перекрываются от "старшего" файла к младшему.
#    Поиск конфигурационных файлов выполняется по следующим критериям:
#     1. Если имя файла <file> содержит неполный путь, то в начале проверяется
#     текущий каталог, затем каталог конфигураций по умолчанию
#     2. Если имя файла содержит полный путь, то рабочим каталогом является этот
#     полный путь
#     3. Последняя попытка - найти файл в каталоге /etc
#    Важно: имя <file> не должно начинаться с точки и им заканчиваться!
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента
#              считываются данные до первого заголовка секции [<...>] данных или
#              до конца конфигурационного файла, если секций нет
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся
#              конфигурационные данные в формате "<key>=<value>;..."
#  ERRORS
#    NoSuchFileOrDir - файл конфигурации не найден
#    MissingArgument - аргумент отсутствует
#  EXAMPLE
#    local csv='b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini
#    echo "simple line" | tee -a $ini
#    printf "$fmt" sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee $iniChild
#    udfIniGroupSection2Csv $iniChild test >| grep "^${csv}$"                   #? true
#    rm -f $iniChild $ini
#    udfIniGroupSection2Csv $iniChild                                           #? $_bashlyk_iErrorNoSuchFileOrDir
#    udfIniGroupSection2Csv                                                     #? $_bashlyk_iErrorEmptyOrMissingArgument
#    ## TODO тест пустой результат
#  SOURCE
udfIniGroupSection2Csv() {

  udfOn MissingArgument $1 || return $?

  local a csv fn path s sTag IFS=$' \t\n' GLOBIGNORE

  path="$_bashlyk_pathIni"

  [[ "$1" == "${1##*/}" && -f "${path}/$1" ]] || path=
  [[ "$1" == "${1##*/}" && -f "$1" ]] && path=$( exec -c pwd )
  [[ "$1" != "${1##*/}" && -f "$1" ]] && path=${1%/*}
  [[ -n "$2" ]] && sTag="$2"
  #
  if [[ ! $path ]]; then

   [[ -f "/etc/${_bashlyk_pathPrefix}/$1" ]] \
     && path="/etc/${_bashlyk_pathPrefix}" \
     || eval $( udfOnError return NoSuchFileOrDir )

  fi
  #
  a=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

  GLOBIGNORE="*:?"

  for s in $a; do

    [[ $s                 ]] || continue
    [[ $fn                ]] && fn="${s}.${fn}" || fn="$s"
    [[ -s "$path/$fn" ]] && csv+=";$( udfIniSection2Csv "$path/$fn" "$sTag" );"

  done

  unset GLOBIGNORE

  udfCsvOrder "$csv"

  return $?
}
#******
#****f* libold/udfIni2Csv
#  SYNOPSIS
#    udfIni2Csv <file>
#  DESCRIPTION
#    Получить конфигурационныe данныe всех секций ini-файла <file> и выдать
#    результат в виде строки CSV, разделенных ';', каждое поле которой содержит
#    данные в формате "[<секция>];<ключ>=<значение>" согласно данных строки
#    секции.
#    В случае если исходная строка не содержит ключ или ключ содержит пробел, то
#    ключом становится переменная "_bashlyk_ini_<секция>_autoKey_<инкремент>", а
#    всё содержимое строки - значением
#  INPUTS
#    file - имя файла конфигурации
#  OUTPUT
#    строки CSV, разделенных ';', каждое поле которой содержит данные в формате
#    "[<секция>];<ключ>=<значение>" согласно данных секции.
#  ERRORS
#    MissingArgument - аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    local ini re
#    re='sTxt="-S-(da.*-R).*y_1="^_s.*e^_";\[exec\].*=$(.*\[ -n "$sUname" \] .*'
#    ini=$(mktemp --suffix=test.ini || tempfile -s .test.ini)                   #? true
#    cat <<'EOFini' > ${ini}                                                    #-
#[test]                                                                         #-
#    sTxt	=	$(date -R) a                                            #-
#    b		=	false                                                   #-
#    iXo Xo	=	19                                                      #-
#    iYo	=	80                                                      #-
#    test	=	line = to = line                                        #-
#    `simple line`                                                              #-
#[exec]:                                                                        #-
#    sUname=$(uname -a)                                                         #-
#    [ -n "$sUname" ] && date                                                   #-
#:[exec]                                                                        #-
#EOFini                                                                         #-
#    udfIni2Csv $ini | grep -o "_bashlyk_&#.._" >| wc -l | grep '^7$'           #? true
#    udfIni2Csv $ini | udfBashlykUnquote >| grep "$re"                          #? true
#    rm -f $ini
#  SOURCE
udfIni2Csv() {

  udfOn NoSuchFileOrDir $1 || return $?

  local IFS=$' \t\n'

  mawk -f ${_bashlyk_pathLib}/ini2csv.awk -- $1

  return 0

}
#******
#****f* libold/udfIniGroup2Csv
#  SYNOPSIS
#    udfIniGroup2Csv <file>
#  DESCRIPTION
#    Получить конфигурационные данные всех секций <section> из <file> и, при
#    наличии, от группы "родительских" к нему файлов. Например, если <file> это
#    "a.b.c.ini", то "родительскими" будут считаться файлы "ini", "c.ini" и
#    "b.c.ini" если они есть в том же каталоге. Данные наследуются и
#    перекрываются от "старшего" файла к младшему.
#    Поиск конфигурационных файлов выполняется по следующим критериям:
#     1. Если имя файла <file> содержит неполный путь, то в начале проверяется
#     текущий каталог, затем каталог конфигураций по умолчанию
#     2. Если имя файла содержит полный путь, то рабочим каталогом является этот
#     полный путь
#     3. Последняя попытка - найти файл в каталоге /etc
#    Важно: имя <file> не должно начинаться с точки и им заканчиваться!
#  INPUTS
#    file    - имя файла конфигурации
#  OUTPUT
#              разделенный символом ";" CSV-строка, в полях которого содержатся
#              конфигурационные данные в формате "[<section>];<key>=<value>;..."
#  ERRORS
#    NoSuchFileOrDir - файл конфигурации не найден
#    MissingArgument - аргумент отсутствует или нет входных данных
#    EmptyResult     - результат отсутствует
#  EXAMPLE
#    local re='\[test\];_b.*d=;sTxt=foo;.*autoKey_0=.*_b.*d=;.*foo bar.*o=1080;'
#    local sTxt=foo b=false iXo=1921 iYo=80 ini iniChild csvResult
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#    printf "$fmt" sTxt $sTxt b $b "iXo Xo" 19 iYo $iYo | tee $ini
#    echo "simple line" | tee -a $ini
#    printf "$fmt" sTxt "foo bar" b "true" iXo "1920" iYo "1080" | tee $iniChild
#    udfIniGroup2Csv $iniChild >| grep "$re"                                    #? true
#    rm -f $iniChild $ini
#    udfIniGroup2Csv $iniChild                                                  #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO проверка пустых данных (iErrorEmptyOrMissingArgument)
#  SOURCE
udfIniGroup2Csv() {

  udfOn MissingArgument $1 || return $?

  local a aini csvIni ini pathIni s sTag aTag csvOut fnOpt ini pathIni IFS=$' \t\n' GLOBIGNORE
  #
  #
  ## TODO встроить защиту от подстановки конфигурационного файла (по владельцу)
  #
  [[ "$1" == "${1##*/}" && -f "$(_ pathIni)/$1" ]] && pathIni=$(_ pathIni)
  [[ "$1" == "${1##*/}" && -f "$1"              ]] && pathIni=$(exec -c pwd )
  [[ "$1" != "${1##*/}" && -f "$1"              ]] && pathIni=$(dirname $1)
  #
  if [[ -z "$pathIni" ]]; then

    [[ -f "/etc/$(_ pathPrefix)/$1" ]] && pathIni="/etc/$(_ pathPrefix)"

  fi
  #
  aini=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

  GLOBIGNORE="*:?"

  if [[ -n "$pathIni" ]]; then

    for s in $aini; do
      [[ $s                     ]] || continue
      [[ $ini                   ]] && ini="${s}.${ini}" || ini="$s"
      [[ -s "${pathIni}/${ini}" ]] && csvIni+="$(udfIni2Csv "${pathIni}/${ini}" | tr -d '\\')"

    done

  fi

  if [[ "$_bashlyk_bSetOptions" == "1" && -n "$_bashlyk_csvOptions2Ini" ]]; then

    udfMakeTemp fnOpt
    udfIniWrite $fnOpt "$_bashlyk_csvOptions2Ini"
    _bashlyk_csvOptions2Ini=''
    _bashlyk_bSetOptions=0
    csvIni+="$( udfIni2Csv $fnOpt | tr -d '\\' )"

  fi

  declare -A a
  IFS='['
  for s in $csvIni; do

    sTag=${s%%]*}
    [[ -z "$sTag"  ]] && sTag=" "
    [[ $sTag == ";" ]] && continue
    [[ -z "$(echo "${s#*]}" | tr -d ';:')" ]] && continue
    a[$sTag]+="_bashlyk_csv_record=${s#*]}"

  done

  for s in "${!a[@]}"; do

    csvOut+="[${s// /}];${a[$s]}"

  done

  IFS=$' \t\n'
  unset GLOBIGNORE

  if [[ ! $csvOut ]]; then

    [[ -d "$pathIni" ]] || eval $(udfOnError return NoSuchFileOrDir '$1')
    [[ $csvIni ]]       || eval $(udfOnError return MissingArgument)

    eval $(udfOnError return EmptyResult)

  fi

  echo "$csvOut" | sed -e "s/;\+/;/g"

}
#******
#****f* libold/udfOptions2Ini
#  SYNOPSIS
#    udfOptions2Ini  [<section>]:(=[<varname>])|<csv;> ...
#  DESCRIPTION
#    подготовить csv-поток из уже инициализированных переменных, например, опций
#    командной строки согласно распределению этих переменных по указанным
#    cекциям <section> (см. udfIni) для совмещения с соответствующими данными
#    ini-конфигурационных файлов. Результат помещается в глобальную переменную
#    _bashlyk_csvOptions2Ini для использования в udfIni
#  INPUTS
#    распределение переменных по указанным секциям (см. udfIni)
#  ERRORS
#    MissingArgument - аргумент отсутствует
#  EXAMPLE
#   local sVoid="verbose;direct;log;" sMain="source;destination"
#   local unify="*.tmp,*~,*.bak" replace="replace" unify="unify" acc="acc"
#   local preExec="sUname=$(TZ=UTC date -R --date='@12345678'),date -R"
#   local sMD5='592dbbd3a17e18e14b828c75898437e4'
#   local sRules=":${sVoid} preExec:! main:${sMain} replace:- unify:= acc:+"
#   local verbose="yes foo" direct="false" log="/var/log/test.log" source="last"
#   local destination="/tmp/last.txt"
#   udfOptions2Ini $sRules                                                      #? true
#   _ csvOptions2Ini | md5sum >| grep ^${sMD5}                                  #? true
#   #udfIniWrite /tmp/${$}.test.ini "$(_ csvOptions2Ini)"
#   #udfIni /tmp/${$}.test.ini preExec:=
#   #udfPrepare2Exec $preExec
#  SOURCE
udfOptions2Ini() {

  udfOn MissingArgument $1 || return $?

  local csv k s sClass sData sIni sRules sSection IFS=$' \t\n'

  for s in $*; do

    sSection="${s%:*}"
    sData="${s/$sSection/}"
    sClass="${s#*:}"
    sData=${sData/:/}
    sData=${sData/[=\-+\!]/}

    [[ "$sClass" == "$sData" ]] && sClass=
    csv=""

    if [[ $sClass && $sData ]]; then

      udfSetLastError InvalidArgument "$sClass"
      continue

    fi

    if [[ $sData ]]; then

      IFS=';'
      for k in $sData; do

        [[ ${!k} ]] && csv+="$k=${!k};"

      done
      IFS=$' \t\n'

    else

      [[ ${!sSection} ]] && csv+="${!sSection};"

    fi

    [[ $csv ]] || continue

    if [[ "$sClass" == "!" ]]; then

      s="[${sSection}]:;${csv};:[${sSection}]"

    else

      s="[${sSection}];${csv};"

    fi

    sIni+=$s

  done

  _ csvOptions2Ini "${sIni//,/;}"

  return 0

}
#******
#****f* libold/udfBashlykUnquote
#  SYNOPSIS
#    udfBashlykUnquote
#  DESCRIPTION
#    Преобразование метапоследовательностей _bashlyk_&#XX_ из потока со стандартного входа в символы '"[]()=;\'
#  EXAMPLE
#    local s="_bashlyk_&#34__bashlyk_&#91__bashlyk_&#93__bashlyk_&#59__bashlyk_&#40__bashlyk_&#41__bashlyk_&#61_"
#    echo $s | udfBashlykUnquote >| grep -e '\"\[\];()='                                                          #? true
#  SOURCE
udfBashlykUnquote() {

  local cmd='sed' i IFS=$' \t\n'
  local -A a=( [34]='\"' [40]='\(' [41]='\)' [59]='\;' [61]='\=' [91]='\[' [92]='\\\' [93]='\]' )

  for i in "${!a[@]}"; do

    cmd+=" -e \"s/_bashlyk_\&#${i}_/${a[$i]}/g\""

  done
  ## TODO продумать команды для удаления "_bashlyk_csv_record=" и автоматических ключей
  #cmd+=" -e \"s/\t\?_bashlyk_ini_.*_autoKey_[0-9]\+\t\?=\t\?//g\""
  cmd+=' -e "s/^\"\(.*\)\"$/\1/"'

  eval "$cmd"

}
#******
#****f* libold/udfPrepare2Exec
#  SYNOPSIS
#    udfPrepare2Exec - args
#  DESCRIPTION
#    Преобразование метапоследовательностей _bashlyk_&#XX_ в символы '[]()=;\'
#    со стандартного входа или строки аргументов. В последнем случае,
#    дополнительно происходит разделение полей "CSV;"-строки в отдельные
#    строки
#  INPUTS
#    args - командная строка
#       - - данные поступают со стандартного входа
#  OUTPUT
#    поток строк, пригодных для выполнения командным интерпретатором
#  EXAMPLE
#    local s1 s2
#    s1="_bashlyk_&#91__bashlyk_&#93__bashlyk_&#59__bashlyk_&#40__bashlyk_&#41__bashlyk_&#61_"
#    s2="while _bashlyk_&#91_ true _bashlyk_&#93_; do read;done"
#    echo $s1 | udfPrepare2Exec -                                                              #? true
#    udfPrepare2Exec $s1 >| grep -e '\[\];()='                                                 #? true
#    udfPrepare2Exec $s2 >| grep -e "^while \[ true \]$\|^ do read$\|^done$"                   #? true
#  SOURCE
udfPrepare2Exec() {

  local s IFS=$' \t\n'

  if [[ "$1" == "-" ]]; then

    udfBashlykUnquote

  else

    echo -e "${*//;/\\n}" | udfBashlykUnquote

  fi

  return 0

}
#******
#****f* libold/udfShellExec
#  SYNOPSIS
#    udfShellExec args
#  DESCRIPTION
#    Выполнение командной строки во внешнем временном файле
#    в текущей среде интерпретатора оболочки
#  INPUTS
#    args - командная строка
#  RETURN VALUE
#    MissingArgument - аргумент не задан
#    в остальных случаях код возврата командной строки с учетом доступа к временному файлу
#  EXAMPLE
#    udfShellExec 'true; false'                                                 #? false
#    udfShellExec 'false; true'                                                 #? true
#  SOURCE
udfShellExec() {

  udfOn MissingArgument $* || return $?

  local rc fn IFS=$' \t\n'

  udfMakeTemp fn
  udfPrepare2Exec "$@" > $fn
  . $fn
  rc=$?
  rm -f $fn

  return $rc

}
#******
#****f* libold/udfLocalVarFromCSV
#  SYNOPSIS
#    udfLocalVarFromCSV CSV1 CSV2 ...
#  DESCRIPTION
#    Prepare string from comma separated lists (ex. INI options) for definition
#    of the local variables by using eval
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    udfLocalVarFromCSV a1,b2,c3                                                #? true
#    udfLocalVarFromCSV a1 b2,c3                                                #? true
#    udfLocalVarFromCSV a1,b2 c3                                                #? true
#    echo $( udfLocalVarFromCSV a1,b2 c3,4d 2>/dev/null ) >| grep '^local'      #? false
#  SOURCE
udfLocalVarFromCSV() {

  if [[ ! $@ ]]; then

    udfOnError1 throw MissingArgument
    return $( _ iErrorMissingArgument )

  fi

  local s
  local -A h

  for s in ${*//[;,]/ }; do

    if ! udfIsValidVariable $s; then

      udfOnError1 throw InvalidVariable "$s"
      return $( _ iErrorInvalidVariable )

    fi

    h[$s]="$s"

  done

  if [[ ${h[@]} ]]; then

    echo "local ${h[@]}"

  else

    udfOnError1 throw EmptyResult
    return $( _ iErrorEmptyResult )

  fi

}
#******
#****f* libold/udfSerialize
#  SYNOPSIS
#    udfSerialize variables
#  DESCRIPTION
#    Generate csv string from variable list
#  INPUTS
#    variables - list of variables
#  OUTPUT
#    Show csv string
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    local sUname="$(uname -a)" sDate="" s=100
#    udfSerialize sUname sDate s >| grep "^sUname=.*s=100;$"                                                                 #? true
#  SOURCE
udfSerialize() {

  udfOn MissingArgument $1 || return $?

  local bashlyk_s_Serialize csv IFS=$' \t\n'

  for bashlyk_s_Serialize in $*; do

    udfIsValidVariable "$bashlyk_s_Serialize" \
      && csv+="${bashlyk_s_Serialize}=${!bashlyk_s_Serialize};" \
      || udfSetLastError InvalidVariable "$bashlyk_s_Serialize"

  done

  echo "$csv"

}
#******
#****f* libold/udfGetOptHash
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
#    MissingArgument - аргумент не задан
#    InvalidArgument - неправильная опция
#    EmptyResult     - пустой результат
#  EXAMPLE
#   udfGetOptHash 'job:,force' --job main --force >| grep "^job=main;force=1;$" #? true
#   udfGetOptHash                                                               #? $_bashlyk_iErrorMissingArgument
#   udfGetOptHash 'bar:,foo' --job main --force                                 #? $_bashlyk_iErrorInvalidArgument
#  SOURCE
udfGetOptHash() {

  udfOn MissingArgument $* || return $?

  local k v csvKeys csvHash sOpt bFound IFS=$' \t\n'

  csvKeys="$1"
  shift

  sOpt="$( getopt -l $csvKeys -n $0 -- $0 $@ 2>/dev/null )" \
    || eval $( udfOnError return InvalidArgument $@ )

  eval set -- "$sOpt"

  while true; do

    [[ $1 ]] || break
    bFound=

    for k in ${csvKeys//,/ }; do

      v=${k//:/}

      [[ "--$v" == "$1" ]] && bFound=1 || continue

      if [[ "$k" =~ :$ ]]; then

       csvHash+="$v=$( udfAlias2WSpace $2 );"
       shift 2

      else

        csvHash+="$v=1;"
        shift

      fi

   done

   [[ -z "$bFound" ]] && shift

  done

  shift

  [[ $csvHash ]] && echo "$csvHash" || return $_bashlyk_iErrorEmptyResult

}
#******
#****f* libold/udfSetOptHash
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
#    udfSetOptHash                                                              #? $_bashlyk_iErrorMissingArgument
#    ## TODO коды возврата проверить
#  SOURCE
udfSetOptHash() {

  udfOn MissingArgument $* || return

  local _bashlyk_udfGetOptHash_confTmp IFS=$' \t\n'

  udfMakeTemp   _bashlyk_udfGetOptHash_confTmp
  udfSetConfig $_bashlyk_udfGetOptHash_confTmp "$*" || eval $(udfOnError return)
  udfGetConfig $_bashlyk_udfGetOptHash_confTmp      || eval $(udfOnError return)

  rm -f $_bashlyk_udfGetOptHash_confTmp

  return 0

}
#******
#****f* libold/udfGetOpt
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

  udfSetOptHash $( udfGetOptHash $* ) && _bashlyk_bSetOptions=1

}
#******
#****f* libold/udfExcludePairFromHash
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
#****f* libold/udfSetLastError
#  SYNOPSIS
#    udfSetLastError <number> <string>
#  DESCRIPTION
#    Set in global variables $_bashlyk_{i,s}Error[$BASHPID] arbitrary values as
#    error states - number and string
#  INPUTS
#    <number> - error code - number or predefined name as 'iErrorXXX' or 'XXX'
#    <string> - error text
#  ERRORS
#    MissingArgument - arguments missing
#    Unknown         - first argument is non valid
#    1-255           - valid value of first argument
#  EXAMPLE
#    local pid=$BASHPID
#    udfSetLastError                                                            #? $_bashlyk_iErrorMissingArgument
#    udfSetLastError non valid argument                                         #? $_bashlyk_iErrorUnknown
#    udfSetLastError 555                                                        #? $_bashlyk_iErrorUnexpected
#    udfSetLastError AlreadyStarted "$$"                                        #? $_bashlyk_iErrorAlreadyStarted
#    udfSetLastError iErrorInvalidVariable "12Invalid Variable"                 #? $_bashlyk_iErrorInvalidVariable
#    _ iLastError[$pid] >| grep -w "$_bashlyk_iErrorInvalidVariable"            #? true
#    _ sLastError[$pid] >| grep "^12Invalid Variable$"                          #? true
#  SOURCE
udfSetLastError() {

  [[ $1 ]] || return $_bashlyk_iErrorMissingArgument

  local i

  if [[ "$1" =~ ^[0-9]+$ ]]; then

    i=$1

  else

    eval "i=\$_bashlyk_iError${1}"
    [[ -n "$i" ]] || eval "i=\$_bashlyk_${1}"

  fi

  [[ "$i" =~ ^[0-9]+$ && $i -le 255 ]] && shift || i=$_bashlyk_iErrorUnknown

  _bashlyk_iLastError[$BASHPID]=$i
  [[ $* ]] && _bashlyk_sLastError[$BASHPID]="$*"

  return $i

}
#******
#****f* libold/udfStackTrace
#  SYNOPSIS
#    udfStackTrace
#  DESCRIPTION
#    OUTPUT BASH Stack Trace
#  OUTPUT
#    BASH Stack Trace
#  EXAMPLE
#    udfStackTrace
#  SOURCE
udfStackTrace() {

  local i s

  echo "Stack Trace for ${BASH_SOURCE[0]}::${FUNCNAME[0]}:"

  for (( i=${#FUNCNAME[@]}-1; i >= 0; i-- )); do

    [[ ${BASH_LINENO[i]} == 0 ]] && continue
    echo "$s $i: call ${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}(...)"
    echo "$s $i: code $(sed -n "${BASH_LINENO[$i]}p" ${BASH_SOURCE[$i+1]})"
    s+=" "

  done

}
#******
#****f* libold/udfOnError
#  SYNOPSIS
#    udfOnError [<action>] [<state>] [<message>]
#  DESCRIPTION
#    Flexible error handling. Processing is controlled by global variables or
#    arguments, and consists in a warning message, the function returns, or the
#    end of the script with a certain return code. Messages may include a stack
#    trace and printed to stderr
#  INPUTS
#    <action> - directly determines how the error handling. Possible actions:
#
#     echo     - just prepare a message from the string argument to STDOUT
#     warn     - prepare a message from the string argument for transmission to
#                the notification system
#     return   - set return from the function. In the global context - the end
#                of the script (exit)
#     retecho  - the combined action of 'echo'+'return', however, if the code is
#                not within the function, it is only the transfer of messages
#                from a string of arguments to STDOUT
#     retwarn  - the combined action of 'warn'+'return', however, if the code is
#                not within the function, it is only the transfer of messages
#                from a string of arguments to the notification system
#     exit     - set unconditional completion of the script
#     exitecho - the same as 'exit', but with the transfer of messages from a
#                string of arguments to STDOUT
#     exitwarn - the same as 'exitecho', but with the transfer of messages to
#                the notification system
#     throw    - the same as 'exitwarn', but with the transfer of messages and
#                the call stack to the notification system
#
#    If an action is not specified, it uses stored in the global variable
#    $_bashlyk_onError action. If it is not valid, then use action 'throw'
#
#    state - number or predefined name as 'iError<Name>' or '<Name>' by which
#            one can get the error code from the global variable
#            $_bashlyk_iError<..> and its description from global hash
#            $_bashlyk_hError
#            If the error code is not specified, it is set to the return code of
#            the last executed command. In the end, the resulting numeric code
#            initializes a global variable $_bashlyk_iLastError[$BASHPID]
#
#    message - error detail, such as the filename. When specifying message
#    should bear in mind that in the error table ($_bashlyk_hError) are already
#    prepared descriptions <...>
#
#  OUTPUT
#    command line, which can be performed using the eval <...>
#  EXAMPLE
#    local cmd=udfOnError e=InvalidArgument s="$RANDOM $RANDOM"
#    eval $($cmd echo $e "$s a")                                                #? $_bashlyk_iErrorInvalidArgument
#    udfIsNumber 020h || eval $($cmd echo $? "020h")                            #? $_bashlyk_iErrorNotNumber
#    udfIsValidVariable 1Invalid || eval $($cmd warn $? "1Invalid")             #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable 2Invalid || eval $($cmd warn "2Invalid")                #? $_bashlyk_iErrorInvalidVariable
#    $cmd exit    $e "$s b" >| grep " exit \$?"                                 #? true
#    $cmd return  $e "$s c" >| grep " return \$?"                               #? true
#    $cmd retecho $e "$s d" >| grep "echo.* return \$?"                         #? true
#    $cmd retwarn $e "$s e" >| grep "Warn.* return \$?"                         #? true
#    $cmd throw   $e "$s f" >| grep "dfWarn.* exit \$?"                         #? true
#    eval $($cmd exitecho MissingArgument) 2>&1 >| grep "E.*: em.*o.*mi"        #? true
#    _ onError warn
#    eval $($cmd $e "$s g")                                                     #? $_bashlyk_iErrorInvalidArgument
#  SOURCE
udfOnError() {

  local rs=$? sAction=$_bashlyk_onError sMessage='' s IFS=$' \t\n'

  case "${sAction,,}" in

    echo|exit|exitecho|exitwarn|retecho|retwarn|return|warn|throw)
    ;;

    *)
      sAction=throw
    ;;

  esac

  case "${1,,}" in

    echo|exit|exitecho|exitwarn|retecho|retwarn|return|warn|throw)
      sAction=$1
      shift
    ;;

  esac

  udfSetLastError $1
  s=$?

  if [[ $s == $_bashlyk_iErrorUnknown ]]; then

    if [[ ${_bashlyk_hError[$rs]} ]]; then

      s=$rs
      rs="${_bashlyk_hError[$rs]} - $* .. ($rs)"

    else

      (( $rs == 0 )) && rs=$_bashlyk_iErrorUnexpected
      rs="$* .. ($rs)"
      s=$_bashlyk_iErrorUnexpected

    fi

  else

    shift

    if [[ ${_bashlyk_hError[$s]} ]]; then

      rs="${_bashlyk_hError[$s]} - $* .. ($s)"

    else

      (( $s == 0 )) && s=$_bashlyk_iErrorUnexpected
      rs="$* .. ($s)"

    fi

  fi

  rs=${rs//\(/\\\(}
  rs=${rs//\)/\\\)}
  rs=${rs//\;/\\\;}

  if [[ "${FUNCNAME[1]}" == "main" || -z "${FUNCNAME[1]}" ]]; then

    [[ "$sAction" == "retecho" ]] && sAction='exitecho'
    [[ "$sAction" == "retwarn" ]] && sAction='exitwarn'
    [[ "$sAction" == "return"  ]] && sAction='exit'

  fi

  case "${sAction,,}" in

           echo) sAction="";             sMessage="echo  Warn: ${rs} >&2;";;
        retecho) sAction="; return \$?"; sMessage="echo Error: ${rs} >&2;";;
       exitecho) sAction="; exit \$?";   sMessage="echo Error: ${rs} >&2;";;
           warn) sAction="";             sMessage="udfWarn  Warn: ${rs} >&2;";;
        retwarn) sAction="; return \$?"; sMessage="udfWarn Error: ${rs} >&2;";;
       exitwarn) sAction="; exit \$?";   sMessage="udfWarn Error: ${rs} >&2;";;
          throw)
                 sAction="; exit \$?"
                 sMessage="udfStackTrace | udfWarn - Error: ${rs} >&2;"
          ;;

    exit|return) sAction="; $sAction \$?"; sMessage="";;

  esac

  printf -- "%s udfSetLastError %s %s%s\n" "$sMessage" "$s" "$rs" "${sAction}"

}
#******
udfOnError2() { udfOnError "$@"; }
#****f* libold/udfOnError1
#  SYNOPSIS
#    udfOnError1 [<action>] [<state>] [<message>]
#  DESCRIPTION
#    Same as udfOnError except output printed to stdout
#  INPUTS
#    see udfOnError
#  OUTPUT
#    see udfOnError
#  EXAMPLE
#    #see udfOnError
#    eval $(udfOnError1 exitecho MissingArgument) >| grep "E.*: em.*o.*mi"      #? true
#    #_ onError warn
#  SOURCE
udfOnError1() {

  udfOnError "$@" | sed -re "s/ >\&2;/;/"

}
#******
#****f* libold/udfThrow
#  SYNOPSIS
#    udfThrow [-] args
#  DESCRIPTION
#    Stop the script. Returns an error code of the last command if value of
#    the special variable $_bashlyk_iLastError[$BASHPID] not defined
#    Perhaps set the the message. In the case of non-interactive execution
#    message is sent notification system.
#  INPUTS
#    -    - read message from stdin
#    args - message string. With stdin data ("-" option required) used as header
#  OUTPUT
#    show input message or data from special variable
#  RETURN VALUE
#   return ${_bashlyk_iLastError[$BASHPID]} or last non zero return code or 255
#  EXAMPLE
#    local rc=$(( RANDOM / 256 )) cmd=udfSetLastError
#    echo $(false || udfThrow rc=$? 2>&1; echo ok=$?) >| grep "^Error: rc=1.*$" #? true
#    echo $($cmd $rc || udfThrow $? 2>&1; echo rc=$?) >| grep -w "$rc"          #? true
#  SOURCE
udfThrow() {

  local i=$? rc

  rc=${_bashlyk_iLastError[$BASHPID]}

  [[ $rc =~ ^[0-9]+$ ]] || rc=$i

  eval $( udfOnError exitwarn $rc $* )

}
#******
#****f* libold/udfOn
#  SYNOPSIS
#    udfOn <error> [<action>] <args>
#  DESCRIPTION
#    Checks the list of arguments <args> to the <error> (the first argument) and
#    applies the <action> (the second argument, may be omitted) if the condition
#    is satisfied at least one of this arguments
#  INPUTS
#    <error>  - error condition on which the arguments are checked, now
#               supported CommandNotFound, EmptyVariable, EmptyOrMissingArgument
#    <action> - one of return, echo, warn, exit, throw:
#    return   - set return from the function. In the global context - the end
#               of the script (exit)
#    echo     - just prepare a message from the string argument to STDOUT and
#               set return if the code is within the function
#    warn     - prepare a message from the string argument for transmission to
#               the notification system and set return if the code is within the
#               function
#    exit     - set unconditional completion of the script
#    throw    - set unconditional completion of the script and prepare a message
#               and the call stack for transmission to the notification system
#    <args>   - list of arguments for checking
#  OUTPUT
#    Error or warning message with listing the arguments on which the error is
#    triggered by the condition
#  EXAMPLE
#    ## TODO improved tests
#    local cmdYes='sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}" e=CommandNotFound
#    udfOn $e                                                                   #? $_bashlyk_iErrorMissingArgument
#    udfOn $e $cmdNo1                                                           #? $_bashlyk_iErrorCommandNotFound
#    $(udfOn $e $cmdNo2 || exit 123)                                            #? 123
#    udfOn $e WARN $cmdYes $cmdNo1 $cmdNo2 2>&1 >| grep "Error.*bin.*"          #? true
#    udfOn $e Echo $cmdYes $cmdNo1 $cmdNo2 2>&1 >| grep ', bin'                 #? true
#    $(udfOn $e  Exit $cmdNo1 >/dev/null 2>&1; true)                            #? $_bashlyk_iErrorCommandNotFound
#    $(udfOn $e Throw $cmdNo2 >/dev/null 2>&1; true)                            #? $_bashlyk_iErrorCommandNotFound
#    udfOn $e $cmdYes                                                           #? true
#    udfOn MissingArgument ""                                                   #? $_bashlyk_iErrorMissingArgument
#    udfOn EmptyArgument ""                                                     #? $_bashlyk_iErrorMissingArgument
#    udfOn EmptyResult ""                                                       #? $_bashlyk_iErrorEmptyResult
#    udfOn EmptyResult return ""                                                #? $_bashlyk_iErrorEmptyResult
#    udfOn InvalidVariable invalid+variable                                     #? $_bashlyk_iErrorInvalidVariable
#    udfOn NoSuchFileOrDir "/$RANDOM/$RANDOM"                                   #? $_bashlyk_iErrorNoSuchFileOrDir
#  SOURCE

udfOn() {

  local cmd csv e i IFS j s

  cmd='return'
  i=0
  j=0
  IFS=$' \t\n'
  e=$1

  if [[ $1 =~ ^(CommandNotFound|Empty(Variable|Argument|OrMissingArgument|Result)|Invalid(Argument|Variable)|MissingArgument|NoSuchFileOrDir)$ ]]; then

    e=$1

  else

    eval $( udfOnError InvalidArgument "1" )
    return $( _ iErrorInvalidArgument )

  fi

  shift

  case "${1,,}" in

      'echo')  cmd='retecho'; shift;;
      'exit')  cmd='exit';    shift;;
      'warn')  cmd='retwarn'; shift;;
     'throw')  cmd='throw';   shift;;
    'return')  cmd='return';  shift;;
   'retwarn')  cmd='retwarn'; shift;;
          '')

               [[ $e =~ ^(Empty|Missing) && ! $e =~ EmptyVariable ]] \
                 || e='MissingArgument'
               eval $( udfOnError $cmd $e 'no arguments' )

           ;;

  esac

  if [[ -z "$@" ]]; then

    [[ $e =~ ^(Empty|Missing) && ! $e =~ ^EmptyVariabl ]] || e='MissingArgument'
    eval $( udfOnError $cmd $e 'no arguments' )

  fi

  for s in "$@"; do

    : $(( j++ ))

    if ! typeset -f "udf${e}" >/dev/null 2>&1; then

      eval $( udfOnError InvalidFunction "udf${e}" )
      continue

    fi

    if udf${e} $s; then

      [[ $s ]] || s=$j

      (( i++ == 0 )) && csv=$s || csv+=", $s"

    fi

  done

  [[ $csv ]] && eval $( udfOnError $cmd ${e} '$csv (total $i)' )

  return 0

}
#******
#****f* libold/udfCommandNotFound
#  SYNOPSIS
#    udfCommandNotFound <filename>
#  DESCRIPTION
#    return true if argument is empty, nonexistent or not executable
#    designed to check the conditions in the function udfOn
#  INPUTS
#    filename - argument for executable file matching by searching the PATH
#  RETURN VALUE
#    0 - no arguments, specified filename is nonexistent or not executable
#    1 - specified filename are found and executable
#  EXAMPLE
#    local cmdYes='sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    udfCommandNotFound                                                         #? true
#    udfCommandNotFound $cmdNo1                                                 #? true
#    $(udfCommandNotFound $cmdNo2 && exit 123)                                  #? 123
#    udfCommandNotFound $cmdYes                                                 #? false
#  SOURCE
udfCommandNotFound() {

  [[ $1 ]] && hash "$1" 2>/dev/null && return 1 || return 0

}
#******
#****f* libold/udfNoSuchFileOrDir
#  SYNOPSIS
#    udfNoSuchFileOrDir <filename>
#  DESCRIPTION
#    return true if argument is empty, nonexistent, designed to check the
#    conditions in the function udfOn
#  ARGUMENTS
#    filename - filesystem object for checking
#  RETURN VALUE
#    0 - no arguments, specified filesystem object is nonexistent
#    1 - specified filesystem object are found
#  EXAMPLE
#    local cmdYes='/bin/sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    udfNoSuchFileOrDir                                                         #? true
#    udfNoSuchFileOrDir $cmdNo1                                                 #? true
#    $(udfNoSuchFileOrDir $cmdNo2 && exit 123)                                  #? 123
#    udfNoSuchFileOrDir $cmdYes                                                 #? false
#  SOURCE
udfNoSuchFileOrDir() {

  [[ $1 && -e "$1" ]] && return 1 || return 0

}
#******
#****f* libold/udfInvalidVariable
#  SYNOPSIS
#    udfInvalidVariable <variable>
#  DESCRIPTION
#    return true if argument is empty, non valid variable, designed to check the
#    conditions in the function udfOn
#  INPUTS
#    variable - expected variable name
#  RETURN VALUE
#    0 - argument is empty, non valid variable
#    1 - valid variable
#  EXAMPLE
#    udfInvalidVariable                                                         #? true
#    udfInvalidVariable a1                                                      #? false
#    $(udfInvalidVariable 2b && exit 123)                                       #? 123
#    $(udfInvalidVariable c3 || exit 123)                                       #? 123
#  SOURCE
udfInvalidVariable() {

  [[ $1 ]] && udfIsValidVariable "$1" && return 1 || return 0

}
#******
#****f* libold/udfEmptyVariable
#  SYNOPSIS
#    udfEmptyVariable <variable>
#  DESCRIPTION
#    return true if argument is empty, non valid or empty variable
#    designed to check the conditions in the function udfOn
#  INPUTS
#    variable - expected variable name
#  RETURN VALUE
#    0 - argument is empty, non valid or empty variable
#    1 - valid not empty variable
#  EXAMPLE
#    local a b="$RANDOM"
#    eval set -- b
#    udfEmptyVariable                                                           #? true
#    udfEmptyVariable a                                                         #? true
#    $(udfEmptyVariable a && exit 123)                                          #? 123
#    $(udfEmptyVariable b || exit 123)                                          #? 123
#    udfEmptyVariable b                                                         #? false
#  SOURCE
udfEmptyVariable() {

  [[ $1 ]] && udfIsValidVariable "$1" && [[ ${!1} ]] && return 1 || return 0

}
#******
#****f* libold/udfEmptyOrMissingArgument
#  SYNOPSIS
#    udfEmptyOrMissingArgument <argument>
#  DESCRIPTION
#    return true if argument is empty
#    designed to check the conditions in the function udfOn
#  INPUTS
#    argument - one argument
#  RETURN VALUE
#    0 - argument is empty
#    1 - not empty argument
#  EXAMPLE
#    local a b="$RANDOM"
#    eval set -- b
#    udfEmptyOrMissingArgument                                                  #? true
#    udfEmptyOrMissingArgument $a                                               #? true
#    $(udfEmptyOrMissingArgument $a && exit 123)                                #? 123
#    $(udfEmptyOrMissingArgument $b || exit 123)                                #? 123
#    udfEmptyOrMissingArgument $b                                               #? false
#  SOURCE
udfEmptyOrMissingArgument() {

  [[ $1 ]] && return 1 || return 0

}
#******
udfMissingArgument() { udfEmptyOrMissingArgument $@; }
udfEmptyArgument()   { udfEmptyOrMissingArgument $@; }
udfEmptyResult()     { udfEmptyOrMissingArgument $@; }
#****f* libold/udfOnCommandNotFound
#  SYNOPSIS
#    udfOnCommandNotFound [<action>] <filenames>
#  DESCRIPTION
#    wrapper to call 'udfOn CommandNotFound ...'
#    see udfOn and udfCommandNotFound
#  INPUTS
#    <action> - same as udfOn
#    <filenames> - list of short filenames
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    MissingArgument - arguments not specified
#    CommandNotFound - one or more of all specified filename is
#                      nonexistent or not executable
#    0               - all specified filenames are found and executable
#  EXAMPLE
#    # see also udfOn CommandNotFound ...
#    local cmd=udfOnCommandNotFound
#    local cmdYes='sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    $cmd                                                                       #? $_bashlyk_iErrorMissingArgument
#    $cmd $cmdNo1                                                               #? $_bashlyk_iErrorCommandNotFound
#    $($cmd $cmdNo2 || exit 123)                                                #? 123
#    $cmd WARN $cmdYes $cmdNo1 $cmdNo2 2>&1 >| grep "Error.*bin.*"              #? true
#    $($cmd Throw $cmdNo2 >/dev/null 2>&1; true)                                #? $_bashlyk_iErrorCommandNotFound
#    $cmd $cmdYes                                                               #? true
#  SOURCE
udfOnCommandNotFound() { udfOn CommandNotFound "$@"; }
#******
#****f* libold/udfThrowOnCommandNotFound
#  SYNOPSIS
#    udfThrowOnCommandNotFound <filenames>
#  DESCRIPTION
#    wrapper to call 'udfOn CommandNotFound throw ...'
#    see udfOn and udfCommandNotFound
#  INPUTS
#    <filenames> - list of short filenames
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnCommandNotFound
#  EXAMPLE
#    local cmdYes="sh" cmdNo="bin_${RANDOM}"
#    udfThrowOnCommandNotFound $cmdYes                                          #? true
#    $(udfThrowOnCommandNotFound >/dev/null 2>&1)                               #? $_bashlyk_iErrorMissingArgument
#    $(udfThrowOnCommandNotFound $cmdNo >/dev/null 2>&1)                        #? $_bashlyk_iErrorCommandNotFound
#  SOURCE
udfThrowOnCommandNotFound() { udfOnCommandNotFound throw $@; }
#******
#****f* libold/udfWarnOnCommandNotFound
#  SYNOPSIS
#    udfWarnOnCommandNotFound <filenames>
#  DESCRIPTION
#    wrapper to call 'udfOn CommandNotFound warn ...'
#    see udfOn udfOnCommandNotFound udfCommandNotFound
#  INPUTS
#    <filenames> - list of short filenames
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnCommandNotFound
#  EXAMPLE
#    local cmd=udfWarnOnCommandNotFound cmdYes="sh" cmdNo="bin_${RANDOM}"
#    $cmd $cmdYes                                                               #? true
#    $cmd $cmdNo 2>&1 >| grep "Error.* command not found - bin_"                #? true
#    $cmd                                                                       #? $_bashlyk_iErrorMissingArgument
#  SOURCE
udfWarnOnCommandNotFound() { udfOnCommandNotFound warn $@; }
#******
#****f* libold/udfOnEmptyVariable
#  SYNOPSIS
#    udfOnEmptyVariable [<action>] <args>
#  DESCRIPTION
#    wrapper to call 'udfOn EmptyVariable ...'
#    see udfOn udfEmptyVariable
#  INPUTS
#    <action> - same as udfOn
#    <args>   - list of variable names
#  RETURN VALUE
#    MissingArgument - no arguments
#    EmptyVariable   - one or more of all specified arguments empty or
#                      non valid variable
#    0               - all arguments are valid and not empty variable
#  OUTPUT
#    see udfOn
#  EXAMPLE
#    # see also udfOn EmptyVariable
#    local cmd=udfOnEmptyVariable sNoEmpty='test' sEmpty='' sMoreEmpty=''
#    $cmd                                                                       #? $_bashlyk_iErrorMissingArgument
#    $cmd sEmpty                                                                #? $_bashlyk_iErrorEmptyVariable
#    $($cmd sEmpty || exit 111)                                                 #? 111
#    $cmd WARN sEmpty sNoEmpty sMoreEmpty 2>&1 >| grep "Error.*y, s"            #? true
#    $cmd Echo sEmpty sMoreEmpty 2>&1 >| grep 'y, s'                            #? true
#    $($cmd  Exit sEmpty >/dev/null 2>&1; true)                                 #? $_bashlyk_iErrorEmptyVariable
#    $($cmd Throw sEmpty >/dev/null 2>&1; true)                                 #? $_bashlyk_iErrorEmptyVariable
#    $cmd sNoEmpty                                                              #? true
#  SOURCE
udfOnEmptyVariable() { udfOn EmptyVariable "$@"; }
#******
#****f* libold/udfThrowOnEmptyVariable
#  SYNOPSIS
#    udfThrowOnEmptyVariable <args>
#  DESCRIPTION
#    stop the script with stack trace call
#    wrapper for 'udfOn EmptyVariable throw ...'
#    see also udfOn udfOnEmptyVariable udfEmptyVariable
#  INPUTS
#    <args> - list of variable names
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnEmptyVariable
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''
#    udfThrowOnEmptyVariable sNoEmpty                                           #? true
#    $(udfThrowOnEmptyVariable sEmpty >/dev/null 2>&1)                          #? $_bashlyk_iErrorEmptyVariable
#  SOURCE
udfThrowOnEmptyVariable() { udfOnEmptyVariable throw "$@"; }
#******
#****f* libold/udfWarnOnEmptyVariable
#  SYNOPSIS
#    udfWarnOnEmptyVariable <args>
#  DESCRIPTION
#    send warning to notification system
#    wrapper for 'udfOn EmptyVariable warn ...'
#    see also udfOn udfOnEmptyVariable udfEmptyVariable
#  INPUTS
#    <args> - list of variable names
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnEmptyVariable
#  EXAMPLE
#    local cmd=udfWarnOnEmptyVariable sNoEmpty='test' sEmpty=''
#    $cmd sNoEmpty                                                              #? true
#    $cmd sEmpty 2>&1 >| grep "Error: empty variable - sEmpty.*"                #? true
#  SOURCE
udfWarnOnEmptyVariable() { udfOnEmptyVariable Warn "$@"; }
#******
#****f* libold/udfOnEmptyOrMissingArgument
#  SYNOPSIS
#    udfOnEmptyOrMissingArgument [<action>] <args>
#  DESCRIPTION
#    wrapper to call 'udfOn EmptyOrMissingArgument ...'
#    see udfOn udfEmptyOrMissingArgument
#  INPUTS
#    <action> - same as udfOn
#    <args>   - list of arguments
#  RETURN VALUE
#    MissingArgument - one or more of all specified arguments empty
#    0               - all arguments are not empty
#  OUTPUT
#   see udfOn
#  EXAMPLE
#    local cmd=udfOnEmptyOrMissingArgument sNoEmpty='test' sEmpty sMoreEmpty
#    $cmd                                                                       #? $_bashlyk_iErrorMissingArgument
#    $cmd "$sEmpty"                                                             #? $_bashlyk_iErrorMissingArgument
#    $($cmd "$sEmpty" || exit 111)                                              #? 111
#    $cmd WARN "$sEmpty" "$sNoEmpty" "$sMoreEmpty" 2>&1 >| grep "Error.*1, 3"   #? true
#    $cmd Echo "$sEmpty" "$sMoreEmpty" 2>&1 >| grep '1, 2'                      #? true
#    $cmd WARN "$sEmpty" "$sNoEmpty" "$sMoreEmpty" 2>&1                         #? $_bashlyk_iErrorMissingArgument
#    $cmd Echo "$sEmpty" "$sMoreEmpty" 2>&1                                     #? $_bashlyk_iErrorMissingArgument
#    $($cmd Exit "$sEmpty" >/dev/null 2>&1; true)                               #? $_bashlyk_iErrorMissingArgument
#    $($cmd Throw "$sEmpty" >/dev/null 2>&1; true)                              #? $_bashlyk_iErrorMissingArgument
#    $cmd "$sNoEmpty"                                                           #? true
#  SOURCE
udfOnEmptyOrMissingArgument() { udfOn EmptyOrMissingArgument "$@"; }
#******
#****f* libold/udfThrowOnEmptyMissingArgument
#  SYNOPSIS
#    udfThrowOnEmptyOrMissingArgument <args>
#  DESCRIPTION
#    wrapper to call 'udfOn EmptyOrMissingArgument throw ...'
#    see udfOn udfOnEmptyOrMissingArgument udfEmptyOrMissingArgument
#  INPUTS
#    <args>   - list of arguments
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnEmptyOrMissingArgument
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''
#    udfThrowOnEmptyVariable sNoEmpty                                           #? true
#    $(udfThrowOnEmptyOrMissingArgument "$sEmpty" >/dev/null 2>&1)              #? $_bashlyk_iErrorMissingArgument
#  SOURCE
udfThrowOnEmptyOrMissingArgument() { udfOnEmptyOrMissingArgument throw "$@"; }
#******
#****f* libold/udfWarnOnEmptyOrMissingArgument
#  SYNOPSIS
#    udfWarnOnEmptyOrMissingArgument <args>
#  DESCRIPTION
#    wrapper to call 'udfOn EmptyOrMissingArgument warn ...'
#    see udfOn udfOnEmptyOrMissingArgument udfEmptyOrMissingArgument
#  INPUTS
#    <args>   - list of arguments
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnEmptyOrMissingArgument
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''
#    udfWarnOnEmptyOrMissingArgument "$sNoEmpty"                                #? true
#    udfWarnOnEmptyOrMissingArgument "$sEmpty" 2>&1 >| grep "Error: empty or.*" #? true
#  SOURCE
udfWarnOnEmptyOrMissingArgument() { udfOnEmptyOrMissingArgument warn "$@"; }
#******
shopt -s expand_aliases
alias try="try()"
alias catch='; eval "$( ERR::__convert_try_to_func )" ||'
#****f* libold/ERR::__add_throw_to_command
#  SYNOPSIS
#    ERR::__add_throw_to_command <command line>
#  DESCRIPTION
#    add controlled trap for errors of the <commandline>
#  INPUTS
#    <commandline> - source command line
#  OUTPUT
#    changed command line
#  NOTES
#    private method, used for 'try ..catch' emulation
#  EXAMPLE
#    local s='command --with -a -- arguments' cmd='ERR::__add_throw_to_command'
#    $cmd $s             >| md5sum | grep ^856f03be5778a30bb61dcd1e2e3fdcde.*-$ #? true
#  SOURCE
ERR::__add_throw_to_command() {

  local s

   s='_bashlyk_sLastError[$BASHPID]="command: $( udfTrim '${*/;/}' )\n output: '
  s+='{\n$('${*/;/}' 2>&1)\n}" && echo -n . || return $?;'

  echo $s

}
#******
#****f* libold/ERR::__convert_try_to_func
#  SYNOPSIS
#    ERR::__convert_try_to_func
#  DESCRIPTION
#    convert "try" block to the function with controlled traps of the errors
#  OUTPUT
#    function definition for evaluate
#  NOTES
#    private method, used for 'try ..catch' emulation
#  TODO
#    error handling for input 'try' function checking not worked
#  EXAMPLE
#    ERR::__convert_try_to_func >| grep "^${TMPDIR}/.*ok.*fail.*; false; }$"    #? true
#  SOURCE
ERR::__convert_try_to_func() {

  local s
  udfMakeTemp -v s

  while read -t 4; do

    if [[ ! $REPLY =~ ^[[:space:]]*(try \(\)|\{|\})[[:space:]]*$ ]]; then

      ERR::__add_throw_to_command $REPLY

    else

      #echo "${REPLY/try/try${s//\//.}}"
      echo "${REPLY/try/$s}"

    fi

  done< <( declare -pf try 2>/dev/null)

  echo $s' && echo " ok." || { udfSetLastError $?; echo " fail..($?)"; false; }'
  rm -f $s

}
#******
#****f* libold/ERR::exception.message
#  SYNOPSIS
#    ERR::exception.message
#  DESCRIPTION
#    show last error status
#  INPUTS
#    used global variables $_bashlyk_{i,s}LastError
#  OUTPUT
#    try show commandline, status(error code) and output
#  ERRORS
#    MissingArgument - _bashlyk_iLastError[$BASHPID] empty
#    NotNumber       - _bashlyk_iLastError[$BASHPID] is not number
#  EXAMPLE
#   _bashlyk_iLastError[$BASHPID]=''
#   ERR::exception.message                                                      #? $_bashlyk_iErrorMissingArgument
#   _bashlyk_iLastError[$BASHPID]='not number'
#   ERR::exception.message                                                      #? $_bashlyk_iErrorNotNumber
#   local s fn                                                                  #-
#   error4test() { echo "${0##*/}: special error for testing"; return 210; };   #-
#   udfMakeTemp fn                                                              #-
#   cat <<-'EOFtry' > $fn                                                       #-
#   try {                                                                       #-
#     uname -a                                                                  #-
#     date -R                                                                   #-
#     uname                                                                     #-
#     error4test                                                                #-
#     true                                                                      #-
#   } catch {                                                                   #-
#                                                                               #-
#     ERR::exception.message                                                    #-
#                                                                               #-
#   }                                                                           #-
#   EOFtry                                                                      #-
#  . $fn                  >| md5sum -| grep ^65128961dfcf8819e88831025ad5f1.*-$ #? true
#  SOURCE
ERR::exception.message() {

  local msg=${_bashlyk_sLastError[$BASHPID]} rc=${_bashlyk_iLastError[$BASHPID]}
  udfIsNumber $rc || return $?

  printf -- "\ntry block exception:\n~~~~~~~~~~~~~~~~~~~~\n status: %s\n" "$rc"

  [[ $msg ]] && printf -- "${msg}\n"

  return $rc

}
#******
#****f* libold/udfIsNumber
#  SYNOPSIS
#    udfIsNumber <number> [<tag>]
#  DESCRIPTION
#    Checking the argument that it is a natural number
#    The argument is considered a number if it contains decimal digits and can
#    have a symbol at the end - a sign of order, for example, k M G T
#    (kilo-, Mega-, Giga-, Terra-)
#  INPUTS
#    <number> - input data
#    <tag>    - a set of characters, one of which is permissible after the
#    digits to indicate a characteristic of a number, for example, of order.
#    (The register does not matter)
#  RETURN VALUE
#    0               - argument is a natural number
#    NotNumber       - argument is not natural number
#    MissingArgument - no arguments
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
#****f* libold/udfShowVariable
#  SYNOPSIS
#    udfShowVariable <var>[,|;| ]...
#  DESCRIPTION
#    Listing the values of the arguments if they are variable names. It is
#    possible to separate the names of variables by the signs ',' and ';',
#    however, it must be remembered that the ';' (Or entire arguments) must be
#    quoted.
#    If the argument is not a valid variable name, an appropriate message is
#    displayed. The function can be used to form the initialization lines for
#    variables, while the information lines are escaped by the ':' command when
#    parsing by the interpreter; they can also be filtered using the command
#    "grep -v '^:'".
#  INPUTS
#    <var> - list of the variables
#  OUTPUT
#    Listing the values of the arguments if they are variable names.
#    Service lines are output with the initial ':' to automatically suppress the
#    execution capability
#  EXAMPLE
#    local s='text' b='true' i=2015 a='true 2015 text'
#    udfShowVariable a,b';' i s 1w >| md5sum - | grep ^72f4ca740b23dcec5a82.*-$ #? true
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

  echo -e ": Variable listing>\n${bashlyk_udfShowVariable_a}"

  return 0

}
#******
#****f* libold/udfIsValidVariable
#  SYNOPSIS
#    udfIsValidVariable <arg>
#  DESCRIPTION
#    Validate <arg> as variable name
#  INPUTS
#    <arg> - expected valid variable name (without leader '$')
#  RETURN VALUE
#    0               - valid variable name
#    MissingArgument - no arguments
#    InvalidVariable - is not valid variable name
#  EXAMPLE
#    udfIsValidVariable                                                         #? $_bashlyk_iErrorMissingArgument
#    udfIsValidVariable "12w"                                                   #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable "a"                                                     #? true
#    udfIsValidVariable "k1"                                                    #? true
#    udfIsValidVariable "&w1"                                                   #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable "#k12s"                                                 #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable ":v1"                                                   #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable "a1-b"                                                  #? $_bashlyk_iErrorInvalidVariable
#  SOURCE
udfIsValidVariable() {

  [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]] && return 0

  udfOn MissingArgument $1 || return

  return $_bashlyk_iErrorInvalidVariable

}
#******
#****f* libold/udfQuoteIfNeeded
#  SYNOPSIS
#    udfQuoteIfNeeded <arg>
#  DESCRIPTION
#    Argument with whitespaces is doublequoted
#  INPUTS
#    <arg> - input
#  OUTPUT
#    doublequoted input with whitespaces
#  EXAMPLE
#    udfQuoteIfNeeded                                                           #? $_bashlyk_iErrorMissingArgument
#    udfQuoteIfNeeded "word"                                 >| grep '^word$'   #? true
#    udfQuoteIfNeeded two words                              >| grep '^\".*\"$' #? true
#  SOURCE
udfQuoteIfNeeded() {

  if [[ "$*" =~ [[:space:]] && ! "$*" =~ ^\".*\"$ ]]; then

    echo "\"$*\""

  else

    [[ $* ]] && echo "$*" || return $_bashlyk_iErrorMissingArgument

  fi

}
#******
#****f* libold/udfWSpace2Alias
#  SYNOPSIS
#    udfWSpace2Alias -|<arg>
#  DESCRIPTION
#    The whitespace in the argument is replaced by the "magic" sequence of
#    characters defined in the global variable $_bashlyk_sWSpaceAlias
#  INPUTS
#    <arg> - input data for conversion
#        - - expected data from the standard input
#  OUTPUT
#   input data with replaced (masked) whitespaces by a special sequence of
#   characters
#  EXAMPLE
#    a=($(udfWSpace2Alias single argument expected ... ))
#    echo ${#a[@]}                                                  >| grep ^1$ #? true
#    a=($(echo single argument expected ... | udfWSpace2Alias -))
#    echo ${#a[@]}                                                  >| grep ^1$ #? true
#  SOURCE
udfWSpace2Alias() {

  local s=$*

  case $* in

    -)
       ## TODO - on/off timeout
       while read s; do

         echo "${s// /$_bashlyk_sWSpaceAlias}"

       done
    ;;

    *)
       echo "${s// /$_bashlyk_sWSpaceAlias}"
    ;;

  esac

}
#******
#****f* libold/udfAlias2WSpace
#  SYNOPSIS
#    udfAlias2WSpace -|<arg>
#  DESCRIPTION
#    If the input contains a sequence of characters defined in the global
#    variable $_bashlyk_WSpase2Alias, then they are replaced by a whitespace.
#    If, as a result of processing data from arguments (not from the standard
#    input), replacements are made for whitespace, then the output is quoted.
#  INPUTS
#    arg - argument
#  OUTPUT
#    input data with "restored" whitespaces
#  EXAMPLE
#    local text s
#    s="${_bashlyk_sWSpaceAlias}"
#    text="many${s}arguments${s}expected${s}..."
#    udfAlias2WSpace $text
#    a=($(udfAlias2WSpace $text))
#    echo ${#a[@]}                                                  >| grep ^4$ #? true
#    a=($(echo $text | udfAlias2WSpace -))
#    echo ${#a[@]}                                                  >| grep ^4$ #? true
#  SOURCE
udfAlias2WSpace() {

  local s=$*

  case "$s" in

    -)
       ## TODO - on/off timeout
       while read s; do

         echo "${s//${_bashlyk_sWSpaceAlias}/ }"

       done
    ;;

    *)
       udfQuoteIfNeeded "${s//${_bashlyk_sWSpaceAlias}/ }"
    ;;

  esac
}
#******
#****f* libold/udfMakeTemp
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
#****f* libold/udfMakeTempV
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
#****f* libold/udfPrepareByType
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
#****f* libold/_
#  SYNOPSIS
#    _ [[<get>]=]<subname> [<value>]
#  DESCRIPTION
#    Special getter/setter for global variables with names like "$_bashlyk_..."
#  INPUTS
#    <get>     - (local) variable for getting value ${_bashlyk_<subname>}, may
#                be supressed if their name equal <subname>
#    <subname> - substantial part of the global variable ${_bashlyk_<subname>}
#    <value>   - new value for ${_bashlyk_<subname>}. The operation takes
#                precedence over the "get" mode
#                Important! If a variable is used as a <value>, then it must
#                be in double quotes, otherwise in the case of an empty value,
#                the meaning of the operation changes from "set" to "get" with
#                the output of the value to STDOUT
#  OUTPUT
#                Output the variable $_bashlyk_<subname> value in get mode
#  ERRORS
#    MissingArgument - no arguments
#    InvalidVariable - invalid variable for "get" mode
#    ## TODO updated needed
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

          udfOn InvalidVariable ${1%=*} || return
          eval "export ${1%=*}=\$$( udfPrepareByType "_bashlyk_${1##*=}" )"

        else

          udfOn InvalidVariable $( udfPrepareByType "${1##*=}" ) || return
          eval "export $( udfPrepareByType "${1##*=}" )=\$$( udfPrepareByType "_bashlyk_${1##*=}" )"

        fi

      ;;

        *) eval "echo \$$( udfPrepareByType "_bashlyk_${1}" )";;

    esac

  fi

  return 0

}
#******
#****f* libold/udfGetMd5
#  SYNOPSIS
#    udfGetMd5 [-]|--file <filename>|<args>
#  DESCRIPTION
#   make MD5 digest for input data
#  INPUTS
#    -                 - data expected from standart input
#    --file <filename> - data is a file
#    <args>            - data is a arguments list
#  OUTPUT
#    MD5 digest only
#  ERRORS
#    EmptyResult - no digest
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
#****f* libold/udfGetPathMd5
#  SYNOPSIS
#    udfGetPathMd5 <path>
#  DESCRIPTION
#   Get recursively MD5 digest of all the non-hidden files in the directory
#   <path>
#  INPUTS
#    <path>  - source path
#  OUTPUT
#    List of MD5 digest with the names of non-hidden files in the directory
#    <path> recursively
#  ERRORS
#    MissingArgument - not arguments
#    NoSuchFileOrDir - path not found
#    NotPermitted    - not permissible
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
#****f* libold/udfXml
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
#****f* libold/udfGetTimeInSec
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
#****f* libold/udfGetFreeFD
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
#****f* libold/udfIsHash
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
#****f* libold/udfTrim
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
#****f* libold/udfCat
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
#****f* libold/udfEcho
#  SYNOPSIS
#    udfEcho [-] <text>
#  DESCRIPTION
#    Build a message from arguments and standard input
#  INPUTS
#    -      - data is read from standard input
#    <text> - is used as a header for a stream from standard input
#  EXAMPLE
#    udfEcho 'test' >| grep -w 'test'                                           #? true
#    echo body | udfEcho - subject >| md5sum - | grep ^472002e8a20e4cf6d78e.*-$ #? true
#  SOURCE
udfEcho() {

  if [[ "$1" == "-" ]]; then

    shift
    [[ $1 ]] && printf -- "%s\n----\n" "$*"

    udfCat -

  else

    [[ $* ]] && echo $*

  fi

}
#******
#****f* libold/udfWarn
#  SYNOPSIS
#    udfWarn [-] <text>
#  DESCRIPTION
#    Show input message or data from special variable. In the case of
#    non-interactive execution  message is sent notification system.
#  INPUTS
#    -      - read message from stdin
#    <text> - message string. With stdin data ("-" option required) used as
#             header. By default ${_bashlyk_sLastError[$BASHPID]}
#  OUTPUT
#   show input message or value of ${_bashlyk_sLastError[$BASHPID]}
#  EXAMPLE
#    # TODO требуется более точная проверка
#    _bashlyk_sLastError[$BASHPID]="udfWarn testing .."
#    local bNotUseLog=$_bashlyk_bNotUseLog
#    _bashlyk_bNotUseLog=1
#    udfWarn                                                                    #? true
#    _bashlyk_bNotUseLog=0
#    date | udfWarn - "bashlyk::libold::udfWarn testing (non-interactive mode)" #? true
#    _bashlyk_bNotUseLog=1
#    date | udfWarn - "udfWarn test int"                                        #? true
#    _bashlyk_bNotUseLog=$bNotUseLog
#  SOURCE
udfWarn() {

  local s IFS=$' \t\n'

  [[ $* ]] && s="$*" || s="${_bashlyk_sLastError[$BASHPID]}"

  [[ "$_bashlyk_bNotUseLog" != "0" ]] && udfEcho $s || udfMessage $s

}
#******
#****f* libold/udfMail
#  SYNOPSIS
#    udfMail [[-] <arg>]
#  DESCRIPTION
#    Send <text> as email
#  INPUTS
#    <arg> - if this is the name of a non-empty existing file, the data is read
#            from it, otherwise the argument string is treated as the message
#            text
#    -     - data is read from standard input
#  ERRORS
#    MissingArgument - no arguments
#    CommandNotFound - 'mail' command not found
#  EXAMPLE
#    echo "notification testing" | udfMail - "bashlyk::libold::udfMail"
#    [ $? -eq $(_ iErrorCommandNotFound) -o $? -eq 0 ] && true                  #? true
#    udfMail -
#    [ $? -eq $(_ iErrorCommandNotFound) -o $? -eq 0 ] && true                  #? true
##   see user (or aliased) mailbox for result checking
#  SOURCE
udfMail() {

  udfOn MissingArgument $1 || return $?

  local sTo=$_bashlyk_sLogin IFS=$' \t\n'

  udfOn CommandNotFound mail || return

  : ${sTo:=$_bashlyk_sUser}
  : ${sTo:=postmaster}

  {

    case "$1" in

      -)

         shift && udfEcho ${*:-empty message}

       ;;

      *)

         [[ -s "$*" ]] && udfCat < "$*" || echo "$*"

       ;;

    esac

  } | mail -s "${_bashlyk_emailSubj}" $_bashlyk_emailOptions $sTo

  return $?

}
#******
#****f* libold/udfMessage
#  SYNOPSIS
#    udfMessage [-] <text>
#  DESCRIPTION
#    Send the message to the active user of the local X-Window desktop or the
#    process owner using one of the available methods:
#    - X-Window desktop notification service
#    - e-mail
#    - 'write' utility or show to the standard output of the script
#  INPUTS
#    -      - data is read from standard input
#    <text> - is used as a header for a stream from standard input
#  ERRORS
#    MissingArgument - no input data
#  EXAMPLE
#    local sBody="notification testing" sSubj="bashlyk::libold::udfMessage"
#    echo "$sBody" | udfMessage - "$sSubj"                                      #? true
#    [[ $rc -eq 0 ]] && sleep 1.5
#  SOURCE
udfMessage() {

  local fnTmp

  udfMakeTemp fnTmp

  ## TODO limit input data for safety
  udfEcho $* > $fnTmp

  [[ -s $fnTmp ]] || return $_bashlyk_MissingArgument

  udfNotify2X $fnTmp || udfMail $fnTmp || {

    [[ $_bashlyk_sLogin ]] && write $_bashlyk_sLogin < $fnTmp

  } || udfCat - < $fnTmp

  rm -f $fnTmp

  return $i

}
#******
#****f* libold/udfNotify2X
#  SYNOPSIS
#    udfNotify2X <arg>
#  DESCRIPTION
#    Sending message through notification services based on X-Window
#  INPUTS
#    <arg> - if this is the name of a non-empty existing file, the data is read
#            from it, otherwise the argument string is treated as the message
#            text
#  ERRORS
#    MissingArgument  - no input data
#    CommandNotFound  - clients  for sending not found
#    XsessionNotFound - X-Session not found
#    NotPermitted     - not permitted
#  EXAMPLE
#    local sBody="notification testing" sSubj="bashlyk::libold::udfNotify2X" rc
#    udfNotify2X "${sSubj}\n----\n${sBody}\n"
#    rc=$?
#    echo $rc >| grep "$(_ iErrorNotPermitted)\|$(_ iErrorXsessionNotFound)\|0" #? true
#    [[ $rc -eq 0 ]] && sleep 1.5
#  SOURCE
udfNotify2X() {

  udfOn MissingArgument $1 || return $?

  local iTimeout=8 s IFS=$' \t\n'

  [[ -s "$*" ]] && s="$( udfCat - < "$*" )" || s="$( printf -- "$*" )"

  for cmd in notify-send kdialog zenity xmessage; do

    udfNotifyCommand $cmd "$(_ emailSubj)" "$s" "$iTimeout" && break

  done

  return $?

}
#******
#****f* libold/udfGetXSessionProperties
#  SYNOPSIS
#    udfGetXSessionProperties
#  DESCRIPTION
#    Get some environment global variables from first local X-Window session
#  ERRORS
#    CommandNotFound  - no commands were found to send the message to the active
#                       X-Window session
#    XsessionNotFound - X-Session not found
#    NotPermitted     - not permitted
#    ## TODO improve test
#  EXAMPLE
#    udfGetXSessionProperties || echo "X-Session error ($?)"
#  SOURCE
udfGetXSessionProperties() {

  local a pid s sB sD sX sudo user userX IFS=$' \t\n'
  local -A h

  a="                                                                          \
                                                                               \
      x-session-manager gnome-session gnome-session-flashback lxsession        \
      mate-session-manager openbox razorqt-session xfce4-session kwin twin     \
                                                                               \
  "

  user=$(_ sUser)

  [[ "$user" == "root" && $SUDO_USER ]] && user=$SUDO_USER

  for s in $a; do h[$s]=1; done

  while read -t 4; do

    h[${REPLY#*Exec=}]=1

  done< <( exec -c grep '^Exec=.*' /usr/share/xsessions/*.desktop 2>/dev/null )

  for s in $a ${!h[@]}; do

    for pid in $( exec -c pgrep -f "${s##*/}" ); do

      userX=$( exec -c stat -c %U /proc/$pid )
      [[ $userX ]] || continue
      [[ "$user" == "$userX" || "$user" == "root" ]] || continue

      ## TODO many X-Sessions ?
      sB="$(exec -c grep -az DBUS_SESSION_BUS_ADDRESS= /proc/${pid}/environ)"
      sD="$(exec -c grep -az DISPLAY= /proc/${pid}/environ)"
      sX="$(exec -c grep -az XAUTHORITY= /proc/${pid}/environ)"

      [[ $sB && $sD && $sX ]] && break 2

   done

  done 2>/dev/null

  [[ $userX ]] || return $_bashlyk_iErrorXsessionNotFound

  [[ $user == $userX || $user == root ]] || return $_bashlyk_iErrorNotPermitted

  [[ $sB && $sD && $sX ]] || return $_bashlyk_iErrorMissingArgument

  [[ $(_ sUser) == root ]] && sudo="sudo -u $userX" || sudo=''

  _ sXSessionProp "$sudo $sD $sX $sB"

  return 0

}
#******
#****f* libold/udfNotifyCommand
#  SYNOPSIS
#    udfNotifyCommand <command> <title> <text> <timeout>
#  DESCRIPTION
#    Sending messages through notification services based on X-Window
#  INPUTS
#    <command> - The notification utility, in this version this is one of:
#                notify-send
#                kdialog
#                zenity
#                xmessage
#      <title> - Message header
#       <text> - Message body
#    <timeout> - Message window time
#       <user> - recipient of the message
#  ERRORS
#    MissingArgument - no arguments
#    CommandNotFound - no commands were found to send the message to the active
#                      X-Window session
#  EXAMPLE
#    local title="bashlyk::libold::udfNotifyCommand" body="notification testing"
#    local rc
#    DEBUGLEVEL=$(( DEBUGLEVEL + 1 ))
#    udfNotifyCommand notify-send $title "$body" 8
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    [[ $rc -eq 0 ]] && sleep 2
#    udfNotifyCommand kdialog     $title "$body" 8
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    [[ $rc -eq 0 ]] && sleep 2
#    udfNotifyCommand zenity      $title "$body" 2
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    [[ $rc -eq 0 ]] && sleep 2
#    udfNotifyCommand xmessage    $title "$body" 4
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    DEBUGLEVEL=$(( DEBUGLEVEL - 1 ))
#  SOURCE
udfNotifyCommand() {

  udfOn MissingArgument $4 || return $?

  local h t rc X IFS=$' \t\n'

  udfIsNumber $4 && t=$4 || t=8

  [[ $( _ sXSessionProp ) ]] || udfGetXSessionProperties || return $?

  X=$( _ sXSessionProp )
  #
  declare -A h=(                                                                                                   \
    [notify-send]="$X $1 -t $t \"$2 via $1\" \"$(printf -- "%s" "$3")\""                                           \
    [kdialog]="$X $1 --title \"$2 via $1\" --passivepopup \"$(printf -- "%s" "$3")\" $t"                           \
    [zenity]="$X $1 --notification --timeout $(($t/2)) --text \"$(printf -- "%s via %s\n\n%s\n" "$2" "$1" "$3")\"" \
    [xmessage]="$X $1 -center -timeout $t \"$(printf -- "%s via %s\n\n%s\n" "$2" "$1" "$3")\""                     \
  )

  if hash "$1" 2>/dev/null; then

    if (( DEBUGLEVEL > 0 )); then

      ## save stderr for debugging
      udfMakeTemp t keep=true prefix='msg.' suffix=".notify_command.${1}.err"

      eval "${h[$1]}" 2>$t
      rc=$?

      [[ -s $t ]] && printf -- "\n%s status: %s\n" "$1" "$rc" >> $t || rm -f $t

    else

      eval "${h[$1]}"
      rc=$?

    fi

    ## TODO workaround for zenity
    [[ "$1" == "zenity" && "$rc" == "5" ]] && rc=0

  else

    rc=$( _ iErrorCommandNotFound )
    udfSetLastError $rc "$1"

  fi

  return $rc

}
#******
#****f* libold/udfCheckStarted
#  SYNOPSIS
#    udfCheckStarted <PID> <args>
#  DESCRIPTION
#    Compare the PID of the process with a command line pattern which must
#    contain the process name
#  ARGUMENTS
#    <PID>  - process id
#    <args> - command line pattern with process name
#  ERRORS
#    NoSuchProcess   - Process for the specified command line is not detected.
#    CurrentProcess  - The process for this command line is identical to the
#                      PID of the current process
#    InvalidArgument - PID is not number
#    MissingArgument - no arguments
#  EXAMPLE
#    (sleep 8)&                                                                 #-
#    local pid=$!                                                               #-
#    ps -p $pid -o pid= -o args=
#    udfCheckStarted                                                            #? $_bashlyk_iErrorMissingArgument
#    udfCheckStarted $pid sleep 8                                               #? true
#    udfCheckStarted $pid sleep 88                                              #? $_bashlyk_iErrorNoSuchProcess
#    udfCheckStarted $$ $0                                                      #? $_bashlyk_iErrorCurrentProcess
#    udfCheckStarted notvalid $0                                                #? $_bashlyk_iErrorInvalidArgument

#  SOURCE
udfCheckStarted() {

  udfOn MissingArgument $* || return

  local re="\\b${1}\\b"

  udfIsNumber $1 || return $( _ iErrorInvalidArgument )

  [[ "$$" == "$1" ]] && return $( _ iErrorCurrentProcess )

  shift

  if [[ $(pgrep -d' ' -f "$*") =~ $re && $(pgrep -d' ' ${1##*/}) =~ $re ]]; then

    return 0

  else

    return $( _ iErrorNoSuchProcess )

  fi
}
#******
#****f* libold/udfStopProcess
#  SYNOPSIS
#    udfStopProcess [pid=PID[,PID,..]] [childs] <command-line>
#  DESCRIPTION
#    Stop the processes associated with the specified command line which must
#    contain the process name. Options allow you to manage the list of processes
#    to stop. The process of the script itself is excluded
#  ARGUMENTS
#    pid=PID[,..]   - comma separated list of PID. Only these processes will be
#                     stopped if they are associated with the command line
#    childs         - stop only child processes
#    <command-line> - command line pattern with process name
#  ERRORS
#    NoSuchProcess   - processes for the specified command is not detected
#    NoChildProcess  - child processes for the specified command line is not
#                      detected.
#    CurrentProcess  - process for this command line is identical to the PID
#                      of the current process, do not stopped
#    InvalidArgument - PID is not number
#    MissingArgument - no arguments
#  EXAMPLE
#    local a cmd1 cmd2 fmt1 fmt2 i pid                                          #-
#    fmt1='#!/bin/bash\nread -t %s -N 0 </dev/zero\n'
#    fmt2='#!/bin/bash\nfor i in 900 700 600 500; do\n%s %s &\ndone\n'
#    udfMakeTemp cmd1
#    udfMakeTemp cmd2
#    printf -- "$fmt1" '$1' | tee $cmd1
#    chmod +x $cmd1
#    printf -- "$fmt2" "$cmd1" '$i' | tee $cmd2
#    chmod +x $cmd2
#    for i in 800 700 600 500; do                                               #-
#    $cmd1 $i &                                                                 #-
#    a+="${!},"                                                                 #-
#    done                                                                       #-
#    $cmd2
#    ($cmd1 400)&                                                               #-
#    pid=$!
#    ## TODO wait for cmd1 starting
#    udfStopProcess                                                             #? $_bashlyk_iErrorMissingArgument
#    udfStopProcess pid=$pid                                                    #? $_bashlyk_iErrorMissingArgument
#    udfStopProcess childs                                                      #? $_bashlyk_iErrorMissingArgument
#    udfStopProcess pid=$pid $cmd1 88                                           #? $_bashlyk_iErrorNoSuchProcess
#    udfStopProcess $cmd1 88                                                    #? $_bashlyk_iErrorNoSuchProcess
#    udfStopProcess pid=$$ $0                                                   #? $_bashlyk_iErrorCurrentProcess
#    udfStopProcess pid=invalid $0                                              #? $_bashlyk_iErrorInvalidArgument
#    udfStopProcess childs pid=$pid $cmd1 400                                   #? true
#    udfStopProcess childs pid=$a $cmd1 800                                     #? true
#    udfStopProcess childs pid=$a $cmd1 600                                     #? $_bashlyk_iErrorNotChildProcess
#    udfStopProcess $cmd1                                                       #? true
#  SOURCE
udfStopProcess() {

  local bChild i iStopped pid rc re s
  local -a a

  for s in $*; do

    case "$s" in

      pid=*)
             i="${s#*=}"
             a=( ${i//,/ } )
             shift
      ;;

      childs)
             bChild=1
             shift
      ;;

    esac

  done

  udfOn MissingArgument $* || return

  rc=$( _ iErrorNoSuchProcess )

  udfOn MissingArgument "${a[*]}" || a=( $( pgrep -d' ' ${1##*/} ) )
  udfOn MissingArgument "${a[*]}" || return $rc

  iStopped=0
  for (( i=0; i<${#a[*]}; i++ )) ; do

    pid=${a[i]}

    if ! udfIsNumber $pid; then

      rc=$( _ iErrorInvalidArgument )
      continue

    fi

    if (( pid == $$ )); then

      rc=$( _ iErrorCurrentProcess )
      continue

    fi

    re="\\b${pid}\\b"

    if [[ $bChild && ! "$( pgrep -P $$ )" =~ $re ]]; then

      rc=$( _ iErrorNotChildProcess )
      continue

    fi

    for s in 15 9; do

      if [[ $(pgrep -d' ' ${1##*/}) =~ $re && $(pgrep -d' ' -f "$*") =~ $re ]]
      then

        if kill -${s} $pid; then

          a[i]=""
          : $(( iStopped++ ))

        else

          rc=$( _ iErrorNotPermitted )

        fi

      else

        a[i]=""
        break

      fi

    done

  done

  s="${a[*]}"

  [[ $iStopped != 0 && -z "${s// /}" ]] || return $rc

  return 0

}
#******
#****f* libold/udfSetPid
#  SYNOPSIS
#    udfSetPid
#  DESCRIPTION
#    Protection against re-run the script with the given arguments. PID file is
#    created when this script is not already running. If the script has
#    arguments, the PID file is created with the name of a MD5-hash this command
#    line, or it is derived from the name of the script.
#  ERRORS
#    AlreadyStarted     - process of command line already started
#    AlreadyLocked      - PID file locked by flock
#    NotExistNotCreated - PID file don't created
#  EXAMPLE
#    local cmd fmt='#!/bin/bash\n%s . bashlyk\n%s || exit $?\n%s\n'             #-
#    udfMakeTemp cmd                                                            #? true
#    printf -- "$fmt" '_bashlyk_log=nouse' 'udfSetPid' 'sleep 8' | tee $cmd
#    chmod +x $cmd                                                              #? true
#    ($cmd)&                                                                    #? true
#    sleep 0.5                                                                  #-
#    ( $cmd || false )                                                          #? false
#    udfSetPid                                                                  #? true
#    test -f $_bashlyk_fnPid                                                    #? true
#    head -n 1 $_bashlyk_fnPid >| grep -w $$                                    #? true
#    rm -f $_bashlyk_fnPid
#  SOURCE
udfSetPid() {

  local fnPid pid

  if [[ -n "$( _ sArg )" ]]; then

    fnPid="$( _ pathRun )/$( udfGetMd5 $( _ s0 ) $( _ sArg ) ).pid"

  else

    fnPid="$( _ pathRun )/$( _ s0 ).pid"

  fi

  mkdir -p "${fnPid%/*}" || on error echo+return NotExistNotCreated ${fnPid%/*}

  fd=$( udfGetFreeFD )
  udfThrowOnEmptyVariable fd

  eval "exec $fd>>${fnPid}"

  [[ -s $fnPid ]] && pid=$( exec -c head -n 1 $fnPid )

  if eval "flock -n $fd"; then

    if udfCheckStarted "$pid" $( _ s0 ) $( _ sArg ); then

      on error echo+return AlreadyStarted $pid

    fi

    if printf -- "%s\n%s\n" "$$" "$0 $( _ sArg )" > $fnPid; then

      _ fnPid $fnPid
      udfAddFO2Clean $fnPid
      udfAddFD2Clean $fd

    else

      on error echo+return NotExistNotCreated $fnPid

    fi

  else

    if udfCheckStarted "$pid" $( _ s0 ) $( _ sArg ); then

      on error echo+return AlreadyStarted $pid

    else

      on error echo+return AlreadyLocked $fnPid

    fi

  fi

  return 0

}
#******
#****f* libold/udfExitIfAlreadyStarted
#  SYNOPSIS
#    udfExitIfAlreadyStarted
#  DESCRIPTION
#    Alias-wrapper for udfSetPid with extended behavior:
#    If command line process already exist then
#    this current process with identical command line stopped
#    else created pid file and current process don`t stopped.
#  ERRORS
#    AlreadyStarted     - PID file exist and command line process already
#                         started, current process stopped
#    NotExistNotCreated - PID file don't created, current process stopped
#  EXAMPLE
#    udfExitIfAlreadyStarted                                                    #? true
#    ## TODO проверка кодов возврата
#  SOURCE
udfExitIfAlreadyStarted() {

  udfSetPid || exit $?

}
#******
udfAddJob2Clean() { return 0; }
#****f* libold/udfAddPid2Clean
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

  trap "udfOnTrap" EXIT INT TERM

}
#******
#****f* libold/udfAddFD2Clean
#  SYNOPSIS
#    udfAddFD2Clean <args>
#  DESCRIPTION
#    add list of filedescriptors for cleaning on exit
#  ARGUMENTS
#    <args> - file descriptors
#  SOURCE
udfAddFD2Clean() {

  udfOn MissingArgument $* || return

  _bashlyk_afdClean[$BASHPID]+=" $*"

  trap "udfOnTrap" EXIT INT TERM

}
#******
#****f* libold/udfAddFO2Clean
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

  udfOn MissingArgument $* || return

  _bashlyk_afoClean[$BASHPID]+=" $*"

  trap "udfOnTrap" EXIT INT TERM

}
#******
udfCleanQueue()    { udfAddFO2Clean $@; }
udfAddFObj2Clean() { udfAddFO2Clean $@; }
udfAddFile2Clean() { udfAddFO2Clean $@; }
udfAddPath2Clean() { udfAddFO2Clean $@; }
#****f* libold/udfOnTrap
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
#****f* libold/udfGetConfig
#  SYNOPSIS
#    udfGetConfig <file>
#  DESCRIPTION
#    Safely reading of the active configuration by using the INI library.
#    configuration source can be a single file or a group of related files. For
#    example, if <file> - is "a.b.c.conf" and it exists, sequentially read
#    "conf", "c.conf", "b.c.conf", "a.b.c.conf" files, if they exist, too.
#    Search  source of the configuration is done on the following criteria (in
#    the absence of the full path):
#      1. in the default directory,
#      2. in the current directory
#      3. in the system directory "/etc"
#  NOTES
#    The file name must not begin with a point or end with a point.
#    configuration sources are ignored if they do not owned by the owner of the
#    process or root.
#  ARGUMENTS
#    <file>     - source of the configuration
#    <variable> - set only this list of the variables from the configuration
#  ERRORS
#    MissingArgument - no arguments
#    NoSuchFileOrDir - configuration file is not found
#    InvalidArgument - name contains the point at the beginning or at the end of
#                      the name
#  EXAMPLE
#    local b confChild confMain pid s s0
#    udfMakeTemp confMain suffix=.conf
#    confChild="${confMain%/*}/child.${confMain##*/}"                           #-
#    udfAddFile2Clean $confChild                                                #-
#    cat <<'EOFconf' > $confMain                                                #-
#                                                                               #-
#    s0=$0                                                                      #-
#    b=true                                                                     #-
#    pid=$$                                                                     #-
#    s="$(uname -a)"                                                            #-
#                                                                               #-
#    EOFconf                                                                    #-
#    cat $confMain
#    udfGetConfig $confMain                                                     #? true
#    echo "$s0 $b $pid $s" >| grep "$0 true $$ $(uname -a)"                     #? true
#    unset b pid s0 s
#    cat <<'EOFchild' > $confChild                                              #-
#                                                                               #-
#    s0=bash                                                                    #-
#    b=false                                                                    #-
#    pid=$$                                                                     #-
#    s="$(uname)"                                                               #-
#    test=test                                                                  #-
#                                                                               #-
#    EOFchild                                                                   #-
#    cat $confChild
#    udfGetConfig $confChild pid,b,test                                         #? true
#    echo "$b $pid $test" >| grep "false $$ test"                               #? true
#    rm -f $confChild
#    _ onError echo+return
#    udfGetConfig $confChild s                                                  #? $_bashlyk_iErrorNoSuchFileOrDir
#    udfGetConfig                                                               #? $_bashlyk_iErrorMissingArgument
#  SOURCE
udfGetConfig() {

  local bashlyk_aconf_MROATHra bashlyk_conf_MROATHra bashlyk_s_MROATHra
  local bashlyk_pathCnf_MROATHra="$_bashlyk_pathCnf" IFS=$' \t\n'

  [[ -n $1 ]] || eval $( udfOnError return iErrorEmptyOrMissingArgument )

  [[ "$1" == "${1##*/}" && -f "${bashlyk_pathCnf_MROATHra}/$1" ]] || bashlyk_pathCnf_MROATHra=
  [[ "$1" == "${1##*/}" && -f "$1" ]] && bashlyk_pathCnf_MROATHra=$(pwd)
  [[ "$1" != "${1##*/}" && -f "$1" ]] && bashlyk_pathCnf_MROATHra=$(dirname $1)

  if [[ ! $bashlyk_pathCnf_MROATHra ]]; then

    if [[ -f "/etc/${_bashlyk_pathPrefix}/$1" ]]; then

      bashlyk_pathCnf_MROATHra="/etc/${_bashlyk_pathPrefix}"

    else

     eval $(udfOnError return iErrorNoSuchFileOrDir)

    fi

  fi

  bashlyk_conf_MROATHra=
  bashlyk_aconf_MROATHra=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

  for bashlyk_s_MROATHra in $bashlyk_aconf_MROATHra; do

    [[ $bashlyk_s_MROATHra ]] || continue

    if [[ $bashlyk_conf_MROATHra ]]; then

      bashlyk_conf_MROATHra="${bashlyk_s_MROATHra}.${bashlyk_conf_MROATHra}"

    else

      bashlyk_conf_MROATHra="$bashlyk_s_MROATHra"

    fi

    if [[ -s "${bashlyk_pathCnf_MROATHra}/${bashlyk_conf_MROATHra}" ]]; then

      . "${bashlyk_pathCnf_MROATHra}/${bashlyk_conf_MROATHra}"

    fi

  done

  return 0

}
#******
#****f* libold/udfSetConfig
#  SYNOPSIS
#    udfSetConfig <file> "<comma separated key=value pairs>;"
#  DESCRIPTION
#    Write to <file> string in the format "key = value" from a fields of the
#    second argument "<CSV>;"
#    In the case where the filename does not contain the path, it is saved in a
#    default directory, or is saved using a full path.
#  ARGUMENTS
#    <file> - file name of the active configuration
#    "<comma separated key=value pairs>;" - CSV-string, divided by ";", fields
#             that contain the data of the form "key = value"
#  NOTES
#    It is important to take the arguments in double quotes, if they contain a
#    whitespace or ';'
#  ERRORS
#    MissingArgument    - no arguments
#    NotExistNotCreated - target file not created or updated
#    InvalidArgument    - name contains the point at the beginning or at the end
#                         of the name
#  EXAMPLE
#    std::temp conf suffix=.conf
#    udfSetConfig $conf "s0=$0;b=true;pid=$$;s=$(uname -a);1nvalid.key=invalid" #? true
#    cat $conf >| grep "s0=$0\|b=true\|pid=$$\|s=\"$(uname -a)\""               #? true
#    rm -f $conf
#  SOURCE
udfSetConfig() {

 local conf IFS=$' \t\n' pathCnf="$_bashlyk_pathCnf"

 [[ -n "$1" && -n "$2" ]] || eval $( udfOnError return MissingArgument )

 #
 [[ "$1" != "${1##*/}" ]] && pathCnf="$( dirname $1 )"

 mkdir -p "$pathCnf" || eval $(udfOnError return NotExistNotCreated '$pathCnf')

 conf="${pathCnf}/${1##*/}"

 [[ ${conf##*/} =~ ^\.|\.$ ]] && $( udfOnError InvalidArgument "${BASH_REMATCH[0]}" )

 {
  echo "# Created $(date -R) by $USER via $0 (pid $$)"
  udfCheckCsv "$2" | tr ';' '\n'
 } >> $conf 2>/dev/null

 return 0

}
#******
#****f* libold/udfLogger
#  SYNOPSIS
#    udfLogger <text>
#  DESCRIPTION
#    add <text> to log file with standart stamps if logging is setted
#  INPUTS
#    <text> - input text
#  OUTPUT
#    There are four possibilities:
#     * stdout only
#     * $_bashlyk_fnLog only
#     * syslog by logger and stdout
#     * syslog by logger and $_bashlyk_fnLog
#  BUGS
#    The time stamp sometimes breaks from the output of the 'date'
#  EXAMPLE
#    local bInteract bNotUseLog bTerminal
#    _ =bInteract
#    _ =bNotUseLog
#    _ =bTerminal
#    local b=true fnExec reT reP s
#    fnExec=$(mktemp --suffix=.sh || tempfile -s .test.sh)
#    reT='[ADFJMNOS][abceglnoprtuyv]{2} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'
#    reP="[[:space:]]$HOSTNAME ${0##*/}\[[[:digit:]]{5}\]:[[:space:]].*"
#    cat <<'EOF' > $fnExec                                                      #-
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)               #-
#    _ fnLog $fnLog                                                             #-
#    _ bInteract 0                                                              #-
#    _ bNotUseLog 0                                                             #-
#    _ bTerminal 0                                                              #-
#    udfSetLogSocket                                                            #-
#    _ fnLog                                                                    #-
#    udfLogger test                                                             #-
#    # date break pid in the stamp                                              #-
#    uname -a                                                                   #-
#    echo $_bashlyk_pidLogSock                                                  #-
#    EOF                                                                        #-
#    . $fnExec
#    kill $_bashlyk_pidLogSock
#    rm -f $_bashlyk_fnLogSock
#    sleep 0.1
#    while read -t9 s; do [[ $s =~ ^${reT}${reP}$ ]] || b=false; done < $fnLog  #-
#    [[ $b == true ]]                                                           #? true
#    cat $fnLog
#    rm -f $fnExec $fnLog
#    _ bInteract "$bInteract"
#    _ bNotUseLog "$bNotUseLog"
#    _ bTerminal "$bTerminal"
#  SOURCE
udfLogger() {

  local bSysLog bUseLog sTagLog IFS=$' \t\n'

  bSysLog=0
  bUseLog=0

  sTagLog="${_bashlyk_s0}[$(printf -- "%05d" $$)]"

  if [[ -z "$_bashlyk_bUseSyslog" || "$_bashlyk_bUseSyslog" -eq 0 ]]; then

    bSysLog=0

  else

    bSysLog=1

  fi

  if [[ $_bashlyk_bNotUseLog ]]; then

    (( $_bashlyk_bNotUseLog != 0 )) && bUseLog=0 || bUseLog=1

  else

    udfCheck4LogUse && bUseLog=1 || bUseLog=0

  fi

  mkdir -p "$_bashlyk_pathLog" \
    || eval $( udfOnError throw NotExistNotCreated "${_bashlyk_pathLog}" )

  udfAddFO2Clean $_bashlyk_pathLog

  case "${bSysLog}${bUseLog}" in

    00)
        echo "$@"
     ;;

    01)
        udfTimeStamp "$HOSTNAME $sTagLog: $*" >> $_bashlyk_fnLog
     ;;

    10)
        echo "$*"
        logger -t "$sTagLog" "$*"
     ;;

    11)
        udfTimeStamp "$HOSTNAME $sTagLog: ${*//%/%%}" >> $_bashlyk_fnLog
        logger -t "$sTagLog" "$*"
     ;;

  esac

}
#******
#****f* libold/udfLog
#  SYNOPSIS
#    udfLog [-] [<text>]
#  DESCRIPTION
#    Wrapper around udfLogger to support stream from standard input
#  INPUTS
#    -      - data is expected from standard input
#    <text> - String (tag) for output.
#             If there is a "-" as the first argument, then the string is
#             considered a prefix (tag) for each line from the standard input.
#  OUTPUT
#   Depends on output parameters
#  EXAMPLE
#    # TODO improved test
#    echo -n . | udfLog -                                  >| grep '^\.$'       #? true
#    echo test | udfLog - tag                              >| grep '^tag test$' #? true
#  SOURCE
udfLog() {

  local sTag s

  if [[ "$1" == "-" ]]; then

    shift
    [[ $* ]] && sTag="$* "

    while read s || [[ $s ]]; do [[ $s ]] && udfLogger "${sTag}${s}"; done

  else

    [[ $* ]] && udfLogger "$*"

  fi

}
#******
#****f* libold/udfIsInteract
#  SYNOPSIS
#    udfIsInteract
#  DESCRIPTION
#    Checking the operating mode of standard input and output devices
#  RETURN VALUE
#    0 - "non-interactive" mode, there is redirection of standard input and/or
#         output
#    1 - "interactive" mode, redirection of standard input and/or output is not
#        detected
#  EXAMPLE
#    udfIsInteract                                                              #? true
#    udfIsInteract                                                              #= false
#  SOURCE
udfIsInteract() {

  [[ -t 1 && -t 0 && $TERM && "$TERM" != "dumb" ]] \
    && _bashlyk_bInteract=1 || _bashlyk_bInteract=0

  return $_bashlyk_bInteract

}
#******
#****f* libold/udfIsTerminal
#  SYNOPSIS
#    udfIsTerminal
#  DESCRIPTION
#    Checking the presence of a control terminal
#  RETURN VALUE
#    0 - terminal not detected
#    1 - terminal detected
#  EXAMPLE
#    udfIsTerminal                                                              #? false
#    udfIsTerminal                                                              #= false
#  SOURCE
udfIsTerminal() {

  tty > /dev/null 2>&1 && _bashlyk_bTerminal=1 || _bashlyk_bTerminal=0
  return $_bashlyk_bTerminal

}
#******
#****f* libold/udfCheck4LogUse
#  SYNOPSIS
#    udfCheck4LogUse
#  DESCRIPTION
#    Check the conditions for using the log file
#  RETURN VALUE
#    0 - save stdout and stderr to log file
#    1 - logging do not required
#  EXAMPLE
#    _bashlyk_sCond4Log='redirect'
#    udfCheck4LogUse                                                            #? true
#    udfCheck4LogUse                                                            #= false
#  SOURCE
udfCheck4LogUse() {

  udfIsTerminal
  udfIsInteract

  case ${_bashlyk_sCond4Log} in

    redirect)
              _bashlyk_bNotUseLog=$_bashlyk_bInteract ;;
      noterm)
              _bashlyk_bNotUseLog=$_bashlyk_bTerminal ;;
           *)
              _bashlyk_bNotUseLog=$_bashlyk_bInteract ;;
  esac

  return $_bashlyk_bNotUseLog

}
#******
#****f* libold/udfSetLogSocket
#  SYNOPSIS
#    udfSetLogSocket
#  DESCRIPTION
#    Creating a named pipe for redirecting the output of stdout and stderr to a
#     log file with automatic addition of standard stamps.
#  ERRORS
#     1                  - The socket is not created, but the output of the
#                          stdout and the stderr is redirected to the log file
#                          (without stamps)
#     NotExistNotCreated - The socket directory does not exist and can not be
#                          created
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)
#    _ fnLog $fnLog                                                             #? true
#    udfSetLogSocket                                                            #? true
#    ls -l $fnLog                                                               #? true
#    rm -f $fnLog
#  SOURCE
udfSetLogSocket() {

  local fnSock IFS=$' \t\n'

  if [[ $_bashlyk_sArg ]]; then

    fnSock="$(udfGetMd5 ${_bashlyk_s0} ${_bashlyk_sArg}).${$}.socket"
    fnSock="${_bashlyk_pathRun}/${fnSock}"

  else

    fnSock="${_bashlyk_pathRun}/${_bashlyk_s0}.${$}.socket"

  fi

  mkdir -p ${_bashlyk_pathRun} \
    || eval $( udfOnError retwarn NotExistNotCreated "${_bashlyk_pathRun}" )

  [[ -a "$fnSock" ]] && rm -f $fnSock

  if mkfifo -m 0600 $fnSock >/dev/null 2>&1; then

    ( udfLog - < $fnSock )&
    _bashlyk_pidLogSock=$!
    exec >>$fnSock 2>&1

    _bashlyk_fnLogSock=$fnSock
     udfAddFO2Clean $fnSock

     return 0

  else

    udfWarn "Warn: Socket $fnSock not created..."

    exec >>$_bashlyk_fnLog 2>&1

    _bashlyk_fnLogSock=$_bashlyk_fnLog

    return 1

  fi

}
#******
#****f* libold/udfSetLog
#  SYNOPSIS
#    udfSetLog [<filename>]
#  DESCRIPTION
#    Wrapper around udfSetLogSocket to activate output redirection to the log
#    file with error handling
#  ERRORS
#     NotExistNotCreated - log file can not be created, abort
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)
#    rm -f $fnLog
#    udfSetLog $fnLog                                                           #? true
#    ls -l $fnLog                                                               #? true
#    rm -f $fnLog
#  SOURCE
udfSetLog() {

  local IFS=$' \t\n'

  case "$1" in
          '') ;;
    ${1##*/}) _bashlyk_fnLog="${_bashlyk_pathLog}/$1";;
           *)
              _bashlyk_fnLog="$1"
              _bashlyk_pathLog=${_bashlyk_fnLog%/*}
           ;;
  esac

  mkdir -p "$_bashlyk_pathLog" \
    || eval $(udfOnError throw NotExistNotCreated "$_bashlyk_pathLog")

  touch "$_bashlyk_fnLog" \
    || eval $(udfOnError throw NotExistNotCreated "$_bashlyk_fnLog")

  udfSetLogSocket

  return 0

}
#******
#****f* libold/udfDebug
#  SYNOPSIS
#    udfDebug <level> <message>
#  DESCRIPTION
#    show a <message> on stderr if the <level> is equal or less than the
#    $DEBUGLEVEL value otherwise return code 1
#  INPUTS
#    <level>   - decimal number of the debug level ( 0 for wrong argument)
#    <message> - debug message
#  OUTPUT
#    show a <message> on stderr
#  RETURN VALUE
#    0               - <level> equal or less than $DEBUGLEVEL value
#    1               - <level> more than $DEBUGLEVEL value
#    MissingArgument - no arguments
#  EXAMPLE
#    DEBUGLEVEL=0
#    udfDebug                                                                   #? $_bashlyk_iErrorMissingArgument
#    udfDebug 0 echo level 0                                                    #? true
#    udfDebug 1 silence level 0                                                 #? 1
#    DEBUGLEVEL=5
#    udfDebug 0 echo level 5                                                    #? true
#    udfDebug 6 echo 5                                                          #? 1
#    udfDebug default level test '(0)'                                          #? true
#  SOURCE
udfDebug() {

  udfOn MissingArgument $* || return

  if [[ $1 =~ ^[0-9]+$ ]]; then

    (( ${DEBUGLEVEL:=0} >= $1 )) && shift || return 1

  fi

  [[ $* ]] && echo "$*" >&2

  return 0

}
#******
#****f* libold/udfTimeStamp
#  SYNOPSIS
#    udfTimeStamp <text>
#  DESCRIPTION
#    Show input <text> with time stamp in format 'Mar 28 10:03:40' (LC_ALL=C)
#  INPUTS
#    <text> - suffix to the header
#  OUTPUT
#    input <text> with time stamp in format 'Mar 28 10:03:40' (LC_ALL=C)
#  EXAMPLE
#    local r
#    r='^[ADFJMNOS][abceglnoprtuyv]{2} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} A%B$'
#    udfTimeStamp A%B >| grep -E "$r"                                           #? true
#  SOURCE

readonly _bashlyk_iStartTimeStamp=$( exec -c date "+%s" )

udfTimeStamp() { LC_ALL=C date "+%b %d %H:%M:%S ${*//%/%%}"; }

udfDateR()     { exec -c date -R; }

udfUptime()    { echo $(( $(exec -c date "+%s") - _bashlyk_iStartTimeStamp )); }

#******
#****f* libold/udfDateR
#  SYNOPSIS
#    udfDateR
#  DESCRIPTION
#    show 'date -R' like output
#  EXAMPLE
#    udfDateR >| grep -P "^\S{3}, \d{2} \S{3} \d{4} \d{2}:\d{2}:\d{2} .\d{4}$"  #? true
#  SOURCE
#******
#****f* libold/udfUptime
#  SYNOPSIS
#    udfUptime
#  DESCRIPTION
#    show uptime value in the seconds
#  EXAMPLE
#    udfUptime >| grep "^[[:digit:]]*$"                                         #? true
#  SOURCE
#******
#****f* libold/udfFinally
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
