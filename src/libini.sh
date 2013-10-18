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
[ -s "${_bashlyk_pathLib}/libstd.sh" ] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****v*  bashlyk/libini/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathIni:=$(pwd)}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}
: ${_bashlyk_aRequiredCmd_ini:="[ awk cat cut dirname echo false grep mv printf pwd rm sed sort touch tr true uniq w xargs"}
: ${_bashlyk_aExport_ini:="udfGetIniSection udfReadIniSection udfCsvOrder udfAssembly udfSetVarFromCsv udfSetVarFromIni udfCsvKeys udfIniWrite udfIniChange udfGetIni udfGetCsvSection udfGetLines2Csv udfIniGroupSection2Csv"}
#: ${_bashlyk_aExport_ini:="udfGetIniSection udfReadIniSection udfIniSection2Csv udfIniGroupSection2Csv"}
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
#    local csv='b=true;_bashlyk_unnamed_key_0="iXo Xo = 19";_bashlyk_unnamed_key_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'  ##udfGetIniSection
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild                 ##udfGetIniSection
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfGetIniSection
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfGetIniSection ? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          ##udfGetIniSection
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini               ##udfGetIniSection
#    echo "simple line" | tee -a $ini                                           ##udfGetIniSection
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $iniChild  ##udfGetIniSection
#    time udfGetIniSection $iniChild test                                            ##udfGetIniSection ? true
#    udfGetIniSection $iniChild test | grep "^${csv}$"                          ##udfGetIniSection ? true
#    time udfGetIniSection $iniChild test csvResult                                  ##udfGetIniSection ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfGetIniSection ? true
#    rm -f $iniChild $ini                                                       ##udfGetIniSection
#  SOURCE
udfGetIniSection() {
 [ -n "$1" ] || return 255
 #
 local bashlyk_aini_rWrBeelW bashlyk_csvIni_rWrBeelW bashlyk_csvResult_rWrBeelW
 local bashlyk_ini_rWrBeelW bashlyk_pathIni_rWrBeelW bashlyk_s_rWrBeelW
 local bashlyk_sTag_rWrBeelW bashlyk_sGlobIgnore_rWrBeelW
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
  [ -f "/etc/${_bashlyk_pathPrefix}/$1" ] \
   && bashlyk_pathIni_rWrBeelW="/etc/${_bashlyk_pathPrefix}" || return 1
 fi
 #
 bashlyk_aini_rWrBeelW=$(echo "${1##*/}" |\
  awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

 bashlyk_sGlobIgnore_rWrBeelW=$GLOBIGNORE
 GLOBIGNORE="*:?"

 for bashlyk_s_rWrBeelW in $bashlyk_aini_rWrBeelW; do
  [ -n "$bashlyk_s_rWrBeelW" ] || continue
  [ -n "$bashlyk_ini_rWrBeelW" ] \
   && bashlyk_ini_rWrBeelW="${bashlyk_s_rWrBeelW}.${bashlyk_ini_rWrBeelW}" \
   || bashlyk_ini_rWrBeelW="$bashlyk_s_rWrBeelW"
  [ -s "${bashlyk_pathIni_rWrBeelW}/${bashlyk_ini_rWrBeelW}" ] \
   && bashlyk_csvIni_rWrBeelW+=";$(udfReadIniSection \
    "${bashlyk_pathIni_rWrBeelW}/${bashlyk_ini_rWrBeelW}" \
    "$bashlyk_sTag_rWrBeelW");"
 done

 udfCsvOrder "$bashlyk_csvIni_rWrBeelW" bashlyk_csvResult_rWrBeelW

 GLOBIGNORE=$bashlyk_sGlobIgnore_rWrBeelW

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
#    ключом становится выражение ${_bashlyk_sUnnamedKeyword}_<инкремент>, а всё
#    содержимое строки - значением.
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных 
#              или до конца конфигурационного файла, если секций нет
#    varname - идентификатор переменной (без "$"). При его наличии результат
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
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_bashlyk_unnamed_key_0="simple line";' ##udfReadIniSection
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult       ##udfReadIniSection
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfReadIniSection
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfReadIniSection ? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini ##udfReadIniSection
#    echo "simple line" | tee -a $ini                                           ##udfReadIniSection
#    time udfReadIniSection $ini test                                                ##udfReadIniSection ? true
#    udfReadIniSection $ini test | grep "^${csv}$"                              ##udfReadIniSection ? true
#    time udfReadIniSection $ini test csvResult                                      ##udfReadIniSection ? true
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
   bashlyk_k_yLn0ZVLi="$(echo ${bashlyk_s_yLn0ZVLi%%=*}|xargs -0)"
   bashlyk_v_yLn0ZVLi="$(echo ${bashlyk_s_yLn0ZVLi#*=}|xargs -0)"
   if [ -z "$bashlyk_k_yLn0ZVLi" -o "$bashlyk_k_yLn0ZVLi" = "$bashlyk_v_yLn0ZVLi" \
    -o -n "$(echo "$bashlyk_k_yLn0ZVLi" | grep '.*[[:space:]+].*')" ]; then
    bashlyk_k_yLn0ZVLi=${_bashlyk_sUnnamedKeyword}${bashlyk_i_yLn0ZVLi}
    bashlyk_i_yLn0ZVLi=$((bashlyk_i_yLn0ZVLi+1))
    bashlyk_v_yLn0ZVLi="$bashlyk_s_yLn0ZVLi"
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
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo = bar;b=true;iXo=1920;' ##udfSetVarFromCsv
#    local sResult="true:foo = bar:1920:1080"                                   ##udfSetVarFromCsv
#    udfSetVarFromCsv "$csv" b sTxt iXo iYo                                     ##udfSetVarFromCsv ? true
#    echo "${b}:${sTxt}:${iXo}:${iYo}" | grep "^${sResult}$"                    ##udfSetVarFromCsv ? true
#  SOURCE
udfSetVarFromCsv() {
 [ -n "$1" ] || return 255
 #
 local bashlyk_csvInput_KLokRJky bashlyk_csvResult_KLokRJky 
 local bashlyk_k_KLokRJky bashlyk_v_KLokRJky
 #
 bashlyk_csvInput_KLokRJky=";$(udfCsvOrder "$1");"
 shift
 #
 for bashlyk_k_KLokRJky in $*; do
  #bashlyk_csvResult_KLokRJky=$(echo $bashlyk_csvInput_KLokRJky | grep -Po ";$bashlyk_k_KLokRJky=.*?;" | tr -d ';')
  bashlyk_v_KLokRJky="$(echo "${bashlyk_csvInput_KLokRJky#*;$bashlyk_k_KLokRJky=}" | cut -f 1 -d ';')"
  if [ -n "$bashlyk_v_KLokRJky" ]; then
   eval "$bashlyk_k_KLokRJky=$bashlyk_v_KLokRJky" 2>/dev/null
  fi
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
#    local sResult='true:foo bar:1024:768'                                      ##udfSetVarFromIni
#    local sTxt b iXo iYo ini                                                   ##udfSetVarFromIni
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfSetVarFromIni
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfSetVarFromIni ? true
#    printf "$fmt" sTxt "foo bar" b true iXo 1024 iYo 768 | tee $ini            ##udfSetVarFromIni
#    udfSetVarFromIni $ini test sTxt b iXo iYo                                  ##udfSetVarFromIni ? true
#    echo "${b}:${sTxt}:${iXo}:${iYo}" | grep "^${sResult}$"                    ##udfSetVarFromIni ? true
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
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;' sResult               ##udfCsvKeys
#    udfCsvKeys "$csv"                                                          ##udfCsvKeys ? true
#    udfCsvKeys "$csv" | xargs | grep "^sTxt b iXo iYo$"                        ##udfCsvKeys ? true
#    udfCsvKeys "$csv" sResult                                                  ##udfCsvKeys ? true
#    echo $sResult | grep "^sTxt b iXo iYo$"                                    ##udfCsvKeys ? true
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
#  EXAMPLE
#    local csv='[test];sTxt="foo bar";b=true;iXo=1921;iYo=1080;' ini s          ##udfIniWrite
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfIniWrite ? true
#    udfIniWrite $ini "$csv"                                                    ##udfIniWrite ? true
#     grep -E '^\[test\]$'        $ini                                          ##udfIniWrite ? true
#     grep -E 'sTxt.*=.*foo bar$' $ini                                          ##udfIniWrite ? true
#     grep -E 'b.*=.*true$'       $ini                                          ##udfIniWrite ? true
#     grep -E 'iXo.*=.*1921$'     $ini                                          ##udfIniWrite ? true
#     grep -E 'iYo.*=.*1080$'     $ini                                          ##udfIniWrite ? true
#     cat $ini                                                                  ##udfIniWrite
#     rm -f $ini ${ini}.bak                                                     ##udfIniWrite
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
  | sed -e "s/${_bashlyk_sUnnamedKeyword}[0-9]\+=//g" \
   -e "s/\(.*\)=/\t\1\t=\t/g" | tr -d '"' > "$ini"
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
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=999;' csvResult              ##udfIniChange
#    local sTxt="bar foo" b=true iXo=1234 iYo=4321 ini                          ##udfIniChange
#    local fmt="[sect%s]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n" ##udfIniChange
#    local md5='85d52ed0688bc4406aa0021b44901ba4'                               ##udfIniChange
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfIniChange ? true
#    printf "$fmt" 1 sTxt foo '' value iXo 720 "non valid key" value | tee $ini ##udfIniChange
#    echo "simple line" | tee -a $ini                                           ##udfIniChange
#    printf "$fmt" 2 sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee -a $ini    ##udfIniChange
#    udfIniChange $ini "$csv" sect1                                             ##udfIniChange ? true
#    udfReadIniSection $ini sect1 | md5sum | grep "^${md5}.*-$"                 ##udfIniChange ? true
#    rm -f $ini ${ini}.bak                                                      ##udfIniChange
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
#****f* bashlyk/libini/udfGetIni
#  SYNOPSIS
#    udfGetIni <file> <csvSections> [<varname>]
#  DESCRIPTION
#    Получить опции секций <csvSections> конфигурации <file> в CSV-строку в
#    формате "[section];<key>=<value>;..." в переменную <varname>, если 
#    представлена или на стандартный вывод
#  INPUTS
#     file - файл конфигурации формата "*.ini".
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргументы отсутствуют
#  EXAMPLE
#    local csv='b=true;_bashlyk_unnamed_key_0="iXo Xo = 19";_bashlyk_unnamed_key_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";' ##udfGetIni
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild                 ##udfGetIni
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfGetIni
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfGetIni ? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          ##udfGetIni
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini               ##udfGetIni
#    echo "simple line" | tee -a $ini                                           ##udfGetIni
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $iniChild  ##udfGetIni
#    udfGetIni $iniChild test                                                   ##udfGetIni ? true
#    udfGetIni $iniChild test | grep "^\[\];;\[test\];${csv}$"                  ##udfGetIni ? true
#    udfGetIni $iniChild test csvResult                                         ##udfGetIni ? true
#    echo "$csvResult" | grep "^\[\];;\[test\];${csv}$"                         ##udfGetIni ? true
#    rm -f $iniChild $ini                                                       ##udfGetIni
#  SOURCE
udfGetIni() {
 [ -n "$2" ] || return 255
 #
 local bashlyk_csv_HNAuwHlU bashlyk_ini_HNAuwHlU bashlyk_s_HNAuwHlU
 #
 for bashlyk_s_HNAuwHlU in "" $(echo $2 | tr ',' ' '); do
  bashlyk_csv_HNAuwHlU+="[${bashlyk_s_HNAuwHlU}];$(udfGetIniSection $1 \
  "$bashlyk_s_HNAuwHlU")"
 done
 if [ -n "$3" ];then
  udfIsValidVariable "$3" || return 2
  eval 'export ${3}="${bashlyk_csv_HNAuwHlU}"'
 else
  echo "$bashlyk_csv_HNAuwHlU"
 fi
 return 0
}
#******
#****f* bashlyk/libini/udfGetCsvSection
#  SYNOPSIS
#    udfGetCsvSection <csv> <tag>
#  DESCRIPTION
#    Выделить из CSV-строки <csv> фрагмент вида "[tag];key=value;...;" до
#    символа [ (очередная секция) или конца строки
#    формате "[section];<key>=<value>;..." в переменную <varname>, если
#    представлена или на стандартный вывод
#  INPUTS
#    tag - имя ini-секции
#    csv - строка сериализации данных ini-файлов
#  OUTPUT
#    csv; строка без заголовка секции [tag]
#  RETURN VALUE
#     0  - Выполнено успешно
#  EXAMPLE
#    local csv='[];a=b;c=d e;[s1];a=f;c=g h;[s2];a=k;c=l m;'                    ##udfGetCsvSection
#    udfGetCsvSection "$csv" | grep '^a=b;c=d e;$'                              ##udfGetCsvSection ? true
#    udfGetCsvSection "$csv" s1 | grep '^a=f;c=g h;$'                           ##udfGetCsvSection ? true
#    udfGetCsvSection "$csv" s2 | grep '^a=k;c=l m;$'                           ##udfGetCsvSection ? true
#  SOURCE
udfGetCsvSection() {
 local bashlyk_csv_KLokRJk1
 bashlyk_csv_KLokRJk1=$(echo "${1#*\[$2\];}" | cut -f1 -d'[')
 if [ -n "$3" ];then
  udfIsValidVariable "$3" || return 2
  eval 'export ${3}="${bashlyk_csv_KLokRJk1}"'
 else
  echo "$bashlyk_csv_KLokRJk1"
 fi
 return 0
}
#******
#****f* bashlyk/libini/udfGetLines2Csv
# TODO отредактировать описание и тест
#  SYNOPSIS
#    udfGetLines2Csv <csv> <tag>
#  DESCRIPTION
#    Выделить из CSV-строки <csv> вида "[tag];key=value;...;" до
#    символа [ (очередная секция) или конца строки все поля, которые не
#    представляют собой пару "key=value" в
#    формате "<value>;..." в переменную <varname>, если
#    представлена или на стандартный вывод
#  INPUTS
#    tag - имя ini-секции
#    csv - строка сериализации данных ini-файлов
#  OUTPUT
#    csv; строка без заголовка секции [tag]
#  RETURN VALUE
#     0  - Выполнено успешно
#  EXAMPLE
#    local csv='[];a=b;c=d e;[s1];a=f;c=g h;[s2];a=k;c=l m;'                    ##udfGetLines2Csv
#    udfGetLines2Csv "$csv" | grep '^a=b;c=d e;$'                              ##udfGetLines2Csv ? true
#    udfGetLines2Csv "$csv" s1 | grep '^a=f;c=g h;$'                           ##udfGetLines2Csv ? true
#    udfGetLines2Csv "$csv" s2 | grep '^a=k;c=l m;$'                           ##udfGetLines2Csv ? true
#  SOURCE
udfGetLines2Csv() {
 local cIFS s csv
 cIFS=$IFS
 IFS=';'
 for s in $(echo "${1#*\[$2\];}" | cut -f1 -d'[')
 do
  s=$(echo "$s" | grep "^${_bashlyk_sUnnamedKeyword}" | sed -e "s/${_bashlyk_sUnnamedKeyword}.*=//")
  [ -n "$s" ] && csv+="${s};"
 done
 IFS=$cIFS
 echo "$csv"
}
#****f* bashlyk/libini/udfIniSection2Csv
#  SYNOPSIS
#    udfIniSection2Csv <file> [<section>] [<varname>]
#  DESCRIPTION
#    Получить секцию конфигурационных данных <section> из файла <file> и выдать
#    результат в виде строки CSV, разделенных ';', каждое поле которой содержит
#    данные в формате "<ключ>=<значение>" согласно данных строки секции.
#    В случае если исходная строка не содержит ключ или ключ содержит пробел, то
#    ключом становится выражение ${_bashlyk_sUnnamedKeyword}_<инкремент>, а всё
#    содержимое строки - значением.
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных 
#              или до конца конфигурационного файла, если секций нет
#    varname - идентификатор переменной (без "$"). При его наличии результат
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
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_test_Key_0="simple line";' ##udfIniSection2Csv
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult       ##udfIniSection2Csv
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfIniSection2Csv
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfIniSection2Csv ? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini ##udfIniSection2Csv
#    echo "simple line" | tee -a $ini                                           ##udfIniSection2Csv
#    time udfIniSection2Csv $ini test                                                ##udfIniSection2Csv ? true
#    udfIniSection2Csv $ini test | grep "^${csv}$"                              ##udfIniSection2Csv ? true
#    time udfIniSection2Csv $ini test csvResult                                      ##udfIniSection2Csv ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfIniSection2Csv ? true
#    rm -f $ini                                                                 ##udfIniSection2Csv
#  SOURCE
udfIniSection2Csv() {
 [ -n "$1" -a -f "$1" ] || return 255
 local bashlyk_csvResult_yLn0ZVLi="$(awk -f ${_bashlyk_pathLib}/inisection2csv.awk -v "sTag=$2" -- $1)"
 #
 if [ -n "$3" ]; then
  udfIsValidVariable "$3" || return 2
  #udfThrow "Error: required valid variable name \"$1\""
  eval 'export ${3}="$bashlyk_csvResult_yLn0ZVLi"'
 else
  echo "$bashlyk_csvResult_yLn0ZVLi"
 fi
 return 0
}
#******
#****f* bashlyk/libini/udfIniGroupSection2Csv
#  SYNOPSIS
#    udfIniGroupSection2Csv <file> [<section>] [<varname>]
#  DESCRIPTION
#    Получить конфигурационные данные секции <section> из <file> и, при наличии,
#    от группы "родительских" к нему файлов. Например, если <file> это 
#    "a.b.c.ini", то "родительскими" будут считаться файлы "ini", "c.ini" и 
#    "b.c.ini" если они есть в том же каталоге. Данные наследуются и 
#    перекрываются от "старшего" файла к младшему.
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
#    local csv='b=true;iXo=1921;iYo=1080;sTxt="foo bar";_test_Key_0="iXo Xo = 19";_test_Key_1="simple line";'  ##udfIniGroupSection2Csv
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild                 ##udfIniGroupSection2Csv
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfIniGroupSection2Csv
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfIniGroupSection2Csv ? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          ##udfIniGroupSection2Csv
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini               ##udfIniGroupSection2Csv
#    echo "simple line" | tee -a $ini                                           ##udfIniGroupSection2Csv
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $iniChild  ##udfIniGroupSection2Csv
#    time udfIniGroupSection2Csv $iniChild test                                       ##udfIniGroupSection2Csv ? true
#    udfIniGroupSection2Csv $iniChild test | grep "^${csv}$"                          ##udfIniGroupSection2Csv ? true
#    time udfIniGroupSection2Csv $iniChild test csvResult                             ##udfIniGroupSection2Csv ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfIniGroupSection2Csv ? true
#    rm -f $iniChild $ini                                                       ##udfIniGroupSection2Csv
#  SOURCE
udfIniGroupSection2Csv() {
 [ -n "$1" ] || return 255
 #
 local bashlyk_aini_rWrBeelW bashlyk_csvIni_rWrBeelW bashlyk_csvResult_rWrBeelW
 local bashlyk_ini_rWrBeelW bashlyk_pathIni_rWrBeelW bashlyk_s_rWrBeelW
 local bashlyk_sTag_rWrBeelW bashlyk_sGlobIgnore_rWrBeelW
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
  [ -f "/etc/${_bashlyk_pathPrefix}/$1" ] \
   && bashlyk_pathIni_rWrBeelW="/etc/${_bashlyk_pathPrefix}" || return 1
 fi
 #
 bashlyk_aini_rWrBeelW=$(echo "${1##*/}" |\
  awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

 bashlyk_sGlobIgnore_rWrBeelW=$GLOBIGNORE
 GLOBIGNORE="*:?"

 for bashlyk_s_rWrBeelW in $bashlyk_aini_rWrBeelW; do
  [ -n "$bashlyk_s_rWrBeelW" ] || continue
  [ -n "$bashlyk_ini_rWrBeelW" ] \
   && bashlyk_ini_rWrBeelW="${bashlyk_s_rWrBeelW}.${bashlyk_ini_rWrBeelW}" \
   || bashlyk_ini_rWrBeelW="$bashlyk_s_rWrBeelW"
  [ -s "${bashlyk_pathIni_rWrBeelW}/${bashlyk_ini_rWrBeelW}" ] \
   && bashlyk_csvIni_rWrBeelW+=";$(udfIniSection2Csv \
    "${bashlyk_pathIni_rWrBeelW}/${bashlyk_ini_rWrBeelW}" \
    "$bashlyk_sTag_rWrBeelW");"
 done

 udfCsvOrder "$bashlyk_csvIni_rWrBeelW" bashlyk_csvResult_rWrBeelW

 GLOBIGNORE=$bashlyk_sGlobIgnore_rWrBeelW

 if [ -n "$3" ]; then
  udfIsValidVariable "$3" || return 2
  eval 'export ${3}="${bashlyk_csvResult_rWrBeelW}"'
 else
  echo "$bashlyk_csvResult_rWrBeelW"
 fi
 return 0
}
#******
