#
# $Id: libcsv.sh 624 2016-12-14 23:42:36+04:00 toor $
#
#****h* BASHLYK/libcsv
#  DESCRIPTION
#    Управление пассивными конфигурационными файлов в стиле INI. Имеется
#    возможность подгрузки исполнимого контента
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libcsv/Required Once
#  DESCRIPTION
#    Глобальная переменная $_BASHLYK_LIBINI обеспечивает
#    защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
[[ $_BASHLYK_LIBCSV ]] && return 0 || _BASHLYK_LIBCSV=1
#******
#****** libcsv/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s "${_bashlyk_pathLib}/libstd.sh" ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s "${_bashlyk_pathLib}/libopt.sh" ]] && . "${_bashlyk_pathLib}/libopt.sh"
#******
#****v* libcsv/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:="$@"}
: ${_bashlyk_pathIni:=$(pwd)}
: ${_bashlyk_bSetOptions:=}
: ${_bashlyk_csvOptions2Ini:=}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_ini_void_autoKey_}
: ${_bashlyk_aRequiredCmd_ini:="awk cat cut dirname echo false grep mawk mkdir \
  mv printf pwd rm sed sort touch tr true uniq xargs"}
: ${_bashlyk_aExport_ini:="udfAssembly udfCsvHash2Raw udfCsvKeys udfCsvKeys2Var       \
  udfCsvOrder udfCsvOrder2Var udfGetCsvSection udfGetCsvSection2Var udfGetIni         \
  udfGetIni2Var udfGetIniSection udfGetIniSection2Var udfIni udfIni2Csv udfIni2CsvVar \
  udfIniChange udfIniGroup2Csv udfIniGroup2CsvVar udfIniGroupSection2Csv              \
  udfIniGroupSection2CsvVar udfIniSection2Csv udfIniSection2CsvVar udfIniWrite        \
  udfOptions2Ini udfReadIniSection udfReadIniSection2Var udfSelectEnumFromCsvHash     \
  udfSetVarFromCsv udfSetVarFromIni"}
#******
#****f* libcsv/udfGetIniSection
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
#   0                            - Выполнено успешно
#   iErrorNoSuchFileOrDir        - файл конфигурации не найден
#   iErrorEmptyOrMissingArgument - аргумент не задан
#   iErrorEmptyResult            - результат отсутствует
#  EXAMPLE
#    local csv='b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini
#    echo "simple line" | tee -a $ini
#    printf "$fmt" sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee $iniChild
#    udfGetIniSection $iniChild test >| grep "^${csv}$"                         #? true
#    udfGetIniSection2Var csvResult $iniChild test                              #? true
#    echo "$csvResult" | grep "^${csv}$"                                        #? true
#    rm -f $iniChild $ini
#    udfGetIniSection $iniChild test                                            #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO тест пустой результат
#  SOURCE
udfGetIniSection() {
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 local aini csvIni csvResult ini pathIni s sTag IFS=$' \t\n' GLOBIGNORE
 #
 ini=''
 pathIni="$_bashlyk_pathIni"
 #
 [[ "$1" == "${1##*/}" && -f "${pathIni}/$1" ]] || pathIni=
 [[ "$1" == "${1##*/}" && -f "$1" ]] && pathIni=$(pwd)
 [[ "$1" != "${1##*/}" && -f "$1" ]] && pathIni=$(dirname $1)
 [[ -n "$2" ]] && sTag="$2"
 #
 if [[ -z "$pathIni" ]]; then
  [[ -f "/etc/${_bashlyk_pathPrefix}/$1" ]] \
   && pathIni="/etc/${_bashlyk_pathPrefix}" \
   || eval $(udfOnError return iErrorNoSuchFileOrDir 'file /etc/${_bashlyk_pathPrefix}/$1 is not exist...')
 fi
 #
 aini=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

 GLOBIGNORE="*:?"

 for s in $aini; do
  [[ -n "$s"                ]] || continue
  [[ -n "$ini"              ]] && ini="${s}.${ini}" || ini="$s"
  [[ -s "${pathIni}/${ini}" ]] && csvIni+=";$(udfIniSection2Csv "${pathIni}/${ini}" "$sTag");"
 done
 unset GLOBIGNORE

 udfCsvOrder "$csvIni" || eval $(udfOnError return)
 return 0
}
#******
#****f* libcsv/udfGetIniSection2Var
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
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfGetIniSection
#  SOURCE
udfGetIniSection2Var() {
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfGetIniSection "$2" $3)"'
 return 0
}
#******
#****f* libcsv/udfReadIniSection
#  SYNOPSIS
#    udfReadIniSection <file> [<section>]
#  DESCRIPTION
#    Получить секцию конфигурационных данных <section> из <file> и выдать
#    результат в виде строки CSV, разделенных ';', каждое поле которой содержит
#    данные в формате "<ключ>=<значение>" согласно данных строки секции.
#    В случае если исходная строка не содержит ключ или ключ содержит пробел, то
#    ключом становится выражение "_bashlyk_ini_<секция>_autokey_<инкремент>", а
#    всё содержимое строки - значением - "безымянным", с автоматически
#    формируемым ключом
#  INPUTS
#    file    - имя файла конфигурации
#    section - название секции конфигурации, при отсутствии этого аргумента
#              считываются данные до первого заголовка секции [<...>] данных
#              или до конца конфигурационного файла, если секций нет
#  OUTPUT
#              строка CSV;
#  RETURN VALUE
#   0  - Выполнено успешно
#   iErrorNoSuchFileOrDir - аргумент не задан или это не файл конфигурации
#   iErrorEmptyResult     - функция не возвращает результат
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_bashlyk_ini_test_autoKey_0="simple line";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult
#    local fmt="[test] \n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini
#    printf "\n\n# comment\nsimple line\n\n" | tee -a $ini
#    udfReadIniSection $ini test >| grep "^${csv}$"                             #? true
#    udfReadIniSection2Var csvResult $ini test                                  #? true
#    echo "$csvResult" >| grep "^${csv}$"                                       #? true
#    rm -f $ini
#    udfReadIniSection $ini test                                                #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO тест "пустой результат"
#  SOURCE
udfReadIniSection() {
 local b bOpen=false csvResult i=0 ini="$1" k v s sTag IFS=$' \t\n' sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"
 [[ -n "$1" && -f "$1" ]] || eval $(udfOnError return iErrorNoSuchFileOrDir)
 #
 [[ -n "$2" ]] && sTag=$2 || bOpen=true
 while read s; do
  [[ "$s" =~ ^#|^$ ]] && continue
  [[ "$s" =~ \[.*\] ]] && b=${s//[\[\]]/} || b=''
  if [[ -n "$b" ]]; then
   $bOpen && break
   if [[ $b =~ [[:blank:]]*${sTag}[[:blank:]]* ]]; then
    csvResult=
    bOpen=true
   else
    continue
   fi
  else
   $bOpen || continue
   s=$(echo $s | tr -d "'")
   k="$(echo ${s%%=*}|xargs -0)"
   v="$(echo ${s#*=}|xargs -0)"
   if [[ -z "$k" || "$k" == "$v" || "$k" =~ .*[[:space:]+].* ]]
   then
    k=${sUnnamedKeyword}${i}
    i=$((i+1))
    v="$s"
   fi
   csvResult+="$k=$(udfQuoteIfNeeded $v);"
  fi
 done < $ini
 $bOpen || eval $(udfOnError return iErrorEmptyResult)
 echo $csvResult
 #return 0
}
#******
#****f* libcsv/udfReadIniSection2Var
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
#     0                           - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    #пример приведен в описании udfIniGroup2Csv
#  SOURCE
udfReadIniSection2Var() {
 local IFS=$' \t\n'
 [[ -n "$2" && -f "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfReadIniSection "$2" $3)"'
 return 0
}
#******
#****f* libcsv/udfCsvOrder
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
#    0                            - Выполнено успешно
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#    iErrorEmptyResult            - пустой результат
#  EXAMPLE
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo bar;b=true;iXo=1920;'
#    local csvResult
#    local csvTest='b=true;iXo=1920;iYo=1080;sTxt="foo bar";'
#    udfCsvOrder "$csv" >| grep "^${csvTest}$"                                  #? true
#    udfCsvOrder2Var csvResult "$csv"                                           #? true
#    echo $csvResult | grep "^${csvTest}$"                                      #? true
#    udfCsvOrder ""                                                             #? $_bashlyk_iErrorEmptyOrMissingArgument
#    ## TODO тест пустой результат
#  SOURCE
udfCsvOrder() {
 local aKeys csvResult csv fnExec IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
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
 udfShowVariable $aKeys | grep -v '^:' | tr -d '\t' \
  | sed -e "s/=\(.*[[:space:]]\+.*\)/=\"\1\"/" | tr '\n' ';' | sed -e "s/;;/;/"
 #
 return 0
}
#
udfAssembly
_CsvOrder_EOF

 csvResult=$(. $fnExec 2>/dev/null)
 rm -f $fnExec
 [[ -n "$csvResult" ]] && echo $csvResult || eval $(udfOnError return iErrorEmptyResult)
 #return 0
}
#******
#****f* libcsv/udfCsvOrder2Var
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
#   0                            - Выполнено успешно
#   iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#   iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfCsvOrder
#  SOURCE
udfCsvOrder2Var() {
 local IFS=$' \t\n'
 #
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfCsvOrder "$2")"'
 return 0
}
#******
#****f* libcsv/udfSetVarFromCsv
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
#    0                            - Выполнено успешно
#    iErrorEmptyOrMissingArgument - аргумент(ы) отсутствуют
#  EXAMPLE
#    local b sTxt iXo iYo
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo = bar;b=true;iXo=1920;'
#    local sResult="true:foo = bar:1920:1080"
#    udfSetVarFromCsv "$csv" b sTxt iXo iYo                                     #? true
#    echo "${b}:${sTxt}:${iXo}:${iYo}" | grep "^${sResult}$"                    #? true
#  SOURCE
udfSetVarFromCsv() {
 local bashlyk_csvInput_KLokRJky bashlyk_csvResult_KLokRJky bashlyk_k_KLokRJky bashlyk_v_KLokRJky IFS=$' \t\n'
 #
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 bashlyk_csvInput_KLokRJky=";$(udfCsvOrder "$1");"
 shift
 #
 for bashlyk_k_KLokRJky in $*; do
  #bashlyk_csvResult_KLokRJky=$(echo $bashlyk_csvInput_KLokRJky | grep -Po ";$bashlyk_k_KLokRJky=.*?;" | tr -d ';')
  bashlyk_v_KLokRJky="$(echo "${bashlyk_csvInput_KLokRJky#*;$bashlyk_k_KLokRJky=}" | cut -f 1 -d ';')"
  if [[ -n "$bashlyk_v_KLokRJky" ]]; then
   eval "$bashlyk_k_KLokRJky=$bashlyk_v_KLokRJky"
  fi
 done
 return 0
}
#******
#****f* libcsv/udfSetVarFromIni
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
#    iErrorEmptyOrMissingArgument - аргумент(ы) отсутствуют
#     0                           - Выполнено успешно
#  EXAMPLE
#    local sResult='true:foo bar:1024:768'
#    local sTxt b iXo iYo ini
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" sTxt "foo bar" b true iXo 1024 iYo 768 | tee $ini
#    udfSetVarFromIni $ini test sTxt b iXo iYo                                  #? true
#    echo "${b}:${sTxt}:${iXo}:${iYo}" | grep "^${sResult}$"                    #? true
#    rm -f $ini
#  SOURCE
udfSetVarFromIni() {
 local ini="$1" sSection="$2" IFS=$' \t\n'
 #
 [[ -n "$1" && -f "$1" && -n "$3" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 shift 2

 udfSetVarFromCsv ";$(udfIniGroupSection2Csv $ini $sSection);" $*

 return 0
}
#******
#****f* libcsv/udfCsvKeys
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
#    0                            - Выполнено успешно
#    iErrorEmptyOrMissingArgument - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;' sResult
#    udfCsvKeys "$csv" | xargs >| grep "^sTxt b iXo iYo$"                       #? true
#    udfCsvKeys2Var sResult "$csv"                                              #? true
#    echo $sResult | grep "^sTxt b iXo iYo$"                                    #? true
#  SOURCE
udfCsvKeys() {
 local csv="$1" csvResult s IFS=$' \t\n'
 #
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 IFS=';'
 for s in $csv; do
  csvResult+="${s%%=*} "
 done
 echo "$csvResult"
 return 0
}
#******
#****f* libcsv/udfCsvKeys2Var
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
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfCsvKeys
#  SOURCE
udfCsvKeys2Var() {
 local IFS=$' \t\n'
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfCsvKeys "$2")"'
 return 0
}
#******
#****f* libcsv/udfIniWrite
#  SYNOPSIS
#    udfIniWrite <file> <csv;>
#  DESCRIPTION
#    сохранить данные из CSV-строки <csv;> в формате [<section>];<key>=<value>;
#    в файл конфигурации <file> c заменой предыдущего содержания. Сохранение
#    производится с форматированием строк, разделитель ";" заменяется на перевод
#    строки
#  INPUTS
#    file - файл конфигурации в стиле "ini". Если он не пустой, то сохраняется
#           в виде копии "<file>.bak"
#    csv; - CSV-строка, разделённая ";", поля которой содержат данные вида
#           "[<section>];<key>=<value>;..."
#  RETURN VALUE
#    0  - Выполнено успешно
#    iErrorNotExistNotCreated     - путь не существует и не создан
#    iErrorEmptyOrMissingArgument - аргументы отсутствуют
#  EXAMPLE
#    ## TODO дополнить тесты по второму аргументу
#    local ini csv='[];void=0;[exec]:;"TZ_bashlyk_&#61_UTC date -R --date_bashlyk_&#61_'@12345679'";sUname_bashlyk_&#61_"$_bashlyk_&#40_uname_bashlyk_&#41_";:[exec];[main];sTxt="foo = bar";b=true;iXo=1921;[replace];"after replacing";[unify];*.bak;*.tmp;*~;[acc];;*.bak;*.tmp;;*.bak;*.tmp;*~;'
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    udfIniWrite $ini "$csv"                                                    #? true
#    cat $ini
#    grep -E '^\[unify\]$'                      $ini                            #? true
#    grep -E 'sTxt.*=.*foo.*=.*bar$'            $ini                            #? true
#    grep -E 'b.*=.*true$'                      $ini                            #? true
#    grep -E 'iXo.*=.*1921$'                    $ini                            #? true
#    grep -E 'TZ=UTC date -R --date=@12345679$' $ini                            #? true
#    cat $ini
#    rm -f $ini ${ini}.bak
#  SOURCE
udfIniWrite() {
 local csv ini="$1" s IFS=$' \t\n'
 #
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument "\$1")
 #
 [[ -n "$2" ]] && s="$2" || s="$(_ csvOptions2Ini)"
 [[ -n "$s" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument "\$2 _ csvOptions2Ini")
 #
 mkdir -p $(dirname "$ini") || eval $(udfOnError iErrorNotExistNotCreated "$(dirname $ini)")
 [[ -s "$ini" ]] && mv -f "$ini" "${ini}.bak"
 csv="$(echo "$s" | sed -e "s/[;]\+/;/g" -e "s/\(:\?\[\)/;;\1/g" -e "s/\[\]//g" | tr -d '"')"
 IFS=';'
 for s in $csv; do
  k="${s%%=*}"
  v="${s#*=}"
  [[ "$k" == "$v" ]] && echo "$v" || printf -- "\t%s\t=\t%s\n" "$k" "$v"
 ## TODO продумать перенос уничтожения автоключей в udfBashlykUnquote
 done | sed -e "s/\t\?_bashlyk_ini_.*_autoKey_[0-9]\+\t\?=\t\?//g" | udfBashlykUnquote > "$ini"
 #
 return 0
}
#******
#****f* libcsv/udfIniChange
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
#    0                            - Выполнено успешно
#    iErrorEmptyOrMissingArgument - аргументы отсутствуют
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=999;' csvResult
#    local re='b=.*;_b.*auto.*0="= value".*auto.*1=.*key = value".*sTxt=".*ar";'
#    local sTxt="bar foo" b=true iXo=1234 iYo=4321 ini
#    local fmt="[sect%s]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    local md5='a0e4879ea58a1cb5f1889c2de949f485'
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" 1 sTxt foo '' value iXo 720 "non valid key" value | tee $ini
#    echo "simple line" | tee -a $ini
#    printf "$fmt" 2 sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee -a $ini
#    udfIniChange $ini "$csv" sect1                                             #? true
#    udfReadIniSection $ini sect1 >| grep "$re"                                 #? true
#    cat $ini
#    rm -f $ini ${ini}.bak
#  SOURCE
udfIniChange() {
 local a aKeys aTag csv ini="$1" s csvNew="$2" sTag IFS=$' \t\n'
 #
 [[ -n "$1" && -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 [[ -n "$3" ]] && sTag="$3"
 #
 [[ -f "$ini" ]] || touch "$ini"
 aTag="$(grep -oE '\[.*\]' $ini | tr -d '[]' | sort -u | uniq -u | xargs)"
 [[ -n "$sTag" ]] && echo "$aTag" | grep -w "$sTag" >/dev/null || aTag+=" $sTag"
 for s in "" $aTag; do
  csv=$(udfIniSection2Csv $ini $s)
  if [[ "$s" == "$sTag" ]]; then
   csv=$(udfCsvOrder "${csv};${csvNew}")
  fi
  a+=";[${s}];$csv;"
 done
 udfIniWrite $ini "$a"
 return 0
}
#******
#****f* libcsv/udfIni
#  SYNOPSIS
#    udfIni <file> [<section>]:[<csv;>]|[(=|-|+|!)] ...
#  DESCRIPTION
#    получить данные указанных секций <section> ini-файла <file> (и, возможно,
#    ему родственных, а также, опций командной строки, предварительно полученных
#    функцией udfGetOpt) через инициализацию перечисленных в "csv;"-строке
#    валидных идентификаторов переменных, идентичных соответствующим ключам
#    секции или "сырую" сериализацию всех данных секции в переменную c именем
#    секции
#  INPUTS
#     file    - файл конфигурации в стиле ini
#     section - имена секций. Пустое значение для "безымянной" секции
#     csv;    - список валидных переменных для приема соответствующих значений
#               строк вида "<ключ>=<значение>" секции section, в случае
#               повторения ключей, актуальной становится последняя пара
#     =-+!    - сериализация всех данных секции в переменную c именем секции,
#               модификаторы "=-+!" задают стратегию обработки "сырых" данных:
#     =       - накапливание данные с последующей унификацией
#     -       - замена данных
#     +       - накопление данных
#     !       - замена данных (активная секция)
#
#  RETURN VALUE
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - невалидный идентификатор переменной
#    iErrorNoSuchFileOrDir        - файл конфигурации не найден
#    iErrorEmptyOrMissingArgument - аргументы отсутствуют
#  EXAMPLE
#    local sTxt="foo = bar" b=true iXo=1921 iYo=1080 ini iniChild
#    local exec replace unify acc sVoid=void sMain='sTxt;b;iXo'
#    local sRules=":${sVoid} exec:! main:${sMain} replace:- unify:= acc:+"
#
#    ini=$(mktemp --suffix=test.ini || tempfile -s .test.ini)                   #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#
#    cat <<'EOFini' > ${ini}                                                    #-
#    void	=	1                                                               #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt	=	$(date -R)                                                      #-
#    b		=	false                                                           #-
#    iXo Xo	=	19                                                              #-
#    iYo	=	80                                                              #-
#    `simple line`                                                              #-
#[replace]                                                                      #-
#    before replacing                                                           #-
#[unify]                                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#[acc]                                                                          #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#                                                                               #-
#    EOFini                                                                     #-
#    cat <<'EOFiniChild' > ${iniChild}                                          #-
#    void	=	0                                                               #-
#    [main]	                                                                    #-
#    sTxt	=	foo = bar                                                       #-
#    b		=	true                                                            #-
#    iXo	=	1921                                                            #-
#    iYo	=	1080                                                            #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345679'                                          #-
#    sUname="$(uname)"                                                          #-
#:[exec]                                                                        #-
#[replace]                                                                      #-
#	after replacing                                                             #-
#[unify]                                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    *~                                                                         #-
#[acc]                                                                          #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    *~                                                                         #-
#                                                                               #-
#    EOFiniChild                                                                #-
#    udfIni $iniChild $sRules                                                   #? true
#    echo "${sTxt};${b};${iXo}" >| grep -e "^foo = bar;true;1921$"              #? true
#    echo "$exec"     | udfBashlykUnquote >| grep 'TZ=UTC.*@12345679.*$(uname)' #? true
#    echo "$replace" >| grep '"after replacing";$'                              #? true
#    echo "$unify"   >| grep '^\*\.bak;\*\.tmp;\*~;$'                           #? true
#    echo "$acc"     >| grep '^\*\.bak;\*\.tmp;\*\.bak;\*\.tmp;\*~;$'           #? true
#    rm -f $iniChild $ini
#    udfIni $iniChild $sRules                                                   #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO проверка пустых данных (iErrorEmptyOrMissingArgument)
#  SOURCE
udfIni() {
 local IFS=$' \t\n'
 #
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 local bashlyk_udfIni_csv bashlyk_udfIni_s bashlyk_udfIni_sSection
 local bashlyk_udfIni_csvSection bashlyk_udfIni_csvVar bashlyk_udfIni_ini
 local bashlyk_udfIni_cClass
 #
 bashlyk_udfIni_ini="$1"
 shift
 #
 [[ "$_bashlyk_bSetOptions" == 1 ]] && udfOptions2Ini $*
 #
 bashlyk_udfIni_csv=$(udfIniGroup2Csv "$bashlyk_udfIni_ini")
 bashlyk_udfIni_s=$?
 [[ "$bashlyk_udfIni_s" == 0 ]] || eval $(udfOnError return $bashlyk_udfIni_s)
 #
 for bashlyk_udfIni_s in $*; do
  bashlyk_udfIni_sSection=${bashlyk_udfIni_s%:*}
  bashlyk_udfIni_csvSection=$(udfGetCsvSection "$bashlyk_udfIni_csv" "$bashlyk_udfIni_sSection")
  if [[ "$bashlyk_udfIni_s" == "${bashlyk_udfIni_s%:[=\-+\!]*}" ]]; then
   bashlyk_udfIni_aVar="${bashlyk_udfIni_s#*:}"
   ## TODO продумать расширение имен переменных до вида "имяСекции_переменная"
   udfSetVarFromCsv "$bashlyk_udfIni_csvSection" ${bashlyk_udfIni_aVar//;/ }
  else
   bashlyk_udfIni_cClass="${bashlyk_udfIni_s#*:}"
   udfIsValidVariable $bashlyk_udfIni_sSection || eval $(udfOnError return iErrorNonValidVariable '$bashlyk_udfIni_sSection')
   case "$bashlyk_udfIni_cClass" in
    !|-) bashlyk_udfIni_csvSection="${bashlyk_udfIni_csvSection##*_bashlyk_csv_record=;}" ;;
      #+) bashlyk_udfIni_csvSection="$(echo "$bashlyk_udfIni_csvSection" | sed -e "s/_bashlyk_csv_record=;//g")" ;;
      =) bashlyk_udfIni_csvSection="$(echo "$bashlyk_udfIni_csvSection" | tr ';' '\n' | sort | uniq | tr '\n' ';')" ;;
   esac
   eval 'export $bashlyk_udfIni_sSection="$(udfCsvHash2Raw "$bashlyk_udfIni_csvSection" "$bashlyk_udfIni_sSection")"'
  fi
 done
 ## TODO вложенные кавычки: " " ""
 return 0
}
#******
#****f* libcsv/udfGetIni
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
#    0                            - Выполнено успешно
#    iErrorEmptyOrMissingArgument - аргументы отсутствуют или файл конфигурации не найден
#  EXAMPLE
#    local csv='b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini
#    echo "simple line" | tee -a $ini
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $iniChild
#    udfGetIni $iniChild test >| grep "^\[\];;\[test\];${csv}$"                 #? true
#    udfGetIni2Var csvResult $iniChild test                                     #? true
#    echo "$csvResult" | grep "^\[\];;\[test\];${csv}$"                         #? true
#    rm -f $iniChild $ini
#  SOURCE
udfGetIni() {
 local csv s ini="$1" IFS=$' \t\n'
 #
 [[ -n "$1" && -f "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 shift
 #
 for s in "" $*; do
  csv+="[${s}];$(udfIniGroupSection2Csv $ini $s)"
 done
 echo "$csv"
 return 0
}
#******
#****f* libcsv/udfGetIni2Var
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
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - не валидный идентификатор переменной
#    iErrorEmptyOrMissingArgument - аргументы отсутствуют
#  EXAMPLE
#    #пример приведен в описании udfGetIni
#  SOURCE
udfGetIni2Var() {
 local bashlyk_GetIni2Var_ini="$2" bashlyk_GetIni2Var_s="$1" IFS=$' \t\n'
 #
 [[ -n "$2" && -f "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 shift 2
 eval 'export ${bashlyk_GetIni2Var_s}="$(udfGetIni ${bashlyk_GetIni2Var_ini} $*)"'
 return 0
}
#******
#****f* libcsv/udfGetCsvSection
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
#    local csv='[];a=b;c=d e;[s1];a=f;c=g h;[s2];a=k;c=l m;'
#    udfGetCsvSection "$csv"    >| grep '^a=b;c=d e;$'                          #? true
#    udfGetCsvSection "$csv" s1 >| grep '^a=f;c=g h;$'                          #? true
#    udfGetCsvSection "$csv" s2 >| grep '^a=k;c=l m;$'                          #? true
#  SOURCE
udfGetCsvSection() {
 echo "${1#*\[$2\];}" | cut -f1 -d'['
 return 0
}
#******
#****f* libcsv/udfGetCsvSection2Var
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
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - отсутствует аргумент
#  EXAMPLE
#    local csv='[];a=b;c=d e;[s1];a=f;c=g h;[s2];a=k;c=l m;' csvResult
#    udfGetCsvSection2Var csvResult "$csv"
#    echo $csvResult >| grep '^a=b;c=d e;$'                                     #? true
#    udfGetCsvSection2Var csvResult "$csv" s1
#    echo $csvResult >| grep '^a=f;c=g h;$'                                     #? true
#    udfGetCsvSection2Var csvResult "$csv" s2
#    echo $csvResult >| grep '^a=k;c=l m;$'                                     #? true
#  SOURCE
udfGetCsvSection2Var() {
 local IFS=$' \t\n'
 #
 [ -n "$2" ] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfGetCsvSection "$2" $3)"'
 return 0
}
#******
#****f* libcsv/udfSelectEnumFromCsvHash
#  SYNOPSIS
#    udfSelectEnumFromCsvHash <csv> [<tag>]
#  DESCRIPTION
#     CSV-строку, в полях которых указаны только неименованные значения,
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
#    local csv='[];a=b;_bashlyk_ini_void_autoKey_0="d = e";[s1];_bashlyk_ini_s1_autoKey_0=f=0;c=g h;[s2];a=k;_bashlyk_ini_s2_autoKey_0=l m;'
#    udfSelectEnumFromCsvHash "$csv"    >| grep '^"d = e";$'                    #? true
#    udfSelectEnumFromCsvHash "$csv" s1 >| grep '^f=0;$'                        #? true
#    udfSelectEnumFromCsvHash "$csv" s2 >| grep '^l m;$'                        #? true
#  SOURCE
udfSelectEnumFromCsvHash() {
 local IFS=';' csv s sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"
 for s in $(echo "${1#*\[$2\];}" | cut -f1 -d'[')
 do
  echo "$s" | grep "^${sUnnamedKeyword}" >/dev/null 2>&1 && csv+="${s#*=};"
 done
 echo "$csv"
}
#******
#****f* libcsv/udfCsvHash2Raw
#  SYNOPSIS
#    udfCsvHash2Raw <csv> [<tag>]
#  DESCRIPTION
#    подготовить CSV;-строку для выполнения в качестве сценария, поля которого
#    рассматриваются как строки команд. При этом автоматические ключи вида
#    "_bashlyk_ini_<секция>_autoKey_<номер>" и поля-разделители записей разных
#    источников данных "_bashlyk_csv_record=" будут убраны. Поля вида
#    "ключ=значение" становятся командами присвоения значения переменной.
#    Предполагается, что входная <csv> строка является сериализацией ini-файла.
#  INPUTS
#    tag - имя ini-секции
#    csv - строка сериализации данных ini-файлов
#  OUTPUT
#    csv; строка без заголовка секции [tag]
#  RETURN VALUE
#     0  - Выполнено успешно
#  EXAMPLE
#    local csv='[];_bashlyk_csv_record=;a=b;_bashlyk_ini_void_autoKey_0="d = e";[s1];_bashlyk_ini_s1_autoKey_0=f=0;c=g h;[s2];a=k;_bashlyk_ini_s2_autoKey_0=l m;'
#    udfCsvHash2Raw "$csv"    >| grep '^a=b;"d = e";$'                          #? true
#    udfCsvHash2Raw "$csv" s1 >| grep '^f=0;c=g h;$'                            #? true
#    udfCsvHash2Raw "$csv" s2 >| grep '^a=k;l m;$'                              #? true
#  SOURCE
udfCsvHash2Raw() {
 local IFS=';' csv s sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"
 for s in $(echo "${1#*\[$2\];}" | cut -f1 -d'[')
 do
  s="${s#${sUnnamedKeyword}[0-9]*=}"
  s="${s##*_bashlyk_csv_record=}"
  [[ -n "$s" ]] || continue
  csv+="${s};"
 done
 echo "$csv"
}
#******
#****f* libcsv/udfIniSection2Csv
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
#    0                            - Выполнено успешно
#    iErrorEmptyOrMissingArgument - аргумент отсутствует или файл конфигурации
#                                   не найден
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_bashlyk_ini_test_autoKey_0="simple line";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini
#    echo "simple line" | tee -a $ini
#    udfIniSection2Csv $ini test >| grep "^${csv}$"                             #? true
#    udfIniSection2CsvVar csvResult $ini test                                   #? true
#    echo "$csvResult"           >| grep "^${csv}$"                             #? true
#    rm -f $ini
#  SOURCE
udfIniSection2Csv() {
 local IFS=$' \t\n'
 #
 [[ -n "$1" && -f "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 mawk -f ${_bashlyk_pathLib}/inisection2csv.awk -v "sTag=$2" -- $1
 return 0
}
#******
#****f* libcsv/udfIniSection2CsvVar
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
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    #пример приведен в описании udfIniGroupSection2Csv
#  SOURCE
udfIniSection2CsvVar() {
 local IFS=$' \t\n'
 #
 [[ -n "$2" && -f "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfIniSection2Csv "$2" $3)"'
 return 0
}
#******
#****f* libcsv/udfIniGroupSection2Csv
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
#    0                            - Выполнено успешно
#    iErrorNoSuchFileOrDir        - файл конфигурации не найден
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    local csv='b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini
#    echo "simple line" | tee -a $ini
#    printf "$fmt" sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee $iniChild
#    udfIniGroupSection2Csv $iniChild test >| grep "^${csv}$"                   #? true
#    udfIniGroupSection2CsvVar csvResult $iniChild test                         #? true
#    echo "$csvResult"                     >| grep "^${csv}$"                   #? true
#    rm -f $iniChild $ini
#    udfIniGroupSection2Csv $iniChild                                           #? $_bashlyk_iErrorNoSuchFileOrDir
#    udfIniGroupSection2Csv                                                     #? $_bashlyk_iErrorEmptyOrMissingArgument
#    ## TODO тест пустой результат
#  SOURCE
udfIniGroupSection2Csv() {
 local aini csvIni csvResult ini pathIni s sTag IFS=$' \t\n' GLOBIGNORE
 #
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 pathIni="$_bashlyk_pathIni"
 #
 [[ "$1" == "${1##*/}" && -f "${pathIni}/$1" ]] || pathIni=
 [[ "$1" == "${1##*/}" && -f "$1" ]] && pathIni=$(pwd)
 [[ "$1" != "${1##*/}" && -f "$1" ]] && pathIni=$(dirname $1)
 [[ -n "$2" ]] && sTag="$2"
 #
 if [[ -z "$pathIni" ]]; then
  [[ -f "/etc/${_bashlyk_pathPrefix}/$1" ]] \
   && pathIni="/etc/${_bashlyk_pathPrefix}" || eval $(udfOnError return iErrorNoSuchFileOrDir)
 fi
 #
 aini=$(echo "${1##*/}" |\
  awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

 GLOBIGNORE="*:?"

 for s in $aini; do
  [[ -n "$s"   ]] || continue
  [[ -n "$ini" ]] && ini="${s}.${ini}" || ini="$s"
  [[ -s "${pathIni}/${ini}" ]] && \
   csvIni+=";$(udfIniSection2Csv "${pathIni}/${ini}" "$sTag");"
 done
 unset GLOBIGNORE
 udfCsvOrder "$csvIni" || eval $(udfOnError return)
 #return 0
}
#******
#****f* libcsv/udfIniGroupSection2CsvVar
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
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfIniGroupSection2Csv
#  SOURCE
udfIniGroupSection2CsvVar() {
 local IFS=$' \t\n'
 #
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfIniGroupSection2Csv "$2" $3)"'
 return 0
}
#******
#****f* libcsv/udfIni2Csv
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
#    0                            - Выполнено успешно
#    iErrorEmptyOrMissingArgument - аргумент отсутствует или файл конфигурации
#                                   не найден
#  EXAMPLE
#    local ini re
#    re='sTxt="-S-(da.*-R).*y_1="^_s.*e^_";\[exec\].*=$(.*\[ -n "$sUname" \] .*'
#    ini=$(mktemp --suffix=test.ini || tempfile -s .test.ini)                   #? true
#    cat <<'EOFini' > ${ini}                                                    #-
#[test]                                                                         #-
#    sTxt	=	$(date -R) a                                            #-
#    b		=	false                                                   #-
#    iXo Xo	=	19                                                      #-
#    iYo	=	80                                                      #-
#    test	=	line = to = line                                        #-
#    `simple line`                                                              #-
#[exec]:                                                                        #-
#    sUname=$(uname -a)                                                         #-
#    [ -n "$sUname" ] && date                                                   #-
#:[exec]                                                                        #-
#EOFini                                                                         #-
#    udfIni2Csv $ini | grep -o "_bashlyk_&#.._" >| wc -l | grep '^7$'           #? true
#    udfIni2Csv $ini | udfBashlykUnquote >| grep "$re"                          #? true
#    udfIni2CsvVar csvResult $ini                                               #? true
#    echo "$csvResult" | udfBashlykUnquote >| grep "$re"                        #? true
#    rm -f $ini
#  SOURCE
udfIni2Csv() {
 local IFS=$' \t\n'
 #
 [[ -n "$1" && -f "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 mawk -f ${_bashlyk_pathLib}/ini2csv.awk -- $1
 return 0
}
#******
#****f* libcsv/udfIni2CsvVar
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
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfIni2Csv
#  SOURCE
udfIni2CsvVar() {
 local IFS=$' \t\n'
 #
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfIni2Csv "$2")"'
 return 0
}
#******
#****f* libcsv/udfIniGroup2Csv
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
#    0                            - Выполнено успешно
#    iErrorNoSuchFileOrDir        - файл конфигурации не найден
#    iErrorEmptyOrMissingArgument - аргумент отсутствует или нет входных данных
#    iErrorEmptyResult            - результат отсутствует
#  EXAMPLE
#    local re='\[test\];_b.*d=;sTxt=foo;.*autoKey_0=.*_b.*d=;.*foo bar.*o=1080;'
#    local sTxt=foo b=false iXo=1921 iYo=80 ini iniChild csvResult
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#    printf "$fmt" sTxt $sTxt b $b "iXo Xo" 19 iYo $iYo | tee $ini
#    echo "simple line" | tee -a $ini
#    printf "$fmt" sTxt "foo bar" b "true" iXo "1920" iYo "1080" | tee $iniChild
#    udfIniGroup2Csv $iniChild >| grep "$re"                                    #? true
#    udfIniGroup2CsvVar csvResult $iniChild                                     #? true
#    echo "$csvResult" >| grep "$re"                                            #? true
#    rm -f $iniChild $ini
#    udfIniGroup2Csv $iniChild                                                  #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO проверка пустых данных (iErrorEmptyOrMissingArgument)
#  SOURCE
udfIniGroup2Csv() {
 local a aini csvIni ini pathIni s sTag aTag csvOut fnOpt ini pathIni IFS=$' \t\n' GLOBIGNORE
 #
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 ## TODO встроить защиту от подстановки конфигурационного файла (по владельцу)
 #
 [[ "$1" == "${1##*/}" && -f "$(_ pathIni)/$1" ]] && pathIni=$(_ pathIni)
 [[ "$1" == "${1##*/}" && -f "$1"              ]] && pathIni=$(pwd)
 [[ "$1" != "${1##*/}" && -f "$1"              ]] && pathIni=$(dirname $1)
 #
 if [[ -z "$pathIni" ]]; then
  [[ -f "/etc/$(_ pathPrefix)/$1" ]] && pathIni="/etc/$(_ pathPrefix)"
 fi
 #
 aini=$(echo "${1##*/}" |\
  awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

 GLOBIGNORE="*:?"

 if [[ -n "$pathIni" ]]; then
  for s in $aini; do
   [[ -n "$s"                ]] || continue
   [[ -n "$ini"              ]] && ini="${s}.${ini}" || ini="$s"
   [[ -s "${pathIni}/${ini}" ]] && \
    csvIni+="$(udfIni2Csv "${pathIni}/${ini}" | tr -d '\\')"
  done
 fi

 [[ "$_bashlyk_bSetOptions" == "1" && -n "$_bashlyk_csvOptions2Ini" ]] && {
  udfMakeTemp fnOpt
  udfIniWrite $fnOpt "$_bashlyk_csvOptions2Ini"
  _bashlyk_csvOptions2Ini=''
  _bashlyk_bSetOptions=0
  csvIni+="$(udfIni2Csv $fnOpt | tr -d '\\')"
 }

 declare -A a
 IFS='['
 for s in $csvIni; do
  sTag=${s%%]*}
  [[ -z "$sTag"  ]] && sTag=" "
  [[ $sTag == ";" ]] && continue
  [[ -z "$(echo "${s#*]}" | tr -d ';:')" ]] && continue
  a[$sTag]+="_bashlyk_csv_record=${s#*]}"
 done
 for s in "${!a[@]}"; do
  csvOut+="[${s// /}];${a[$s]}"
 done
 IFS=$' \t\n'
 unset GLOBIGNORE
 [[ -n "$csvOut" ]] || {
  [[ -d "$pathIni" ]] || eval $(udfOnError return iErrorNoSuchFileOrDir '$1')
  [[ -n "$csvIni"  ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
  eval $(udfOnError return iErrorEmptyResult)
 }
 echo ${csvOut} | sed -e "s/;\+/;/g"
 return 0
}
#******
#****f* libcsv/udfIniGroup2CsvVar
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
#    0                            - Выполнено успешно
#    iErrorNonValidVariable       - аргумент <varname> не является валидным идентификатором переменной
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#    #пример приведен в описании udfIniGroup2Csv
#  SOURCE
udfIniGroup2CsvVar() {
 local IFS=$' \t\n'
 #
 [[ -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfIsValidVariable $1 || eval $(udfOnError return $? '$1')
 eval 'export ${1}="$(udfIniGroup2Csv "$2")"'
 return 0
}
#******
#****f* libcsv/udfOptions2Ini
#  SYNOPSIS
#    udfOptions2Ini  [<section>]:(=[<varname>])|<csv;> ...
#  DESCRIPTION
#    подготовить csv-поток из уже инициализированных переменных, например, опций
#    командной строки согласно распределению этих переменных по указанным
#    cекциям <section> (см. udfIni) для совмещения с соответствующими данными
#    ini-конфигурационных файлов. Результат помещается в глобальную переменную
#    _bashlyk_csvOptions2Ini для использования в udfIni
#  INPUTS
#    распределение переменных по указанным секциям (см. udfIni)
#  RETURN VALUE
#    0                            - Выполнено успешно
#    iErrorEmptyOrMissingArgument - аргумент отсутствует
#  EXAMPLE
#   local sVoid="verbose;direct;log;" sMain="source;destination"
#   local unify="*.tmp,*~,*.bak" replace="replace" unify="unify" acc="acc"
#   local preExec="sUname=$(TZ=UTC date -R --date='@12345678'),date -R"
#   local sMD5='592dbbd3a17e18e14b828c75898437e4'
#   local sRules=":${sVoid} preExec:! main:${sMain} replace:- unify:= acc:+"
#   local verbose="yes foo" direct="false" log="/var/log/test.log" source="last"
#   local destination="/tmp/last.txt"
#   udfOptions2Ini $sRules                                                      #? true
#   _ csvOptions2Ini | md5sum >| grep ^${sMD5}                                  #? true
#   #udfIniWrite /tmp/${$}.test.ini "$(_ csvOptions2Ini)"
#   #udfIni /tmp/${$}.test.ini preExec:=
#   #udfPrepare2Exec $preExec
#  SOURCE
udfOptions2Ini() {
 local csv k s sClass sData sIni sRules sSection IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 for s in $*; do
  sSection="${s%:*}"
  sData="${s/$sSection/}"
  sClass="${s#*:}"
  sData=${sData/:/}
  sData=${sData/[=\-+\!]/}
  [[ "$sClass" == "$sData" ]] && sClass=
  csv=""
  [[ -n "$sClass" && -n "$sData" ]] && {
   udfSetLastError iErrorNonValidArgument "$sClass"
   continue
  }
  if [[ -z "$sData" ]]; then
   [[ -n "${!sSection}" ]] && csv+="${!sSection};"
  else
   IFS=';'
   for k in $sData; do
    [[ -n "${!k}" ]] && csv+="$k=${!k};"
   done
   IFS=$' \t\n'
  fi
  [[ -n "$csv" ]] || continue
  if [[ "$sClass" == "!" ]]; then
   s="[${sSection}]:;${csv};:[${sSection}]"
  else
   s="[${sSection}];${csv};"
  fi
  sIni+=$s
 done
 _ csvOptions2Ini "${sIni//,/;}"
 return 0
}
#******
