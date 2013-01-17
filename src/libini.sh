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
[ -s "${_bashlyk_pathLib}/libstd.sh" ] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****v*  bashlyk/libini/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathIni:=$(pwd)}
: ${_bashlyk_aRequiredCmd_ini:=""}
#******
#udfGetIni $csv
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
 local aini csvIni csvResultm41dp3EM ini pathIni s sTag
 #
 ini=''
 pathIni="$_bashlyk_pathIni"
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
  [ -s "${pathIni}/${ini}" ] \
   && csvIni+=";$(udfReadIniSection "${pathIni}/${ini}" "$sTag");"
 done
 udfCsvOrder "$csvIni" csvResultm41dp3EM
 [ -n "$3" ] \
  && eval 'export ${3}="${csvResultm41dp3EM}"' \
  || echo "$csvResultm41dp3EM"
 return 0
}
#******
#****f* bashlyk/libini/udfReadIniSection
#  SYNOPSIS
#    udfReadIniSection <file> [<section>] [<varname>]
#  DESCRIPTION
#    Получить секцию конфигурационных данных <section> из файла <file> и выдать
#    результат в виде строки CSV, разделенных ';', каждое поле которой содержит
#    данные в формате "<ключ>=<значение>" согласно данных строки секции.
#    В случае если исходная строка не содержит ключ или ключ содержит пробел, то
#    ключом становится выражение _zzz_bashlyk_line_<инкремент>, а всё содержимое
#    строки - значением.
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных 
#              или до конца конфигурационного файла, если секций нет
#    varname - идентификатор переменной (без "$ "). При его наличии результат
#              будет помещен в соответствующую переменную. При отсутствии такого
#              идентификатора результат будет выдан на стандартный вывод
#  OUTPUT
#              При отсутствии аргумента <varname> результат будет выдан на
#              стандартный вывод
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#  SOURCE
udfReadIniSection() {
 [ -n "$1" -a -f "$1" ] || return 255
 unset csv9AT0Vgyp
 local ini="$1" csv9AT0Vgyp b bOpen=false k v s sTag i=0
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
   if [ "$k" = "$v" -o -n "$(echo "$k" | grep '.*[[:space:]+].*')" ]; then
     k=_zzz_bashlyk_ini_line_${i}
     i=$((i+1))
#   else
#    [ -z "$(echo "$k" | grep '.*[[:space:]+].*')" ] || continue
   fi
   csv9AT0Vgyp+="$k=$(udfQuoteIfNeeded $v);"
  fi
 done < $ini
 $bOpen || csv9AT0Vgyp=''
 [ -n "$3" ] && eval 'export ${3}="${csv9AT0Vgyp}"' || echo "$csv9AT0Vgyp"
 return 0
}
#******
#****f* bashlyk/libini/udfCsvOrder
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
#    255 - Ошибка: аргумент отсутствует
#     0  - Выполнено успешно
#  SOURCE
udfCsvOrder() {
 [ -n "$1" ] || return 255
 unset csvjzUfQLA9
 local fnExec aKeys csv csvjzUfQLA9
 #
 csv="$(udfCheckCsv "$1")"
 aKeys="$(udfCsvKeys "$csv" | tr ' ' '\n' | sort -u | uniq -u | xargs)"
 csv=$(echo "$csv" | tr ';' '\n')
 #
 udfMakeTemp fnExec
 #
 cat << _CsvOrder_EOF > $fnExec
#!/bin/bash
#
# . bashlyk
#
udfAssembly() {
 local $aKeys
 #
 $csv
 #
 udfShowVariable $aKeys | grep -v Variable | tr -d '\t' \
  | sed -e "s/=\(.*[[:space:]]\+.*\)/=\"\1\"/" | tr '\n' ';' | sed -e "s/;;/;/"
 #
 return 0
}
#
udfAssembly
_CsvOrder_EOF

 csvjzUfQLA9=$(. $fnExec 2>/dev/null)
 rm -f $fnExec
 [ -n "$2" ] && eval 'export ${2}="${csvjzUfQLA9}"' || echo "$csvjzUfQLA9"
 return 0
}
#******
#****f* bashlyk/libini/udfSetVarFromCsv
#  SYNOPSIS
#    udfSetVarFromCsv <csv;> <keys> ...
#  DESCRIPTION
#    Инициализировать переменные <keys> значениями соответствующих ключей пар
#    "key=value" из CSV-строки <csv;>
#  INPUTS
#    csv; - CSV-строка, разделённая ";", поля которой содержат данные вида 
#          "key=value"
#    keys - идентификаторы переменных (без "$ "). При их наличии будет 
#           произведена инициализация в соответствующие переменные значений 
#           совпадающих ключей CSV-строки
#  RETURN VALUE
#    255 - Ошибка: аргумент(ы) отсутствуют
#     0  - Выполнено успешно
#  SOURCE
udfSetVarFromCsv() {
 [ -n "$1" ] || return 255
 unset s1LXAboOd7DyIwoBI
 local aKeys csv k s1LXAboOd7DyIwoBI
 #
 csv=";$(udfCsvOrder "$1");"
 shift
 for k in $*; do
  #s1LXAboOd7DyIwoBI=$(echo $csv | grep -Po ";$k=.*?;" | tr -d ';')
  s1LXAboOd7DyIwoBI=$(echo "$k=${csv#*;$k=}" | cut -f1 -d';')
  [ -n "$s1LXAboOd7DyIwoBI" ] && eval "$s1LXAboOd7DyIwoBI" 2>/dev/null
 done
 return 0
}
#******
#****f* bashlyk/libini/udfSetVarFromIni
#  SYNOPSIS
#    udfSetVarFromIni <file> <section> <keys> ...
#  DESCRIPTION
#    Инициализировать переменнные <keys> значениями соответствующих ключей пар
#    "key=value" секции <section> ini файла <file> (и всех его родительских
#    ini-файлов, см. описание udfGetIniSection)
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных или
#              до конца конфигурационного файла, если секций нет
#    keys    - идентификаторы переменных (без "$ "). При их наличии будет 
#              произведена инициализация в соответствующие переменные значений 
#              совпадающих ключей CSV-строки
#  RETURN VALUE
#    255 - Ошибка: аргумент(ы) отсутствуют
#     0  - Выполнено успешно
#  SOURCE
udfSetVarFromIni() {
 [ -n "$1" -a -f "$1" -a -n "$3" ] || return 255
 #
 local ini aTag
 #
 ini="$1"
 [ -n "$2" ] && aTag="$2"
 shift 2
 #
 udfSetVarFromCsv ";$(udfGetIniSection $ini "$aTag");" $* 
 return 0
}
#******
#****f* bashlyk/libini/udfCsvKeys
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
 unset csv8LayYbbT
 local cIFS csv csv8LayYbbT s
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
#****f* bashlyk/libini/udfCheckCsv
#  SYNOPSIS
#    udfCheckCsv <csv;> [<varname>]
#  DESCRIPTION
#    Нормализация CSV-строки <csv;>. Приведение к виду "ключ=значение" полей.
#    В случае если поле не содержит ключа или ключ содержит пробел, то к полю 
#    добавляется ключ вида _zzz_bashlyk_line_<инкремент>, всё содержимое поля
#    становится значением.
#    Результат выводится в стандартный вывод или в переменную, если имеется
#    второй аргумент функции <varname>
#  INPUTS
#    csv;    - CSV-строка, разделённая ";"
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
udfCheckCsv() {
 [ -n "$1" ] || return 255
 local swRhg7E54 c0AsEJm98 kynnxDV76 vYYu45sZw iEOJ1F48r csvuKwhY5ay
 #
 c0AsEJm98=$IFS
 IFS=';'
 iEOJ1F48r=0
 csvuKwhY5ay=''
 #
 for swRhg7E54 in $1; do
  swRhg7E54=$(echo $swRhg7E54 | tr -d "'" | tr -d '"')
  kynnxDV76="$(echo ${swRhg7E54%%=*}|xargs)"
  vYYu45sZw="$(echo ${swRhg7E54#*=}|xargs)"
  [ -n "$kynnxDV76" ] || continue
  if [ "$kynnxDV76" = "$vYYu45sZw" -o -n "$(echo "$kynnxDV76" | grep '.*[[:space:]+].*')" ]; then
   kynnxDV76=_zzz_bashlyk_ini_line_${iEOJ1F48r}
   iEOJ1F48r=$((iEOJ1F48r+1))
  fi
  csvuKwhY5ay+="$kynnxDV76=$(udfQuoteIfNeeded $vYYu45sZw);"
 done
 IFS=$c0AsEJm98
 [ -n "$2" ] && eval 'export ${2}="${csvuKwhY5ay}"' || echo "$csvuKwhY5ay"
 return 0
}
#******
#****f* bashlyk/libini/udfIniWrite
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
 echo "$csv" | sed -e "s/[;]\+/;/g" -e "s/\[/;\[/g" | tr ';' '\n' | sed -e "s/\(.*\)=/\t\1\t=\t/g" -e "s/_zzz_bashlyk_ini_line_.*\t=\t//g" | tr -d '"' > "$ini"
 #
 return 0
}
#******
#****f* bashlyk/libini/udfIniChange
#  SYNOPSIS
#    udfIniChange <file> <csv;> [<section>]
#  DESCRIPTION
#    Внести изменения в секцию <section> конфигурации <file> согласно данных 
#    CSV-строки  <csv;> в формате "<key>=<value>;..."
#  INPUTS
#     file - файл конфигурации формата "*.ini". Если он не пустой, то
#            сохраняется в виде копии "<file>.bak"
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

