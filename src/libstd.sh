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
: ${_bashlyk_sArg:=$*}
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
 local s b=1
 printf "\n- libstd.sh tests: "
 udfIsNumber "$(date +%S)"      && echo -n '.' || { echo -n '?'; b=0; }
 udfIsNumber "$(date +%S)k" kMG && echo -n '.' || { echo -n '?'; b=0; }
 udfIsNumber "$(date +%S)M"     && { echo -n '?'; b=0; } || echo -n '.'
 udfIsNumber "$(date +%b)G" kMG && { echo -n '?'; b=0; } || echo -n '.'
 udfIsNumber "$(date +%b)"      && { echo -n '?'; b=0; } || echo -n '.'
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 printf "\n--\n\n"
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

