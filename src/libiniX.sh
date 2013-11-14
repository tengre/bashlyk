#
# $Id: libini.sh 272 2013-11-06 13:28:19Z yds $
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
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_ini_void_autoKey_}
: ${_bashlyk_aRequiredCmd_ini:="[ awk cat cut dirname echo false grep mv printf pwd rm sed sort touch tr true uniq w xargs"}
: ${_bashlyk_aExport_ini:="udfGetIniSection udfReadIniSection udfReadIniSection2Var udfCsvOrder udfAssembly udfSetVarFromCsv udfSetVarFromIni udfCsvKeys udfIniWrite udfIniChange udfGetIni udfGetCsvSection udfGetCsvSection2Var udfGetIniSection2Var udfCsvOrder2Var udfCsvKeys2Var udfGetIni2Var udfGetLines2Csv udfIniGroupSection2Csv udfIniGroupSection2CsvVar udfIni2Csv udfIni2CsvVar udfIniGroup2Csv udfIniGroup2CsvVar udfIni"}
#: ${_bashlyk_aExport_ini:="udfGetIniSection udfReadIniSection udfIniSection2Csv udfIniGroupSection2Csv"}
#******
#****f* bashlyk/libini/udfGetIniSection
#  SYNOPSIS
#    udfGetIniSection <file> [<section>]
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
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся 
#              конфигурационные данные в формате "<key>=<value>;..."
#  RETURN VALUE
#     0  - Выполнено успешно
#     1  - Ошибка: файл конфигурации не найден
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'  ##udfGetIniSection
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild                 ##udfGetIniSection
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfGetIniSection
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfGetIniSection ? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          ##udfGetIniSection
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini               ##udfGetIniSection
#    echo "simple line" | tee -a $ini                                           ##udfGetIniSection
#    printf "$fmt" sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee $iniChild    ##udfGetIniSection
#    udfGetIniSection $iniChild test                                            ##udfGetIniSection ? true
#    udfGetIniSection $iniChild test | grep "^${csv}$"                          ##udfGetIniSection ? true
#    udfGetIniSection2Var csvResult $iniChild test                              ##udfGetIniSection ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfGetIniSection ? true
#    rm -f $iniChild $ini                                                       ##udfGetIniSection
#  SOURCE
udfGetIniSection() {
 [ -n "$1" ] || return 255
 #
 local aini csvIni csvResult
 local ini pathIni s
 local sTag sGlobIgnore
 #
 ini=''
 pathIni="$_pathIni"
 #
 [ "$1"  = "${1##*/}" -a -f ${pathIni}/$1 ] || pathIni=
 [ "$1"  = "${1##*/}" -a -f $1 ] && pathIni=$(pwd)
 [ "$1" != "${1##*/}" -a -f $1 ] && pathIni=$(dirname $1)
 [ -n "$2" ] && sTag="$2"
 #
 if [ -z "$pathIni" ]; then
  [ -f "/etc/${_bashlyk_pathPrefix}/$1" ] && pathIni="/etc/${_bashlyk_pathPrefix}" || return 1
 fi
 #
 aini=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

 sGlobIgnore=$GLOBIGNORE
 GLOBIGNORE="*:?"

 for s in $aini; do
  [ -n "$s" ] || continue
  [ -n "$ini" ] && ini="${s}.${ini}" || ini="$s"
  [ -s "${pathIni}/${ini}" ] && csvIni+=";$(udfIniSection2Csv "${pathIni}/${ini}" "$sTag");"
 done
 
 GLOBIGNORE=$sGlobIgnore
 
 udfCsvOrder "$csvIni"
 return 0
}
#******
#****f* bashlyk/libini/udfGetIniSection2Var
#  SYNOPSIS
#    udfGetIniSection <varname> <file> [<section>]
#  DESCRIPTION
#    поместить результат вызова udfGetIniSection в переменную <varname>
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных или
#              до конца конфигурационного файла, если секций нет
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде
#              CSV; строки формата "ключ=значение;" будет помещен в
#              соответствующую переменную.
#  RETURN VALUE
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    пример приведен в описании udfGetIniSection
#  SOURCE
udfGetIniSection2Var() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 eval 'export ${1}="$(udfGetIniSection "$2" $3)"'
 return 0
}
#******
#****f* bashlyk/libini/udfReadIniSection
#  SYNOPSIS
#    udfReadIniSection <file> [<section>]
#  DESCRIPTION
#    Получить секцию конфигурационных данных <section> из файла <file> и выдать
#    результат в виде строки CSV, разделенных ';', каждое поле которой содержит
#    данные в формате "<ключ>=<значение>" согласно данных строки секции.
#    В случае если исходная строка не содержит ключ или ключ содержит пробел, то
#    ключом становится выражение "_bashlyk_ini_<секция>_autokey_<инкремент>", а
#    всё содержимое строки - значением.
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных 
#              или до конца конфигурационного файла, если секций нет
#  OUTPUT
#              ## TODO
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_bashlyk_ini_test_autoKey_0="simple line";' ##udfReadIniSection
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult       ##udfReadIniSection
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfReadIniSection
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfReadIniSection ? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini ##udfReadIniSection
#    echo "simple line" | tee -a $ini                                           ##udfReadIniSection
#    udfReadIniSection $ini test                                                ##udfReadIniSection ? true
#    udfReadIniSection $ini test | grep "^${csv}$"                              ##udfReadIniSection ? true
#    udfReadIniSection2Var csvResult $ini test                                  ##udfReadIniSection ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfReadIniSection ? true
#    rm -f $ini                                                                 ##udfReadIniSection
#  SOURCE
udfReadIniSection() {
 [ -n "$1" -a -f "$1" ] || return 255
 local ini csvResult b
 local bOpen k v
 local s sTag i
 local sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"
 #
 ini="$1"
 bOpen=false
 i=0
 #
 [ -n "$2" ] && sTag="$2" || bOpen=true
 while read s; do
  ( echo $s | grep "^#\|^$" )>/dev/null && continue
  b=$(echo $s | grep -oE '\[.*\]' \
   | tr -d '[]' | xargs)
  if [ -n "$b" ]; then
   $bOpen && break
   if [ "$b" = "$sTag" ]; then
    csvResult=''
    bOpen=true
   else
    continue
   fi
  else
   $bOpen || continue
   s=$(echo $s | tr -d "'")
   k="$(echo ${s%%=*}|xargs -0)"
   v="$(echo ${s#*=}|xargs -0)"
   if [ -z "$k" -o "$k" = "$v" \
    -o -n "$(echo "$k" | grep '.*[[:space:]+].*')" ]; then
    k=${sUnnamedKeyword}${i}
    i=$((i+1))
    v="$s"
   fi
   csvResult+="$k=$(udfQuoteIfNeeded $v);"
  fi
 done < $ini
 $bOpen || csvResult=''
 echo $csvResult
 return 0
}
#******
#****f* bashlyk/libini/udfReadIniSection2Var
#  SYNOPSIS
#    udfReadIniSection2Var <varname> <file> [<section>]
#  DESCRIPTION
#    поместить результат вызова udfReadIniSection в переменную <varname>
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных 
#              или до конца конфигурационного файла, если секций нет
#    varname - идентификатор переменной (без "$"). При его наличии результат
#              будет помещен в соответствующую переменную. При отсутствии такого
#              идентификатора результат будет выдан на стандартный вывод
#  RETURN VALUE
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    пример приведен в описании udfIniGroup2Csv
#  SOURCE
udfReadIniSection2Var() {
 [ -n "$2" -a -f "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 #udfThrow "Error: required valid variable name \"$1\""
 eval 'export ${1}="$(udfReadIniSection "$2" $3)"'
 return 0
}
#******
#****f* bashlyk/libini/udfCsvOrder
#  SYNOPSIS
#    udfCsvOrder <csv;>
#  DESCRIPTION
#    упорядочение CSV-строки, которое заключается в удалении устаревших значений
#    пар "<key>=<value>". Более старыми при повторении ключей считаются более 
#    левые поля в строке
#  INPUTS
#    csv;    - CSV-строка, разделённая ";", поля которой содержат данные вида 
#              "key=value"
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся 
#              данные в формате "<key>=<value>;..."
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo bar;b=true;iXo=1920;' ##udfCsvOrder
#    local csvResult                                                            ##udfCsvOrder
#    local csvTest='b=true;iXo=1920;iYo=1080;sTxt="foo bar";'                   ##udfCsvOrder
#    udfCsvOrder "$csv" | grep "^${csvTest}$"                                   ##udfCsvOrder ? true
#    udfCsvOrder2Var csvResult "$csv"                                           ##udfCsvOrder ? true
#    echo $csvResult | grep "^${csvTest}$"                                      ##udfCsvOrder ? true
#  SOURCE
udfCsvOrder() {
 [ -n "$1" ] || return 255
 local fnExec aKeys csv
 local csvResult
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

 csvResult=$(. $fnExec 2>/dev/null)
 rm -f $fnExec
 echo $csvResult
 return 0
}
#******
#****f* bashlyk/libini/udfCsvOrder2Var
#  SYNOPSIS
#    udfCsvOrder2Var <varname> <csv;>
#  DESCRIPTION
#    поместить результат вызова udfCsvOrder в переменную <varname>
#  INPUTS
#    csv;    - CSV-строка, разделённая ";", поля которой содержат данные вида 
#              "key=value"
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде 
#              разделённой символом ";" CSV-строки, поля которого содержат 
#              данные в формате "<key>=<value>;...", будет помещен в
#              соответствующую переменну.
#  RETURN VALUE
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    пример приведен в описании udfCsvOrder
#  SOURCE
udfCsvOrder2Var() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 #udfThrow "Error: required valid variable name \"$1\""
 eval 'export ${1}="$(udfCsvOrder "$2")"'
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
   eval "$bashlyk_k_KLokRJky=$bashlyk_v_KLokRJky"
   #2>/dev/null
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
 local ini sSection
 #
 ini="$1"
 [ -n "$2" ] && sSection="$2"
 shift 2
 #
 #udfSetVarFromCsv ";$(udfGetIniSection $ini $sSection);" $* 
 udfSetVarFromCsv ";$(udfIniGroupSection2Csv $ini $sSection);" $* 
 
 return 0
}
#******
#****f* bashlyk/libini/udfCsvKeys
#  SYNOPSIS
#    udfCsvKeys <csv;>
#  DESCRIPTION
#    Получить ключи пар "ключ=значение" из CSV-строки <csv;>
#  INPUTS
#    csv;    - CSV-строка, разделённая ";", поля которой содержат данные вида 
#              "key=value"
#  OUTPUT
#              строка ключей
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;' sResult               ##udfCsvKeys
#    udfCsvKeys "$csv"                                                          ##udfCsvKeys ? true
#    udfCsvKeys "$csv" | xargs | grep "^sTxt b iXo iYo$"                        ##udfCsvKeys ? true
#    udfCsvKeys2Var sResult "$csv"                                              ##udfCsvKeys ? true
#    echo $sResult | grep "^sTxt b iXo iYo$"                                    ##udfCsvKeys ? true
#  SOURCE
udfCsvKeys() {
 [ -n "$1" ] || return 255
 local cIFS csv csvResult
 local s
 #
 csv="$1"
 cIFS=$IFS
 IFS=';'
 for s in $csv; do
  csvResult+="${s%%=*} "
 done
 IFS=$cIFS
 echo "$csvResult"
 return 0
}
#******
#****f* bashlyk/libini/udfCsvKeys2Var
#  SYNOPSIS
#    udfCsvKeys2Var <varname> <csv;>
#  DESCRIPTION
#    Поместить вывод udfCsvKeys в переменную <varname>
#  INPUTS
#    csv;  - CSV-строка, разделённая ";", поля которой содержат данные вида 
#            "key=value"
#  varname - валидный идентификатор переменной. Результат в виде строки ключей, 
#            разделенной пробелами, будет помещёна в соответствующую переменную
#  RETURN VALUE
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной  
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    пример приведен в описании udfCsvKeys
#  SOURCE
udfCsvKeys2Var() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 #udfThrow "Error: required valid variable name \"$1\""
 eval 'export ${1}="$(udfCsvKeys "$2")"'
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
  | sed -e "s/_bashlyk_ini_.*_autoKey_[0-9]\+=//g" \
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
#    local md5='c48c02c5744053a7dbf14dc775730e8c'                               ##udfIniChange
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfIniChange ? true
#    printf "$fmt" 1 sTxt foo '' value iXo 720 "non valid key" value | tee $ini ##udfIniChange
#    echo "simple line" | tee -a $ini                                           ##udfIniChange
#    printf "$fmt" 2 sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee -a $ini    ##udfIniChange
#    udfIniChange $ini "$csv" sect1                                             ##udfIniChange ? true
#    udfReadIniSection $ini sect1                                               ##udfIniChange ? true
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
  ## TODO расмотреть возможность замены udfReadIniSection2Var
  #csv=$(udfReadIniSection $ini $s) 
  csv=$(udfIniSection2Csv $ini $s)
  #udfIniSection2CsvVar csv $ini $s
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
#****f* bashlyk/libini/udfIni
#  SYNOPSIS
#    udfIni <file> [<section>]:<csv;> ...
#  DESCRIPTION
#    инициализировать перечисленные в <csv;> переменные секций <section> 
#    конфигурации <file> 
#  INPUTS
#     file    - файл конфигурации формата "*.ini".
#     section - любое количество имен секций, переменные которых нужно получить. 
#     csv;    - список переменных
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргументы отсутствуют или файл конфигурации не найден
#  EXAMPLE
#    local sTxt="foo = bar" b=true iXo=1921 iYo=1080 ini iniChild               ##udfIni
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfIni
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfIni ? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          ##udfIni
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini               ##udfIni
#    echo "simple line" | tee -a $ini                                           ##udfIni
#    printf "$fmt" sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee $iniChild    ##udfIni
#    sTxt='';b='';iXo=''                                                        ##udfIni
#    udfIni $iniChild 'test:sTxt;b;iXo'                                     ##udfIni ? true
#    echo "${sTxt};${b};${iXo}" | grep -e "^foo = bar;true;1921$"               ##udfIni ? true
#    echo "$_bashlyk_ini_test_enum" | grep -e '^"iXo Xo = 19";"simple line";$'  ##udfIni ? true
#    rm -f $iniChild $ini                                                       ##udfIni
#  SOURCE
udfIni() {
 [ -n "$1" -a -f "$1" ] || return 255
 #
 local csv s sSection csvSection csvVar
 #
 csv=$(udfIniGroup2Csv "$1")
 shift
 #
 for s in $*; do
  sSection=${s%:*}
  aVar="$(echo ${s#*:} | tr ';' ' ')"
  csvSection=$(udfGetCsvSection "$csv" "$sSection")
  ## TODO udfCsvOrder лишний вызов
  udfSetVarFromCsv "$csvSection" $aVar
  eval 'export _bashlyk_ini_${sSection:-void}_enum="$(udfGetLines2Csv "$csvSection" "$sSection")"'
 done
 return 0
}
#******
#******
#****f* bashlyk/libini/udfGetIni
#  SYNOPSIS
#    udfGetIni <file> [<section>] ...
#  DESCRIPTION
#    Получить опции секций <csvSections> конфигурации <file> в CSV-строку в
#    формате "[section];<key>=<value>;..." на стандартный вывод
#  INPUTS
#     file    - файл конфигурации формата "*.ini".
#     section - любое количество имен секций, данные которых нужно получить. 
#               По умолчанию и всегда выполняется сериализация "безымянной" 
#               секции
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргументы отсутствуют или файл конфигурации не найден
#  EXAMPLE
#    local csv='b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";' ##udfGetIni
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild                 ##udfGetIni
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfGetIni
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfGetIni ? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          ##udfGetIni
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini               ##udfGetIni
#    echo "simple line" | tee -a $ini                                           ##udfGetIni
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $iniChild  ##udfGetIni
#    udfGetIni $iniChild test                                                   ##udfGetIni ? true
#    udfGetIni $iniChild test | grep "^\[\];;\[test\];${csv}$"                  ##udfGetIni ? true
#    udfGetIni2Var csvResult $iniChild test                                     ##udfGetIni ? true
#    echo "$csvResult" | grep "^\[\];;\[test\];${csv}$"                         ##udfGetIni ? true
#    rm -f $iniChild $ini                                                       ##udfGetIni
#  SOURCE
udfGetIni() {
 [ -n "$1" -a -f "$1" ] || return 255
 #
 local csv s ini="$1"
 shift
 #
 for s in "" $*; do
  csv+="[${s}];$(udfIniGroupSection2Csv $ini $s)"
 done
 echo "$csv"
 return 0
}
#******
#****f* bashlyk/libini/udfGetIni2Var
#  SYNOPSIS
#    udfGetIni2Var <varname> <file> [<section>] ...
#  DESCRIPTION
#    Поместить вывод udfGetIni в переменную <varname>
#  INPUTS
#    file    - файл конфигурации формата "*.ini".
#    varname - валидный идентификатор переменной. Результат в виде 
#              CSV-строки в формате "[section];<key>=<value>;..." будет 
#              помещён в соответствующую переменную
#    section - список имен секций, данные которых нужно получить 
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргументы отсутствуют
#  EXAMPLE
#    пример приведен в описании udfGetIni
#  SOURCE
udfGetIni2Var() {
 [ -n "$2" -a -f "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 local bashlyk_GetIni2Var_ini="$2" bashlyk_GetIni2Var_s="$1"
 shift 2
 eval 'export ${bashlyk_GetIni2Var_s}="$(udfGetIni ${bashlyk_GetIni2Var_ini} $*)"'
 return 0
}
#******
#****f* bashlyk/libini/udfGetCsvSection
#  SYNOPSIS
#    udfGetCsvSection <csv> <tag>
#  DESCRIPTION
#    Выделить из CSV-строки <csv> фрагмент вида "[tag];key=value;...;" до
#    символа [ (очередная секция) или конца строки
#    формате "[section];<key>=<value>;..."  на стандартный вывод
#  INPUTS
#    tag - имя ini-секции
#    csv - строка сериализации данных ini-файлов
#  OUTPUT
#    csv; строка без заголовка секции [tag]
#  EXAMPLE
#    local csv='[];a=b;c=d e;[s1];a=f;c=g h;[s2];a=k;c=l m;'                    ##udfGetCsvSection
#    udfGetCsvSection "$csv" | grep '^a=b;c=d e;$'                              ##udfGetCsvSection ? true
#    udfGetCsvSection "$csv" s1 | grep '^a=f;c=g h;$'                           ##udfGetCsvSection ? true
#    udfGetCsvSection "$csv" s2 | grep '^a=k;c=l m;$'                           ##udfGetCsvSection ? true
#  SOURCE
udfGetCsvSection() {
 echo "${1#*\[$2\];}" | cut -f1 -d'['
 return 0
}
#******
#****f* bashlyk/libini/udfGetCsvSection2Var
#  SYNOPSIS
#    udfGetCsvSection <varname> <csv> [<tag>]
#  DESCRIPTION
#    поместить результат вызова udfGetCsvSection в переменную <varname>
#  INPUTS
#    tag     - имя ini-секции
#    csv     - строка сериализации данных ini-файлов
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде
#              CSV; строки формата "ключ=значение;" будет помещен в
#              соответствующую переменную.
#  RETURN VALUE
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - отсутствует аргумент 
#  EXAMPLE
#    local csv='[];a=b;c=d e;[s1];a=f;c=g h;[s2];a=k;c=l m;' csvResult          ##udfGetCsvSection2Var
#    udfGetCsvSection2Var csvResult "$csv"                                      ##udfGetCsvSection2Var
#    echo $csvResult | grep '^a=b;c=d e;$'                                      ##udfGetCsvSection2Var ? true
#    udfGetCsvSection2Var csvResult "$csv" s1                                   ##udfGetCsvSection2Var
#    echo $csvResult | grep '^a=f;c=g h;$'                                      ##udfGetCsvSection2Var ? true
#    udfGetCsvSection2Var csvResult "$csv" s2                                   ##udfGetCsvSection2Var
#    echo $csvResult | grep '^a=k;c=l m;$'                                      ##udfGetCsvSection2Var ? true
#  SOURCE
udfGetCsvSection2Var() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 eval 'export ${1}="$(udfGetCsvSection "$2" $3)"'
 return 0
}
#******
#****f* bashlyk/libini/udfGetLines2Csv
#  SYNOPSIS
#    udfGetLines2Csv <csv> [<tag>]
#  DESCRIPTION
#    получить CSV-строку, в полях которых указаны только неименованные значения,
#    из CSV-строки <csv>. Предполагается, что данная <csv> строка является 
#    сериализацией ini-файла, неименованные данные которого получают ключи вида
#    "_bashlyk_ini_<секция>_autoKey_<номер>"
#  INPUTS
#    tag - имя ini-секции
#    csv - строка сериализации данных ini-файлов
#  OUTPUT
#    csv; строка без заголовка секции [tag]
#  RETURN VALUE
#     0  - Выполнено успешно
#  EXAMPLE
#    local csv='[];a=b;_bashlyk_ini_void_autoKey_0="d = e";[s1];_bashlyk_ini_s1_autoKey_0=f=0;c=g h;[s2];a=k;_bashlyk_ini_s2_autoKey_0=l m;'                    ##udfGetLines2Csv
#    udfGetLines2Csv "$csv"                                                     ##udfGetLines2Csv ? true
#    udfGetLines2Csv "$csv" | grep '^"d = e";$'                                     ##udfGetLines2Csv ? true
#    udfGetLines2Csv "$csv" s1                                                  ##udfGetLines2Csv ? true
#    udfGetLines2Csv "$csv" s1 | grep '^f=0;$'                                    ##udfGetLines2Csv ? true
#    udfGetLines2Csv "$csv" s2                                                  ##udfGetLines2Csv ? true
#    udfGetLines2Csv "$csv" s2 | grep '^l m;$'                                  ##udfGetLines2Csv ? true
#  SOURCE
udfGetLines2Csv() {
 local cIFS csv s sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"
 cIFS=$IFS
 IFS=';'
 for s in $(echo "${1#*\[$2\];}" | cut -f1 -d'[')
 do
  echo "$s" | grep "^${sUnnamedKeyword}" >/dev/null 2>&1 && {
   csv+="${s#*=};"
  }
 done
 IFS=$cIFS
 echo "$csv"
}
#******
#****f* bashlyk/libini/udfIniSection2Csv
#  SYNOPSIS
#    udfIniSection2Csv <file> [<section>]
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
#  OUTPUT
#    строки CSV, разделенных ';', каждое поле которой содержит данные в формате
#    "<ключ>=<значение>" согласно данных строки секции
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_test_Key_0="simple line";' ##udfIniSection2Csv
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult       ##udfIniSection2Csv
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfIniSection2Csv
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfIniSection2Csv ? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini ##udfIniSection2Csv
#    echo "simple line" | tee -a $ini                                           ##udfIniSection2Csv
#    udfIniSection2Csv $ini test                                                ##udfIniSection2Csv ? true
#    udfIniSection2Csv $ini test | grep "^${csv}$"                              ##udfIniSection2Csv ? true
#    udfIniSection2CsvVar csvResult $ini test                                   ##udfIniSection2Csv ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfIniSection2Csv ? true
#    rm -f $ini                                                                 ##udfIniSection2Csv
#  SOURCE
udfIniSection2Csv() {
 [ -n "$1" -a -f "$1" ] || return 255
 awk -f ${_bashlyk_pathLib}/inisection2csv.awk -v "sTag=$2" -- $1
 return 0
}
#******
#****f* bashlyk/libini/udfIniSection2CsvVar
#  SYNOPSIS
#    udfIniSection2CsvVar <varname> <file> [<section>]
#  DESCRIPTION
#    поместить результат вызова udfIniSection2Csv в переменную <varname>
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных 
#              или до конца конфигурационного файла, если секций нет
#    varname - идентификатор переменной (без "$"). При его наличии результат
#              будет помещен в соответствующую переменную. При отсутствии такого
#              идентификатора результат будет выдан на стандартный вывод
#  RETURN VALUE
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    пример приведен в описании udfIniGroupSection2Csv
#  SOURCE
udfIniSection2CsvVar() {
 [ -n "$2" -a -f "$2" ] || return 255
 udfIsValidVariable $1  || return 2
 #udfThrow "Error: required valid variable name \"$1\""
 eval 'export ${1}="$(udfIniSection2Csv "$2" $3)"'
 return 0
}
#******
#****f* bashlyk/libini/udfIniGroupSection2Csv
#  SYNOPSIS
#    udfIniGroupSection2Csv <file> [<section>]
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
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся 
#              конфигурационные данные в формате "<key>=<value>;..."
#  RETURN VALUE
#     0  - Выполнено успешно
#     1  - Ошибка: файл конфигурации не найден
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'  ##udfIniGroupSection2Csv
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild                 ##udfIniGroupSection2Csv
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfIniGroupSection2Csv
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfIniGroupSection2Csv ? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          ##udfIniGroupSection2Csv
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini               ##udfIniGroupSection2Csv
#    echo "simple line" | tee -a $ini                                           ##udfIniGroupSection2Csv
#    printf "$fmt" sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee $iniChild    ##udfIniGroupSection2Csv
#    udfIniGroupSection2Csv $iniChild test                                      ##udfIniGroupSection2Csv ? true
#    udfIniGroupSection2Csv $iniChild test | grep "^${csv}$"                    ##udfIniGroupSection2Csv ? true
#    udfIniGroupSection2CsvVar csvResult $iniChild test                         ##udfIniGroupSection2Csv ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfIniGroupSection2Csv ? true
#    rm -f $iniChild $ini                                                       ##udfIniGroupSection2Csv
#  SOURCE
udfIniGroupSection2Csv() {
 [ -n "$1" ] || return 255
 #
 local aini csvIni csvResult
 local ini pathIni s
 local sTag sGlobIgnore
 #
 ini=''
 pathIni="$_pathIni"
 #
 [ "$1"  = "${1##*/}" -a -f ${pathIni}/$1 ] \
  || pathIni=
 [ "$1"  = "${1##*/}" -a -f $1 ] && pathIni=$(pwd)
 [ "$1" != "${1##*/}" -a -f $1 ] && pathIni=$(dirname $1)
 [ -n "$2" ] && sTag="$2"
 #
 if [ -z "$pathIni" ]; then
  [ -f "/etc/${_bashlyk_pathPrefix}/$1" ] \
   && pathIni="/etc/${_bashlyk_pathPrefix}" || return 1
 fi
 #
 aini=$(echo "${1##*/}" |\
  awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

 sGlobIgnore=$GLOBIGNORE
 GLOBIGNORE="*:?"

 for s in $aini; do
  [ -n "$s" ] || continue
  [ -n "$ini" ] && ini="${s}.${ini}" || ini="$s"
  [ -s "${pathIni}/${ini}" ] && csvIni+=";$(udfIniSection2Csv "${pathIni}/${ini}" "$sTag");"
 done
 GLOBIGNORE=$sGlobIgnore
 udfCsvOrder "$csvIni"
 return 0
}
#******
#****f* bashlyk/libini/udfIniGroupSection2CsvVar
#  SYNOPSIS
#    udfIniGroupSection2CsvVar <varname> <file> [<section>] 
#  DESCRIPTION
#    поместить результат вызова udfIniGroupSection2Csv в переменную <varname>
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента 
#              считываются данные до первого заголовка секции [<...>] данных или
#              до конца конфигурационного файла, если секций нет
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде 
#              разделенной символом ";" CSV-строки, в полях которого содержатся 
#              конфигурационные данные в формате "<key>=<value>;..." будет 
#              помещён в соответствующую переменную
#  RETURN VALUE
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    пример приведен в описании udfIniGroupSection2Csv
#  SOURCE
udfIniGroupSection2CsvVar() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 eval 'export ${1}="$(udfIniGroupSection2Csv "$2" $3)"'
 return 0
}
#******
#****f* bashlyk/libini/udfIni2Csv
#  SYNOPSIS
#    udfIni2Csv <file>
#  DESCRIPTION
#    Получить конфигурационныe данныe всех секций ini-файла <file> и выдать
#    результат в виде строки CSV, разделенных ';', каждое поле которой содержит
#    данные в формате "[<секция>];<ключ>=<значение>" согласно данных строки 
#    секции.
#    В случае если исходная строка не содержит ключ или ключ содержит пробел, то
#    ключом становится переменная "_bashlyk_ini_<секция>_autoKey_<инкремент>", а
#    всё содержимое строки - значением
#  INPUTS
#    file - имя файла конфигурации
#  OUTPUT
#    строки CSV, разделенных ';', каждое поле которой содержит данные в формате
#    "[<секция>];<ключ>=<значение>" согласно данных секции.
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
#    udfIniSection2Csv $ini test                                                ##udfIniSection2Csv ? true
#    udfIniSection2Csv $ini test | grep "^${csv}$"                              ##udfIniSection2Csv ? true
#    udfIniSection2CsvVar $ini test csvResult                                   ##udfIniSection2Csv ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfIniSection2Csv ? true
#    rm -f $ini                                                                 ##udfIniSection2Csv
#  SOURCE
udfIni2Csv() {
 [ -n "$1" -a -f "$1" ] || return 255
 awk -f ${_bashlyk_pathLib}/ini2csv.awk -- $1
 return 0
}
#******
#****f* bashlyk/libini/udfIni2CsvVar
#  SYNOPSIS
#    udfIni2CsvVar <varname> <file>
#  DESCRIPTION
#    поместить результат вызова udfIni2Csv в переменную <varname>
#  INPUTS
#    varname - валидный идентификатор переменной (без "$ "). Результат в  виде
#              CSV; строки формата "[секция];ключ=значение;" будет помещен в
#              соответствующую переменную.
#    file    - имя файла конфигурации
#  RETURN VALUE
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    пример приведен в описании udfIni2Csv
#  SOURCE
udfIni2CsvVar() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 #udfThrow "Error: required valid variable name \"$1\""
 eval 'export ${1}="$(udfIni2Csv "$2")"'
 return 0
}
#******
#****f* bashlyk/libini/udfIniGroup2Csv
#  SYNOPSIS
#    udfIniGroup2Csv <file>
#  DESCRIPTION
#    Получить конфигурационные данные всех секций <section> из <file> и, при 
#    наличии, от группы "родительских" к нему файлов. Например, если <file> это 
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
#  OUTPUT
#              разделенный символом ";" CSV-строка, в полях которого содержатся 
#              конфигурационные данные в формате "[<section>];<key>=<value>;..."
#  RETURN VALUE
#     0  - Выполнено успешно
#     1  - файл конфигурации не найден
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='\[\];\[test\];b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'  ##udfIniGroup2Csv
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild                 ##udfIniGroup2Csv
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   ##udfIniGroup2Csv
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       ##udfIniGroup2Csv ? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          ##udfIniGroup2Csv
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini               ##udfIniGroup2Csv
#    echo "simple line" | tee -a $ini                                           ##udfIniGroup2Csv
#    printf "$fmt" sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee $iniChild    ##udfIniGroup2Csv
#    udfIniGroup2Csv $iniChild                                                  ##udfIniGroup2Csv ? true
#    udfIniGroup2Csv $iniChild | grep "^${csv}$"                                ##udfIniGroup2Csv ? true
#    udfIniGroup2CsvVar csvResult $iniChild                                     ##udfIniGroup2Csv ? true
#    echo "$csvResult"                                                          ##udfIniGroup2Csv ? true
#    echo "$csvResult" | grep "^${csv}$"                                        ##udfIniGroup2Csv ? true
#    rm -f $iniChild $ini                                                       ##udfIniGroup2Csv
#  SOURCE
udfIniGroup2Csv() {
 [ -n "$1" ] || return 255
 #
 local aini csvIni csvResult ini pathIni s sTag sGlobIgnore aTag sS sF sT sR 
 #
 ini=''
 pathIni="$_pathIni"
 #
 [ "$1"  = "${1##*/}" -a -f ${pathIni}/$1 ] || pathIni=
 [ "$1"  = "${1##*/}" -a -f $1 ] && pathIni=$(pwd)
 [ "$1" != "${1##*/}" -a -f $1 ] && pathIni=$(dirname $1)
 [ -n "$2" ] && sTag="$2"
 #
 if [ -z "$pathIni" ]; then
  [ -f "/etc/${_bashlyk_pathPrefix}/$1" ] \
   && pathIni="/etc/${_bashlyk_pathPrefix}" || return 1
 fi
 #
 aini=$(echo "${1##*/}" |\
  awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

 sGlobIgnore=$GLOBIGNORE
 GLOBIGNORE="*:?"

 for s in $aini; do
  [ -n "$s" ] || continue
  [ -n "$ini" ] && ini="${s}.${ini}" || ini="$s"
  [ -s "${pathIni}/${ini}" ] && csvIni+=";$(udfIni2Csv "${pathIni}/${ini}" "$sTag");"
 done
 
 aTag=$(echo $csvIni | tr ';' '\n' | grep -oE '\[.*\]' | sort | uniq | tr -d '[]' | tr '\n' ' ')
 sR=''
 for s in "" $aTag; do
  sT=''
  sS='\['${s}'\]'
  while [ true ]; do
   [ -n "$(echo $csvIni | grep -oE $sS)" ] || break
   sF=$(echo "${csvIni#*${sS};}" | cut -f1 -d'[')
   csvIni=$(echo ${csvIni/${sS};${sF}/})
   sT+=";"${sF}
  done
  sR+="[${s}];$(udfCsvOrder "${sT}");"
 done
 GLOBIGNORE=$sGlobIgnore
 echo ${sR} | sed -e "s/;\+/;/g"
 return 0
}
#******
#****f* bashlyk/libini/udfIniGroup2CsvVar
#  SYNOPSIS
#    udfIniGroup2CsvVar <varname> <file>
#  DESCRIPTION
#    поместить результат вызова udfIniGroup2Csv в переменную <varname>
#  INPUTS
#    varname - валидный идентификатор переменной (без "$ "). Результат в виде
#              CSV; строки формата "[секция];ключ=значение;" будет помещен в
#              соответствующую переменную.
#    file    - имя файла конфигурации
#  RETURN VALUE
#     0  - Выполнено успешно
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    пример приведен в описании udfIniGroup2Csv
#  SOURCE
udfIniGroup2CsvVar() {
 [ -n "$2" ] || return 255
 udfIsValidVariable "$1" || return 2
 eval 'export ${1}="$(udfIniGroup2Csv "$2")"'
 return 0
}
#******
