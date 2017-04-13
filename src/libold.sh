#
# $Id: libold.sh 733 2017-04-13 09:58:01+04:00 toor $
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
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libcsv.sh ]] && . "${_bashlyk_pathLib}/libcsv.sh"
#******
#****G* libold/Global variables
#  DESCRIPTION
#    global variables of the library
#  SOURCE
#: ${_bashlyk_bSetOptions:=}
#: ${_bashlyk_csvOptions2Ini:=}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_ini_void_autoKey_}
: ${_bashlyk_reMetaRules:='34=":40=(:41=):59=;:91=[:92=\\:93=]:61=='}


declare -rg _bashlyk_exports_old="                                             \
                                                                               \
    _ARGUMENTS _gete _getv _pathDat _fnLog _s0 _set udfCsvKeys2Var             \
    udfCsvOrder2Var udfGetCsvSection2Var udfGetIni2Var udfGetIniSection2Var    \
    udfIni2CsvVar udfIniGroup2CsvVar udfIniGroupSection2CsvVar                 \
    udfIniSection2CsvVar udfReadIniSection2Var                                 \
                                                                               \
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

