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
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$_BASHLYK_LIBINI" ] && return 0 || _BASHLYK_LIBINI=1
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
#******
#****** bashlyk/libini/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "libstd.sh" ] && . "libstd.sh"
#[ -s "${_bashlyk_pathLib}/libstd.sh" ] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****v*  bashlyk/libini/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathIni:=$(pwd)}
: ${_bashlyk_aRequiredCmd_ini:="[ awk cat cut dirname echo false grep mv printf pwd rm sed sort touch tr true uniq w xargs"}
: ${_bashlyk_aExport_ini:="udfGetIniSection udfReadIniSection udfCsvOrder udfAssembly udfSetVarFromCsv udfSetVarFromIni udfCsvKeys udfCheckCsv udfIniWrite udfIniChange"}
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
#    Важно: имя <file> не должно начинаться с точки и им заканчиваться!
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
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='b=true;iXo=1921;iYo=1080;sTxt="foo bar";' csvResult             ##udfGetIniSection
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild                 ##udfGetIniSection
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfGetIniSection
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfGetIniSection ? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          ##udfGetIniSection
#    printf "$fmt" "sTxt" "foo" "b" "false" "iXo" "1920" "iYo" "$80" | tee $ini ##udfGetIniSection
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $iniChild  ##udfGetIniSection
#    udfGetIniSection $iniChild test | grep "^${csv}$"                          ##udfGetIniSection ? true
#    udfGetIniSection $iniChild test csvResult                                  ##udfGetIniSection ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfGetIniSection ? true
#    rm -f $iniChild $ini                                                       ##udfGetIniSection
#  SOURCE
udfGetIniSection() {
 [ -n "$1" ] || return 255
 #
 local bashlyk_aini_rWrBeelW bashlyk_csvIni_rWrBeelW bashlyk_csvResult_rWrBeelW
 local bashlyk_ini_rWrBeelW bashlyk_pathIni_rWrBeelW bashlyk_s_rWrBeelW
 local bashlyk_sTag_rWrBeelW
 #
 bashlyk_ini_rWrBeelW=''
 bashlyk_pathIni_rWrBeelW="$_bashlyk_pathIni"
 #
 [ "$1"  = "${1##*/}" -a -f ${bashlyk_pathIni_rWrBeelW}/$1 ] \
  || bashlyk_pathIni_rWrBeelW=
 [ "$1"  = "${1##*/}" -a -f $1 ] && bashlyk_pathIni_rWrBeelW=$(pwd)
 [ "$1" != "${1##*/}" -a -f $1 ] && bashlyk_pathIni_rWrBeelW=$(dirname $1)
 [ -n "$2" ] && bashlyk_sTag_rWrBeelW="$2"
 #
 if [ -z "$bashlyk_pathIni_rWrBeelW" ]; then
  [ -f "/etc${_bashlyk_pathPrefix}/$1" ] \
   && bashlyk_pathIni_rWrBeelW="/etc${_bashlyk_pathPrefix}" || return 1
 fi
 #
 bashlyk_aini_rWrBeelW=$(echo "${1##*/}" |\
  awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')
 for bashlyk_s_rWrBeelW in $bashlyk_aini_rWrBeelW; do
  [ -n "$bashlyk_s_rWrBeelW" ] || continue
  [ -n "$bashlyk_ini_rWrBeelW" ] \
   && bashlyk_ini_rWrBeelW="${bashlyk_s_rWrBeelW}.${bashlyk_ini_rWrBeelW}" \
   || bashlyk_ini_rWrBeelW="$bashlyk_s_rWrBeelW"
  [ -s "${bashlyk_pathIni_rWrBeelW}/${bashlyk_ini_rWrBeelW}" ] \
   && bashlyk_csvIni_rWrBeelW+=";$(udfReadIniSection \
    "${bashlyk_pathIni_rWrBeelW}/${bashlyk_ini_rWrBeelW}" \
    "$bashlyk_sTag_rWrBeelW");"
    echo "${bashlyk_pathIni_rWrBeelW}/${bashlyk_ini_rWrBeelW}" >> /tmp/$$.log
 done
 udfCsvOrder "$bashlyk_csvIni_rWrBeelW" bashlyk_csvResult_rWrBeelW
 if [ -n "$3" ]; then
  udfIsValidVariable "$3" || return 2
  eval 'export ${3}="${bashlyk_csvResult_rWrBeelW}"'
 else
  echo "$bashlyk_csvResult_rWrBeelW"
 fi
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
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;' csvResult             ##udfReadIniSection
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild                 ##udfReadIniSection
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfReadIniSection
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfReadIniSection ? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini ##udfReadIniSection
#    udfReadIniSection $ini test | grep "^${csv}$"                              ##udfReadIniSection ? true
#    udfReadIniSection $ini test csvResult                                      ##udfReadIniSection ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfReadIniSection ? true
#    rm -f $ini                                                                 ##udfReadIniSection
#  SOURCE
udfReadIniSection() {
 [ -n "$1" -a -f "$1" ] || return 255
 local bashlyk_ini_yLn0ZVLi bashlyk_csvResult_yLn0ZVLi bashlyk_b_yLn0ZVLi
 local bashlyk_bOpen_yLn0ZVLi bashlyk_k_yLn0ZVLi bashlyk_v_yLn0ZVLi
 local bashlyk_s_yLn0ZVLi bashlyk_sTag_yLn0ZVLi bashlyk_i_yLn0ZVLi
 #
 bashlyk_ini_yLn0ZVLi="$1"
 bashlyk_bOpen_yLn0ZVLi=false
 bashlyk_i_yLn0ZVLi=0
 #
 [ -n "$2" ] && bashlyk_sTag_yLn0ZVLi="$2" || bashlyk_bOpen_yLn0ZVLi=true
 while read bashlyk_s_yLn0ZVLi; do
  ( echo $bashlyk_s_yLn0ZVLi | grep "^#\|^$" )>/dev/null && continue
  bashlyk_b_yLn0ZVLi=$(echo $bashlyk_s_yLn0ZVLi | grep -oE '\[.*\]' \
   | tr -d '[]' | xargs)
  if [ -n "$bashlyk_b_yLn0ZVLi" ]; then
   $bashlyk_bOpen_yLn0ZVLi && break
   if [ "$bashlyk_b_yLn0ZVLi" = "$bashlyk_sTag_yLn0ZVLi" ]; then
    bashlyk_csvResult_yLn0ZVLi=''
    bashlyk_bOpen_yLn0ZVLi=true
   else
    continue
   fi
  else
   $bashlyk_bOpen_yLn0ZVLi || continue
   bashlyk_s_yLn0ZVLi=$(echo $bashlyk_s_yLn0ZVLi | tr -d "'")
   bashlyk_k_yLn0ZVLi="$(echo ${bashlyk_s_yLn0ZVLi%%=*}|xargs)"
   bashlyk_v_yLn0ZVLi="$(echo ${bashlyk_s_yLn0ZVLi#*=}|xargs)"
   if [ "$bashlyk_k_yLn0ZVLi" = "$bashlyk_v_yLn0ZVLi" \
    -o -n "$(echo "$bashlyk_k_yLn0ZVLi" | grep '.*[[:space:]+].*')" ]; then
    bashlyk_k_yLn0ZVLi=_zzz_bashlyk_line_${bashlyk_i_yLn0ZVLi}
    bashlyk_i_yLn0ZVLi=$((bashlyk_i_yLn0ZVLi+1))
   fi
   bashlyk_csvResult_yLn0ZVLi+="$bashlyk_k_yLn0ZVLi=$(udfQuoteIfNeeded \
    $bashlyk_v_yLn0ZVLi);"
  fi
 done < $bashlyk_ini_yLn0ZVLi
 $bashlyk_bOpen_yLn0ZVLi || bashlyk_csvResult_yLn0ZVLi=''
 if [ -n "$3" ]; then
  udfIsValidVariable "$3" || return 2
  #udfThrow "Error: required valid variable name \"$3\""
  eval 'export ${3}="${bashlyk_csvResult_yLn0ZVLi}"'
 else
  echo "$bashlyk_csvResult_yLn0ZVLi"
 fi
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
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo bar;b=true;iXo=1920;' ##udfCsvOrder
#    local csvResult                                                            ##udfCsvOrder
#    local csvTest='b=true;iXo=1920;iYo=1080;sTxt="foo bar";'                   ##udfCsvOrder
#    udfCsvOrder "$csv" | grep "^${csvTest}$"                                   ##udfCsvOrder ? true
#    udfCsvOrder "$csv" csvResult                                               ##udfCsvOrder ? true
#    echo $csvResult | grep "^${csvTest}$"                                      ##udfCsvOrder ? true
#  SOURCE
udfCsvOrder() {
 [ -n "$1" ] || return 255
 local bashlyk_fnExec_YAogTAX2 bashlyk_aKeys_YAogTAX2 bashlyk_csv_YAogTAX2
 local bashlyk_csvResult_YAogTAX2
 #
 bashlyk_csv_YAogTAX2="$(udfCheckCsv "$1")"
 bashlyk_aKeys_YAogTAX2="$(udfCsvKeys "$bashlyk_csv_YAogTAX2" | tr ' ' '\n' \
  | sort -u | uniq -u | xargs)"
 bashlyk_csv_YAogTAX2=$(echo "$bashlyk_csv_YAogTAX2" | tr ';' '\n')
 #
 udfMakeTemp bashlyk_fnExec_YAogTAX2
 #
 cat << _CsvOrder_EOF > $bashlyk_fnExec_YAogTAX2
#!/bin/bash
#
# . bashlyk
#
udfAssembly() {
 local $bashlyk_aKeys_YAogTAX2
 #
 $bashlyk_csv_YAogTAX2
 #
 udfShowVariable $bashlyk_aKeys_YAogTAX2 | grep -v Variable | tr -d '\t' \
  | sed -e "s/=\(.*[[:space:]]\+.*\)/=\"\1\"/" | tr '\n' ';' | sed -e "s/;;/;/"
 #
 return 0
}
#
udfAssembly
_CsvOrder_EOF

 bashlyk_csvResult_YAogTAX2=$(. $bashlyk_fnExec_YAogTAX2 2>/dev/null)
 rm -f $bashlyk_fnExec_YAogTAX2
 if [ -n "$2" ]; then
  udfIsValidVariable "$2" || return 2
  #udfThrow "Error: required valid variable name \"$2\""
  eval 'export ${2}="${bashlyk_csvResult_YAogTAX2}"'
 else
  echo "$bashlyk_csvResult_YAogTAX2"
 fi
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
#  EXAMPLE
#    local b sTxt iXo iYo                                                       ##udfSetVarFromCsv
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo bar;b=true;iXo=1920;' ##udfSetVarFromCsv
#    udfSetVarFromCsv "$csv" b sTxt iXo iYo                                     ##udfSetVarFromCsv
#    udfShowVariable b sTxt iXo iYo                                             ##udfSetVarFromCsv
#  SOURCE
udfSetVarFromCsv() {
 [ -n "$1" ] || return 255
 #
 local bashlyk_csvInput_KLokRJky bashlyk_csvResult_KLokRJky bashlyk_k_KLokRJky
 #
 bashlyk_csvInput_KLokRJky=";$(udfCsvOrder "$1");"
 shift
 #
 for bashlyk_k_KLokRJky in $*; do
  #bashlyk_csvResult_KLokRJky=$(echo $bashlyk_csvInput_KLokRJky | grep -Po ";$bashlyk_k_KLokRJky=.*?;" | tr -d ';')
  bashlyk_csvResult_KLokRJky=$(echo \
   "$bashlyk_k_KLokRJky=${bashlyk_csvInput_KLokRJky#*;$bashlyk_k_KLokRJky=}" \
   | cut -f1 -d';')
  [ -n "$bashlyk_csvResult_KLokRJky" ] \
   && eval "$bashlyk_csvResult_KLokRJky" 2>/dev/null
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
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;' csvResult             ##udfSetVarFromIni
#    local sTxt b iXo iYo ini                                                   ##udfSetVarFromIni
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfSetVarFromIni
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfSetVarFromIni ? true
#    printf "$fmt" "sTxt" "foo" "b" "false" "iXo" "720" "iYo" "999" | tee $ini  ##udfSetVarFromIni
#    udfSetVarFromIni $ini test sTxt b iXo iYo                                  ##udfSetVarFromIni ? true
#    udfShowVariable sTxt b iXo iYo                                             ##udfSetVarFromIni ? true
#    rm -f $ini                                                                 ##udfSetVarFromIni
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
#              строка ключей
#  RETURN VALUE
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;' csvResult             ##udfCsvKeys
#    udfCsvKeys "$csv"                                                          ##udfCsvKeys ? true
#    udfCsvKeys "$csv" | xargs | grep "^sTxt b iXo iYo$"                        ##udfCsvKeys ? true
#    udfCsvKeys "$csv" csvResult                                                ##udfCsvKeys ? true
#    echo $csvResult | grep "^sTxt b iXo iYo$"                                  ##udfCsvKeys ? true
#  SOURCE
udfCsvKeys() {
 [ -n "$1" ] || return 255
 local bashlyk_cIFS_xWuzbRzM bashlyk_csv_xWuzbRzM bashlyk_csvResult_xWuzbRzM
 local bashlyk_s_xWuzbRzM
 #
 bashlyk_csv_xWuzbRzM="$1"
 bashlyk_cIFS_xWuzbRzM=$IFS
 IFS=';'
 for bashlyk_s_xWuzbRzM in $bashlyk_csv_xWuzbRzM; do
  bashlyk_csvResult_xWuzbRzM+="${bashlyk_s_xWuzbRzM%%=*} "
 done
 IFS=$bashlyk_cIFS_xWuzbRzM
 if [ -n "$2" ];then
  udfIsValidVariable "$2" || return 2
  #udfThrow "Error: required valid variable name \"$2\""
  eval 'export ${2}="${bashlyk_csvResult_xWuzbRzM}"'
 else
  echo "$bashlyk_csvResult_xWuzbRzM"
 fi
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
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует
#  SOURCE
udfCheckCsv() {
 [ -n "$1" ] || return 255
 local bashlyk_s_Q1eiphgO bashlyk_cIFS_Q1eiphgO bashlyk_k_Q1eiphgO
 local bashlyk_v_Q1eiphgO bashlyk_i_Q1eiphgO bashlyk_csvResult_Q1eiphgO
 #
 bashlyk_cIFS_Q1eiphgO=$IFS
 IFS=';'
 bashlyk_i_Q1eiphgO=0
 bashlyk_csvResult_Q1eiphgO=''
 #
 for bashlyk_s_Q1eiphgO in $1; do
  bashlyk_s_Q1eiphgO=$(echo $bashlyk_s_Q1eiphgO | tr -d "'" | tr -d '"')
  bashlyk_k_Q1eiphgO="$(echo ${bashlyk_s_Q1eiphgO%%=*}|xargs)"
  bashlyk_v_Q1eiphgO="$(echo ${bashlyk_s_Q1eiphgO#*=}|xargs)"
  [ -n "$bashlyk_k_Q1eiphgO" ] || continue
  if [ "$bashlyk_k_Q1eiphgO" = "$bashlyk_v_Q1eiphgO" \
   -o -n "$(echo "$bashlyk_k_Q1eiphgO" | grep '.*[[:space:]+].*')" ]; then
   bashlyk_k_Q1eiphgO=_zzz_bashlyk_line_${bashlyk_i_Q1eiphgO}
   bashlyk_i_Q1eiphgO=$((bashlyk_i_Q1eiphgO+1))
  fi
  bashlyk_csvResult_Q1eiphgO+="$bashlyk_k_Q1eiphgO=$(udfQuoteIfNeeded \
   $bashlyk_v_Q1eiphgO);"
 done
 IFS=$bashlyk_cIFS_Q1eiphgO
 if [ -n "$2" ]; then
  udfIsValidVariable "$2" || return 2
  #udfThrow "Error: required valid variable name \"$2\""
  eval 'export ${2}="${bashlyk_csvResult_Q1eiphgO}"'
 else
  echo "$bashlyk_csvResult_Q1eiphgO"
 fi
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
 echo "$csv" | sed -e "s/[;]\+/;/g" -e "s/\[/;\[/g" | tr ';' '\n' \
  | sed -e "s/\(.*\)=/\t\1\t=\t/g" -e "s/_zzz_bashlyk_line_.*\t=\t//g" \
  | tr -d '"' > "$ini"
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

