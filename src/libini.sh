#!/bin/bash
#
# $Id$
#
#****h* bashlyk/libini
#  DESCRIPTION
#    bashlyk INI library
#    Чтение/запись файлов пассивных конфигураций
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/libini/Required Once
#  DESCRIPTION
#    Глобальная переменная $_BASHLYK_LIBINI обеспечивает
#    защиту от повторного использования данного модуля
#  SOURCE
[ -n "$_BASHLYK_LIBINI" ] && return 0 || _BASHLYK_LIBINI=1
#******
#****** bashlyk/libini/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/liblog.sh" ] && . "${_bashlyk_pathLib}/liblog.sh"
#******
#****v*  bashlyk/libini/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathINI:=$(pwd)}
: ${_bashlyk_aRequiredCmd_ini:=""}
: ${_bashlyk_aIni:=""}
declare -A _bashlyk_aIni
#******
#****f* bashlyk/libini/udfGetIni
#  SYNOPSIS
#    udfGetIni <file>
#  DESCRIPTION
#    Найти и прочитать <file> и предварительно все другие файлы, от которых он 
#    зависит. Такие файлы должны находится в том же каталоге. То есть, если 
#    <file> это "a.b.c.conf", то вначале прочитать файлы "conf" "c.conf",
#    "b.c.conf" если таковые существуют.
#    Поиск выполняется по следующим критериям:
#     1. Если имя файла содержит неполный путь, то в начале проверяется текущий 
#     каталог, затем каталог конфигураций по умолчанию
#     2. Если имя файла содержит полный путь, то рабочим каталогом является этот
#     полный путь
#     3. Последняя попытка - найти файл в каталоге /etc
#  INPUTS
#    file - имя файла конфигурации
#  RETURN VALUE
#     0  - Выполнено успешно
#     1  - Ошибка: файл конфигурации не найден
#    255 - Ошибка: аргумент отсутствует
#  SOURCE
udfGetIni() {
 [ -n "$1" ] || return 255
 #
 local aini chIFS ini fn i pathIni=$_bashlyk_pathIni
 #
 [ "$1"  = "$(basename $1)" -a -f ${pathIni}/$1 ] || pathIni=
 [ "$1"  = "$(basename $1)" -a -f $1 ] && pathIni=$(pwd)
 [ "$1" != "$(basename $1)" -a -f $1 ] && pathIni=$(dirname $1)
 #
 if [ -z "$pathIni" ]; then
  [ -f "/etc${_bashlyk_pathPrefix}/$1" ] \
   && pathIni="/etc${_bashlyk_pathPrefix}" || return 1
 fi
 #
 chIFS=$IFS
 IFS='.'
 i=0
 for fn in $(basename "$1"); do
  aini[++i]=$fn
 done
 IFS=$chIFS
 conf=
 for ((i=$((${#aini[*]})); $i; i--)); do
  [ -n "${aini[i]}" ] || continue
  [ -n "$ini" ] && ini="${aini[$i]}.${ini}" || ini=${aini[i]}
  [ -s "${pathIni}/${ini}" ] && udfReadIni "${pathIni}/${ini}"
 done
 return 0
}
#******
udfReadIni() {
 [ -n "$1" -a -f "$1" ] || return 255
 #[ -n "$2" ] && 
 local ini=$1 a s b sSection='void' k v
 unset _bashlyk_aIni
 declare -A _bashlyk_aIni
 while read s; do
  ( echo $s | grep "^#\|^$" )>/dev/null && continue
  b=$(echo $s | grep -oE '\[.*\]' | tr -d '[]')
  if [ -n "$b" ]; then
   sSection=$b
   _bashlyk_aIni[$sSection]+="; ;"
  else
   k="$(echo ${s%%=*}|xargs)"
   v="$(echo ${s#*=}|xargs)"
   if [ "$k" = "$v" ]; then
    _bashlyk_aIni[$sSection]+=";;;"
   else
    [ -z "$(echo "$k" | grep '.*[[:space:]+].*')" ] && k="$k=$v"
   fi
   _bashlyk_aIni[$sSection]+="$k;"
  fi
 done < $ini
}
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
