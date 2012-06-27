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


udfSection() {
 [ -n "$1" -a -n "$2" -a -n "$3" ] || return 1
 local fn aKeys csv sTag
 #
 fn="$1"
 aKeys="$2"
 csv="$3"
 sTag="$4"
 #
 csv=$(echo "$csv" | sed -e "s/[;]\+/;/g" | tr ';' '\n')
 #
 cat << _EOF > $fn
#!/bin/bash
#
. bashlyk
#
udfSetValue() { 
 local $aKeys 
 #
 $csv
 #
 #[ -n "$sTag" ] && echo "[${sTag}]"
 udfShowVariable $aKeys | grep -v Variable
 return 0 
}
#
#
#
udfSetValue
_EOF
 chmod +x $fn
 return $?  
}

udfCsvKeys() {
 local cIFS csv a s v
 #
 [ -n "$2" ] || return 1
 #
 csv="$1"
 cIFS=$IFS
 IFS=';'
 for s in $csv; do
  a+="${s%%=*} "
 done
 IFS=$cIFS
 eval 'export ${2}="${a}"' 2>/dev/null
 return 0
}

udfSplitWord2Line() {
 return 0
}

udfWriteIniSection() {
 [ -n "$1" ] || return 255
 [ -n "$2" ] || return 254
 local ini="$1" a b bEdit=false bOpen=false sOld fnTmp fnExec $fnConf s sTag sNew="$2" cIFS=$IFS aKeys aKeysOld aKeysNew
 [ -n "$3" ] && sTag="$3" || bOpen=true
 [ -f "$ini" ] && udfReadIniSection $ini sOld "$sTag" || touch $ini
 udfMakeTempV fnExec
 udfMakeTempV fnTmp
 udfMakeTempV fnConf

 udfCsvKeys "$sOld" aOldKeys
 udfCsvKeys "$sNew" aNewKeys

 aKeys="$(echo "${aOldKeys} ${aNewKeys} " | tr ' ' '\n' | sort -u | uniq -u | xargs)"
 udfSection $fnExec "$aKeys" "${sOld};${sNew};" "$sTag"
 $fnExec > $fnConf
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
  if $bOpen; then
   echo "dbg s $s : edit $bEdit : open $bOpen : b $b : tag $sTag"
  else
   echo "$s" >> $fnTmp
   continue
  fi

  $bEdit && continue
  cat $fnConf >> $fnTmp
  bEdit=true  

 done < $ini
 if $bEdit; then
  mv -f $fnTmp $ini
 else
  [ -n "$sTag" ] && echo "[${sTag}]" >> $fnTmp
  cat $fnConf >> $fnTmp
  if [ -n "$sTag" ]; then 
   cat $fnTmp >> $ini 
  else
   cat $ini >> $fnTmp
   mv -f $fnTmp $ini
  fi
 fi
 return 0
}
#******

udfQuoteIfNeeded() {
 [ -n "$(echo "$*" | grep -e [[:space:]])" ] && echo "\"$*\"" || echo "$*"
}

#udfReadIniSection test.ini sTest "$1"

sTest='a1982="Final cut";a1979="mark";a=test3;wer=ta'
#sTest='a="2849849 4848 ";ddd="mark";av="test20 2";wert=ta'
echo $sTest
udfWriteIniSection /tmp/test.ini "$sTest" "laidback"
