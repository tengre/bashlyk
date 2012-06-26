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
: ${_bashlyk_pathIni:=$(pwd)}
: ${_bashlyk_aRequiredCmd_ini:=""}
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
 local aini chIFS ini fn i pathIni="$_bashlyk_pathIni"
 #
 [ "$1"  = "${1##*/}" -a -f ${pathIni}/$1 ] || pathIni=
 [ "$1"  = "${1##*/}" -a -f $1 ] && pathIni=$(pwd)
 [ "$1" != "${1##*/}" -a -f $1 ] && pathIni=$(dirname $1)
 #
 if [ -z "$pathIni" ]; then
  [ -f "/etc${_bashlyk_pathPrefix}/$1" ] \
   && pathIni="/etc${_bashlyk_pathPrefix}" || return 1
 fi
 #
 chIFS="$IFS"
 IFS='.'
 i=0
 for fn in $(basename "$1"); do
  aini[++i]=$fn
 done
 IFS="$chIFS"
 conf=
 for ((i=$((${#aini[*]})); $i; i--)); do
  [ -n "${aini[i]}" ] || continue
  [ -n "$ini" ] && ini="${aini[$i]}.${ini}" || ini=${aini[i]}
  [ -s "${pathIni}/${ini}" ] && udfReadIni "${pathIni}/${ini}"
 done
 return 0
}
#******
udfReadIniSection() {
 [ -n "$1" -a -f "$1" ] || return 255
 [ -n "$2" ] || return 254
 local ini="$1" a b bOpen=true k v s sTag
 if [ -n "$3" ]; then 
  sTag="$3" 
  bOpen=false
 fi
 while read s; do
  ( echo $s | grep "^#\|^$" )>/dev/null && continue
  b=$(echo $s | grep -oE '\[.*\]' | tr -d '[]' | xargs)
  if [ -n "$b" ]; then
   $bOpen && break
   if [ "$b" = "$sTag" ]; then
    a=''
    bOpen=true
   else
    continue
   fi
  else
   $bOpen || continue
   s=$(echo $s | tr -d "'")
   k="$(echo ${s%%=*}|xargs)"
   v="$(echo ${s#*=}|xargs)"
   if [ "$k" = "$v" ]; then
    continue
   else
    [ -z "$(echo "$k" | grep '.*[[:space:]+].*')" ] || continue
   fi
   a+=";$k=$(udfQuoteIfNeeded $v);"
  fi
 done < $ini
 $bOpen || a=''
 eval 'export ${2}="${a}"'
 return 0
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

udfWriteSection() {
 date
 [ -n "$1" -a -n "$2" ] || return 255
#
 local ini s cIFS="$IFS" pathIni="$_bashlyk_pathCnf" fnTmp
#
 [ "$1" != "${1##*/}" ] && pathIni="$(dirname $1)"
 [ -d "$pathIni" ] || mkdir -p "$pathIni"
 ini="${pathIni}/${1##*/}"
 udfMakeTempV fnTmp
 ls -l $ini
 {
 IFS=';'
  echo
  LANG=C date "+#Generated %c by $USER $0 ($$)"
  [ -n "$3" ] && echo "[${3}]"
  for s in $2; do
   [ -n "$s" ] && echo "$s" || continue
  done
  echo
 IFS="$cIFS"
 } >> $fnTmp 2>/dev/null
 if [ -n "$3" ]; then 
  cat $fnTmp >> $ini
 else
  cat $ini >> $fnTmp
  mv $fnTmp $ini
 fi
 return 0
}




udfWriteIniSection() {
 [ -n "$1" ] || return 255
 [ -n "$2" ] || return 254
 local ini="$1" a b bEdit=false bOpen=true csv=$2 fnTmp k v s sTag sS
 [ -f "$ini" ] || touch $ini
 if [ -n "$3" ]; then 
  sTag="$3" 
  bOpen=false
 fi
 udfMakeTempV fnTmp

 while read s; do
  if echo "$s" | grep "^#\|^$" >/dev/null; then
   echo "$s" >> $fnTmp
   continue
  fi
  b=$(echo "$s" | grep -oE '\[.*\]' | tr -d '[]' 2>/dev/null)
  if [ -n "$b" ]; then
   echo "$s" >> $fnTmp
   [ "$b" = "$sTag" ] && bOpen=true
   continue
  fi
  $bOpen || continue
  s=$(echo $s | tr -d "'")
  k="$(echo ${s%%=*}|xargs)"
  v="$(echo ${s#*=}|xargs)" 
  if [ -n "$k" ]; then 
   sS=$(echo $csv | grep -Eo ";${k}=[^;]+;" | tr -d ';' | xargs)  
  else
   
  fi
  if [ -n "$sS" ]; then
   bEdit=true
   echo "$sS" >> $fnTmp
  else
   echo "$s" >> $fnTmp
  fi
  echo "dbg $sTag : $s : $k : $v : $sS : $bEdit : $bOpen"
 done < $ini 
 $bEdit && mv -f $fnTmp $ini || udfWriteSection "$ini" "$csv" "$sTag"
 return 0
}
#******

udfQuoteIfNeeded() {
 [ -n "$(echo "$*" | grep -e [[:space:]])" ] && echo "\"$*\"" || echo "$*"
}

udfReadIniSection test.ini sTest "$1"
echo $sTest
udfWriteIniSection /tmp/test2.ini "$sTest" "$2"
