#!/bin/bash
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
#  SOURCE
[ -n "$_BASHLYK_LIBSTD" ] && return 0 || _BASHLYK_LIBSTD=1
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
#****f* bashlyk/libstd/udfBaseId
#  SYNOPSIS
#    udfBaseId
#  DESCRIPTION
#    Alias для команды basename
#  OUTPUT
#    Короткое имя запущенного сценария без расширения ".sh"
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
#  SOURCE
udfDate() {
 date "+%b %d %H:%M:%S $*"
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
#    Вызывает останов сценария, если аргументы, как имена переменных, содержат пустые значения
#  INPUTS
#    args - имена переменных
#  OUTPUT
#    Сообщение об ошибке с перечислением имен переменных, которые содержат
#    пустые значения
#  RETURN VALUE
#    0   - переменные не содержат пустые значения
#    255 - есть не инициализированные переменные
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
#    Аргумент считается числом, если он содержит
#  INPUTS
#    number - проверяемое значение
#    tag    - набор символов, один из которых можно применить
#             после цифр для указания признака числа, например, 
#             порядка
#  RETURN VALUE
#    0 - аргумент является натуральным числом
#    1 - аргумент не является натуральным числом
#    2 - аргумент не задан
#  EXAMPLE
#    udfIsNumber $iSize kMG
#    Возвращает 0 если $iSize содержит число вида 12,34k,67M или 89G
#  SOURCE
udfIsNumber() {
 [ -n "$1" ] || return 2
 local s=''
 [ -n "$2" ] && s="[$2]?"
 case "$(echo "$1" | grep -E "^[[:digit:]]+${s}$")" in
  '') return 1;;
   *) return 0;;
 esac
}
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
#    выполнение: udfWSpace2Alias a b  cd
#         вывод: a___b______cd
#  SOURCE
udfWSpace2Alias() {
 case "$1" in
 -) sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
 *) echo "$*" | sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
 esac
}
#******
#****f* bashlyk/libopt/udfAlias2WSpace
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
#    выполнение: udfWSpace2Alias a___b______cd
#         вывод: "a b  cd"
#    выполнение: echo a___b______cd | udfWSpace2Alias -
#         вывод: a b  cd
#  SOURCE
udfAlias2WSpace() {
 case "$1" in
 -) sed -e "s/$_bashlyk_sWSpaceAlias/ /g";;
 *) udfQuoteIfNeeded $(echo "$*" | sed -e "s/$_bashlyk_sWSpaceAlias/ /g");;
 esac 
}
#******
#****u* bashlyk/libstd/udfLibStd
#  SYNOPSIS
#    udfLibStd
# DESCRIPTION
#   bashlyk STD library test unit
#   Запуск проверочных операций модуля выполняется если только аргументы 
#   командной строки cодержат строку вида "--bashlyk-test=[.*,]std[,.*]",
#   где * - ярлыки на другие тестируемые библиотеки
#  SOURCE
udfLibStd() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -E -e "--bashlyk-test=.*std")" ] \
  && return 0
 local s b=1 s0='' s1="test" fnTmp
 printf "\n- libstd.sh tests: "
 fnTmp=/tmp/$$.$(date +%s).tmp
 {
  udfIsNumber "$(date +%S)"      && echo -n '.' || { echo -n '?'; b=0; }
  udfIsNumber "$(date +%S)k" kMG && echo -n '.' || { echo -n '?'; b=0; }
  udfIsNumber "$(date +%S)M"     && { echo -n '?'; b=0; } || echo -n '.'
  udfIsNumber "$(date +%b)G" kMG && { echo -n '?'; b=0; } || echo -n '.'
  udfIsNumber "$(date +%b)"      && { echo -n '?'; b=0; } || echo -n '.'
 [ -n "$(udfShowVariable s1 | grep 's1=test')" ] && echo -n '.' || { echo -n '?'; b=0; }
  udfOnEmptyVariable Warn s0     && { echo -n '?'; b=0; } || echo -n '.' 
  udfOnEmptyVariable Warn s1     && echo -n '.' || { echo -n '?'; b=0; }
 } 2>/dev/null
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 echo "--"
 return 0
}
#******
#****** bashlyk/libstd/Main section
# DESCRIPTION
#   Running LOG library test unit if $_bashlyk_sArg ($*) contains
#   substrings "--bashlyk-test=" and "std" - command for test using
#  SOURCE
udfLibStd
#******

