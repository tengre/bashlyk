#
# $Id: libcsv.sh 733 2017-04-13 09:58:01+04:00 toor $
#
#****h* BASHLYK/libcsv
#  DESCRIPTION
#    Management of the configuration files in the INI-style
#    Deprecated, for backward compatibility
#  USES
#    liberr libstd libold
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libcsv/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBCSV provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBCSV" ] && return 0 || _BASHLYK_LIBCSV=1
[ -n "$_BASHLYK" ] || . bashlyk || eval '                                      \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* libcsv/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libold.sh ]] && . "${_bashlyk_pathLib}/libold.sh"
#******
#****G* libcsv/Global variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
#: ${_bashlyk_bSetOptions:=}
#: ${_bashlyk_csvOptions2Ini:=}
#: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_ini_void_autoKey_}

declare -rg _bashlyk_externals_csv="                                           \
                                                                               \
    awk cat cut dirname false getopt grep mawk mkdir                           \
    mv pwd rm sed sort touch tr true uniq xargs                                \
                                                                               \
"

declare -rg _bashlyk_exports_csv="                                             \
                                                                               \
    udfBashlykUnquote udfCheckCsv udfCsvHash2Raw udfCsvKeys udfCsvOrder        \
    udfExcludePairFromHash udfGetCsvSection udfGetIni udfGetIniSection         \
    udfGetOpt udfGetOptHash udfIni udfIni2Csv udfIniChange udfIniGroup2Csv     \
    udfIniGroupSection2Csv udfIniSection2Csv udfIniWrite udfLocalVarFromCSV    \
    udfOptions2Ini udfPrepare2Exec udfReadIniSection udfSelectEnumFromCsvHash  \
    udfSerialize udfSetOptHash udfSetVarFromCsv udfSetVarFromIni udfShellExec  \
                                                                               \
"
#******
#****f* libcsv/udfCheckCsv
#  SYNOPSIS
#    udfCheckCsv [[-v] <varname>] "<csv>;"
#  DESCRIPTION
#    Bringing the format "key = value" fields of the CSV-line. If the field does
#    not contain a key or key contains a space, then the field receives key
#    species ${_bashlyk_sUnnamedKeyword_}<increment>, and all the contents of
#    the field becomes the value. The result is printed to stdout or assigned to
#    the <var> if the first argument is listed as -v <var> ( -v can be skipped )
#  INPUTS
#    csv;    - CSV-string, separated by ';'
#    Important! Enclose the string in double quotes if it can contain spaces
#    Important! The string must contain the field sign ";"
#    varname - variable identifier (without the "$"). If present the result will
#    be assigned to this variable, otherwise result will be printed to stdout
#  OUTPUT
#    separated by a ";" CSV-string in fields that contain data in the format
#    "<key> = <value>; ..."
#  ERRORS
#    EmptyResult     - empty result
#    MissingArgument - no arguments
#    InvalidArgument - invalid argument
#    InvalidVariable - invalid variable for output assign
#  EXAMPLE
#    local cmd=udfCheckCsv csv="a=b;a=c;s=a b c d e f;test value" v1 v2
#    local re="^a=b;a=c;s=\"a b c d e f\";${_bashlyk_sUnnamedKeyword}0=\"test value\";$"
#    $cmd "$csv" >| grep "$re"                                                  #? true
#    $cmd -v v1 "$csv"                                                          #? true
#    echo $v1 >| grep "$re"                                                     #? true
#    $cmd  v2 "$csv"                                                            #? true
#    echo $v2 >| grep "$re"                                                     #? true
#    $cmd  v2 ""                                                                #? ${_bashlyk_iErrorEmptyResult}
#    echo $v2 >| grep "$re"                                                     #? false
#    $cmd -v invalid+variable "$csv"                                            #? ${_bashlyk_iErrorInvalidVariable}
#    $cmd    invalid+variable "$csv"                                            #? ${_bashlyk_iErrorInvalidVariable}
#    $cmd invalid+variable                                                      #? ${_bashlyk_iErrorInvalidArgument}
#    $cmd _valid_variable_                                                      #? ${_bashlyk_iErrorInvalidArgument}
#    $cmd 'csv data;' | grep "^${_bashlyk_sUnnamedKeyword}0=.csv.data.;$"       #? true
#    $cmd                                                                       #? ${_bashlyk_iErrorMissingArgument}
#  SOURCE
udfCheckCsv() {

  if (( $# > 1 )); then

    [[ "$1" == "-v" ]] && shift

    udfIsValidVariable $1 || eval $( udfOnError return InvalidVariable "$1" )

    eval 'export $1="$( shift; udfCheckCsv "$1" )"'

    [[ ${!1} ]] || eval $( udfOnError return EmptyResult "$1" )

    return 0

  fi

  udfOn MissingArgument $1 || return $?

  [[ $1 =~ \; ]] || return $( _ iErrorInvalidArgument )

  local csv i IFS k s v

  IFS=';'
  i=0
  csv=''

  for s in $1; do

    s=${s/\[*\][;]/}
    s=${s//[\'\"]/}

    k="$( echo ${s%%=*} )"
    v="$( echo ${s#*=} )"

    [[ -n "$k" ]] || continue

    if [[ "$k" == "$v" || "$k" =~ ^.*[[:space:]]+.*$ ]]; then

      k=${_bashlyk_sUnnamedKeyword}${i}
      i=$((i+1))

    fi

    IFS=' ' csv+="$k=$( udfQuoteIfNeeded $v );"

  done

  IFS=$' \t\n'

  echo "$csv"

  [[ $csv ]] && return 0 || return $( _ iErrorEmptyResult )

}
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
#  ERRORS
#   NoSuchFileOrDir - файл конфигурации не найден
#   MissingArgument - аргумент не задан
#   EmptyResult     - результат отсутствует
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
#    rm -f $iniChild $ini
#    udfGetIniSection $iniChild test                                            #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO тест пустой результат
#  SOURCE
udfGetIniSection() {

  udfOn MissingArgument $1 || return $?

  local a csv fn path s sTag IFS=$' \t\n' GLOBIGNORE

  path="$_bashlyk_pathIni"

  [[ "$1" == "${1##*/}" && -f "${path}/$1" ]] || path=
  [[ "$1" == "${1##*/}" && -f "$1" ]] && path=$( exec -c pwd )
  [[ "$1" != "${1##*/}" && -f "$1" ]] && path=${1%/*}
  [[ $2 ]] && sTag="$2"

  if [[ ! $path ]]; then

    [[ -f "/etc/${_bashlyk_pathPrefix}/$1" ]] \
      && path="/etc/${_bashlyk_pathPrefix}" \
      || eval $( udfOnError return NoSuchFileOrDir '/etc/${_bashlyk_pathPrefix}/$1' )

  fi

  a=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

  GLOBIGNORE="*:?"

  for s in $a; do

    [[ $s             ]] || continue
    [[ $fn            ]] && fn="${s}.${fn}" || fn="$s"
    [[ -s "$path/$fn" ]] && csv+=";$( udfIniSection2Csv "$path/$fn" "$sTag" );"

  done
  unset GLOBIGNORE

  udfCsvOrder "$csv"

  return $?

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
#  ERRORS
#    MissingArgument - аргумент отсутствует
#    EmptyResult     - пустой результат
#  EXAMPLE
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo bar;b=true;iXo=1920;'
#    local csvResult
#    local csvTest='b=true;iXo=1920;iYo=1080;sTxt="foo bar";'
#    udfCsvOrder "$csv" >| grep "^${csvTest}$"                                  #? true
#    udfCsvOrder                                                                #? $_bashlyk_iErrorMissingArgument
#    ## TODO тест пустой результат
#  SOURCE
udfCsvOrder() {

  udfOn MissingArgument $1 || return $?

  local aKeys csv fnExec IFS=$' \t\n'

  csv="$( udfCheckCsv "$1" )"
  aKeys="$( udfCsvKeys "$csv" | tr ' ' '\n' | sort -u | uniq -u | xargs )"
  csv=$( echo -e "${csv/;/\\n}" )
  #
  udfMakeTemp fnExec
  #
  cat <<- _CsvOrder_EOF > $fnExec
	#!/bin/bash
	#
	# . bashlyk
	#
	udfAssembly() {
	  local $aKeys
	#
	  $csv
	#
	  udfShowVariable $aKeys | grep -v '^:' | tr -d '\t' | \
	   sed -e "s/=\(.*[[:space:]]\+.*\)/=\"\1\"/" | tr '\n' ';' | sed -e "s/;;/;/"
	#
	  return 0
	}
	#
	udfAssembly
	_CsvOrder_EOF

  csv="$( . $fnExec 2>/dev/null )"

  rm -f $fnExec

  [[ $csv ]] && echo "$csv" || eval $( udfOnError return EmptyResult )

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
#  ERRORS
#    MissingArgument - аргумент(ы) отсутствуют
#  EXAMPLE
#    local b sTxt iXo iYo
#    local csv='sTxt=bar;b=false;iXo=21;iYo=1080;sTxt=foo = bar;b=true;iXo=1920;'
#    local sResult="true:foo = bar:1920:1080"
#    udfSetVarFromCsv "$csv" b sTxt iXo iYo                                     #? true
#    echo "${b}:${sTxt}:${iXo}:${iYo}" | grep "^${sResult}$"                    #? true
#  SOURCE
udfSetVarFromCsv() {

  udfOn MissingArgument $1 || return $?

  local bashlyk_csvInput_KLokRJky bashlyk_csvResult_KLokRJky bashlyk_k_KLokRJky bashlyk_v_KLokRJky IFS=$' \t\n'

  bashlyk_csvInput_KLokRJky=";$(udfCsvOrder "$1");"
  shift

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
#  ERRORS
#    MissingArgument - аргумент(ы) отсутствуют
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

  udfOn NoSuchFileOrDir $1 || return $?
  udfOn MissingArgument $3 || return $?

  local fn="$1" sSection="$2" IFS=$' \t\n'

  shift 2

  udfSetVarFromCsv ";$(udfIniGroupSection2Csv $fn $sSection);" $*

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
#  ERRORS
#    MissingArgument - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;' sResult
#    udfCsvKeys "$csv" | xargs >| grep "^sTxt b iXo iYo$"                       #? true
#  SOURCE
udfCsvKeys() {

  udfOn MissingArgument $* || return $?

  local csv s IFS=';'

  for s in $*; do

   csv+="${s%%=*} "

  done

  echo "$csv"

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
#  ERRORS
#   NoSuchFileOrDir - аргумент не задан или это не файл конфигурации
#   EmptyResult     - функция не возвращает результат
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_bashlyk_ini_test_autoKey_0="simple line";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult
#    local fmt="[test] \n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini
#    printf "\n\n# comment\nsimple line\n\n" | tee -a $ini
#    udfReadIniSection $ini test >| grep "^${csv}$"                             #? true
#    rm -f $ini
#    udfReadIniSection $ini test                                                #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO тест "пустой результат"
#  SOURCE
udfReadIniSection() {

  udfOn NoSuchFileOrDir $1 || return $?

  local b bOpen csvResult i ini k v s sTag IFS sUnnamedKeyword

  bOpen=false
  i=0
  ini="$1"
  IFS=$' \t\n'
  sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"

  [[ $2 ]] && sTag=$2 || bOpen=true

  while read -t 4 s; do

    [[ "$s" =~ ^#|^$  ]] && continue
    [[ "$s" =~ \[.*\] ]] && b=${s//[\[\]]/} || b=''

    if [[ $b ]]; then

      $bOpen && break
      if [[ $b =~ [[:blank:]]*${sTag}[[:blank:]]* ]]; then

        csvResult=
        bOpen=true

      else

        continue

      fi

    else

      $bOpen || continue
      s="${s//\'/}"
      k="$(echo ${s%%=*} )"
      v="$(echo ${s#*=} )"

      if [[ -z "$k" || "$k" == "$v" || "$k" =~ .*[[:space:]+].* ]]; then

        k=${sUnnamedKeyword}${i}
        i=$((i+1))
        v="$s"

      fi

      csvResult+="$k=$( udfQuoteIfNeeded $v );"

    fi

  done < $ini

  $bOpen || eval $( udfOnError return EmptyResult )
  echo $csvResult

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
#  ERRORS
#    NotExistNotCreated - путь не существует и не создан
#    MissingArgument    - аргументы отсутствуют
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

  udfOn MissingArgument $1 || return $?

  local csv ini="$1" s IFS=$' \t\n'

  [[ $2 ]] && s="$2" || s="$( _ csvOptions2Ini )"

  udfOn MissingArgument $s || return $?

  mkdir -p "${ini%/*}" || eval $( udfOnError NotExistNotCreated "${ini%/*}" )

  [[ -s "$ini" ]] && mv -f "$ini" "${ini}.bak"

  csv="$(echo "$s" | sed -e "s/[;]\+/;/g" -e "s/\(:\?\[\)/;;\1/g" -e "s/\[\]//g" | tr -d '"')"

  IFS=';'

  for s in $csv; do

    k="${s%%=*}"
    v="${s#*=}"
    [[ "$k" == "$v" ]] && echo "$v" || printf -- "\t%s\t=\t%s\n" "$k" "$v"
    ## TODO продумать перенос уничтожения автоключей в udfBashlykUnquote

  done | sed -e "s/\t\?_bashlyk_ini_.*_autoKey_[0-9]\+\t\?=\t\?//g" | udfBashlykUnquote > "$ini"

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
#  ERRORS
#    MissingArgument - аргументы отсутствуют
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

  udfOn NoSuchFileOrDir $1 || return $?
  udfOn MissingArgument $2 || return $?

  local a aKeys aTag csv ini="$1" s csvNew="$2" sTag IFS=$' \t\n'

  [[ $3 ]] && sTag="$3"

  [[ -f "$ini" ]] || touch "$ini"

  aTag="$( exec -c grep -oE '\[.*\]' $ini | tr -d '[]' | sort -u | uniq -u | xargs)"

  [[ $sTag ]] && echo "$aTag" | grep -w "$sTag" >/dev/null || aTag+=" $sTag"

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
#  ERRORS
#    InvalidVariable - невалидный идентификатор переменной
#    NoSuchFileOrDir - файл конфигурации не найден
#    MissingArgument - аргументы отсутствуют
#  EXAMPLE
#    local sTxt="foo = bar" b=true iXo=1921 iYo=1080 ini iniChild
#    local exec replace unify acc sVoid=void sMain='sTxt;b;iXo'
#    local sRules=":${sVoid} exec:! main:${sMain} replace:- unify:= acc:+"
#
#    ini=$(mktemp --suffix=test.ini || tempfile -s .test.ini)                   #? true
#    iniChild="$(dirname $ini)/child.$(basename $ini)"
#
#    cat <<'EOFini' > ${ini}                                                    #-
#    void	=	1                                                       #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt	=	$(date -R)                                              #-
#    b		=	false                                                   #-
#    iXo Xo	=	19                                                      #-
#    iYo	=	80                                                      #-
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
#    void	=	0                                                       #-
#    [main]	                                                                #-
#    sTxt	=	foo = bar                                               #-
#    b		=	true                                                    #-
#    iXo	=	1921                                                    #-
#    iYo	=	1080                                                    #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345679'                                          #-
#    sUname="$(uname)"                                                          #-
#:[exec]                                                                        #-
#[replace]                                                                      #-
#	after replacing                                                         #-
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

  udfOn MissingArgument $1 || return $?

  local IFS=$' \t\n'
  local bashlyk_udfIni_csv bashlyk_udfIni_s bashlyk_udfIni_sSection
  local bashlyk_udfIni_csvSection bashlyk_udfIni_csvVar bashlyk_udfIni_ini
  local bashlyk_udfIni_cClass

  bashlyk_udfIni_ini="$1"
  shift

  [[ "$_bashlyk_bSetOptions" == 1 ]] && udfOptions2Ini $*
  #
  bashlyk_udfIni_csv=$( udfIniGroup2Csv "$bashlyk_udfIni_ini" )
  bashlyk_udfIni_s=$?
  [[ "$bashlyk_udfIni_s" == 0 ]] || eval $(udfOnError return $bashlyk_udfIni_s)
  #
  for bashlyk_udfIni_s in $*; do

    bashlyk_udfIni_sSection=${bashlyk_udfIni_s%:*}
    bashlyk_udfIni_csvSection=$(udfGetCsvSection "$bashlyk_udfIni_csv" "$bashlyk_udfIni_sSection")

    if [[ "$bashlyk_udfIni_s" == "${bashlyk_udfIni_s%:[=\-+\!]*}" ]]; then

      bashlyk_udfIni_aVar="${bashlyk_udfIni_s#*:}"
      udfSetVarFromCsv "$bashlyk_udfIni_csvSection" ${bashlyk_udfIni_aVar//;/ }

    else

      bashlyk_udfIni_cClass="${bashlyk_udfIni_s#*:}"
      udfIsValidVariable $bashlyk_udfIni_sSection \
        || eval $(udfOnError return InvalidVariable '$bashlyk_udfIni_sSection')

      case "$bashlyk_udfIni_cClass" in

        !|-) bashlyk_udfIni_csvSection="${bashlyk_udfIni_csvSection##*_bashlyk_csv_record=;}" ;;
         #+) bashlyk_udfIni_csvSection="$(echo "$bashlyk_udfIni_csvSection" | sed -e "s/_bashlyk_csv_record=;//g")" ;;
          =) bashlyk_udfIni_csvSection="$(echo "$bashlyk_udfIni_csvSection" | tr ';' '\n' | sort | uniq | tr '\n' ';')" ;;

      esac

      eval 'export $bashlyk_udfIni_sSection="$(udfCsvHash2Raw "$bashlyk_udfIni_csvSection" "$bashlyk_udfIni_sSection")"'

    fi

  done
  ## TODO internal double quoted: " " ""
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
#  ERRORS
#    MissingArgument - аргументы отсутствуют или файл конфигурации не найден
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
#    rm -f $iniChild $ini
#  SOURCE
udfGetIni() {

  udfOn NoSuchFileOrDir $1 || return $?

  local csv s ini="$1" IFS=$' \t\n'

  shift

  for s in "" $*; do

    csv+="[${s}];$(udfIniGroupSection2Csv $ini $s)"

  done

  echo "$csv"

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
#  EXAMPLE
#    local csv='[];a=b;_bashlyk_ini_void_autoKey_0="d = e";[s1];_bashlyk_ini_s1_autoKey_0=f=0;c=g h;[s2];a=k;_bashlyk_ini_s2_autoKey_0=l m;'
#    udfSelectEnumFromCsvHash "$csv"    >| grep '^"d = e";$'                    #? true
#    udfSelectEnumFromCsvHash "$csv" s1 >| grep '^f=0;$'                        #? true
#    udfSelectEnumFromCsvHash "$csv" s2 >| grep '^l m;$'                        #? true
#  SOURCE
udfSelectEnumFromCsvHash() {

  local IFS=';' csv s sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"

  for s in $(echo "${1#*\[$2\];}" | cut -f1 -d'['); do

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
#  EXAMPLE
#    local csv='[];_bashlyk_csv_record=;a=b;_bashlyk_ini_void_autoKey_0="d = e";[s1];_bashlyk_ini_s1_autoKey_0=f=0;c=g h;[s2];a=k;_bashlyk_ini_s2_autoKey_0=l m;'
#    udfCsvHash2Raw "$csv"    >| grep '^a=b;"d = e";$'                          #? true
#    udfCsvHash2Raw "$csv" s1 >| grep '^f=0;c=g h;$'                            #? true
#    udfCsvHash2Raw "$csv" s2 >| grep '^a=k;l m;$'                              #? true
#  SOURCE
udfCsvHash2Raw() {

  local IFS=';' csv s sUnnamedKeyword="_bashlyk_ini_${2:-void}_autoKey_"

  for s in $(echo "${1#*\[$2\];}" | cut -f1 -d'['); do

    s="${s#${sUnnamedKeyword}[0-9]*=}"
    s="${s##*_bashlyk_csv_record=}"

    [[ $s ]] || continue

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
#  ERRORS
#    MissingArgument - аргумент отсутствует или файл конфигурации не найден
#  EXAMPLE
#    local csv='sTxt="foo bar";b=true;iXo=1921;iYo=1080;_bashlyk_ini_test_autoKey_0="simple line";'
#    local sTxt="foo bar" b=true iXo=1921 iYo=1080 ini iniChild csvResult
#    local fmt="[test]\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n\t%s\t=\t%s\n"
#    ini=$(mktemp --suffix=.ini || tempfile -s .test.ini)                       #? true
#    printf "$fmt" "sTxt" "$sTxt" "b" "$b" "iXo" "$iXo" "iYo" "$iYo" | tee $ini
#    echo "simple line" | tee -a $ini
#    udfIniSection2Csv $ini test >| grep "^${csv}$"                             #? true
#    rm -f $ini
#  SOURCE
udfIniSection2Csv() {

  udfOn NoSuchFileOrDir $1 || return $?

  local IFS=$' \t\n'

  mawk -f ${_bashlyk_pathLib}/inisection2csv.awk -v "sTag=$2" -- $1

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
#  ERRORS
#    NoSuchFileOrDir - файл конфигурации не найден
#    MissingArgument - аргумент отсутствует
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
#    rm -f $iniChild $ini
#    udfIniGroupSection2Csv $iniChild                                           #? $_bashlyk_iErrorNoSuchFileOrDir
#    udfIniGroupSection2Csv                                                     #? $_bashlyk_iErrorEmptyOrMissingArgument
#    ## TODO тест пустой результат
#  SOURCE
udfIniGroupSection2Csv() {

  udfOn MissingArgument $1 || return $?

  local a csv fn path s sTag IFS=$' \t\n' GLOBIGNORE

  path="$_bashlyk_pathIni"

  [[ "$1" == "${1##*/}" && -f "${path}/$1" ]] || path=
  [[ "$1" == "${1##*/}" && -f "$1" ]] && path=$( exec -c pwd )
  [[ "$1" != "${1##*/}" && -f "$1" ]] && path=${1%/*}
  [[ -n "$2" ]] && sTag="$2"
  #
  if [[ ! $path ]]; then

   [[ -f "/etc/${_bashlyk_pathPrefix}/$1" ]] \
     && path="/etc/${_bashlyk_pathPrefix}" \
     || eval $( udfOnError return NoSuchFileOrDir )

  fi
  #
  a=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

  GLOBIGNORE="*:?"

  for s in $a; do

    [[ $s                 ]] || continue
    [[ $fn                ]] && fn="${s}.${fn}" || fn="$s"
    [[ -s "$path/$fn" ]] && csv+=";$( udfIniSection2Csv "$path/$fn" "$sTag" );"

  done

  unset GLOBIGNORE

  udfCsvOrder "$csv"

  return $?
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
#  ERRORS
#    MissingArgument - аргумент отсутствует или файл конфигурации не найден
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
#    rm -f $ini
#  SOURCE
udfIni2Csv() {

  udfOn NoSuchFileOrDir $1 || return $?

  local IFS=$' \t\n'

  mawk -f ${_bashlyk_pathLib}/ini2csv.awk -- $1

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
#  ERRORS
#    NoSuchFileOrDir - файл конфигурации не найден
#    MissingArgument - аргумент отсутствует или нет входных данных
#    EmptyResult     - результат отсутствует
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
#    rm -f $iniChild $ini
#    udfIniGroup2Csv $iniChild                                                  #? $_bashlyk_iErrorNoSuchFileOrDir
#    ## TODO проверка пустых данных (iErrorEmptyOrMissingArgument)
#  SOURCE
udfIniGroup2Csv() {

  udfOn MissingArgument $1 || return $?

  local a aini csvIni ini pathIni s sTag aTag csvOut fnOpt ini pathIni IFS=$' \t\n' GLOBIGNORE
  #
  #
  ## TODO встроить защиту от подстановки конфигурационного файла (по владельцу)
  #
  [[ "$1" == "${1##*/}" && -f "$(_ pathIni)/$1" ]] && pathIni=$(_ pathIni)
  [[ "$1" == "${1##*/}" && -f "$1"              ]] && pathIni=$(exec -c pwd )
  [[ "$1" != "${1##*/}" && -f "$1"              ]] && pathIni=$(dirname $1)
  #
  if [[ -z "$pathIni" ]]; then

    [[ -f "/etc/$(_ pathPrefix)/$1" ]] && pathIni="/etc/$(_ pathPrefix)"

  fi
  #
  aini=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')

  GLOBIGNORE="*:?"

  if [[ -n "$pathIni" ]]; then

    for s in $aini; do
      [[ $s                     ]] || continue
      [[ $ini                   ]] && ini="${s}.${ini}" || ini="$s"
      [[ -s "${pathIni}/${ini}" ]] && csvIni+="$(udfIni2Csv "${pathIni}/${ini}" | tr -d '\\')"

    done

  fi

  if [[ "$_bashlyk_bSetOptions" == "1" && -n "$_bashlyk_csvOptions2Ini" ]]; then

    udfMakeTemp fnOpt
    udfIniWrite $fnOpt "$_bashlyk_csvOptions2Ini"
    _bashlyk_csvOptions2Ini=''
    _bashlyk_bSetOptions=0
    csvIni+="$( udfIni2Csv $fnOpt | tr -d '\\' )"

  fi

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

  if [[ ! $csvOut ]]; then

    [[ -d "$pathIni" ]] || eval $(udfOnError return NoSuchFileOrDir '$1')
    [[ $csvIni ]]       || eval $(udfOnError return MissingArgument)

    eval $(udfOnError return EmptyResult)

  fi

  echo "$csvOut" | sed -e "s/;\+/;/g"

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
#  ERRORS
#    MissingArgument - аргумент отсутствует
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

  udfOn MissingArgument $1 || return $?

  local csv k s sClass sData sIni sRules sSection IFS=$' \t\n'

  for s in $*; do

    sSection="${s%:*}"
    sData="${s/$sSection/}"
    sClass="${s#*:}"
    sData=${sData/:/}
    sData=${sData/[=\-+\!]/}

    [[ "$sClass" == "$sData" ]] && sClass=
    csv=""

    if [[ $sClass && $sData ]]; then

      udfSetLastError InvalidArgument "$sClass"
      continue

    fi

    if [[ $sData ]]; then

      IFS=';'
      for k in $sData; do

        [[ ${!k} ]] && csv+="$k=${!k};"

      done
      IFS=$' \t\n'

    else

      [[ ${!sSection} ]] && csv+="${!sSection};"

    fi

    [[ $csv ]] || continue

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
#****f* libcsv/udfBashlykUnquote
#  SYNOPSIS
#    udfBashlykUnquote
#  DESCRIPTION
#    Преобразование метапоследовательностей _bashlyk_&#XX_ из потока со стандартного входа в символы '"[]()=;\'
#  EXAMPLE
#    local s="_bashlyk_&#34__bashlyk_&#91__bashlyk_&#93__bashlyk_&#59__bashlyk_&#40__bashlyk_&#41__bashlyk_&#61_"
#    echo $s | udfBashlykUnquote >| grep -e '\"\[\];()='                                                          #? true
#  SOURCE
udfBashlykUnquote() {

  local cmd='sed' i IFS=$' \t\n'
  local -A a=( [34]='\"' [40]='\(' [41]='\)' [59]='\;' [61]='\=' [91]='\[' [92]='\\\' [93]='\]' )

  for i in "${!a[@]}"; do

    cmd+=" -e \"s/_bashlyk_\&#${i}_/${a[$i]}/g\""

  done
  ## TODO продумать команды для удаления "_bashlyk_csv_record=" и автоматических ключей
  #cmd+=" -e \"s/\t\?_bashlyk_ini_.*_autoKey_[0-9]\+\t\?=\t\?//g\""
  cmd+=' -e "s/^\"\(.*\)\"$/\1/"'

  eval "$cmd"

}
#******
#****f* libcsv/udfPrepare2Exec
#  SYNOPSIS
#    udfPrepare2Exec - args
#  DESCRIPTION
#    Преобразование метапоследовательностей _bashlyk_&#XX_ в символы '[]()=;\'
#    со стандартного входа или строки аргументов. В последнем случае,
#    дополнительно происходит разделение полей "CSV;"-строки в отдельные
#    строки
#  INPUTS
#    args - командная строка
#       - - данные поступают со стандартного входа
#  OUTPUT
#    поток строк, пригодных для выполнения командным интерпретатором
#  EXAMPLE
#    local s1 s2
#    s1="_bashlyk_&#91__bashlyk_&#93__bashlyk_&#59__bashlyk_&#40__bashlyk_&#41__bashlyk_&#61_"
#    s2="while _bashlyk_&#91_ true _bashlyk_&#93_; do read;done"
#    echo $s1 | udfPrepare2Exec -                                                              #? true
#    udfPrepare2Exec $s1 >| grep -e '\[\];()='                                                 #? true
#    udfPrepare2Exec $s2 >| grep -e "^while \[ true \]$\|^ do read$\|^done$"                   #? true
#  SOURCE
udfPrepare2Exec() {

  local s IFS=$' \t\n'

  if [[ "$1" == "-" ]]; then

    udfBashlykUnquote

  else

    echo -e "${*//;/\\n}" | udfBashlykUnquote

  fi

  return 0

}
#******
#****f* libcsv/udfShellExec
#  SYNOPSIS
#    udfShellExec args
#  DESCRIPTION
#    Выполнение командной строки во внешнем временном файле
#    в текущей среде интерпретатора оболочки
#  INPUTS
#    args - командная строка
#  RETURN VALUE
#    MissingArgument - аргумент не задан
#    в остальных случаях код возврата командной строки с учетом доступа к временному файлу
#  EXAMPLE
#    udfShellExec 'true; false'                                                 #? false
#    udfShellExec 'false; true'                                                 #? true
#  SOURCE
udfShellExec() {

  udfOn MissingArgument $* || return $?

  local rc fn IFS=$' \t\n'

  udfMakeTemp fn
  udfPrepare2Exec "$@" > $fn
  . $fn
  rc=$?
  rm -f $fn

  return $rc

}
#******
#****f* libcsv/udfLocalVarFromCSV
#  SYNOPSIS
#    udfLocalVarFromCSV CSV1 CSV2 ...
#  DESCRIPTION
#    Prepare string from comma separated lists (ex. INI options) for definition
#    of the local variables by using eval
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    udfLocalVarFromCSV a1,b2,c3                                                #? true
#    udfLocalVarFromCSV a1 b2,c3                                                #? true
#    udfLocalVarFromCSV a1,b2 c3                                                #? true
#    echo $( udfLocalVarFromCSV a1,b2 c3,4d 2>/dev/null ) >| grep '^local'      #? false
#  SOURCE
udfLocalVarFromCSV() {

  if [[ ! $@ ]]; then

    udfOnError1 throw MissingArgument
    return $( _ iErrorMissingArgument )

  fi

  local s
  local -A h

  for s in ${*//[;,]/ }; do

    if ! udfIsValidVariable $s; then

      udfOnError1 throw InvalidVariable "$s"
      return $( _ iErrorInvalidVariable )

    fi

    h[$s]="$s"

  done

  if [[ ${h[@]} ]]; then

    echo "local ${h[@]}"

  else

    udfOnError1 throw EmptyResult
    return $( _ iErrorEmptyResult )

  fi

}
#******
#****f* libcsv/udfSerialize
#  SYNOPSIS
#    udfSerialize variables
#  DESCRIPTION
#    Generate csv string from variable list
#  INPUTS
#    variables - list of variables
#  OUTPUT
#    Show csv string
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    local sUname="$(uname -a)" sDate="" s=100
#    udfSerialize sUname sDate s >| grep "^sUname=.*s=100;$"                                                                 #? true
#  SOURCE
udfSerialize() {

  udfOn MissingArgument $1 || return $?

  local bashlyk_s_Serialize csv IFS=$' \t\n'

  for bashlyk_s_Serialize in $*; do

    udfIsValidVariable "$bashlyk_s_Serialize" \
      && csv+="${bashlyk_s_Serialize}=${!bashlyk_s_Serialize};" \
      || udfSetLastError InvalidVariable "$bashlyk_s_Serialize"

  done

  echo "$csv"

}
#******
#****f* libcsv/udfGetOptHash
#  SYNOPSIS
#    udfGetOptHash <csvopt> <args>
#  DESCRIPTION
#    Разбор строки аргументов в формате "longoptions" и
#    формирование ассоциативного массива в виде CSV строки с
#    парами "ключ=значение", разделенные символом ";"
#  INPUTS
#    csvopt - список ожидаемых опций
#    args   - опции с аргументами
#  OUTPUT
#   Ассоциативный массив в виде CSV строки
#  ERRORS
#    MissingArgument - аргумент не задан
#    InvalidArgument - неправильная опция
#    EmptyResult     - пустой результат
#  EXAMPLE
#   udfGetOptHash 'job:,force' --job main --force >| grep "^job=main;force=1;$" #? true
#   udfGetOptHash                                                               #? $_bashlyk_iErrorMissingArgument
#   udfGetOptHash 'bar:,foo' --job main --force                                 #? $_bashlyk_iErrorInvalidArgument
#  SOURCE
udfGetOptHash() {

  udfOn MissingArgument $* || return $?

  local k v csvKeys csvHash sOpt bFound IFS=$' \t\n'

  csvKeys="$1"
  shift

  sOpt="$( getopt -l $csvKeys -n $0 -- $0 $@ 2>/dev/null )" \
    || eval $( udfOnError return InvalidArgument $@ )

  eval set -- "$sOpt"

  while true; do

    [[ $1 ]] || break
    bFound=

    for k in ${csvKeys//,/ }; do

      v=${k//:/}

      [[ "--$v" == "$1" ]] && bFound=1 || continue

      if [[ "$k" =~ :$ ]]; then

       csvHash+="$v=$( udfAlias2WSpace $2 );"
       shift 2

      else

        csvHash+="$v=1;"
        shift

      fi

   done

   [[ -z "$bFound" ]] && shift

  done

  shift

  [[ $csvHash ]] && echo "$csvHash" || return $_bashlyk_iErrorEmptyResult

}
#******
#****f* libcsv/udfSetOptHash
#  SYNOPSIS
#    udfSetOptHash <arg>
#  DESCRIPTION
#    Разбор аргумента в виде CSV строки, представляющего
#    собой ассоциативный массив с парами "ключ=значение" и формирование
#    соответствующих переменных.
#  INPUTS
#    arg - CSV строка
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    local job bForce
#    udfSetOptHash "job=main;bForce=1;"                                         #? true
#    echo "$job :: $bForce" >| grep "^main :: 1$"                               #? true
#    udfSetOptHash                                                              #? $_bashlyk_iErrorMissingArgument
#    ## TODO коды возврата проверить
#  SOURCE
udfSetOptHash() {

  udfOn MissingArgument $* || return

  local _bashlyk_udfGetOptHash_confTmp IFS=$' \t\n'

  udfMakeTemp   _bashlyk_udfGetOptHash_confTmp
  udfSetConfig $_bashlyk_udfGetOptHash_confTmp "$*" || eval $(udfOnError return)
  udfGetConfig $_bashlyk_udfGetOptHash_confTmp      || eval $(udfOnError return)

  rm -f $_bashlyk_udfGetOptHash_confTmp

  return 0

}
#******
#****f* libcsv/udfGetOpt
#  SYNOPSIS
#    udfGetOpt <csvopt> <args>
#  DESCRIPTION
#    Разбор строки аргументов в формате "longoptions" и
#    формирование соответствующих опциям переменных
#    с установленными значениями.
#  INPUTS
#    csvopt - список ожидаемых опций
#    args   - опции с аргументами
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    local job bForce
#    udfGetOpt job:,bForce --job main --bForce                                  #? true
#    echo "dbg $job :: $bForce" >| grep "^dbg main :: 1$"                       #? true
#  SOURCE
udfGetOpt() {

  udfSetOptHash $( udfGetOptHash $* ) && _bashlyk_bSetOptions=1

}
#******
#****f* libcsv/udfExcludePairFromHash
#  SYNOPSIS
#    udfExcludePairFromHash <pair> <hash>
#  DESCRIPTION
#    Из второго аргумента <hash> исключаются подстроки ";<pair>;"
#    Ожидается, что второй аргумент является CSV-строкой с полями "ключ=значение"
#    и разделителем ";", а первый аргумент является одним из таких полей.
#  INPUTS
#    pair - строка в виде "ключ=значение"
#    hash - ассоциативный массив в виде CSV строки c разделителем ";"
#  OUTPUT
#    аргумент <hash> без подстрок ";<pair>;"
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    local s="job=main;bForce=1"
#    udfExcludePairFromHash 'save=1' "${s};save=1;" >| grep "^${s}$"            #? true
#  SOURCE
udfExcludePairFromHash() {

  udfOn MissingArgument $* || return $?

  local s="$1" IFS=$' \t\n'

  shift

  echo "${*//;$s;/}"

}
#******
