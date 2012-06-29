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
#    udfGetIniSection <file> [<section>] [<varname>]
#  DESCRIPTION
#    Получить секцию конфигурационных данных <section> из <file> и, при наличии,
#    от "родительских" к нему файлов. Например, если <file> это "a.b.c.ini", то 
#    "родительскими" будут считаться файлы "ini", "c.ini" и "b.c.ini" если есть 
#    в том же каталоге. Данные наследуются и перекрываются от "старшего" файла к
#    младшему.
#    Поиск конфигурационных файлов выполняется по следующим критериям:
#     1. Если имя файла <file> содержит неполный путь, то в начале проверяется
#     текущий каталог, затем каталог конфигураций по умолчанию
#     2. Если имя файла содержит полный путь, то рабочим каталогом является этот
#     полный путь
#     3. Последняя попытка - найти файл в каталоге /etc
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных или
#              до конца конфигурационного файла, если секций нет
#    varname - идентификатор переменной (без "$ "). При его наличии результат 
#              будет помещен в соответствующую переменную. При отсутствии такого 
#              идентификатора результат будет выдан на стандартный вывод
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся 
#              конфигурационные данные в формате "<key>=<value>;..."
#  RETURN VALUE
#     0  - Выполнено успешно
#     1  - Ошибка: файл конфигурации не найден
#    255 - Ошибка: аргумент отсутствует
#  SOURCE
udfGetIniSection() {
 [ -n "$1" ] || return 255
 #
 local aini csv csv1LXAboOd ini='' pathIni="$_bashlyk_pathIni" s sTag
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
  [ -s "${pathIni}/${ini}" ] && csv+=";$(udfReadIniSection "${pathIni}/${ini}" "$sTag");"
 done
 udfCsvOrder "$csv" csv1LXAboOd
 [ -n "$3" ] && eval 'export ${3}="${csv1LXAboOd}"' || echo "$csv1LXAboOd"
 return 0
}
#******
#****f* bashlyk/libini/udfReadIniSection
#  SYNOPSIS
#    udfReadIniSection <file> [<section>] [<varname>]
#  DESCRIPTION
#    Получить секцию конфигурационных данных <section> из <file>
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных или
#              до конца конфигурационного файла, если секций нет
#    varname - идентификатор переменной (без "$ "). При его наличии результат 
#              будет помещен в соответствующую переменную. При отсутствии такого 
#              идентификатора результат будет выдан на стандартный вывод
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся 
#              конфигурационные данные в формате "<key>=<value>;..."
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#  SOURCE
udfReadIniSection() {
 [ -n "$1" -a -f "$1" ] || return 255
 local ini="$1" csv9AT0Vgyp b bOpen=false k v s sTag
 [ -n "$2" ] && sTag="$2" || bOpen=true
 while read s; do
  ( echo $s | grep "^#\|^$" )>/dev/null && continue
  b=$(echo $s | grep -oE '\[.*\]' | tr -d '[]' | xargs)
  if [ -n "$b" ]; then
   $bOpen && break
   if [ "$b" = "$sTag" ]; then
    csv9AT0Vgyp=''
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
   csv9AT0Vgyp+="$k=$(udfQuoteIfNeeded $v);"
  fi
 done < $ini
 $bOpen || csv9AT0Vgyp=''
 [ -n "$3" ] && eval 'export ${3}="${csv9AT0Vgyp}"' || echo "$csv9AT0Vgyp"
 return 0
}
#******
#****f* bashlyk/libcnf/udfCsvOrder
#  SYNOPSIS
#    udfCsvOrder <csv;> [<varname>]
#  DESCRIPTION
#    упорядочение CSV-строки, которое заключается в удалении устаревших значений
#    пар "<key>=<value>". Более старыми при повторении ключей считаются более 
#    левые поля в строке
#  INPUTS
#    csv;    - CSV-строка, разделённая ";", поля которой содержат данные вида 
#              "key=value"
#    varname - идентификатор переменной (без "$ "). При его наличии результат 
#              будет помещен в соответствующую переменную. При отсутствии такого 
#              идентификатора результат будет выдан на стандартный вывод
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся 
#              данные в формате "<key>=<value>;..."
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#  SOURCE
#  RETURN VALUE
#    255 - Ошибка: аргумент отсутствует
#     0  - Выполнено успешно
#  SOURCE
udfCsvOrder() {
 [ -n "$1" ] || return 255
 local fnExec aKeys csv csvjzUfQLA9
 #
 csv="$1"
 aKeys="$(udfCsvKeys "$csv" | tr ' ' '\n' | sort -u | uniq -u | xargs)"
 #
 csv=$(echo "$csv" | tr ';' '\n')
 udfMakeTempV fnExec
 #
 cat << _EOF > $fnExec
#!/bin/bash
#
_bashlyk=libini . bashlyk
#
udfAssembly() { 
 local $aKeys 
 #
 $csv
 #
 udfShowVariable $aKeys | grep -v Variable | tr -d '\t' | sed -e "s/=\(.*[[:space:]]\+.*\)/=\"\1\"/" | tr '\n' ';' 

 return 0 
}
#
udfAssembly
_EOF
 csvjzUfQLA9=$(. $fnExec 2>/dev/null)
 [ -n "$2" ] && eval 'export ${2}="${csvjzUfQLA9}"' || echo "$csvjzUfQLA9"
 return 0
}
#******
#****f* bashlyk/libcnf/udfCsvKeys
#  SYNOPSIS
#    udfCsvKeys <csv;> [<varname>]
#  DESCRIPTION
#    Получить ключи пар "ключ=значение" из CSV-строки <csv;>
#  INPUTS
#    csv;    - CSV-строка, разделённая ";", поля которой содержат данные вида 
#              "key=value"
#    varname - идентификатор переменной (без "$ "). При его наличии результат 
#              будет помещен в соответствующую переменную. При отсутствии такого 
#              идентификатора результат будет выдан на стандартный вывод
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся 
#              данные в формате "<key>=<value>;..."
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргумент отсутствует
#  SOURCE
udfCsvKeys() {
 [ -n "$1" ] || return 255
 local cIFS csv csv8LayYbbT  s
 #
 csv="$1"
 cIFS=$IFS
 IFS=';'
 for s in $csv; do
  csv8LayYbbT+="${s%%=*} "
 done
 IFS=$cIFS
 [ -n "$2" ] && eval 'export ${2}="${csv8LayYbbT}"' || echo "$csv8LayYbbT"
 return 0
}
#******
#****f* bashlyk/libcnf/udfIniWrite
#  SYNOPSIS
#    udfIniWrite <file> <csv;>
#  DESCRIPTION
#    сохранить данные из CSV-строки <csv;> в формате [<section>];<key>=<value>;
#    в файл конфигурации <file> c заменой предыдущего содержания. Сохранение
#    производится с форматированием строк, разделитель ";" заменяется на перевод
#    строки
#  INPUTS
#    file - файл конфигурации формата "*.ini". Если он не пустой, то сохраняется
#           в виде копии "<file>.bak"
#    csv; - CSV-строка, разделённая ";", поля которой содержат данные вида 
#           "[<section>];<key>=<value>;..."
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргументы отсутствуют
#  SOURCE
udfIniWrite() {
 [ -n "$1" -a -n "$2" ] || return 255
 #
 local ini csv
 #
 ini="$1"
 csv="$2"
 #
 [ -s "$ini" ] && mv -f "$ini" "${ini}.bak"
 echo "$csv" | sed -e "s/[;]\+/;/g" -e "s/\[/;\[/g" | tr ';' '\n' | sed -e "s/\(.*\)=/\t\1\t=\t/g" | tr -d '"' > "$ini"
 return 0
}
#******
#****f* bashlyk/libcnf/udfIniChange
#  SYNOPSIS
#    udfIniChange <file> <csv;> [<section>]
#  DESCRIPTION
#    Внести изменения в секцию <section> конфигурации <file> согласно данных 
#    CSV-строки  <csv;> в формате "<key>=<value>;..."
#  INPUTS
#     file - файл конфигурации формата "*.ini". Если он не пустой, то сохраняется
#            в виде копии "<file>.bak"
#     csv; - CSV-строка, разделённая ";", поля которой содержат данные вида 
#            "<key>=<value>;..."
#  section - название секции конфигурации, в которую вносятся изменения. При
#            отсутствии этого аргумента изменения производятся в блоке от 
#            начала файла до первого заголовка секции "[<...>]" данных или до
#            конца конфигурационного файла, если секций нет вообще
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргументы отсутствуют
#  SOURCE
udfIniChange() {
 [ -n "$1" -a -n "$2" ] || return 255
 #
 local a aKeys aTag csv ini s csvNew sTag
 #
 ini="$1"
 csvNew="$2"
 [ -n "$3" ] && sTag="$3"
 #
 [ -f "$ini" ] || touch $ini
 aTag="$(grep -oE '\[.*\]' $ini | tr -d '[]' | sort -u | uniq -u | xargs)"
 [ -n "$sTag" ] && echo "$aTag" | grep -w "$sTag" >/dev/null || aTag+=" $sTag"
 for s in "" $aTag; do
  udfReadIniSection $ini "$s" csv
  if [ "$s" = "$sTag" ]; then
   csv=$(udfCsvOrder "${csv};${csvNew}")
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
#sTest='a1982="Final cut";a1979="mark";a=test3;wer=ta'
#sTest='a="2849849 4848 ";ddd="mark";av="test20 2";wert=tak;djeidjei;deiei eie=e'
sTest='array="a b c d";iY=2345.34;iX=123.45;bState=false;glory="sic mundi"'
udfIniChange /tmp/test.ini "$sTest" "settings"
sTest='array="a b c d e";iX=124.45;bState=true;'
udfIniChange /tmp/a.test.ini "$sTest" "settings"

udfGetIniSection /tmp/a.test.ini settings csvResult
echo "b $csvResult"
udfIniChange /tmp/b.test.ini "$csvResult" "settings"

