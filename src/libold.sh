#
# $Id: libold.sh 628 2016-12-19 00:29:51+04:00 toor $
#
#****h* BASHLYK/libold
#  DESCRIPTION
#    Управление пассивными конфигурационными файлов в стиле INI. Имеется
#    возможность подгрузки исполнимого контента
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libold/Required Once
#  DESCRIPTION
#    Глобальная переменная $_BASHLYK_LIBINI обеспечивает
#    защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
[[ $_BASHLYK_LIBOLD ]] && return 0 || _BASHLYK_LIBOLD=1
#******
#****** libold/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s "${_bashlyk_pathLib}/libstd.sh" ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s "${_bashlyk_pathLib}/libopt.sh" ]] && . "${_bashlyk_pathLib}/libopt.sh"
[[ -s "${_bashlyk_pathLib}/libcsv.sh" ]] && . "${_bashlyk_pathLib}/libcsv.sh"
#******
#****v* libold/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:="$@"}
: ${_bashlyk_pathIni:=$(pwd)}
: ${_bashlyk_bSetOptions:=}
: ${_bashlyk_csvOptions2Ini:=}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_ini_void_autoKey_}
: ${_bashlyk_aRequiredCmd_ini:="awk cat cut dirname echo false grep mawk mkdir \
  mv printf pwd rm sed sort touch tr true uniq xargs"}
: ${_bashlyk_aExport_ini:="udfCsvKeys2Var udfCsvOrder2Var udfGetCsvSection2Var \
  udfGetIni2Var udfGetIniSection2Var udfIni2CsvVar udfIniGroup2CsvVar          \
  udfIniGroupSection2CsvVar udfIniSection2CsvVar udfReadIniSection2Var"}
#******
#****f* libold/udfGetIniSection2Var
#  SYNOPSIS
#    udfGetIniSection <varname> <file> [<section>]
#  DESCRIPTION
#    поместить результат вызова udfGetIniSection в переменную <varname>
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента
#              считываются данные до первого заголовка секции [<...>] данных или
#              до конца конфигурационного файла, если секций нет
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде
#              CSV; строки формата "ключ=значение;" будет помещен в
#              соответствующую переменную.
#  RETURN VALUE
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfGetIniSection
#  SOURCE
udfGetIniSection2Var() {
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfGetIniSection "$2" $3)"'
 return 0
}
#******
#****f* libold/udfReadIniSection2Var
#  SYNOPSIS
#    udfReadIniSection2Var <varname> <file> [<section>]
#  DESCRIPTION
#    поместить результат вызова udfReadIniSection в переменную <varname>
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента
#              считываются данные до первого заголовка секции [<...>] данных
#              или до конца конфигурационного файла, если секций нет
#    varname - идентификатор переменной (без "$"). При его наличии результат
#              будет помещен в соответствующую переменную. При отсутствии такого
#              идентификатора результат будет выдан на стандартный вывод
#  RETURN VALUE
#     0                           - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    #пример приведен в описании udfIniGroup2Csv
#  SOURCE
udfReadIniSection2Var() {
 local IFS=$' \t\n'
 [[ -n "$2" && -f "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfReadIniSection "$2" $3)"'
 return 0
}
#******
#****f* libold/udfCsvOrder2Var
#  SYNOPSIS
#    udfCsvOrder2Var <varname> <csv;>
#  DESCRIPTION
#    поместить результат вызова udfCsvOrder в переменную <varname>
#  INPUTS
#    csv;    - CSV-строка, разделённая ";", поля которой содержат данные вида
#              "key=value"
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде
#              разделённой символом ";" CSV-строки, поля которого содержат
#              данные в формате "<key>=<value>;...", будет помещен в
#              соответствующую переменну.
#  RETURN VALUE
#   0                            - Выполнено успешно
#   iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#   iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfCsvOrder
#  SOURCE
udfCsvOrder2Var() {
 local IFS=$' \t\n'
 #
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfCsvOrder "$2")"'
 return 0
}
#******
#****f* libold/udfCsvKeys2Var
#  SYNOPSIS
#    udfCsvKeys2Var <varname> <csv;>
#  DESCRIPTION
#    Поместить вывод udfCsvKeys в переменную <varname>
#  INPUTS
#    csv;  - CSV-строка, разделённая ";", поля которой содержат данные вида
#            "key=value"
#  varname - валидный идентификатор переменной. Результат в виде строки ключей,
#            разделенной пробелами, будет помещёна в соответствующую переменную
#  RETURN VALUE
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfCsvKeys
#  SOURCE
udfCsvKeys2Var() {
 local IFS=$' \t\n'
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfCsvKeys "$2")"'
 return 0
}
#******
#****f* libold/udfGetIni2Var
#  SYNOPSIS
#    udfGetIni2Var <varname> <file> [<section>] ...
#  DESCRIPTION
#    Поместить вывод udfGetIni в переменную <varname>
#  INPUTS
#    file    - файл конфигурации формата "*.ini".
#    varname - валидный идентификатор переменной. Результат в виде
#              CSV-строки в формате "[section];<key>=<value>;..." будет
#              помещён в соответствующую переменную
#    section - список имен секций, данные которых нужно получить
#  RETURN VALUE
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - не валидный идентификатор переменной
#    iErrorEmptyOrMissingArgument - аргументы отсутствуют
#  EXAMPLE
#    #пример приведен в описании udfGetIni
#  SOURCE
udfGetIni2Var() {
 local bashlyk_GetIni2Var_ini="$2" bashlyk_GetIni2Var_s="$1" IFS=$' \t\n'
 #
 [[ -n "$2" && -f "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 shift 2
 eval 'export ${bashlyk_GetIni2Var_s}="$(udfGetIni ${bashlyk_GetIni2Var_ini} $*)"'
 return 0
}
#******
#****f* libold/udfGetCsvSection2Var
#  SYNOPSIS
#    udfGetCsvSection <varname> <csv> [<tag>]
#  DESCRIPTION
#    поместить результат вызова udfGetCsvSection в переменную <varname>
#  INPUTS
#    tag     - имя ini-секции
#    csv     - строка сериализации данных ini-файлов
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде
#              CSV; строки формата "ключ=значение;" будет помещен в
#              соответствующую переменную.
#  RETURN VALUE
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - отсутствует аргумент
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
 local IFS=$' \t\n'
 #
 [ -n "$2" ] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfGetCsvSection "$2" $3)"'
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
#  RETURN VALUE
#     0  - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    #пример приведен в описании udfIniGroupSection2Csv
#  SOURCE
udfIniSection2CsvVar() {
 local IFS=$' \t\n'
 #
 [[ -n "$2" && -f "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfIniSection2Csv "$2" $3)"'
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
#  RETURN VALUE
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfIniGroupSection2Csv
#  SOURCE
udfIniGroupSection2CsvVar() {
 local IFS=$' \t\n'
 #
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfIniGroupSection2Csv "$2" $3)"'
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
#  RETURN VALUE
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfIni2Csv
#  SOURCE
udfIni2CsvVar() {
 local IFS=$' \t\n'
 #
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfIni2Csv "$2")"'
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
#  RETURN VALUE
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfIniGroup2Csv
#  SOURCE
udfIniGroup2CsvVar() {
 local IFS=$' \t\n'
 #
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfIniGroup2Csv "$2")"'
 return 0
}
#******
