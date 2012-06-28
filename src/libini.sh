#!/bin/bash
#
# $Id$
#
#****h* bashlyk/libini
#  DESCRIPTION
#    bashlyk INI library
#    Обработка конфигурационных файлов в стиле INI
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
#****f* bashlyk/libini/udfGetIniSection
#  SYNOPSIS
#    udfGetIniSection <file> [<section>]
#  DESCRIPTION
#    Получить секцию конфигурационных данных <section> из <file> и, при наличии,
#    от родительских к нему файлов. Например, если <file> это "a.b.c.ini", то 
#    эта функция попытается предварительно считать данные из файлов "ini", 
#    "c.ini" и "b.c.ini" если таковые существуют.
#    Поиск выполняется по следующим критериям:
#     1. Если имя файла содержит неполный путь, то в начале проверяется текущий 
#     каталог, затем каталог конфигураций по умолчанию
#     2. Если имя файла содержит полный путь, то рабочим каталогом является этот
#     полный путь
#     3. Последняя попытка - найти файл в каталоге /etc
#  INPUTS
#    file    - имя файла конфигурации
#    section - название блока конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого именного блока [<...>] данных или
#              до конца конфигурационного файла
#  RETURN VALUE
#     0  - Выполнено успешно
#     1  - Ошибка: файл конфигурации не найден
#    255 - Ошибка: аргумент отсутствует
#  SOURCE

udfGetIniSection() {
 [ -n "$1" ] || return 255
 #
 local aini csv ini='' pathIni="$_bashlyk_pathIni" s sTag
 #
 [ "$1"  = "${1##*/}" -a -f ${pathIni}/$1 ] || pathIni=
 [ "$1"  = "${1##*/}" -a -f $1 ] && pathIni=$(pwd)
 [ "$1" != "${1##*/}" -a -f $1 ] && pathIni=$(dirname $1)
 [ -n "$2" ] && sTag="$2"
 #
 if [ -z "$pathIni" ]; then
  [ -f "/etc${_bashlyk_pathPrefix}/$1" ] \
   && pathIni="/etc${_bashlyk_pathPrefix}" || return 1
 fi
 #
 aini=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')
 for s in $aini; do
  [ -n "$s" ] || continue
  [ -n "$ini" ] && ini="${s}.${ini}" || ini="$s"
  [ -s "${pathIni}/${ini}" ] && csv=+";$(udfReadIniSection "${pathIni}/${ini}" "$sTag");"
 done
 csv=$(udfIniSectionAssembly "$csv" "$sTag")
 [ -n "$3" ] && eval 'export ${3}="${csv}"' || echo "$csv"
 return 0
}
#******
udfReadIniSection() {
 [ -n "$1" -a -f "$1" ] || return 255
 local ini="$1" a b bOpen=false k v s sTag
 [ -n "$2" ] && sTag="$2" || bOpen=true
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
 [ -n "$3" ] && eval 'export ${3}="${a}"' || echo "$a"
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
 [ -n "$1" ] || return 1
 local fnExec aKeys csv sTag
 #
 csv="$1"
 sTag="$2"
 aKeys="$(udfCsvKeys "$csv" | tr ' ' '\n' | sort -u | uniq -u | xargs)"
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
 udfShowVariable $aKeys | grep -v Variable | tr -d '\t' | tr '\n' ';'
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
 mv -f "$ini" "${ini}.bak"
 echo "$csv" | sed -e "s/[;]\+/;/g" -e "s/\[/;\[/g" | tr ';' '\n' | sed -e "s/\(.*\)=/\t\1\t=\t/g" > "$ini"
 return 0
}
#
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
  udfReadIniSection $ini "$s" csv
  if [ "$s" = "$sTag" ]; then
   csv=$(udfIniSectionAssembly "${csv};${csvNew}" "$sTag")
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
udfIniChange /tmp/test.ini "$sTest" 
