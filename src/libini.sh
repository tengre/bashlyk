#
# $Id$
#
#****h* BASHLYK/libini
#  DESCRIPTION  
#    Управление пассивными конфигурационными файлов в стиле INI. Имеется 
#    возможность подгрузки исполнимого контента
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libini/Required Once
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
#****** libini/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/libstd.sh" ] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****v* libini/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathIni:=$(pwd)}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_ini_void_autoKey_}
: ${_bashlyk_aRequiredCmd_ini:="[ awk cat cut dirname echo false grep mawk mv  \
  printf pwd rm sed sort touch tr true uniq w xargs"}
: ${_bashlyk_aExport_ini:="udfGetIniSection udfReadIniSection                  \
  udfReadIniSection2Var udfCsvOrder udfAssembly udfSetVarFromCsv               \
  udfSetVarFromIni udfCsvKeys udfIniWrite udfIniChange udfGetIni               \
  udfGetCsvSection udfGetCsvSection2Var udfGetIniSection2Var udfCsvOrder2Var   \
  udfCsvKeys2Var udfGetIni2Var udfSelectEnumFromCsvHash udfIniGroupSection2Csv \
  udfIniGroupSection2CsvVar udfIni2Csv udfIni2CsvVar udfIniGroup2Csv           \
  udfIniGroup2CsvVar udfIni udfCsvHash2Raw"}
#******
#****f* libini/udfGetIniSection
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
  [ -f "/etc/${_bashlyk_pathPrefix}/$1" ] \
   && pathIni="/etc/${_bashlyk_pathPrefix}" || return 1
 fi
 #
 aini=$(echo "${1##*/}"|awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')
 
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
#****f* libini/udfGetIniSection2Var
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
#    #пример приведен в описании udfGetIniSection
#  SOURCE
udfGetIniSection2Var() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 eval 'export ${1}="$(udfGetIniSection "$2" $3)"'
 return 0
}
#******
#****f* libini/udfReadIniSection
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
#     0  - Выполнено успешно
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_bashlyk_ini_test_autoKey_0="simple line";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult       
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini 
#    echo "simple line" | tee -a $ini                                           
#    udfReadIniSection $ini test >| grep "^${csv}$"                             #? true
#    udfReadIniSection2Var csvResult $ini test                                  #? true
#    echo "$csvResult" | grep "^${csv}$"                                        #? true
#    rm -f $ini                                                                 
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
  b=$(echo $s | grep -oE '\[.*\]' | tr -d '[]' | xargs)
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
   if [ -z "$k" -o "$k" = "$v" -o -n "$(echo "$k" | grep '.*[[:space:]+].*')" ]
   then
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
#****f* libini/udfReadIniSection2Var
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
#    #пример приведен в описании udfIniGroup2Csv
#  SOURCE
udfReadIniSection2Var() {
 [ -n "$2" -a -f "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 #udfThrow "Error: required valid variable name \"$1\""
 eval 'export ${1}="$(udfReadIniSection "$2" $3)"'
 return 0
}
#******
#****f* libini/udfCsvOrder
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
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo bar;b=true;iXo=1920;' 
#    local csvResult                                                            
#    local csvTest='b=true;iXo=1920;iYo=1080;sTxt="foo bar";'                   
#    udfCsvOrder "$csv" >| grep "^${csvTest}$"                                  #? true
#    udfCsvOrder2Var csvResult "$csv"                                           #? true
#    echo $csvResult | grep "^${csvTest}$"                                      #? true
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
#****f* libini/udfCsvOrder2Var
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
#    #пример приведен в описании udfCsvOrder
#  SOURCE
udfCsvOrder2Var() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 #udfThrow "Error: required valid variable name \"$1\""
 eval 'export ${1}="$(udfCsvOrder "$2")"'
 return 0
}
#******
#****f* libini/udfSetVarFromCsv
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
#    local b sTxt iXo iYo                                                       
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo = bar;b=true;iXo=1920;'
#    local sResult="true:foo = bar:1920:1080"                                   
#    udfSetVarFromCsv "$csv" b sTxt iXo iYo                                     #? true
#    echo "${b}:${sTxt}:${iXo}:${iYo}" | grep "^${sResult}$"                    #? true
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
#****f* libini/udfSetVarFromIni
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
#****f* libini/udfCsvKeys
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
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;' sResult               
#    udfCsvKeys "$csv" | xargs >| grep "^sTxt b iXo iYo$"                       #? true
#    udfCsvKeys2Var sResult "$csv"                                              #? true
#    echo $sResult | grep "^sTxt b iXo iYo$"                                    #? true
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
#****f* libini/udfCsvKeys2Var
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
#    #пример приведен в описании udfCsvKeys
#  SOURCE
udfCsvKeys2Var() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 #udfThrow "Error: required valid variable name \"$1\""
 eval 'export ${1}="$(udfCsvKeys "$2")"'
 return 0
}
#******
#****f* libini/udfIniWrite
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
#    local csv='[test];sTxt="foo bar";b=true;iXo=1921;iYo=1080;' ini s          
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    udfIniWrite $ini "$csv"                                                    #? true
#     grep -E '^\[test\]$'        $ini                                          #? true
#     grep -E 'sTxt.*=.*foo bar$' $ini                                          #? true
#     grep -E 'b.*=.*true$'       $ini                                          #? true
#     grep -E 'iXo.*=.*1921$'     $ini                                          #? true
#     grep -E 'iYo.*=.*1080$'     $ini                                          #? true
#     cat $ini                                                                  
#     rm -f $ini ${ini}.bak                                                     
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
#****f* libini/udfIniChange
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
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=999;' csvResult              
#    local sTxt="bar foo" b=true iXo=1234 iYo=4321 ini                          
#    local fmt="[sect%s]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n" 
#    local md5='c48c02c5744053a7dbf14dc775730e8c'                               
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" 1 sTxt foo '' value iXo 720 "non valid key" value | tee $ini 
#    echo "simple line" | tee -a $ini                                           
#    printf "$fmt" 2 sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee -a $ini    
#    udfIniChange $ini "$csv" sect1                                             #? true
#    udfReadIniSection $ini sect1 >| md5sum | grep "^${md5}.*-$"                #? true
#    rm -f $ini ${ini}.bak                                                      
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
#****f* libini/udfIni
#  SYNOPSIS
#    udfIni <file> [<section>]:(=[<varname>])|<csv;> ...
#  DESCRIPTION
#    получить данные указанных секций <section> ini-файла <file> ( и ему 
#    родственных) через инициализацию перечисленных в "CSV;"-строке валидных 
#    идентификаторов переменных, идентичных соответствующим ключам секции
#    или "сырую" сериализацию всех данных секции в <varname>
#  INPUTS
#     file    - файл конфигурации формата "*.ini".
#     section - имена секций. Пустое значение для "безымянной" секции
#     csv;    - список валидных переменных для приема соответствующих значений
#               строк вида "<key>=<value>" секции
#     varname - валидный идентификатор переменной для сериализации в CSV-строку 
#               всех данных секции. Если идентификатор опущен, то приемником 
#               будет являться переменная с идентификатором имени секции section
#  RETURN VALUE
#     0  - Выполнено успешно
#    255 - Ошибка: аргументы отсутствуют или файл конфигурации не найден
#  EXAMPLE
#    local sTxt="foo = bar" b=true iXo=1921 iYo=1080 ini iniChild exec          
#    ini=$(mktemp --suffix=test.ini XXXXXXXX || tempfile -s .test.ini)          #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          
#    cat <<'EOFini' > ${ini}                                                    #-
#[test]                                                                         #-
#    sTxt	=	foo                                                     #-
#    b		=	false                                                   #-
#    iXo Xo	=	19                                                      #-
#    iYo	=	80                                                      #-
#    simple line                                                                #-
#[exec]:                                                                        #-
#    date                                                                       #-
#    sUname="$(uname -a)"                                                       #-
#:[exec]                                                                        #-
#    EOFini                                                                     #-
#    cat <<'EOFiniChild' > ${iniChild}                                          #-
#    [test]	                                                                #-
#    sTxt	=	foo = bar                                               #-
#    b		=	true                                                    #-
#    iXo	=	1921                                                    #-
#    iYo	=	1080                                                    #-
#    EOFiniChild                                                                #-
#    sTxt='';b='';iXo=''                                                        
#    udfIni $iniChild 'test:sTxt;b;iXo' 'exec:='                                #? true
#    echo "${sTxt};${b};${iXo}" >| grep -e "^foo = bar;true;1921$"              #? true
#    echo "$exec" >| grep -e '^:;date;"sUname="$(uname -a)"";$'                 #? true
#    rm -f $iniChild $ini                                                       
#  SOURCE
udfIni() {
 [ -n "$1" -a -f "$1" ] || return 255
 #
 local bashlyk_udfIni_csv bashlyk_udfIni_s bashlyk_udfIni_sSection 
 local bashlyk_udfIni_csvSection bashlyk_udfIni_csvVar
 #
 bashlyk_udfIni_csv=$(udfIniGroup2Csv "$1")
 shift
 #
 for bashlyk_udfIni_s in $*; do
  bashlyk_udfIni_sSection=${bashlyk_udfIni_s%:*}
  bashlyk_udfIni_csvSection=$(udfGetCsvSection "$bashlyk_udfIni_csv" "$bashlyk_udfIni_sSection")
  if [ $bashlyk_udfIni_s = "${bashlyk_udfIni_s%:=*}" ]; then
   bashlyk_udfIni_aVar="$(echo ${bashlyk_udfIni_s#*:}  | tr ';' ' ')"
   ## TODO udfCsvOrder лишний вызов
   udfSetVarFromCsv "$bashlyk_udfIni_csvSection" $bashlyk_udfIni_aVar 
  else
   bashlyk_udfIni_aVar="${bashlyk_udfIni_s#*:=}"   
   : ${bashlyk_udfIni_aVar:=$bashlyk_udfIni_sSection}
   udfIsValidVariable $bashlyk_udfIni_aVar || return 2
   eval 'export $bashlyk_udfIni_aVar="$(udfCsvHash2Raw "$bashlyk_udfIni_csvSection" "$bashlyk_udfIni_sSection")"'  
  fi
 done
 ## TODO вложенные кавычки: " " ""
 return 0
}
#******
#****f* libini/udfGetIni
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
#****f* libini/udfGetIni2Var
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
#    #пример приведен в описании udfGetIni
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
#****f* libini/udfGetCsvSection
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
#****f* libini/udfGetCsvSection2Var
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
#    local csv='[];a=b;c=d e;[s1];a=f;c=g h;[s2];a=k;c=l m;' csvResult          
#    udfGetCsvSection2Var csvResult "$csv"                                      
#    echo $csvResult >| grep '^a=b;c=d e;$'                                     #? true
#    udfGetCsvSection2Var csvResult "$csv" s1                                   
#    echo $csvResult >| grep '^a=f;c=g h;$'                                     #? true
#    udfGetCsvSection2Var csvResult "$csv" s2                                   
#    echo $csvResult >| grep '^a=k;c=l m;$'                                     #? true
#  SOURCE
udfGetCsvSection2Var() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 eval 'export ${1}="$(udfGetCsvSection "$2" $3)"'
 return 0
}
#******
#****f* libini/udfSelectEnumFromCsvHash
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
 local cIFS csv s sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"
 cIFS=$IFS
 IFS=';'
 for s in $(echo "${1#*\[$2\];}" | cut -f1 -d'[')
 do
  echo "$s" | grep "^${sUnnamedKeyword}" >/dev/null 2>&1 && csv+="${s#*=};"
 done
 IFS=$cIFS
 echo "$csv"
}
#******
#****f* libini/udfCsvHash2Raw
#  SYNOPSIS
#    udfCsvHash2Raw <csv> [<tag>]
#  DESCRIPTION
#    подготовить CSV;-строку для выполнения в качестве сценария, поля которого 
#    рассматриваются как строки команд. При этом автоматические ключи вида 
#    "_bashlyk_ini_<секция>_autoKey_<номер>" будут убраны. Поля вида 
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
#    local csv='[];a=b;_bashlyk_ini_void_autoKey_0="d = e";[s1];_bashlyk_ini_s1_autoKey_0=f=0;c=g h;[s2];a=k;_bashlyk_ini_s2_autoKey_0=l m;'                                        
#    udfCsvHash2Raw "$csv"    >| grep '^a=b;"d = e";$'                          #? true
#    udfCsvHash2Raw "$csv" s1 >| grep '^f=0;c=g h;$'                            #? true
#    udfCsvHash2Raw "$csv" s2 >| grep '^a=k;l m;$'                              #? true
#  SOURCE
udfCsvHash2Raw() {
 local cIFS csv s sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"
 cIFS=$IFS
 IFS=';'
 for s in $(echo "${1#*\[$2\];}" | cut -f1 -d'[')
 do
  csv+="${s#${sUnnamedKeyword}[0-9]*=};"
 done
 IFS=$cIFS
 echo "$csv"
}
#******
#****f* libini/udfIniSection2Csv
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
 [ -n "$1" -a -f "$1" ] || return 255
 mawk -f ${_bashlyk_pathLib}/inisection2csv.awk -v "sTag=$2" -- $1
 return 0
}
#******
#****f* libini/udfIniSection2CsvVar
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
#    #пример приведен в описании udfIniGroupSection2Csv
#  SOURCE
udfIniSection2CsvVar() {
 [ -n "$2" -a -f "$2" ] || return 255
 udfIsValidVariable $1  || return 2
 #udfThrow "Error: required valid variable name \"$1\""
 eval 'export ${1}="$(udfIniSection2Csv "$2" $3)"'
 return 0
}
#******
#****f* libini/udfIniGroupSection2Csv
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
#****f* libini/udfIniGroupSection2CsvVar
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
#    #пример приведен в описании udfIniGroupSection2Csv
#  SOURCE
udfIniGroupSection2CsvVar() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 eval 'export ${1}="$(udfIniGroupSection2Csv "$2" $3)"'
 return 0
}
#******
#****f* libini/udfIni2Csv
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
#    local csv='\[\];\[test\];sTxt=foo;b=false;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";iYo=80;_bashlyk_ini_test_autoKey_1="simple line";\[exec\];:;_bashlyk_ini_exec_autoKey_0="sUname=$(uname -a)";_bashlyk_ini_exec_autoKey_1="_bashlyk_&#91_ -n "$sUname" _bashlyk_&#93_ && date";'
#    ini=$(mktemp --suffix=test.ini XXXXXXXX || tempfile -s .test.ini)          #? true
#    cat <<'EOFini' > ${ini}                                                    #-
#[test]                                                                         #-
#    sTxt	=	foo                                                     #-
#    b		=	false                                                   #-
#    iXo Xo	=	19                                                      #-
#    iYo	=	80                                                      #-
#    simple line                                                                #-
#[exec]:                                                                        #-
#    sUname=$(uname -a)                                                         #-
#    [ -n "$sUname" ] && date                                                   #-
#:[exec]                                                                        #-
#EOFini                                                                         #-
#    udfIni2Csv $ini   >| grep "^${csv}$"                                       #? true
#    udfIni2CsvVar csvResult $ini                                               #? true
#    echo "$csvResult" >| grep "^${csv}$"                                       #? true
#    rm -f $ini                                                                 
#  SOURCE
udfIni2Csv() {
 [ -n "$1" -a -f "$1" ] || return 255
 mawk -f ${_bashlyk_pathLib}/ini2csv.awk -- $1
 return 0
}
#******
#****f* libini/udfIni2CsvVar
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
#    #пример приведен в описании udfIni2Csv
#  SOURCE
udfIni2CsvVar() {
 [ -n "$2" ] || return 255
 udfIsValidVariable $1 || return 2
 #udfThrow "Error: required valid variable name \"$1\""
 eval 'export ${1}="$(udfIni2Csv "$2")"'
 return 0
}
#******
#****f* libini/udfIniGroup2Csv
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
#    local csv='\[\];\[test\];b=true;_bashlyk_ini_test_autoKey_0="iXo Xo = 19";_bashlyk_ini_test_autoKey_1="simple line";iXo=1921;iYo=1080;sTxt="foo bar";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild                 
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"   
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"                          
#    printf "$fmt" sTxt foo b false "iXo Xo" 19 iYo 80 | tee $ini               
#    echo "simple line" | tee -a $ini                                           
#    printf "$fmt" sTxt "$sTxt" b "$b" iXo "$iXo" iYo "$iYo" | tee $iniChild    
#    udfIniGroup2Csv $iniChild >| grep "^${csv}$"                               #? true
#    udfIniGroup2CsvVar csvResult $iniChild                                     #? true
#    echo "$csvResult" >| grep "^${csv}$"                                       #? true
#    rm -f $iniChild $ini                                                       
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
  [ -s "${pathIni}/${ini}" ] && csvIni+=";$(udfIni2Csv "${pathIni}/${ini}" "$sTag" | tr -d '\\');"
 done

 aTag=$(echo $csvIni | tr ';' '\n' | grep -oE '\[.*\]' | sort | uniq | tr -d '[]' | tr '\n' ' ')
 
 sR=''
 for s in "" $aTag; do
  sT=''
  sS='\['${s}'\]'
  ## TODO защита от зацикливания
  while [ true ]; do
   [ -n "$(echo $csvIni | grep -oE $sS)" ] || break
   sF=$(echo "${csvIni#*${sS};}" | cut -f1 -d'[')
   csvIni=$(echo ${csvIni/${sS};${sF}/})
   sT+=";"${sF}
  done
  [ -z "${sF/:;*/}" ] && sF="${sT}" || sF="$(udfCsvOrder "${sT}")"
  sR+="[${s}];${sF};"
 done
 GLOBIGNORE=$sGlobIgnore
 echo ${sR} | sed -e "s/;\+/;/g"
 return 0
}
#******
#****f* libini/udfIniGroup2CsvVar
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
#    #пример приведен в описании udfIniGroup2Csv
#  SOURCE
udfIniGroup2CsvVar() {
 [ -n "$2" ] || return 255
 udfIsValidVariable "$1" || return 2
 eval 'export ${1}="$(udfIniGroup2Csv "$2")"'
 return 0
}
#******
