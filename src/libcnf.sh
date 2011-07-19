#!/bin/bash
#
# $Id$
#
#****h* bashlyk/libcnf
#  DESCRIPTION
#    bashlyk CNF library
#    Чтение/запись файлов конфигураций
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/libcnf/Required Once
#  DESCRIPTION
#    Глобальная переменная $_BASHLYK_LIBCNF обеспечивает
#    защиту от повторного использования данного модуля
#  SOURCE
[ -n "$_BASHLYK_LIBCNF" ] && return 0 || _BASHLYK_LIBCNF=1
#******
#****** bashlyk/libcnf/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/liblog.sh" ] && . "${_bashlyk_pathLib}/liblog.sh"
#******
#****v*  bashlyk/libcnf/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathCnf:=$(pwd)}
: ${_bashlyk_aRequiredCmd_cnf:="basename cat date dirname echo grep pwd rm sleep ["}
#******
#****f* bashlyk/libcnf/udfGetConfig
#  SYNOPSIS
#    udfGetConfig <file>
#  DESCRIPTION
#    Найти и выполнить <file> и предварительно все другие файлы, от которых он зависит.
#    Такие файлы должны находится в том же каталоге. То есть, если <file> это
#    "a.b.c.conf", то вначале применяются файлы "conf" "c.conf", "b.c.conf"
#    если таковые существуют.
#    Поиск выполняется по следующим критериям:
#     1. Если имя файла -это неполный путь, то
#     в начале проверяется текущий каталог, затем каталог конфигураций по умолчанию
#     2. Если имя файла - полный путь, то каталог в котором он расположен
#     3. Последняя попытка - найти файл в каталоге /etc
#  INPUTS
#    file     - имя файла конфигурации
#  RETURN VALUE
#     0  - Выполнено успешно
#     1  - Ошибка: файл конфигурации не найден
#    255 - Ошибка: аргумент отсутствует
#  SOURCE
udfGetConfig() {
 [ -n "$1" ] || return 255
 #
 local aconf chIFS conf fn i pathCnf=$_bashlyk_pathCnf
 #
 [ "$1"  = "$(basename $1)" -a -f ${pathCnf}/$1 ] || pathCnf=
 [ "$1"  = "$(basename $1)" -a -f $1 ] && pathCnf=$(pwd)
 [ "$1" != "$(basename $1)" -a -f $1 ] && pathCnf=$(dirname $1)
 #
 if [ -z "$pathCnf" ]; then
  [ -f "/etc${_bashlyk_pathPrefix}/$1" ] \
   && pathCnf="/etc${_bashlyk_pathPrefix}" || return 1
 fi
 #
 chIFS=$IFS
 IFS='.'
 i=0
 for fn in $(basename "$1"); do
  aconf[++i]=$fn
 done
 IFS=$chIFS
 conf=
 for ((i=$((${#aconf[*]})); $i; i--)); do
  [ -n "${aconf[i]}" ] || continue
  [ -n "$conf" ] && conf="${aconf[$i]}.${conf}" || conf=${aconf[i]}
  [ -s "${pathCnf}/${conf}" ] && . "${pathCnf}/${conf}"
 done
 return 0
}
#******
#****f* bashlyk/libcnf/udfSetConfig
#  SYNOPSIS
#    udfSetConfig <file> <csv;>
#  DESCRIPTION
#    Дополнить <file> строками вида "key=value" из аргумента <csv;>
#    Расположение файла определяется по следующим критериям:
#     Если имя файла -это неполный путь, то он сохраняется в каталоге по умолчанию,
#     иначе по полному пути.
#  INPUTS
#    <file> - имя файла конфигурации
#    <csv;> - CSV-строка, разделённая ";", поля которой содержат данные вида "key=value"
#  RETURN VALUE
#    255 - Ошибка: аргумент отсутствует
#     0  - Выполнено успешно
#     1  - Ошибка: файл конфигурации не найден
#  SOURCE
udfSetConfig() {
 [ -n "$1" -a -n "$2" ] || return 255
 #
 local conf sKeyValue chIFS=$IFS pathCnf=$_bashlyk_pathCnf
 #
 [ "$1" != "$(basename $1)" ] && pathCnf=$(dirname $1)
 [ -d "$pathCnf" ] || mkdir -p $pathCnf
 conf="${pathCnf}/$(basename $1)"
 IFS=';'
 {
  LANG=C date "+#Created %c by $USER $0 ($$)"
  for sKeyValue in $2; do
   [ -n "${sKeyValue}" ] && echo "${sKeyValue}"
  done
 } >> $conf 2>/dev/null
 IFS=$chIFS
 return 0
}
#******
#****u* bashlyk/libcnf/udfLibCnf
#  SYNOPSIS
#    udfLibCnf
# DESCRIPTION
#   bashlyk CNF library test unit
#   Запуск проверочных операций модуля выполняется если только аргументы 
#   командной строки cодержат строку вида "--bashlyk-test=[.*,]cnf[,.*]",
#   где * - ярлыки на другие тестируемые библиотеки
#  SOURCE
udfLibCnf() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -E -e "--bashlyk-test=.*cnf")" ] \
  && return 0
 local a b=1 c conf="$$.testlib.conf" fn s
 printf "\n- libcnf.sh tests:\n\n"
#
# Проверка файла конфигурации без полного пути
#
 echo -n "check set\get configuration: "
 udfSetConfig $conf "a=\"$BASH_VERSION\";c=\"$(uname -a)\"" >/dev/null 2>&1
 echo -n '.'
 . ${_bashlyk_pathCnf}/${conf} >/dev/null 2>&1
 echo -n '.'
 [ "$a" = "$BASH_VERSION" -a "$c" = "$(uname -a)" ] \
  && echo -n  '.' || { echo -n '?'; b=0; }
 a=;c=
 echo -n '.'
 udfGetConfig $conf 2>/dev/null
 echo -n '.'
 [ "$a" = "$BASH_VERSION" -a "$c" = "$(uname -a)" ] \
  && echo -n '.' || { echo -n '?'; b=0; }
 rm -f "${_bashlyk_pathCnf}/${conf}"
 a=;c=
#
# Проверка файла конфигурации с полным путем
#
 fn=$(mktemp -t "XXXXXXXX.${conf}" 2>/dev/null) && conf=$fn || conf=~/${conf}
 udfSetConfig $conf "a=\"$BASH_VERSION\";c=\"$(uname -a)\"" >/dev/null 2>&1
 echo -n '.'
 . $conf >/dev/null 2>&1
 echo -n '.'
 [ "$a" = "$BASH_VERSION" -a "$c" = "$(uname -a)" ] \
  && echo -n '.' || { echo -n '?'; b=0; }
 a=;c=
 echo -n '.'
 udfGetConfig $conf 2>/dev/null
 echo -n '.'
 [ "$a" = "$BASH_VERSION" -a "$c" = "$(uname -a)" ] \
  && echo -n '.' || { echo -n '?'; b=0; }
 a=;c=
 rm -f $conf
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 printf "\n--\n\n"
 return 0
}
#******
#****** bashlyk/libcnf/Main section
# DESCRIPTION
#   Running CNF library test unit if $_bashlyk_sArg ($*) contains
#   substrings "--bashlyk-test=" and "cnf" - command for test using
#  SOURCE
udfLibCnf
#******
