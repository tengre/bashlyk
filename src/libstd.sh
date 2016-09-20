#
# $Id: libstd.sh 554 2016-09-20 21:37:14+04:00 toor $
#
#****h* BASHLYK/libstd
#  DESCRIPTION
#    стандартный набор функций, включает автоматически управляемые функции
#    вывода сообщений, контроля корректности входных данных, создания временных
#    объектов и автоматического их удаления после завершения сценария или
#    фонового процесса, обработки ошибок
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libstd/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
[[ -n "$_BASHLYK_LIBSTD" ]] && return 0 || _BASHLYK_LIBSTD=1
#******
#****** libstd/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libmsg.sh ]] && . "${_bashlyk_pathLib}/libmsg.sh"
#******
#****v* libstd/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#    * $_bashlyk_sArg - аргументы командной строки вызова сценария
#    * $_bashlyk_sWSpaceAlias - заменяющая пробел последовательность символов
#    * $_bashlyk_aRequiredCmd_opt - список используемых в данном модуле внешних
#    утилит
#  SOURCE
_bashlyk_iMaxOutputLines=1000
#
: ${_bashlyk_onError:=throw}
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathDat:=/tmp}
: ${_bashlyk_sWSpaceAlias:=___}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}
: ${_bashlyk_s0:=${0##*/}}
: ${_bashlyk_sId:=${_bashlyk_s0%.sh}}
: ${_bashlyk_afoClean:=}
: ${_bashlyk_afnClean:=}
: ${_bashlyk_apathClean:=}
: ${_bashlyk_ajobClean:=}
: ${_bashlyk_apidClean:=}
: ${_bashlyk_pidLogSock:=}
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_reMetaRules:='34=":40=(:41=):59=;:91=[:92=\\:93=]:61=='}
: ${_bashlyk_envXSession:=}
: ${_bashlyk_aRequiredCmd_std:="cat chgrp chmod chown cut date echo false grep \
  hostname kill logname md5sum mkdir mktemp ps pwd rm rmdir sed sleep tempfile \
  touch true tr which xargs"}
: ${_bashlyk_aExport_std:="udfIsNumber udfBaseId udfTimeStamp udfDate          \
  udfShowVariable udfIsValidVariable udfQuoteIfNeeded udfWSpace2Alias          \
  udfAlias2WSpace udfMakeTemp udfMakeTempV udfPrepare2Exec udfShellExec        \
  udfAddFile2Clean udfAddPath2Clean udfAddJob2Clean udfAddPid2Clean            \
  udfCleanQueue udfOnTrap _ARGUMENTS _s0 _pathDat udfPrepareByType _ _getv     \
  _gete _set udfCheckCsv udfGetMd5 udfGetPathMd5 udfXml udfSerialize           \
  udfBashlykUnquote"}

#******
#****f* libstd/udfIsNumber
#  SYNOPSIS
#    udfIsNumber <number> [<tag>]
#  DESCRIPTION
#    Проверка аргумента на то, что он является натуральным числом
#    Аргумент считается числом, если он содержит цифры и может иметь в конце
#    символ - признак порядка, например, k M G T (kilo-, Mega-, Giga-, Terra-)
#  INPUTS
#    number - проверяемое значение
#    tag    - набор символов, один из которых можно применить
#             после цифр для указания признака числа, например,
#             порядка. (регистр не имеет значения)
#  RETURN VALUE
#    0                            - аргумент является натуральным числом
#    iErrorNonValidArgument       - аргумент не является натуральным числом
#    iErrorEmptyOrMissingArgument - аргумент не задан
#  EXAMPLE
#    udfIsNumber 12                                                             #? true
#    udfIsNumber 34k k                                                          #? true
#    udfIsNumber 67M kMGT                                                       #? true
#    udfIsNumber 89G G                                                          #? true
#    udfIsNumber 12,34                                                          #? $_bashlyk_iErrorNonValidArgument
#    udfIsNumber 12T                                                            #? $_bashlyk_iErrorNonValidArgument
#    udfIsNumber 1O2                                                            #? $_bashlyk_iErrorNonValidArgument
#    udfIsNumber                                                                #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
udfIsNumber() {
 [[ -n "$1" ]] || return $_bashlyk_iErrorEmptyOrMissingArgument
 local s
 [[ -n "$2" ]] && s="[$2]?"
 [[ "$1" =~ ^[0-9]+${s}$ ]] && return 0 || return $_bashlyk_iErrorNonValidArgument
}
#******
#****f* libstd/udfBaseId
#  SYNOPSIS
#    udfBaseId
#  DESCRIPTION
#    получить имя сценария без расширения .sh
#    устаревшая - заменяется "_ sId"
#  OUTPUT
#    Короткое имя запущенного сценария без расширения ".sh"
#  EXAMPLE
#    udfBaseId >| grep -w "^$(basename $0 .sh)$"                                #? true
#  SOURCE
udfBaseId() {
 _ sId
}
#******
#****f* libstd/udfTimeStamp
#  SYNOPSIS
#    udfTimeStamp <args>
#  DESCRIPTION
#    сформировать строку c заголовком в виде текущего времени в формате
#    'Jun 25 14:52:56' (LANG=C LC_TIME=C)
#  INPUTS
#    <args> - суффикс к заголовку
#  OUTPUT
#    строка с заголовком в виде "штампа времени"
#  EXAMPLE
#    local re="[a-zA-Z]+ [0-9]+ [0-9]+:[0-9]+:[[:digit:]]+ foo bar"
#    udfTimeStamp foo bar >| grep -E "$re"                                      #? true
#  SOURCE
udfTimeStamp() {
 LANG=C LC_TIME=C LC_ALL=C date "+%b %d %H:%M:%S $*"
}
#******
#****f* libstd/udfDate
#  SYNOPSIS
#    udfDate <args>
#  DESCRIPTION
#    сформировать строку c заголовком в виде текущего времени
#  INPUTS
#    <args> - суффикс к заголовку
#  OUTPUT
#    строка с заголовком в виде "штампа времени"
#  EXAMPLE
#    local re="[[:graph:]]+ [0-9]+ [0-9]+:[0-9]+:[[:digit:]]+ foo bar"
#    udfDate foo bar >| grep -E "$re"                                           #? true
#  SOURCE
udfDate() {
 date "+%b %d %H:%M:%S $*"
}
#******
#****f* libstd/udfShowVariable
#  SYNOPSIS
#    udfShowVariable args
#  DESCRIPTION
#    Вывод листинга значений аргументов, если они являются именами переменными. Допускается
#    разделять имена переменных знаками ',' и ';', однако, необходимо помнить, что знак ';'
#    (или аргументы целиком) необходимо экранировать кавычками, иначе интерпретатор воспримет
#    аргумент как следующую команду!
#    Если аргумент не является валидным именем переменной, то выводится соответствующее сообщение.
#    Функцию можно использовать для формирования строк инициализации переменных, при этом
#    информационные строки за счет экранирования командой ':' не выполняют никаких действий
#    при разборе интерпретатором, их также можно отфильтровать командой "grep -v '^:'"
#  INPUTS
#    args - ожидаются имена переменных
#  OUTPUT
#    служебные строки выводятся с начальным ':' для автоматической подавления возможности выполнения
#    Валидное имя переменной и значение в виде <Имя>=<Значение>
#  EXAMPLE
#    local s='text' b='true' i=2015 a='true 2015 text'
#    udfShowVariable "a,b; i" s  >| grep -w "a=true 2015 text\|b=true\|i=2015\|s=text"                                    #? true
#    udfShowVariable a b i s 12w >| grep '^:.*12w.* not valid'                                                            #? true                                                                             #? true
#  SOURCE
udfShowVariable() {
 local bashlyk_udfShowVariable_a bashlyk_udfShowVariable_s IFS=$'\t\n ,;'
 for bashlyk_udfShowVariable_s in $*; do
  if udfIsValidVariable $bashlyk_udfShowVariable_s; then
   bashlyk_udfShowVariable_a+="\t${bashlyk_udfShowVariable_s}=${!bashlyk_udfShowVariable_s}\n"
  else
   bashlyk_udfShowVariable_a+=": Variable name \"${bashlyk_udfShowVariable_s}\" is not valid!\n"
  fi
 done
 echo -e ": Variable listing>\n${bashlyk_udfShowVariable_a}"
 return 0
}
#******
#****f* libstd/udfIsValidVariable
#  SYNOPSIS
#    udfIsValidVariable <arg>
#  DESCRIPTION
#    Проверка аргумента на то, что он может быть валидным идентификатором
#    переменной
#  INPUTS
#    arg - проверяемое значение
#  RETURN VALUE
#    0                            - аргумент валидный идентификатор
#    iErrorNonValidVariable       - аргумент невалидный идентификатор (или не задан)
#  EXAMPLE
#    udfIsValidVariable                                                         #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable "12w"                                                   #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable "a"                                                     #? true
#    udfIsValidVariable "k1"                                                    #? true
#    udfIsValidVariable "&w1"                                                   #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable "#k12s"                                                 #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable ":v1"                                                   #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable ";q1"                                                   #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable ",g99"                                                  #? $_bashlyk_iErrorNonValidVariable
#  SOURCE
udfIsValidVariable() {
 local IFS=$' \t\n'
 [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]] && return 0 || eval $(udfOnError return iErrorNonValidVariable '${1}')
}
#******
#****f* libstd/udfQuoteIfNeeded
#  SYNOPSIS
#    udfQuoteIfNeeded <arg>
#  DESCRIPTION
#   Аргумент, содержащий пробел(ы) отмечается кавычками
#  INPUTS
#    arg - argument
#  OUTPUT
#    аргумент с кавычками, если есть пробелы
#  EXAMPLE
#    udfQuoteIfNeeded "word" >| grep '^word$'                                   #? true
#    udfQuoteIfNeeded two words >| grep '^".*"$'                                #? true
#  SOURCE
udfQuoteIfNeeded() {
 [[ "$*" =~ [[:space:]] ]] &&  echo "\"$*\"" || echo "$*"
}
#******
#****f* libstd/udfWSpace2Alias
#  SYNOPSIS
#    udfWSpace2Alias -|<arg>
#  DESCRIPTION
#   Пробел в аргументе заменяется "магической" последовательностью символов,
#   определённых в глобальной переменной $_bashlyk_sWSpaceAlias
#  INPUTS
#    arg - argument
#    "-" - ожидается ввод в конвейере
#  OUTPUT
#   Аргумент с заменой пробелов на специальную последовательность символов
#  EXAMPLE
#    udfWSpace2Alias 'a b  cd' >| grep  '^a___b______cd$'                       #? true
#    echo 'a b  cd' | udfWSpace2Alias - >| grep '^a___b______cd$'               #? true
#  SOURCE
udfWSpace2Alias() {
 case "$1" in
 -) sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
 *) echo "$*" | sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
 esac
}
#******
#****f* libstd/udfAlias2WSpace
#  SYNOPSIS
#    udfAlias2WSpace -|<arg>
#  DESCRIPTION
#    Последовательность символов, определённых в глобальной переменной
#    $_bashlyk_sWSpaceAlias заменяется на пробел в заданном аргументе.
#    Причём, если появляются пробелы, то вывод обрамляется кавычками.
#    В случае ввода в конвейере вывод не обрамляется кавычками
#  INPUTS
#    arg - argument
#  OUTPUT
#    Аргумент с заменой специальной последовательности символов на пробел
#  EXAMPLE
#    udfAlias2WSpace a___b______cd >| grep '^"a b  cd"$'                        #? true
#    echo a___b______cd | udfAlias2WSpace - >| grep '^a b  cd$'                 #? true
#  SOURCE
udfAlias2WSpace() {
 case "$1" in
 -) sed -e "s/$_bashlyk_sWSpaceAlias/ /g";;
 *) udfQuoteIfNeeded "$(echo "$*" | sed -e "s/$_bashlyk_sWSpaceAlias/ /g")";;
 esac
}
#******
#****f* libstd/udfMakeTemp
#  SYNOPSIS
#    udfMakeTemp [varname] options...
#  DESCRIPTION
#    Создание временного файла или каталога
#  INPUTS
#    varname=[<varid>] - идентификатор переменной для возврата результата, если
#                        аргумент не именной, то должен быть всегда первый
#    path=<path>       - каталог, в котором будут создаваться временные объекты
#    prefix=<prefix>   - префикс имени временного объекта
#    suffix=<suffix>   - суффикс имени временного объекта
#    mode=<mode>       - права на временный объект
#    owner=<owner>     - владелец временного объекта
#    group=<group>     - группа временного объекта
#    type=file|dir     - тип объекта: файл (по умолчанию) или каталог
#    keep=true|false   - удалять/не удалять временные объекты после завершения
#                        сценария. По умолчанию, удаляется, если имя временного
#                        объекта передается аргументу-переменной, если оно
#                        выдается на stdout, то не удаляется
#  OUTPUT
#    вывод происходит если нет аргументов или отсутствует именной аргумент
#    varname, если временный объект не создан, то ничего не выдается
#
#  RETURN VALUE
#    0                        - выполнено успешно
#    iErrorNotExistNotCreated - временный объект файловой системы не создан
#    iErrorNonValidVariable   - аргумент <varname> не является валидным
#                               идентификатором переменной
#
#  EXAMPLE
#    local foTemp
#    udfMakeTemp foTemp path=$HOME prefix=pre. suffix=.suf
#    ls $foTemp >| grep -w "$HOME/pre\.........\.suf"                           #? true
#    udfMakeTemp foTemp type=dir mode=0751
#    ls -ld $foTemp >| grep "^drwxr-x--x.*${foTemp}$"                           #? true
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.suf)
#    ls $foTemp >| grep "pre\.........\.suf$"                                   #? true
#    rm -f $foTemp
#    $(udfMakeTemp foTemp prefix=pre. suffix=.suf)
#    test -f $foTemp                                                            #? false
#    unset foTemp
#    foTemp=$(udfMakeTemp)                                                      #? true
#    test -f $foTemp                                                            #? true
#    rm -f $foTemp
#    udfMakeTemp 2t                                                             #? ${_bashlyk_iErrorNonValidVariable}
#    udfMakeTemp path=/proc                                                     #? ${_bashlyk_iErrorNotExistNotCreated}
#  SOURCE
udfMakeTemp() {
 local bashlyk_foResult_ioAUaE5R bashlyk_optDir_ioAUaE5R bashlyk_s_ioAUaE5R
 local bashlyk_bNoKeep_ioAUaE5R bashlyk_sVar_ioAUaE5R bashlyk_sGroup_ioAUaE5R
 local bashlyk_sCreateMode_ioAUaE5R bashlyk_path_ioAUaE5R bashlyk_sUser_ioAUaE5R
 local bashlyk_sPrefix_ioAUaE5R bashlyk_sSuffix_ioAUaE5R bashlyk_rc_ioAUaE5R
 local bashlyk_octMode_ioAUaE5R IFS=$' \t\n'
 #
 bashlyk_bNoKeep_ioAUaE5R=true
 bashlyk_sCreateMode_ioAUaE5R=direct
 #
 for bashlyk_s_ioAUaE5R in $*; do
  case "$bashlyk_s_ioAUaE5R" in
     path=*) bashlyk_path_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
   prefix=*) bashlyk_sPrefix_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
   suffix=*) bashlyk_sSuffix_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
     mode=*) bashlyk_octMode_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
    type=d*) bashlyk_optDir_ioAUaE5R='-d';;
    type=f*) bashlyk_optDir_ioAUaE5R='';;
     user=*) bashlyk_sUser_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
    group=*) bashlyk_sGroup_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
    keep=t*) bashlyk_bNoKeep_ioAUaE5R=false;;
    keep=f*) bashlyk_bNoKeep_ioAUaE5R=true;;
  varname=*) bashlyk_sVar_ioAUaE5R=${bashlyk_s_ioAUaE5R#*=};;
          *)
            bashlyk_sVar_ioAUaE5R="$1"
            udfIsNumber "$2"
            bashlyk_rc_ioAUaE5R=$?
            if [[ -z "$3" && -n "$2" && $bashlyk_rc_ioAUaE5R -eq 0 ]]; then
             # oldstyle
             bashlyk_octMode_ioAUaE5R="$2"
             bashlyk_sVar_ioAUaE5R=''
             bashlyk_sPrefix_ioAUaE5R="$1"
            fi
          ;;
  esac
 done

 if [[ -n "$bashlyk_sVar_ioAUaE5R" ]]; then
  udfIsValidVariable "$bashlyk_sVar_ioAUaE5R" || eval $(udfOnError return $? $bashlyk_sVar_ioAUaE5R)
 else
  bashlyk_bNoKeep_ioAUaE5R=false
 fi

 if [[ -f "$(which mktemp)" ]]; then
  bashlyk_sCreateMode_ioAUaE5R=mktemp
 elif [[ -f "$(which tempfile)" ]]; then
  [[ -z "$bashlyk_optDir_ioAUaE5R" ]] \
   && bashlyk_sCreateMode_ioAUaE5R=tempfile \
   || bashlyk_sCreateMode_ioAUaE5R=direct
 fi

 case "$bashlyk_sCreateMode_ioAUaE5R" in
    direct)
   [[ -n "$bashlyk_path_ioAUaE5R" ]] \
    && bashlyk_s_ioAUaE5R="${bashlyk_path_ioAUaE5R}/" \
    || bashlyk_s_ioAUaE5R="/tmp/"
   bashlyk_s_ioAUaE5R+="${bashlyk_sPrefix_ioAUaE5R}${$}${bashlyk_sSuffix_ioAUaE5R}"
   [[ -n "$bashlyk_optDir_ioAUaE5R" ]] \
    && mkdir -p $bashlyk_s_ioAUaE5R \
    || touch $bashlyk_s_ioAUaE5R
   [[ -n "$bashlyk_octMode_ioAUaE5R" ]] \
    && chmod $bashlyk_octMode_ioAUaE5R $bashlyk_s_ioAUaE5R
  ;;
    mktemp)
   if [[ -n "$bashlyk_path_ioAUaE5R" ]]; then
    mkdir -p ${bashlyk_path_ioAUaE5R}
    bashlyk_path_ioAUaE5R="--tmpdir=${bashlyk_path_ioAUaE5R}"
   else
    bashlyk_path_ioAUaE5R="--tmpdir=/tmp"
   fi
   if [[ -n "$bashlyk_sPrefix_ioAUaE5R" ]]; then
    bashlyk_sPrefix_ioAUaE5R=$(echo $bashlyk_sPrefix_ioAUaE5R | tr -d '/')
   fi
   if [[ -n "${bashlyk_sSuffix_ioAUaE5R}" ]]; then
    bashlyk_sSuffix_ioAUaE5R="--suffix=$(echo ${bashlyk_sSuffix_ioAUaE5R} | tr -d '/')"
   fi
   bashlyk_s_ioAUaE5R=$(mktemp $bashlyk_path_ioAUaE5R $bashlyk_optDir_ioAUaE5R \
    ${bashlyk_sSuffix_ioAUaE5R} "${bashlyk_sPrefix_ioAUaE5R}XXXXXXXX")

   [[ -n "$bashlyk_octMode_ioAUaE5R" ]] \
    && chmod $bashlyk_octMode_ioAUaE5R $bashlyk_s_ioAUaE5R
  ;;
  tempfile)
   [[ -n "$bashlyk_sPrefix_ioAUaE5R" ]] \
    && bashlyk_sPrefix_ioAUaE5R="-p $bashlyk_sPrefix_ioAUaE5R"
   [[ -n "$bashlyk_sSuffix_ioAUaE5R" ]] \
    && bashlyk_sSuffix_ioAUaE5R="-s $bashlyk_sSuffix_ioAUaE5R"
   bashlyk_s_ioAUaE5R=$(tempfile $bashlyk_optDir_ioAUaE5R \
    $bashlyk_sPrefix_ioAUaE5R $bashlyk_sSuffix_ioAUaE5R)
  ;;
  *)
    ## не достижимое состояние
    eval $(udfOnError return iErrorUnexpected $bashlyk_sCreateMode_ioAUaE5R)
  ;;
 esac
 ## TODO обработка ошибок
 [[ -n "$bashlyk_sUser_ioAUaE5R"  ]] \
  && chown $bashlyk_sUser_ioAUaE5R  $bashlyk_s_ioAUaE5R
 [[ -n "$bashlyk_sGroup_ioAUaE5R" ]] \
  && chgrp $bashlyk_sGroup_ioAUaE5R $bashlyk_s_ioAUaE5R

 if   [[ -f "$bashlyk_s_ioAUaE5R" ]]; then
  $bashlyk_bNoKeep_ioAUaE5R && udfAddFile2Clean $bashlyk_s_ioAUaE5R
 elif [[ -d "$bashlyk_s_ioAUaE5R" ]]; then
  $bashlyk_bNoKeep_ioAUaE5R && udfAddPath2Clean $bashlyk_s_ioAUaE5R
 else
  eval $(udfOnError return iErrorNotExistNotCreated $bashlyk_s_ioAUaE5R)
 fi

 bashlyk_foResult_ioAUaE5R=$bashlyk_s_ioAUaE5R
 if [[ -n "$bashlyk_sVar_ioAUaE5R" ]]; then
  eval 'export ${bashlyk_sVar_ioAUaE5R}=${bashlyk_foResult_ioAUaE5R}'
 else
  echo ${bashlyk_foResult_ioAUaE5R}
 fi
 return 0
}
#******
#****f* libstd/udfMakeTempV
#  SYNOPSIS
#    udfMakeTempV <var> [file|dir|keep|keepf[ile*]|keepd[ir]] [<prefix>]
#  DESCRIPTION
#    Создание временного файла или каталога с автоматическим удалением
#    по завершению сценария
#    устаревшая - заменяется udfMakeTemp
#  INPUTS
#    var        - переменная (без $) для имени временного объекта
#    file       - создавать файл (по умолчанию)
#    dir        - создавать каталог
#    keep[file] - не включать автоматическое удаление временного файла
#    keepdir    - не включать автоматическое удаление временного каталога
#    prefix     - префикс имени временного файла
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNonValidVariable       - ошибка идентификатора для временного объекта
#    0                            - Выполнено успешно
#  EXAMPLE
#    local foTemp
#    udfMakeTempV foTemp file testfile                                          #? true
#    ls $foTemp >| grep "testfile"                                              #? true
#    udfMakeTempV foTemp dir                                                    #? true
#    ls -ld $foTemp >| grep "^drwx------.*${foTemp}$"                           #? true
#    echo $(udfMakeTempV foTemp)
#    test -f $foTemp                                                            #? false
#  SOURCE
udfMakeTempV() {
 local sKeep sType sPrefix IFS=$' \t\n'
 #
 [[ -n "$1" ]] || eval $(udfOnError throw iErrorEmptyOrMissingArgument "$1")
 udfIsValidVariable "$1" || eval $(udfOnError throw iErrorNonValidVariable "$1")
 #
 [[ -n "$3" ]] && sPrefix="prefix=$3"
 case "$2" in
          dir) sType="type=dir" ; sKeep="keep=false" ;;
         file) sType="type=file"; sKeep="keep=false" ;;
  keep|keepf*) sType="type=file"; sKeep="keep=true"  ;;
       keepd*) sType="type=dir" ; sKeep="keep=true"  ;;
           '') sType="type=file"; sKeep="keep=false" ;;
            *) sPrefix="prefix=$2"                   ;;
 esac
 udfMakeTemp $1 $sType $sKeep $sPrefix
}
#******
#****f* libstd/udfPrepare2Exec
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
#****f* libstd/udfShellExec
#  SYNOPSIS
#    udfShellExec args
#  DESCRIPTION
#    Выполнение командной строки во внешнем временном файле
#    в текущей среде интерпретатора оболочки
#  INPUTS
#    args - командная строка
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    в остальных случаях код возврата командной строки с учетом доступа к временному файлу
#  EXAMPLE
#    udfShellExec 'true; false'                                                 #? false
#    udfShellExec 'false; true'                                                 #? true
#  SOURCE
udfShellExec() {
 local rc fn IFS=$' \t\n'
 [[ -n "$*" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfMakeTemp fn
 udfPrepare2Exec $* > $fn
 . $fn
 rc=$?
 rm -f $fn
 return $rc
}
#******
#****f* libstd/udfAddFile2Clean
#  SYNOPSIS
#    udfAddFile2Clean args
#  DESCRIPTION
#    Добавляет имена файлов к списку удаляемых при завершении сценария
#    Предназначен для удаления временных файлов.
#  INPUTS
#    args - имена файлов
#  EXAMPLE
#    local fnTemp rc
#    udfMakeTemp fnTemp keep=true
#    test -f $fnTemp                                                            #? true
#    echo $(udfAddFile2Clean $fnTemp)
#    test -f $fnTemp                                                            #? false
#    udfMakeTemp rc keep=false
#    echo $(udfMakeTemp rc suffix=.debug)
#    test -f $rc                                                                #? true
#  SOURCE
udfAddFile2Clean() {
 [[ -n "$1" ]] || return 0
 _bashlyk_afnClean[$BASHPID]+=" $*"
 trap "udfOnTrap" 1 2 5 9 15 EXIT
}
#******
#****f* libstd/udfAddPath2Clean
#  SYNOPSIS
#    udfAddPath2Clean args
#  DESCRIPTION
#    Добавляет имена каталогов к списку удаляемых при завершении сценария.
#    Предназначен для удаления временных каталогов (если они пустые).
#  INPUTS
#    args - имена каталогов
#  EXAMPLE
#    local pathTemp rc
#    udfMakeTemp pathTemp keep=true type=dir
#    test -d $pathTemp                                                          #? true
#    echo $(udfAddPath2Clean $pathTemp)
#    test -d $pathTemp                                                          #? false
#    udfMakeTemp rc keep=false type=dir
#    echo $(udfMakeTemp rc suffix=.debug type=dir)
#    test -d $rc                                                                #? true
#    ls -ld $rc
#  SOURCE
udfAddPath2Clean() {
 [[ -n "$1" ]] || return 0
 _bashlyk_apathClean[$BASHPID]+=" $*"
 trap "udfOnTrap" 1 2 5 9 15 EXIT
}
#******
#****f* libstd/udfAddJob2Clean
#  SYNOPSIS
#    udfAddJob2Clean args
#  NOTES
#    deprecated
#  DESCRIPTION
#    функция удалена, осталась только заглушка
#  SOURCE
udfAddJob2Clean() {
 return 0
}
#******
#****f* libstd/udfAddPid2Clean
#  SYNOPSIS
#    udfAddPid2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных процессов к списку очистки при
#    завершении текущего процесса.
#  INPUTS
#    args - идентификаторы процессов
#  EXAMPLE
#    sleep 99 &
#    udfAddPid2Clean $!
#    test "${_bashlyk_apidClean[$BASHPID]}" -eq "$!"                                    #? true
#    ps -p $! -o pid= >| grep -w $!                                                     #? true
#    echo $(udfAddPid2Clean $!; echo "$BASHPID : $! : ${_bashlyk_apidClean[$BASHPID]}")
#    ps -p $! -o pid= >| grep -w $!                                                     #? false
#
#  SOURCE
udfAddPid2Clean() {
 [[ -n "$1" ]] || return 0
 _bashlyk_apidClean[$BASHPID]+=" $*"
 trap "udfOnTrap" 1 2 5 9 15 EXIT
}
#******
#****f* libstd/udfCleanQueue
#  SYNOPSIS
#    udfCleanQueue args
#  DESCRIPTION
#    Псевдоним для udfAddFile2Clean. (Устаревшее)
#  INPUTS
#    args - имена файлов
#  SOURCE
udfCleanQueue() {
 udfAddFile2Clean $*
}
#******
#****f* libstd/udfAddFObj2Clean
#  SYNOPSIS
#    udfAddFObj2Clean args
#  DESCRIPTION
#    list file system objects
#  INPUTS
#    args - files or directories for cleaning on exit
#  SOURCE
udfAddFObj2Clean() {

	udfOn MissingArgument return $*

	_bashlyk_afoClean[$BASHPID]+=" $*"

	 trap "udfOnTrap" 1 2 5 9 15 EXIT

}
#******

#****f* libstd/udfOnTrap
#  SYNOPSIS
#    udfOnTrap
#  DESCRIPTION
#    Процедура очистки при завершении вызвавшего сценария.
#    Предназначен только для вызова командой trap.
#    * Производится удаление файлов и пустых каталогов; заданий и процессов,
#    указанных в соответствующих глобальных переменных.
#    Все процессы должны быть родственны и потомками процесса рабочего сценария
#    * Закрывается сокет журнала сценария, если он использовался.
#  EXAMPLE
#    local fnTemp pathTemp pid
#    udfMakeTemp fnTemp
#    udfMakeTemp pathTemp type=dir
#    (sleep 1024)&
#    pid=$!
#    udfAddPid2Clean $pid
#    udfAddFile2Clean $fnTemp
#    udfAddPath2Clean $pathTemp
#    udfOnTrap
#    test -f $fnTemp                                                            #? false
#    test -d $pathTemp                                                          #? false
#    ps -p $pid -o pid= >| grep -w $pid                                         #? false
#  SOURCE
udfOnTrap() {
 local i s IFS=$' \t\n'
 #
 for s in ${_bashlyk_apidClean[$BASHPID]}; do
  for i in 15 9; do
   [[ -n "$(ps -o pid= --ppid $$ | xargs | grep -w $s)" ]] && {
    kill -${i} $s 2>/dev/null
    sleep 0.2
   }
  done
 done
 #
	for s in ${_bashlyk_afoClean[$BASHPID]}; do

		[[ -f $s ]] && rm -f $s && continue
		[[ -p $s ]] && rm -f $s && continue
		[[ -d $s ]] && rmdir --ignore-fail-on-non-empty $s 2>/dev/null && continue

	done

 #
 if (( ${#_bashlyk_afnClean[$BASHPID]} > 0 )); then
  rm -f ${_bashlyk_afnClean[$BASHPID]}
  unset _bashlyk_afnClean[$BASHPID]
 fi
 #
 if (( ${#_bashlyk_apathClean[$BASHPID]} > 0 )); then
  rmdir --ignore-fail-on-non-empty ${_bashlyk_apathClean[$BASHPID]} 2>/dev/null
  unset _bashlyk_apathClean[$BASHPID]
 fi
 #
 [[ -n "${_bashlyk_pidLogSock}" ]] && {
  exec >/dev/null 2>&1
  wait ${_bashlyk_pidLogSock}
 }
}
#******
#****f* libstd/_ARGUMENTS
#  SYNOPSIS
#    _ARGUMENTS [args]
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_sArg -
#    командная строка сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  INPUTS
#    args - новая командная строка
#  OUTPUT
#    Вывод значения переменной $_bashlyk_sArg
#  EXAMPLE
#    local ARGUMENTS=$(_ARGUMENTS)
#    _ARGUMENTS >| grep "^${_bashlyk_sArg}$"                                    #? true
#    _ARGUMENTS "test"
#    _ARGUMENTS >| grep -w "^test$"                                             #? true
#    _ARGUMENTS $ARGUMENTS
#  SOURCE
_ARGUMENTS() {
 [[ -n "$1" ]] && _bashlyk_sArg="$*" || echo ${_bashlyk_sArg}
}
#******
#****f* libstd/_s0
#  SYNOPSIS
#    _s0
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_s0 -
#    короткое имя сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  OUTPUT
#    Вывод значения переменной $_bashlyk_s0
#  EXAMPLE
#    local s0=$(_s0)
#    _s0 >| grep -w "^${_bashlyk_s0}$"                                          #? true
#    _s0 "test"
#    _s0 >| grep -w "^test$"                                                    #? true
#    _s0 $s0
#  SOURCE
_s0() {
 [[ -n "$1" ]] && _bashlyk_s0="$*" || echo ${_bashlyk_s0}
}
#******
#****f* libstd/_pathDat
#  SYNOPSIS
#    _pathDat
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_pathDat -
#    полное имя каталога данных сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  OUTPUT
#    Вывод значения переменной $_bashlyk_pathDat
#  EXAMPLE
#    local pathDat=$(_pathDat)
#    _pathDat >| grep -w "^${_bashlyk_pathDat}$"                                #? true
#    _pathDat "/tmp/testdat.$$"
#    _pathDat >| grep -w "^/tmp/testdat.${$}$"                                  #? true
#    rmdir $(_pathDat)                                                          #? true
#    _pathDat $pathDat
#  SOURCE
_pathDat() {
 if [[ -n "$1" ]]; then
  _bashlyk_pathDat="$*"
  mkdir -p $_bashlyk_pathDat
 else
  echo ${_bashlyk_pathDat}
 fi
}
#******
#****f* libstd/udfPrepareByType
#  SYNOPSIS
#    udfPrepareByType <arg>
#  DESCRIPTION
#    present argument 'Array[item]' as '{Array[item]}'
#  INPUTS
#    <arg> - valid name of variable or valid name item of array
#  OUTPUT
#    converted input string, if necessary
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNonValidVariable       - не валидный идентификатор
#    0                            - успешная операция
#  EXAMPLE
#    _bashlyk_onError=return
#    udfPrepareByType                                                           #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfPrepareByType 12a                                                       #? $_bashlyk_iErrorNonValidVariable
#    udfPrepareByType 12a[te]                                                   #? $_bashlyk_iErrorNonValidVariable
## TODO - do not worked    udfPrepareByType a12[]                               #? $_bashlyk_iErrorNonValidVariable
#    udfPrepareByType _a >| grep '^_a$'                                         #? true
#    udfPrepareByType _a[1234] >| grep '^\{_a\[1234\]\}$'                       #? true
#  SOURCE
udfPrepareByType() {

	[[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)

	[[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*(\[.*\])?$ ]] || eval $( udfOnError return iErrorNonValidVariable '$1' )

	[[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*\[.*\]$ ]] && echo "{$1}" || echo "$1"

}
#******
#****f* libstd/_
#  SYNOPSIS
#    _ [[<get>]=]<subname> [<value>]
#  DESCRIPTION
#    Получить или установить (get/set) значение глобальной переменной
#    $_bashlyk_<subname>
#  INPUTS
#    <get>     - переменная для приема значения (get) ${_bashlyk_<subname>},
#                может быть опущена (знак "=" не опускается), в этом случае
#                предполагается, что она имеет имя <subname>
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#    <value>   - новое значение (set) для ${_bashlyk_<subname>}. Имеет приоритет
#                перед режимом "get"
#    Важно! Если используется переменная в качестве <value>, то она обязательно
#    должна быть в двойных кавычках, иначе в случае принятия пустого значения
#    смысл операции поменяется с "set" на "get" c выводом значения на STDOUT
#  OUTPUT
#    Вывод значения переменной $_bashlyk_<subname> в режиме get, если не указана
#    приемная переменная и нет знака "="
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNonValidVariable       - не валидный идентификатор
#    0                            - успешная операция
#  EXAMPLE
#    local sS sWSpaceAlias pid=$BASHPID
#    _ sS=sWSpaceAlias
#    echo "$sS" >| grep "^${_bashlyk_sWSpaceAlias}$"                            #? true
#    _ =sWSpaceAlias
#    echo "$sWSpaceAlias" >| grep "^${_bashlyk_sWSpaceAlias}$"                  #? true
#    _ sWSpaceAlias >| grep "^${_bashlyk_sWSpaceAlias}$"                        #? true
#    _ sWSpaceAlias _-_
#    _ sWSpaceAlias >| grep "^_-_$"                                             #? true
#    _ sWSpaceAlias ""
#    _ sWSpaceAlias >| grep "^$"                                                #? true
#    _ sWSpaceAlias "two words"
#    _ sWSpaceAlias >| grep "^two words$"                                       #? true
#    _ sWSpaceAlias "$sWSpaceAlias"
#    _ sWSpaceAlias
#    _ sLastError[$pid] "_ sLastError settings test"                            #? true
#    _ sLastError[$pid] >| grep "^_ sLastError settings test$"                  #? true
#  SOURCE
_(){

	local IFS=$' \t\n' k v

	[[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)

	if (( $# > 1 )); then

		eval "_bashlyk_${1##*=}=\"$2\""

	else

		case "$1" in

		*=*)
			k=${1%=*}
			v=${1##*=}
			[[ -n "$k" ]] || k="$( udfPrepareByType "$v" )"
			udfIsValidVariable $k || eval $(udfOnError return $? $k)
			v="$( udfPrepareByType "_bashlyk_${v}" )"
			eval "export $k=\$${v}"
        ;;

		*)
			k="$( udfPrepareByType "_bashlyk_${1}" )"
			eval "echo \$${k}"
		;;
  esac
 fi
 return 0
}
#******
#****f* libstd/_getv
#  SYNOPSIS
#    _getv <subname> [<get>]
#  DESCRIPTION
#    Получить (get) значение глобальной переменной $_bashlyk_<subname> в
#    (локальную) переменную
#  INPUTS
#    <get>     - переменная для приема значения (get) ${_bashlyk_<subname>},
#                может быть опущена, в этом случае приемником становится
#                переменная <subname>
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNonValidVariable       - не валидный идентификатор
#    0                            - успешная операция
#  EXAMPLE
#    local sS sWSpaceAlias
#    _getv sWSpaceAlias sS
#    echo "$sS" >| grep "^${_bashlyk_sWSpaceAlias}$"                            #? true
#    _getv sWSpaceAlias
#    echo "$sWSpaceAlias" >| grep "^${_bashlyk_sWSpaceAlias}$"                  #? true
#  SOURCE
_getv() {
 local IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 if [[ -n "$2" ]]; then
  udfIsValidVariable $2 || return $?
  eval "export $2="'$_bashlyk_'"${1}"
 else
  udfIsValidVariable "$1" || return $?
  eval "export $1="'$_bashlyk_'"${1}"
 fi
 return 0
}
#******
#****f* libstd/_gete
#  SYNOPSIS
#    _gete <subname>
#  DESCRIPTION
#    Вывести значение глобальной переменной $_bashlyk_<subname>
#  INPUTS
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    _gete sWSpaceAlias >| grep "^${_bashlyk_sWSpaceAlias}$"                    #? true
#  SOURCE
_gete() {
 local IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 eval "echo "'$_bashlyk_'"${1}"
}
#******
#****f* libstd/_set
#  SYNOPSIS
#    _set <subname> [<value>]
#  DESCRIPTION
#    установить (set) значение глобальной переменной $_bashlyk_<subname>
#  INPUTS
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#    <value>   - новое значение, в случае отсутствия - пустая строка
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    local sWSpaceAlias=$(_ sWSpaceAlias)
#    _set sWSpaceAlias _-_
#    _ sWSpaceAlias >| grep "^_-_$"                                             #? true
#    _set sWSpaceAlias $sWSpaceAlias
#  SOURCE
_set() {
 local IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 eval "_bashlyk_$1=$2"
}
#******
#****f* libstd/udfCheckCsv
#  SYNOPSIS
#    udfCheckCsv "<csv;>" [<varname>]
#  DESCRIPTION
#    Нормализация CSV-строки <csv;>. Приведение к виду "ключ=значение" полей.
#    В случае если поле не содержит ключа или ключ содержит пробел, то к полю
#    добавляется ключ вида _bashlyk_unnamed_key_<инкремент>, всё содержимое поля
#    становится значением.
#    Результат выводится в стандартный вывод или в переменную, если имеется
#    второй аргумент функции <varname>
#  INPUTS
#    csv;    - CSV-строка, разделённая ";"
#    varname - идентификатор переменной (без "$ "). При его наличии результат
#              будет помещен в соответствующую переменную. При отсутствии такого
#              идентификатора результат будет выдан на стандартный вывод
#    Важно! Экранировать аргументы двойными кавычками, если есть вероятность
#    наличия в них пробелов
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся
#              данные в формате "<key>=<value>;..."
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNonValidVariable       - не валидный идентификатор
#    0                            - успешная операция
#  EXAMPLE
#    local s="a=b;a=c;s=a b c d e f;test value" r
#    local csv='^a=b;a=c;s="a b c d e f";_bashlyk_unnamed_key_0="test value";$'
#    udfCheckCsv "$s" >| grep "$csv"                                            #? true
#    udfCheckCsv "$s" r                                                         #? true
#    echo $r >| grep "$csv"                                                     #? true
#    udfCheckCsv "$s" 2r                                                        #? ${_bashlyk_iErrorNonValidVariable}
#    udfCheckCsv                                                                #? ${_bashlyk_iErrorEmptyOrMissingArgument}
#  SOURCE
udfCheckCsv() {
 local IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 local bashlyk_s_Q1eiphgO bashlyk_k_Q1eiphgO bashlyk_v_Q1eiphgO bashlyk_i_Q1eiphgO bashlyk_csvResult_Q1eiphgO
 #
 IFS=';'
 bashlyk_i_Q1eiphgO=0
 bashlyk_csvResult_Q1eiphgO=''
 #
 for bashlyk_s_Q1eiphgO in $1; do
  bashlyk_s_Q1eiphgO=$(echo $bashlyk_s_Q1eiphgO | tr -d "'" | tr -d '"' | sed -e "s/^\[.*\];//")
  bashlyk_k_Q1eiphgO="$(echo ${bashlyk_s_Q1eiphgO%%=*}|xargs)"
  bashlyk_v_Q1eiphgO="$(echo ${bashlyk_s_Q1eiphgO#*=}|xargs)"
  [[ -n "$bashlyk_k_Q1eiphgO" ]] || continue
  if [[ "$bashlyk_k_Q1eiphgO" == "$bashlyk_v_Q1eiphgO" || -n "$(echo "$bashlyk_k_Q1eiphgO" | grep '.*[[:space:]+].*')" ]]; then
   bashlyk_k_Q1eiphgO=${_bashlyk_sUnnamedKeyword}${bashlyk_i_Q1eiphgO}
   bashlyk_i_Q1eiphgO=$((bashlyk_i_Q1eiphgO+1))
  fi
  IFS=' ' bashlyk_csvResult_Q1eiphgO+="$bashlyk_k_Q1eiphgO=$(udfQuoteIfNeeded $bashlyk_v_Q1eiphgO);"
 done
 IFS=$' \t\n'
 if [[ -n "$2" ]]; then
  udfIsValidVariable "$2" || eval $(udfOnError return iErrorNonValidVariable '$2')
  eval 'export ${2}="${bashlyk_csvResult_Q1eiphgO}"'
 else
  echo "$bashlyk_csvResult_Q1eiphgO"
 fi
 return 0
}
#******
#****f* libstd/udfGetMd5
#  SYNOPSIS
#    udfGetMd5 [-]|--file <filename>|<args>
#  DESCRIPTION
#   Получить дайджест MD5 указанных данных
#  INPUTS
#    "-"  - использовать поток данных "input"
#    --file <filename> - использовать в качестве данных указанный файл
#    <args> - использовать строку аргументов
#  OUTPUT
#    Дайджест MD5
#  EXAMPLE
#    udfGetMd5 "test" >| grep -w 'd8e8fca2dc0f896fd7cb4cb0031ba249'             #? true
#  SOURCE
udfGetMd5() {
 {
  case "$1" in
       "-")
          cat | md5sum
         ;;
  "--file")
          [[ -f "$2" ]] && md5sum "$2"
         ;;
         *)
          [[ -n "$1" ]] && echo "$*" | md5sum
         ;;
  esac
 } | cut -f 1 -d ' '
 return 0
}
#******
#****f* libstd/udfGetPathMd5
#  SYNOPSIS
#    udfGetPathMd5 <path>
#  DESCRIPTION
#   Получить дайджест MD5 всех нескрытых файлов в каталоге <path>
#  INPUTS
#    <path>  - начальный каталог
#  OUTPUT
#    Список MD5-сумм и имён нескрытых файлов в каталоге <path> рекурсивно
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNoSuchFileOrDir        - путь не доступен
#    iErrorNotPermitted           - нет прав
#    0                            - успешная операция
#  EXAMPLE
#    local path=$(udfMakeTemp type=dir)
#    touch ${path}/testfile
#    udfAddFile2Clean ${path}/testfile
#    udfAddPath2Clean ${path}
#    udfGetPathMd5 $path >| grep '^d41.*27e.*testfile'                   #? true
#    udfGetPathMd5                                                       #? ${_bashlyk_iErrorNoSuchFileOrDir}
#    ## TODO udfGetPathMd5 /root                                          #? ${_bashlyk_iErrorNotPermitted}
#  SOURCE
udfGetPathMd5() {
 local pathSrc="$(pwd)" pathDst s IFS=$' \t\n'
 [[ -n "$1" && -d "$1" ]] || eval $(udfOnError return iErrorNoSuchFileOrDir)
 cd "$1" 2>/dev/null || eval $(udfOnError return iErrorNotPermitted '$1')
 pathDst="$(pwd)"
 for s in *; do
  [[ -d "$s" ]] && udfGetPathMd5 $s
 done
 md5sum $pathDst/* 2>/dev/null
 cd $pathSrc
 return 0
}
#******
#****f* libstd/udfXml
#  SYNOPSIS
#    udfXml tag [property] data
#  DESCRIPTION
#    Generate XML code to stdout
#  INPUTS
#    tag      - XML tag name (without <>)
#    property - XML tag property
#    data     - XML tag content
#  OUTPUT
#    Show compiled XML code
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    local sTag='date TO="+0400" TZ="MSK"' sContent='Mon, 22 Apr 2013 15:55:50'
#    local sXml='<date TO="+0400" TZ="MSK">Mon, 22 Apr 2013 15:55:50</date>'
#    udfXml "$sTag" "$sContent" >| grep "^${sXml}$"                             #? true
#  SOURCE
udfXml() {
 local IFS=$' \t\n' s
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 s=($1)
 shift
 echo "<${s[*]}>${*}</${s[0]}>"
}
#******
#****f* libstd/udfSerialize
#  SYNOPSIS
#    udfSerialize variables
#  DESCRIPTION
#    Generate csv string from variable list
#  INPUTS
#    variables - list of variables
#  OUTPUT
#    Show csv string
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    local sUname="$(uname -a)" sDate="" s=100
#    udfSerialize sUname sDate s >| grep "^sUname=.*s=100;$"                                                                 #? true
#  SOURCE
udfSerialize() {
 local bashlyk_s_Serialize csv IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 for bashlyk_s_Serialize in $*; do
  udfIsValidVariable "$bashlyk_s_Serialize" \
   && csv+="${bashlyk_s_Serialize}=${!bashlyk_s_Serialize};" \
   || udfSetLastError iErrorNonValidVariable "$bashlyk_s_Serialize"
 done
 echo "$csv"
}
#******
#****f* libstd/udfBashlykUnquote
#  SYNOPSIS
#    udfBashlykUnquote
#  DESCRIPTION
#    Преобразование метапоследовательностей _bashlyk_&#XX_ из потока со стандартного входа в символы '"[]()=;\'
#  EXAMPLE
#    local s="_bashlyk_&#34__bashlyk_&#91__bashlyk_&#93__bashlyk_&#59__bashlyk_&#40__bashlyk_&#41__bashlyk_&#61_"
#    echo $s | udfBashlykUnquote >| grep -e '\"\[\];()='                                                          #? true
#  SOURCE
udfBashlykUnquote() {
 local a cmd="sed" i IFS=$' \t\n'
 declare -A a=( [34]='\"' [40]='\(' [41]='\)' [59]='\;' [61]='\=' [91]='\[' [92]='\\\' [93]='\]' )
 for i in "${!a[@]}"; do
  cmd+=" -e \"s/_bashlyk_\&#${i}_/${a[$i]}/g\""
 done
 ## TODO продумать команды для удаления "_bashlyk_csv_record=" и автоматических ключей
 #cmd+=" -e \"s/\t\?_bashlyk_ini_.*_autoKey_[0-9]\+\t\?=\t\?//g\""
 cmd+=' -e "s/^\"\(.*\)\"$/\1/"'
 eval "$cmd"
}
#******
#****f* libstd/udfLocalVarFromCSV
#  SYNOPSIS
#    udfLocalVarFromCSV CSV1 CSV2 ...
#  DESCRIPTION
#    Prepare string from comma separated lists (ex. INI options) for definition
#    of the local variables by using eval
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    udfLocalVarFromCSV a1,b2,c3                                                #? true
#    udfLocalVarFromCSV a1 b2,c3                                                #? true
#    udfLocalVarFromCSV a1,b2 c3                                                #? true
#    echo $( udfLocalVarFromCSV a1,b2 c3,4d 2>/dev/null ) >| grep '^local'      #? false
#  SOURCE
udfLocalVarFromCSV() {

	udfOn EmptyOrMissingArgument throw "$@"

	local s
	local -A h

	for s in ${*//[;,]/ }; do

		udfIsValidVariable $s || eval $( udfOnError2 throw iErrorNonValidVariable "$s" )
		h[$s]="$s"

	done

	udfOn EmptyResult throw "${h[@]}"
	echo "local ${h[@]}"

}
#******
