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
 local ini="$1" a b bOpen=false k v s sTag
 [ -n "$3" ] && sTag="$3" || bOpen=true
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
   a+="$k=$(udfQuoteIfNeeded $v);"
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
udfIniSectionAssembly() {
 [ -n "$1" -a -n "$2" ] || return 1
 local fnExec aKeys csv sTag
 #
 aKeys="$1"
 csv="$2"
 sTag="$3"
 #
 csv=$(echo "$csv" | tr ';' '\n')
 udfMakeTempV fnExec
 #
 cat << _EOF > $fnExec
#!/bin/bash
#
. bashlyk
#
udfAssembly() { 
 local $aKeys 
 #
 $csv
 #
 udfShowVariable $aKeys | grep -v Variable | tr '\n' ';'
 return 0 
}
#
#
#
udfAssembly
_EOF
 . $fnExec 2>/dev/null
}
#
udfCsvKeys() {
 local cIFS csv a s v
 #
 csv="$1"
 cIFS=$IFS
 IFS=';'
 for s in $csv; do
  a+="${s%%=*} "
 done
 IFS=$cIFS
 [ -n "$2" ] && eval 'export ${2}="${a}"' || echo "$a"
 return 0
}
#
udfIniWrite() {
 [ -n "$1" -a -n "$2" ] || return 1
 #
 local ini csv
 #
 ini="$1"
 csv="$2"
 #
 echo "$csv" | sed -e "s/[;]\+/;/g" -e "s/\[/;\[/g" -e "s/=/ = /g" | tr ';' '\n' > $ini
}

udfIniChange() {
 [ -n "$1" -a -n "$2" ] || return 1
 #
 local a aKeys aTag csv ini s csvNew sTag
 #
 ini="$1"
 csvNew="$2"
 sTag="$3"
 #
 [ -f "$ini" ] || touch $ini
 aTag="$(grep -oE '\[.*\]' $ini | tr -d '[]' | xargs)"
 [ -n "$sTag" ] && echo "$aTag" | grep "$sTag" >/dev/null || aTag+=" $sTag"
 for s in "" $aTag; do
  udfReadIniSection $ini csv "$s"
  if [ "$s" = "$sTag" ]; then
   csv+=";${csvNew};"
   aKeys="$(udfCsvKeys "$csv" | tr ' ' '\n' | sort -u | uniq -u | xargs)"
   csv=$(udfIniSectionAssembly "$aKeys" "$csv" "$sTag")
  fi 
  a+=";[${s}];$csv;"
 done
 a="$(echo "$a" | sed -e "s/\[\]//")"
 udfIniWrite $ini "$a"
 return 0
}
#******
udfQuoteIfNeeded() {
 [ -n "$(echo "$*" | grep -e [[:space:]])" ] && echo "\"$*\"" || echo "$*"
}

#udfReadIniSection test.ini sTest "$1"

sTest='a1982="Final cut";a1979="mark";a=test3;wer=ta'
sTest='a="2849849 4848 ";ddd="mark";av="test20 2";wert=ta'
echo $sTest
udfIniChange /tmp/test.ini "$sTest" "laid-back"
