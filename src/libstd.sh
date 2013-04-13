#
# $Id$
#
#****h* bashlyk/libstd
#  DESCRIPTION
#    bashlyk Std library
#    стандартный набор функций
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/libstd/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$_BASHLYK_LIBSTD" ] && return 0 || _BASHLYK_LIBSTD=1
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
#******
#****v*  bashlyk/libstd/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#    * $_bashlyk_sArg - аргументы командной строки вызова сценария
#    * $_bashlyk_sWSpaceAlias - заменяющая пробел последовательность символов
#    * $_bashlyk_aRequiredCmd_opt - список используемых в данном модуле внешних
#    утилит
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathDat:=/tmp}
: ${_bashlyk_sWSpaceAlias:=___}
: ${_bashlyk_s0:=$(basename $0)}
: ${_bashlyk_sId:=$(basename $0 .sh)}
: ${_bashlyk_afnClean:=}
: ${_bashlyk_apathClean:=}
: ${_bashlyk_ajobClean:=}
: ${_bashlyk_apidClean:=}
: ${_bashlyk_pidLogSock:=}
: ${_bashlyk_sUser:=$USER}
: ${HOSTNAME:=$(hostname)}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_aRequiredCmd_std:="[ basename cat chgrp chmod chown date dir echo false file grep kill mail mkdir mktemp printf ps rm rmdir sed sleep tee tempfile touch true w which xargs"}
: ${_bashlyk_aExport_std:="udfBaseId udfDate udfEcho udfMail udfWarn udfThrow udfOnEmptyVariable udfThrowOnEmptyVariable udfWarnOnEmptyVariable udfShowVariable udfIsNumber udfIsValidVariable udfQuoteIfNeeded udfWSpace2Alias udfAlias2WSpace udfMakeTemp  udfMakeTempV udfShellExec udfAddFile2Clean udfAddPath2Clean udfAddJob2Clean udfAddPid2Clean udfCleanQueue udfOnTrap _ARGUMENTS _s0  _pathDat _ _set _get _gete _getv"}
#******
#****f* bashlyk/libstd/udfBaseId
#  SYNOPSIS
#    udfBaseId
#  DESCRIPTION
#    Alias для команды basename
#  OUTPUT
#    Короткое имя запущенного сценария без расширения ".sh"
#  EXAMPLE
#    udfBaseId | grep -w "^$(basename $0 .sh)$"                                 ##udfBaseId ? true 
#  SOURCE
udfBaseId() {
 basename $0 .sh
}
#******
#****f* bashlyk/libstd/udfDate
#  SYNOPSIS
#    udfDate <args>
#  DESCRIPTION
#    Alias для команды date
#  INPUTS
#    <args> - суффикс к форматной строке текущей даты
#  OUTPUT
#    текущая дата с возможным суффиксом
#  EXAMPLE
#    udfDate 'test' | grep -E ".* [[:digit:]]+:[[:digit:]]+:[[:digit:]]+ test"  ##udfDate ? true 
#  SOURCE
udfDate() {
 date "+%b %d %H:%M:%S $*"
}
#******
#****f* bashlyk/libstd/udfEcho
#  SYNOPSIS
#    udfEcho [-] args
#  DESCRIPTION
#    Сборка сообщения из аргументов и стандартного ввода
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то эта строка выводится заголовком для данных
#           из стандартного ввода
#  OUTPUT
#   Зависит от параметров вывода
#  EXAMPLE
#    udfEcho 'test' | grep -w 'test'                                            ##udfEcho ? true 
#    echo body | udfEcho - subject | tr -d '\n' | grep -w "^subject----body$"   ##udfEcho ? true
#  SOURCE
udfEcho() {
 if [ "$1" = "-" ]; then
  shift
  [ -n "$1" ] && printf "%s\n----\n" "$*"
  cat
 else
  [ -n "$1" ] && echo $*
 fi
}
#******
#****f* bashlyk/libstd/udfMail
#  SYNOPSIS
#    udfMail [[-] args]
#  DESCRIPTION
#    Передача сообщения по почте
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то эта строка выводится заголовком для данных
#           из стандартного ввода
#  EXAMPLE
#    local emailOptions=$(_ emailOptions)                                       ##udfMail
#    _ emailOptions '-v'                                                        ##udfMail
#    date | udfMail - test                                                      ##udfMail ? true
#    _ emailOptions $emailOptions                                               ##udfMail
#  SOURCE
udfMail() {
 local fnTmp rc
 udfMakeTemp fnTmp
 udfEcho "$*" | tee -a $fnTmp
 cat $fnTmp | mail -e -s "${_bashlyk_emailSubj}" ${_bashlyk_emailOptions} \
  ${_bashlyk_emailRcpt}
 rc=$?
 rm -f $fnTmp
 return $rc
}
#******
#****f* bashlyk/libstd/udfWarn
#  SYNOPSIS
#    udfWarn [-] args
#  DESCRIPTION
#    Вывод предупреждающего сообщения. Если терминал отсутствует, то
#    сообщение передается по почте.
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то строка выводится заголовком для данных
#           из стандартного ввода
#  OUTPUT
#   Зависит от параметров вывода
#  EXAMPLE
#    local bNotUseLog=$_bashlyk_bNotUseLog                                      ##udfWarn
#    _bashlyk_bNotUseLog=0 date | udfWarn - test                                ##udfWarn ? true
#    _bashlyk_bNotUseLog=1 date | udfWarn - test                                ##udfWarn ? true
#    _bashlyk_bNotUseLog=$bNotUseLog                                            ##udfWarn
#  SOURCE
udfWarn() {
 [ $_bashlyk_bNotUseLog -ne 0 ] && udfEcho $* || udfMail $*
}
#******
#****f* bashlyk/libstd/udfThrow
#  SYNOPSIS
#    udfThrow [-] args
#  DESCRIPTION
#    Вывод аварийного сообщения с завершением работы. Если терминал отсутствует,
#    то сообщение передается по почте.
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то строка выводится заголовком для данных
#           из стандартного ввода
#  OUTPUT
#   Зависит от параметров вывода
#  EXAMPLE
#    $(udfThrow test; true)                                                     ##udfThrow ? false
#  SOURCE
udfThrow() {
 udfWarn $*
 exit 255
}
#******
#****f* bashlyk/libstd/udfOnEmptyVariable
#  SYNOPSIS
#    udfOnEmptyVariable [Warn | Throw ] args
#  DESCRIPTION
#    Вызывает останов или выдает предупреждение, если аргументы - имена 
#    переменных - содержат пустые значения
#  INPUTS
#    Warn  - вывод предупреждения
#    Throw - останов сценария (по умолчанию)
#    args  - имена переменных
#  OUTPUT
#    Сообщение об ошибке с перечислением имен переменных, 
#    которые содержат пустые значения
#  RETURN VALUE
#    0   - переменные не содержат пустые значения
#    255 - есть не инициализированные переменные
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''                                            ##udfOnEmptyVariable
#    $(udfOnEmptyVariable sNoEmpty)                                             ##udfOnEmptyVariable ? true
#    $(udfOnEmptyVariable sEmpty >/dev/null 2>&1; true)                         ##udfOnEmptyVariable ? false
#  SOURCE
udfOnEmptyVariable() {
 local bashlyk_EysrBRwAuGMRNQoG_a bashlyk_tfAFyKrLgSeOatp2_s s='Throw'
 case "$1" in
  "Warn")
   s='Warn'; shift;;
  "Throw")
   s='Throw'; shift;;
 esac
 for bashlyk_tfAFyKrLgSeOatp2_s in $*; do
  [ -z "${!bashlyk_tfAFyKrLgSeOatp2_s}" ] \
   && bashlyk_EysrBRwAuGMRNQoG_a+=" $bashlyk_tfAFyKrLgSeOatp2_s"
 done
 [ -n "$bashlyk_EysrBRwAuGMRNQoG_a" ] && {
  udf${s} "Error: Variable(s) or option(s) ($bashlyk_EysrBRwAuGMRNQoG_a ) is empty..."
  return 255
 }
 return 0
}
#******
#****f* bashlyk/libstd/udfThrowOnEmptyVariable
#  SYNOPSIS
#    udfThrowOnEmptyVariable args
#  DESCRIPTION
#    Вызывает останов сценария, если аргументы, как имена переменных, содержат
#    пустые значения
#  INPUTS
#    args - имена переменных
#  OUTPUT
#    Сообщение об ошибке с перечислением имен переменных, которые содержат
#    пустые значения
#  RETURN VALUE
#    0   - переменные не содержат пустые значения
#    255 - есть не инициализированные переменные
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''                                            ##udfThrowOnEmptyVariable
#    $(udfThrowOnEmptyVariable sNoEmpty >/dev/null 2>&1)                        ##udfThrowOnEmptyVariable ? true
#    $(udfThrowOnEmptyVariable sEmpty >/dev/null 2>&1)                          ##udfThrowOnEmptyVariable ? false
#  SOURCE
udfThrowOnEmptyVariable() {
 udfOnEmptyVariable Throw $*
}
#******
#****f* bashlyk/libstd/udfWarnOnEmptyVariable
#  SYNOPSIS
#    udfWarnOnEmptyVariable args
#  DESCRIPTION
#    Выдаёт предупреждение, если аргументы - имена переменных - содержат пустые
#    значения
#  INPUTS
#    args - имена переменных
#  OUTPUT
#    Сообщение об ошибке с перечислением имен переменных, которые содержат
#    пустые значения
#  RETURN VALUE
#    0   - переменные не содержат пустые значения
#    255 - есть не инициализированные переменные
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''                                            ##udfWarnOnEmptyVariable
#    udfWarnOnEmptyVariable sNoEmpty                                            ##udfWarnOnEmptyVariable ? true
#    udfWarnOnEmptyVariable sEmpty                                              ##udfWarnOnEmptyVariable ? false
#  SOURCE
udfWarnOnEmptyVariable() {
 udfOnEmptyVariable Warn $*
}
#******
#****f* bashlyk/libstd/udfShowVariable
#  SYNOPSIS
#    udfShowVariable args
#  DESCRIPTION
#    Выводит значения аргументов, если они являются переменными
#  INPUTS
#    args - имена переменных
#  OUTPUT
#    Имя переменной и значение в виде <Имя>=<Значение>
#  EXAMPLE
#    local sTest='test'                                                         ##udfShowVariable
#    udfShowVariable sTest | grep -w 'sTest=test'                               ##udfShowVariable ? true
#  SOURCE
udfShowVariable() {
 local bashlyk_aSE10yGYS4AwxLJA_a bashlyk_G9WOnrBkEFSt9oKw_s
 for bashlyk_G9WOnrBkEFSt9oKw_s in $*; do
  bashlyk_aSE10yGYS4AwxLJA_a+="\t${bashlyk_G9WOnrBkEFSt9oKw_s}=${!bashlyk_G9WOnrBkEFSt9oKw_s}\n"
 done
 echo -e "Variable listing:\n${bashlyk_aSE10yGYS4AwxLJA_a}"
 return 0
}
#******
#****f* bashlyk/libstd/udfIsNumber
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
#    0 - аргумент является натуральным числом
#    1 - аргумент не является натуральным числом
#    2 - аргумент не задан
#  EXAMPLE
#    udfIsNumber 12                                                             ##udfIsNumber ? true
#    udfIsNumber 34k k                                                          ##udfIsNumber ? true
#    udfIsNumber 67M kMGT                                                       ##udfIsNumber ? true
#    udfIsNumber 89G G                                                          ##udfIsNumber ? true
#    udfIsNumber 12,34                                                          ##udfIsNumber ? false 
#    udfIsNumber 12T                                                            ##udfIsNumber ? false 
#    udfIsNumber 1O2                                                            ##udfIsNumber ? false 
#    udfIsNumber                                                                ##udfIsNumber ? false 
#  SOURCE
udfIsNumber() {
 [ -n "$1" ] || return 2
 local s=''
 [ -n "$2" ] && s="[$2]?"
 case "$(echo "$1" | grep -i -E "^[[:digit:]]+${s}$")" in
  '') return 1;;
   *) return 0;;
 esac
}
#******
#****f* bashlyk/libstd/udfIsValidVariable
#  SYNOPSIS
#    udfIsVariable <arg>
#  DESCRIPTION
#    Проверка аргумента на то, что он может быть валидным идентификатором
#    переменной 
#  INPUTS
#    arg - проверяемое значение
#  RETURN VALUE
#    0 - аргумент является валидным идентификатором
#    1 - аргумент не является валидным идентификатором
#    2 - аргумент не задан
#  EXAMPLE
#    udfIsValidVariable                                                         ##udfIsValidVariable ? false 
#    udfIsValidVariable "12"                                                    ##udfIsValidVariable ? false 
#    udfIsValidVariable "_a"                                                    ##udfIsValidVariable ? true
#    udfIsValidVariable "k1"                                                    ##udfIsValidVariable ? true                                                  
#  SOURCE
udfIsValidVariable() {
 [ -n "$1" ] || return 2
 case "$(echo "$1" | grep -E '^[_a-zA-Z]+[_a-zA-Z0-9]+$')" in
  '') return 1;;
   *) return 0;;
 esac
}
#******
#****f* bashlyk/libstd/udfQuoteIfNeeded
#  SYNOPSIS
#    udfQuoteIfNeeded <arg>
#  DESCRIPTION
#   Аргумент, содержащий пробел(ы) отмечается кавычками
#  INPUTS
#    arg - argument
#  OUTPUT
#    аргумент с кавычками, если есть пробелы
#  EXAMPLE
#    udfQuoteIfNeeded "word" | grep '^word$'                                    ##udfQuoteIfNeeded ? true 
#    udfQuoteIfNeeded two words | grep '^".*"$'                                 ##udfQuoteIfNeeded ? true 
#  SOURCE
udfQuoteIfNeeded() {
 [ -n "$(echo "$*" | grep -e [[:space:]])" ] && echo "\"$*\"" || echo "$*"
}
#******
#****f* bashlyk/libstd/udfWSpace2Alias
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
#    udfWSpace2Alias 'a b  cd' | grep  '^a___b______cd$'                        ##udfWSpace2Alias ? true 
#    echo 'a b  cd' | udfWSpace2Alias - | grep '^a___b______cd$'                ##udfWSpace2Alias ? true 
#  SOURCE
udfWSpace2Alias() {
 case "$1" in
 -) sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
 *) echo "$*" | sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
 esac
}
#******
#****f* bashlyk/libstd/udfAlias2WSpace
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
#    udfAlias2WSpace a___b______cd | grep '^"a b  cd"$'                         ##udfAlias2WSpace ? true
#    echo a___b______cd | udfAlias2WSpace - | grep '^a b  cd$'                  ##udfAlias2WSpace ? true
#  SOURCE
udfAlias2WSpace() {
 case "$1" in
 -) sed -e "s/$_bashlyk_sWSpaceAlias/ /g";;
 *) udfQuoteIfNeeded "$(echo "$*" | sed -e "s/$_bashlyk_sWSpaceAlias/ /g")";;
 esac 
}
#******
#****f* bashlyk/libstd/udfMakeTemp
#  SYNOPSIS
#    udfMakeTemp [varname] options...
#  DESCRIPTION
#    Создание временного файла или каталога
#  INPUTS
#    varname=[<varid>] - идентификатор переменной для возврата результата, если
#                        аргумент не именной, то должен быть всегда первый
#    path=<path>       - каталог, в котором будут создаваться временные объекты
#    prefix=<prefix>   - префикс имени временного объекта
#    suffix=<suffix>   - суффикс имени временного объекта
#    mode=<mode>       - права на временный объект
#    owner=<owner>     - владелец временного объекта
#    group=<group>     - группа временного объекта
#    type=file|dir     - тип объекта: файл или каталог
#    keep=true|false   - удалять/не удалять временные объекты после завершения
#                        сценария (удалять по умолчанию)
#  OUTPUT
#    вывод происходит если нет аргументов или отсутствует именной аргумент
#    varname, если временный объект не создан, то ничего не выдается
#
#  RETURN VALUE
#     0  - Выполнено успешно
#     1  - временный объект файловой системы не создан
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    254 - неожиданная ошибка
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#
#  EXAMPLE
#    local foTemp                                                               ##udfMakeTemp
#    udfMakeTemp foTemp path=$HOME prefix=pre. suffix=.suf                      ##udfMakeTemp
#    ls $foTemp | grep -w "$HOME/pre\.........\.suf"                            ##udfMakeTemp ? true
#    udfMakeTemp foTemp type=dir mode=0751                                      ##udfMakeTemp
#    echo $foTemp                                                               ##udfMakeTemp
#    ls -ld $foTemp                                                             ##udfMakeTemp
#    ls -ld $foTemp | grep "^drwxr-x--x.*${foTemp}$"                            ##udfMakeTemp ? true
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.suf)                              ##udfMakeTemp
#    echo $foTemp                                                               ##udfMakeTemp
#    ls $foTemp | grep "pre\.........\.suf$"                                    ##udfMakeTemp ? true
#    rm -f $foTemp                                                              ##udfMakeTemp
#    $(udfMakeTemp foTemp prefix=pre. suffix=.suf)                              ##udfMakeTemp
#    test -f $foTemp                                                            ##udfMakeTemp ? false
#  SOURCE
udfMakeTemp() {
 local bashlyk_foResult_ioAUaE5R bashlyk_optDir_ioAUaE5R bashlyk_s_ioAUaE5R
 local bashlyk_bNoKeep_ioAUaE5R bashlyk_sVar_ioAUaE5R bashlyk_sGroup_ioAUaE5R
 local bashlyk_sCreateMode_ioAUaE5R bashlyk_path_ioAUaE5R bashlyk_sUser_ioAUaE5R
 local bashlyk_sPrefix_ioAUaE5R bashlyk_sSuffix_ioAUaE5R bashlyk_rc_ioAUaE5R
 local bashlyk_octMode_ioAUaE5R
 #
 bashlyk_bNoKeep_ioAUaE5R=true
 bashlyk_sCreateMode_ioAUaE5R=direct
 #
 for bashlyk_s_ioAUaE5R in $*; do
  case "$bashlyk_s_ioAUaE5R" in
     path=*) bashlyk_path_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
   prefix=*) bashlyk_sPrefix_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
   suffix=*) bashlyk_sSuffix_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
     mode=*) bashlyk_octMode_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
    type=d*) bashlyk_optDir_ioAUaE5R='-d';;
    type=f*) bashlyk_optDir_ioAUaE5R='';;
     user=*) bashlyk_sUser_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
    group=*) bashlyk_sGroup_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
    keep=t*) bashlyk_bNoKeep_ioAUaE5R=false;;
    keep=f*) bashlyk_bNoKeep_ioAUaE5R=true;;
  varname=*) bashlyk_sVar_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
          *)
            bashlyk_sVar_ioAUaE5R="$1"
            udfIsNumber "$2"
            bashlyk_rc_ioAUaE5R=$?
            if [ -z "$3" -a -n "$2" -a $bashlyk_rc_ioAUaE5R -eq 0 ]; then
             # oldstyle
             bashlyk_octMode_ioAUaE5R="$2"
             bashlyk_sVar_ioAUaE5R=''
             bashlyk_sPrefix_ioAUaE5R="$1"
            fi
          ;;
  esac
 done

 if [ -n "$bashlyk_sVar_ioAUaE5R" ]; then
  udfIsValidVariable "$bashlyk_sVar_ioAUaE5R" || return 2
 else
  bashlyk_bNoKeep_ioAUaE5R=false
 fi

 if [ -f "$(which mktemp)" ]; then
  bashlyk_sCreateMode_ioAUaE5R=mktemp
 elif [ -f "$(which tempfile)" ]; then
  [ -z "$bashlyk_optDir_ioAUaE5R" ] \
   && bashlyk_sCreateMode_ioAUaE5R=tempfile \
   || bashlyk_sCreateMode_ioAUaE5R=direct
 fi

 case "$bashlyk_sCreateMode_ioAUaE5R" in
    direct)
   [ -n "$bashlyk_path_ioAUaE5R"    ] \
    && bashlyk_s_ioAUaE5R="${bashlyk_path_ioAUaE5R}/" \
    || bashlyk_s_ioAUaE5R="/tmp/"
   bashlyk_s_ioAUaE5R+="${bashlyk_sPrefix_ioAUaE5R}${$}${bashlyk_sSuffix_ioAUaE5R}"
   [ -n "$bashlyk_optDir_ioAUaE5R"  ] \
    && mkdir -p $bashlyk_s_ioAUaE5R \
    || touch $bashlyk_s_ioAUaE5R
   [ -n "$bashlyk_octMode_ioAUaE5R" ] \
    && chmod $bashlyk_octMode_ioAUaE5R $bashlyk_s_ioAUaE5R
  ;;
    mktemp)
   if [ -n "$bashlyk_path_ioAUaE5R" ]; then
    mkdir -p ${bashlyk_path_ioAUaE5R}
    bashlyk_path_ioAUaE5R="--tmpdir=${bashlyk_path_ioAUaE5R}"
   fi
   if [ -n "$bashlyk_sPrefix_ioAUaE5R" ]; then
    bashlyk_sPrefix_ioAUaE5R=$(echo $bashlyk_sPrefix_ioAUaE5R | tr -d '/')
   fi
   if [ -n "${bashlyk_sSuffix_ioAUaE5R}" ]; then
    bashlyk_sSuffix_ioAUaE5R="--suffix=$(echo ${bashlyk_sSuffix_ioAUaE5R} | tr -d '/')"
   fi
   bashlyk_s_ioAUaE5R=$(mktemp $bashlyk_path_ioAUaE5R $bashlyk_optDir_ioAUaE5R \
    ${bashlyk_sSuffix_ioAUaE5R} "${bashlyk_sPrefix_ioAUaE5R}XXXXXXXX")

   [ -n "$bashlyk_octMode_ioAUaE5R" ] \
    && chmod $bashlyk_octMode_ioAUaE5R $bashlyk_s_ioAUaE5R
  ;;
  tempfile)
   [ -n "$bashlyk_sPrefix_ioAUaE5R" ] \
    && bashlyk_sPrefix_ioAUaE5R="-p $bashlyk_sPrefix_ioAUaE5R"
   [ -n "$bashlyk_sSuffix_ioAUaE5R" ] \
    && bashlyk_sSuffix_ioAUaE5R="-s $bashlyk_sSuffix_ioAUaE5R"
   bashlyk_s_ioAUaE5R=$(tempfile $bashlyk_optDir_ioAUaE5R \
    $bashlyk_sPrefix_ioAUaE5R $bashlyk_sSuffix_ioAUaE5R)
  ;;
  *)
    return 254
  ;;
 esac
 [ -n "$bashlyk_sUser_ioAUaE5R"  ] \
  && chown $bashlyk_sUser_ioAUaE5R  $bashlyk_s_ioAUaE5R
 [ -n "$bashlyk_sGroup_ioAUaE5R" ] \
  && chgrp $bashlyk_sGroup_ioAUaE5R $bashlyk_s_ioAUaE5R

 if   [ -f "$bashlyk_s_ioAUaE5R" ]; then
  $bashlyk_bNoKeep_ioAUaE5R && udfAddFile2Clean $bashlyk_s_ioAUaE5R
 elif [ -d "$bashlyk_s_ioAUaE5R" ]; then
  $bashlyk_bNoKeep_ioAUaE5R && udfAddPath2Clean $bashlyk_s_ioAUaE5R
 else
  return 1
 fi

 bashlyk_foResult_ioAUaE5R=$bashlyk_s_ioAUaE5R
 if [ -n "$bashlyk_sVar_ioAUaE5R" ]; then
  eval 'export ${bashlyk_sVar_ioAUaE5R}=${bashlyk_foResult_ioAUaE5R}'
 else
  echo ${bashlyk_foResult_ioAUaE5R}
 fi
 return $?
}
#******
#****f* bashlyk/libstd/udfMakeTempV
#  SYNOPSIS
#    udfMakeTempV <var> [file|dir|keep|keepf[ile*]|keepd[ir]] [<prefix>]
#  DESCRIPTION
#    Создание временного файла или каталога с автоматическим удалением
#    по завершению сценария
#    устаревшая - заменяется udfMakeTemp
#  INPUTS
#    var        - переменная (без $) для имени временного объекта
#    file       - создавать файл (по умолчанию)
#    dir        - создавать каталог
#    keep[file] - не включать автоматическое удаление временного файла
#    keepdir    - не включать автоматическое удаление временного каталога
#    prefix     - префикс имени временного файла
#  RETURN VALUE
#    255 - аргумент не задан
#      1 - ошибка идентификатора для временного объекта
#      0 - Выполнено успешно
#  EXAMPLE
#    udfMakeTempV pathTmp keepdir temp
#    присваивает значение вида "temp<8 символов>" переменной $pathTmp и создаёт 
#    соответствующий временный каталог, который не будет удаляться по завершении
#    сценария автоматически
#    udfMakeTempV fnTmp $(date +%s)-
#    присваивает значение вида "<секунды эпохи>-<8 симолов>" переменной $fnTmp и
#    создаёт соответствующий временный файл, который может быть удалён по 
#    завершении сценария автоматически
#  SOURCE
udfMakeTempV() {
 [ -n "$1" ] || return 255
 udfIsValidVariable "$1" \
  || udfThrow "Error: required valid variable name \"$1\""

 local bashlyk_foResult_bPfWZngu bashlyk_sDir_bPfWZngu bashlyk_bKeep_bPfWZngu
 local bashlyk_pathTmp_bPfWZngu bashlyk_sPrefix_bPfWZngu
 #
 bashlyk_sDir_bPfWZngu=''
 bashlyk_bKeep_bPfWZngu=0
 #
 [ -n "$3" ] && bashlyk_sPrefix_bPfWZngu="$3"
 case "$2" in 
          dir) bashlyk_sDir_bPfWZngu='-d' ;;
  keep|keepf*) bashlyk_bKeep_bPfWZngu=1;;
       keepd*) bashlyk_bKeep_bPfWZngu=1; bashlyk_sDir_bPfWZngu="-d";;
            *) bashlyk_sPrefix_bPfWZngu="$2";;
 esac
 if [ -d "$bashlyk_sPrefix_bPfWZngu" ]; then
  TMPDIR=$bashlyk_sPrefix_bPfWZngu
  bashlyk_sPrefix_bPfWZngu=$(basename $bashlyk_sPrefix_bPfWZngu)
  bashlyk_pathTmp_bPfWZngu=TMPDIR
 fi
 bashlyk_foResult_bPfWZngu=$(mktemp $bashlyk_sDir_bPfWZngu -q \
  -t "${bashlyk_sPrefix_bPfWZngu}XXXXXXXX") || udfThrow \
   "Error: temporary file object $bashlyk_foResult_bPfWZngu do not created..."
 TMPDIR=bashlyk_pathTmp_bPfWZngu
 if [ $bashlyk_bKeep_bPfWZngu -eq 0 ]; then
  [ -f $bashlyk_foResult_bPfWZngu ] \
   && udfAddFile2Clean $bashlyk_foResult_bPfWZngu
  [ -d $bashlyk_foResult_bPfWZngu ] \
   && udfAddPath2Clean $bashlyk_foResult_bPfWZngu
 fi
 eval 'export ${1}=${bashlyk_foResult_bPfWZngu}' 2>/dev/null
 return $?
}
#******
#****f* bashlyk/libstd/udfShellExec
#  SYNOPSIS
#    udfShellExec args
#  DESCRIPTION
#    Выполнение командной строки во внешнем временном файле
#    в текущей среде интерпретатора оболочки
#  INPUTS
#    args - командная строка
#  RETURN VALUE
#    255 - аргумент не задан
#    в остальных случаях код возврата командной строки с учетом доступа к временному файлу
#  EXAMPLE
#    udfShellExec 'true; false'                                                 ##udfShellExec ? false
#    udfShellExec 'false; true'                                                 ##udfShellExec ? true
#  SOURCE
udfShellExec() {
 [ -n "$*" ] || return 255
 local fn rc
 udfMakeTemp fn
 echo $* > $fn
 . $fn
 rc=$?
 rm -f $fn
 return $rc
}
#******
#****f* bashlyk/libstd/udfAddFile2Clean
#  SYNOPSIS
#    udfAddFile2Clean args
#  DESCRIPTION
#    Добавляет имена файлов к списку удаляемых при завершении сценария
#    Предназначен для удаления временных файлов.
#  INPUTS
#    args - имена файлов
#  EXAMPLE
#    local fnTemp                                                               ##udfAddFile2Clean
#    udfMakeTemp fnTemp keep=true                                               ##udfAddFile2Clean
#    test $(udfAddFile2Clean $fnTemp)                                           ##udfAddFile2Clean
#    test -f $fnTemp                                                            ##udfAddFile2Clean ? false
#  SOURCE
udfAddFile2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_afnClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* bashlyk/libstd/udfAddPath2Clean
#  SYNOPSIS
#    udfAddPath2Clean args
#  DESCRIPTION
#    Добавляет имена каталогов к списку удаляемых при завершении сценария.
#    Предназначен для удаления временных каталогов (если они пустые).
#  INPUTS
#    args - имена каталогов
#  EXAMPLE
#    local pathTemp                                                             ##udfAddPath2Clean
#    udfMakeTemp pathTemp keep=true type=dir                                    ##udfAddPath2Clean
#    test $(udfAddFile2Clean $pathTemp)                                         ##udfAddPath2Clean
#    test -f $pathTemp                                                          ##udfAddPath2Clean ? false
#  SOURCE
udfAddPath2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_apathClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* bashlyk/libstd/udfAddJob2Clean
#  SYNOPSIS
#    udfAddJob2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных заданий к списку удаляемых при
#    завершении сценария.
#  INPUTS
#    args - идентификаторы заданий
#  SOURCE
udfAddJob2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_ajobClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* bashlyk/libstd/udfAddPid2Clean
#  SYNOPSIS
#    udfAddPid2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных процессов к списку завершаемых при
#    завершении сценария.
#  INPUTS
#    args - идентификаторы процессов
#  SOURCE
udfAddPid2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_apidClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* bashlyk/libstd/udfCleanQueue
#  SYNOPSIS
#    udfCleanQueue args
#  DESCRIPTION
#    Псевдоним для udfAddFile2Clean. (Устаревшее)
#  INPUTS
#    args - имена файлов
#  SOURCE
udfCleanQueue() {
 udfAddFile2Clean $*
}
#******
#****f* bashlyk/libstd/udfOnTrap
#  SYNOPSIS
#    udfOnTrap
#  DESCRIPTION
#    Процедура очистки при завершении вызвавшего сценария.
#    Предназначен только для вызова командой trap.
#    * Производится удаление файлов и пустых каталогов; заданий и процессов,
#    указанных в соответствующих глобальных переменных
#    * Закрывается сокет журнала сценария, если он использовался.
#  EXAMPLE
#    local fnTemp pathTemp pid                                                  ##udfOnTrap
#    udfMakeTemp fnTemp                                                         ##udfOnTrap
#    udfMakeTemp pathTemp type=dir                                              ##udfOnTrap
#    (sleep 1024)&                                                              ##udfOnTrap
#    pid=$!                                                                     ##udfOnTrap
#    echo $pid                                                                  ##udfOnTrap
#    udfAddPid2Clean $pid                                                       ##udfOnTrap
#    udfAddFile2Clean $fnTemp                                                   ##udfOnTrap
#    udfAddPath2Clean $pathTemp                                                 ##udfOnTrap
#    udfOnTrap                                                                  ##udfOnTrap
#    test -f $fnTemp                                                            ##udfOnTrap ? false
#    test -d $pathTemp                                                          ##udfOnTrap ? false
#    ps -p $pid -o pid= | grep -w $pid                                          ##udfOnTrap ? false
#  SOURCE
udfOnTrap() {
 local i s
 #
 for s in ${_bashlyk_ajobClean}; do
  kill $s 2>/dev/null
 done
 #
 for s in ${_bashlyk_apidClean}; do
  for i in 15 9; do
   [ -n "$(ps -o pid= --ppid $$ | xargs | grep -w $s)" ] && {
    kill -${i} $s 2>/dev/null
    sleep 0.2
   }
  done
 done
 #
 for s in ${_bashlyk_afnClean}; do
  rm -f $s
 done
 #
 for s in ${_bashlyk_apathClean}; do
  rmdir $s 2>/dev/null
 done
 #
 [ -n "${_bashlyk_pidLogSock}" ] && {
  exec >/dev/null 2>&1
  wait ${_bashlyk_pidLogSock}
 }
}
#******
#****f* bashlyk/libstd/_ARGUMENTS
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
#    local ARGUMENTS=$(_ARGUMENTS)                                              ##_ARGUMENTS
#    _ARGUMENTS | grep "^${_bashlyk_sArg}$"                                     ##_ARGUMENTS ? true
#    _ARGUMENTS "test"                                                          ##_ARGUMENTS
#    _ARGUMENTS | grep -w "^test$"                                              ##_ARGUMENTS ? true
#    _ARGUMENTS $ARGUMENTS                                                      ##_ARGUMENTS
#  SOURCE
_ARGUMENTS() {
 [ -n "$1" ] && _bashlyk_sArg="$*" || echo ${_bashlyk_sArg}
}
#******
#****f* bashlyk/libstd/_s0
#  SYNOPSIS
#    _s0
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_s0 -
#    короткое имя сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  OUTPUT
#    Вывод значения переменной $_bashlyk_s0
#  EXAMPLE
#    local s0=$(_s0)                                                            ##_s0
#    _s0 | grep -w "^${_bashlyk_s0}$"                                           ##_s0 ? true
#    _s0 "test"                                                                 ##_s0
#    _s0 | grep -w "^test$"                                                     ##_s0 ? true
#    _s0 $s0                                                                    ##_s0
#  SOURCE
_s0() {
 [ -n "$1" ] && _bashlyk_s0="$*" || echo ${_bashlyk_s0}
}
#******
#****f* bashlyk/libstd/_pathDat
#  SYNOPSIS
#    _pathDat
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_pathDat -
#    полное имя каталога данных сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  OUTPUT
#    Вывод значения переменной $_bashlyk_pathDat
#  EXAMPLE
#    local pathDat=$(_pathDat)                                                  ##_pathDat
#    _pathDat | grep -w "^${_bashlyk_pathDat}$"                                 ##_pathDat ? true
#    _pathDat "/tmp/testdat.$$/lib"                                             ##_pathDat
#    _pathDat | grep -w "^/tmp/testdat.$$/lib$"                                 ##_pathDat ? true
#    rmdir $(_pathDat)                                                          ##_pathDat
#    _pathDat $pathDat                                                          ##_pathDat
#  SOURCE
_pathDat() {
 if [ -n "$1" ]; then
  _bashlyk_pathDat="$*"
  mkdir -p $_bashlyk_pathDat
 else
  echo ${_bashlyk_pathDat}
 fi
}
#******
#****f* bashlyk/libstd/_
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
#  OUTPUT
#    Вывод значения переменной $_bashlyk_<subname> в режиме get, если не указана
#    приемная переменная и нет знака "="
#  EXAMPLE
#    local sS sWSpaceAlias                                                      ##_
#    _ sS=sWSpaceAlias                                                          ##_
#    echo "$sS" | grep -w "^${_bashlyk_sWSpaceAlias}$"                          ##_? true
#    _ =sWSpaceAlias                                                            ##_
#    echo "$sWSpaceAlias" | grep -w "^${_bashlyk_sWSpaceAlias}$"                ##_ ? true
#    _ sWSpaceAlias | grep -w "^${_bashlyk_sWSpaceAlias}$"                      ##_ ? true
#    _ sWSpaceAlias _-_                                                         ##_
#    _ sWSpaceAlias | grep -w "^_-_$"                                           ##_ ? true
#  SOURCE
_(){
 [ -n "$1" ] || return 255
 if [ -n "$2" ]; then
  eval "_bashlyk_${1##*=}=${2}"
 else
  case "$1" in
   *=*)
        local k v
        k=${1%=*}
        v=${1##*=}
        [ -n "$k" ] || k=$v
        udfIsValidVariable "$k" || return 254
        eval "export $k="'$_bashlyk_'"${v}"
        ;;
     *) eval "echo "'$_bashlyk_'"${1}";;
  esac
 fi
 return 0
}
#******
#****f* bashlyk/libstd/_getv
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
#  EXAMPLE
#    local sS sWSpaceAlias                                                      ##_getv
#    _getv sWSpaceAlias sS                                                      ##_getv
#    echo "$sS" | grep -w "^${_bashlyk_sWSpaceAlias}$"                          ##_getv ? true
#    _getv sWSpaceAlias                                                         ##_getv 
#    echo "$sWSpaceAlias" | grep -w "^${_bashlyk_sWSpaceAlias}$"                ##_getv ? true
#  SOURCE
_getv() {
 if [ -n "$2" ]; then
  udfIsValidVariable "$2" || return 255
  eval "export $2="'$_bashlyk_'"${1}"
 else
  udfIsValidVariable "$1" || return 255
  eval "export $1="'$_bashlyk_'"${1}"
 fi
 return 0
}
#******
#****f* bashlyk/libstd/_gete
#  SYNOPSIS
#    _gete <subname>
#  DESCRIPTION
#    Вывести значение глобальной переменной $_bashlyk_<subname>
#  INPUTS
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#  EXAMPLE
#    _gete sWSpaceAlias | grep -w "^${_bashlyk_sWSpaceAlias}$"                  ##_gete ? true
#  SOURCE
_gete() {
 [ -n "$1" ] || return 255
 eval "echo "'$_bashlyk_'"${1}"
}
#******
#****f* bashlyk/libstd/_set
#  SYNOPSIS
#    _set <subname> [<value>]
#  DESCRIPTION
#    установить (set) значение глобальной переменной $_bashlyk_<subname>
#  INPUTS
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#    <value>   - новое значение, в случае отсутствия - пустая строка
#  EXAMPLE
#    _set sWSpaceAlias _-_                                                      ##_set
#    _ sWSpaceAlias | grep -w "^_-_$"                                           ##_set ? true
#  SOURCE
_set() {
 [ -n "$1" ] || return 255
 eval "_bashlyk_$1=$2"
}
#******
