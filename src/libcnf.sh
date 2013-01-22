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
#******
#****v*  bashlyk/libcnf/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathCnf:=$(pwd)}
: ${_bashlyk_aRequiredCmd_cnf:="[ awk date dirname echo mkdir printf pwd"}
#******
#****f* bashlyk/libcnf/udfGetConfig
#  SYNOPSIS
#    udfGetConfig <file>
#  DESCRIPTION
#    Найти и выполнить <file> и предварительно все другие файлы, от которых он 
#    зависит. Такие файлы должны находится в том же каталоге. То есть, если 
#    <file> это "a.b.c.conf", то вначале применяются файлы "conf" "c.conf",
#    "b.c.conf" если таковые существуют.
#    Поиск выполняется по следующим критериям:
#     1. Если имя файла -это неполный путь, то
#     в начале проверяется текущий каталог, затем каталог конфигураций по 
#     умолчанию
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
 local aconf conf s pathCnf="$_bashlyk_pathCnf"
 #
 [ "$1"  = "${1##*/}" -a -f ${pathCnf}/$1 ] || pathCnf=
 [ "$1"  = "${1##*/}" -a -f $1 ] && pathCnf=$(pwd)
 [ "$1" != "${1##*/}" -a -f $1 ] && pathCnf=$(dirname $1)
 #
 if [ -z "$pathCnf" ]; then
  [ -f "/etc${_bashlyk_pathPrefix}/$1" ] \
   && pathCnf="/etc${_bashlyk_pathPrefix}" || return 1
 fi
 #
 conf=
 aconf=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')
 for s in $aconf; do
  [ -n "$s" ] || continue
  [ -n "$conf" ] && conf="${s}.${conf}" || conf="$s"
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
#     Если имя файла -это неполный путь, то он сохраняется в каталоге по
#     умолчанию, иначе по полному пути.
#  INPUTS
#    <file> - имя файла конфигурации
#    <csv;> - CSV-строка, разделённая ";", поля которой содержат данные вида
#             "key=value"
#  RETURN VALUE
#    255 - Ошибка: аргумент отсутствует
#     0  - Выполнено успешно
#     1  - Ошибка: файл конфигурации не найден
#  SOURCE
udfSetConfig() {
 [ -n "$1" -a -n "$2" ] || return 255
 #
 local conf sKeyValue chIFS="$IFS" pathCnf="$_bashlyk_pathCnf"
 #
 [ "$1" != "${1##*/}" ] && pathCnf="$(dirname $1)"
 [ -d "$pathCnf" ] || mkdir -p "$pathCnf"
 conf="${pathCnf}/${1##*/}"
 IFS=';'
 {
  LANG=C date "+#Created %c by $USER $0 ($$)"
  for sKeyValue in $2; do
   [ -n "${sKeyValue}" ] && echo "${sKeyValue}"
  done
 } >> $conf 2>/dev/null
 IFS="$chIFS"
 return 0
}
#******
