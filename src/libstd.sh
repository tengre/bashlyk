#
# $Id$
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
#****v* libstd/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#    * $_bashlyk_sArg - аргументы командной строки вызова сценария
#    * $_bashlyk_sWSpaceAlias - заменяющая пробел последовательность символов
#    * $_bashlyk_aRequiredCmd_opt - список используемых в данном модуле внешних
#    утилит
#  SOURCE
_bashlyk_iErrorEmptyOrMissingArgument=255
_bashlyk_iErrorUnexpected=254
_bashlyk_iErrorNonValidArgument=250
_bashlyk_iErrorNotPermitted=240
_bashlyk_iErrorNonValidVariable=200
_bashlyk_iErrorNotExistNotCreated=190
_bashlyk_iErrorNoSuchFileOrDir=185
_bashlyk_iErrorNoSuchProcess=184
_bashlyk_iErrorCurrentProcess=183
_bashlyk_iErrorAlreadyStarted=182
_bashlyk_iErrorCommandNotFound=180
_bashlyk_iErrorXsessionNotFound=170
_bashlyk_iErrorUserXsessionNotFound=171
#
_bashlyk_iMaxOutputLines=1000
#
: ${_bashlyk_sBehaviorOnError:=return}
: ${_bashlyk_iLastError:=0}
: ${_bashlyk_sLastError:=}
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathDat:=/tmp}
: ${_bashlyk_sWSpaceAlias:=___}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}
: ${_bashlyk_s0:=${0##*/}}
: ${_bashlyk_sId:=${_bashlyk_s0%.sh}}
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
: ${_bashlyk_aRequiredCmd_std:="[ basename cat cut chgrp chmod chown date dir  \
 echo false file grep kill ls mail md5sum pwd mkdir mktemp printf ps rm rmdir  \
 sed sleep tee tempfile touch true w which xargs"}
: ${_bashlyk_aExport_std:="udfBaseId udfDate udfShowVariable udfIsNumber udfIsValidVariable udfQuoteIfNeeded udfWSpace2Alias \
 udfAlias2WSpace udfMakeTemp  udfMakeTempV udfShellExec udfAddFile2Clean udfAddPath2Clean udfAddJob2Clean udfAddPid2Clean \
 udfCheckCsv udfCleanQueue udfOnTrap _ARGUMENTS _s0 _pathDat _ _gete _getv _set udfGetMd5 udfGetPathMd5 udfXml udfPrepare2Exec \ udfSerialize udfSetLastError udfBashlykUnquote udfTimeStamp"}
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
 echo "$1" | grep -i -E "^[[:digit:]]+${s}$" >/dev/null 2>&1 || return $_bashlyk_iErrorNonValidArgument
 return 0
}
#******
#****f* libstd/udfSetLastError
#  SYNOPSIS
#    udfSetLastError iError sError
#  DESCRIPTION
#    Save in global variables _bashlyk_iLastError _bashlyk_sLastError error states
#  INPUTS
#    iError - Error Number
#    sError - Error text
#  RETURN VALUE
#    last error code
#  EXAMPLE
#    udfSetLastError                                                            #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfSetLastError iErrorNonValidVariable "12NonValid Variable"               #? $_bashlyk_iErrorNonValidVariable
#    _ iLastError >| grep -w "$_bashlyk_iErrorNonValidVariable"                 #? true
#    _ sLastError >| grep "^12NonValid Variable$"                               #? true
#  SOURCE
udfSetLastError() {
 [[ -n "$1" ]] || return $_bashlyk_iErrorEmptyOrMissingArgument
 local i s
 udfIsNumber $1 && i=$1  || eval "i=\$_bashlyk_${1}"
 udfIsNumber $i && shift || i=$_bashlyk_iErrorUnexpected
 _bashlyk_iLastError=$i
 _bashlyk_sLastError="$*"
 for (( i=0; i < ${#BASH_SOURCE[@]}; i++ )); do s+="${BASH_SOURCE[i]} "; done
 for (( i=0; i < ${#BASH_LINENO[@]}; i++ )); do s+="${BASH_LINENO[i]} "; done
 for (( i=0; i < ${#FUNCNAME[@]}; i++    )); do s+="${FUNCNAME[i]} "   ; done
 _bashlyk_sStackTrace=$s
 return $_bashlyk_iLastError
}
#******
#****f* libstd/udfOnError
#  SYNOPSIS
#    udfOnError [<action>] [<iError>] [<sMessage>]
#  DESCRIPTION
#   Подготовка кода для установки состоянии ошибки в глобальные переменные _bashlyk_iLastError, _bashlyk_sLastError и
#   дальнейшего выполнения сценария, который можно вызвать при помощи eval
#  INPUTS
#    action   - необязательный аргумент, учитывается если имеет одно из значений:
#                warn   - вывести сообщение на STDOUT в виде остальной строки аргументов (echo - синоним warn)
#                return - вписать команду возврата если код находится внутри какой-либо функции, иначе вписать "exit"
#                rewarn - комбинированное действие warn + return, однако, если код находится не внутри функции, то возврат не
#                         вписывается в код - только echo
#                exit   - вписать команду безусловного завершения сценария
#               В других случаях выполняется действие, хранимое в глобальной переменной $_bashlyk_sBehaviorOnError
#    iError   - цифровой код ошибки или выражение "iError<Имя ошибки>" при помощи которого можно получить код ошибки c глобальной
#               переменной вида _bashlyk_iError<..>. Если не удается извлечь цифровой код, то он устанавливается равным
#               $_bashlyk_iErrorUnexpected. В конечном итоге полученный цифровой код инициализирует глобальную переменную
#               $_bashlyk_iLastError
#    sMessage - описание ошибки или детализация, например, имя файла или т.п. - инициализирует глобальную переменную
#               $_bashlyk_sLastError
#  OUTPUT
#    строка команд типа "udfSetLastError _bashlyk_iErrorNoSuchFileOrDir "$filename"; exit $?",
#    которую можно выполнить при помощи eval
#  EXAMPLE
#    local s="udfSetLastError iErrorNonValidArgument test unit;"
#    eval $(udfOnError warn   iErrorNonValidArgument "test unit")                           #? $_bashlyk_iErrorNonValidArgument
#    udfIsNumber 020h || eval $(udfOnError echo $? "020h")                                  #? $_bashlyk_iErrorNonValidArgument
#    echo $(udfOnError exit   iErrorNonValidArgument "test unit") >| grep "^$s exit \$?$"   #? true
#    echo $(udfOnError return iErrorNonValidArgument "test unit") >| grep "^$s return \$?$" #? true
#    echo $(udfOnError rewarn iErrorNonValidArgument "test unit") >| grep " $s return \$?$" #? true
#  SOURCE
udfOnError() {
 local sAction=$_bashlyk_sBehaviorOnError sMessage=''
 case "$sAction" in
  echo|rewarn|exit|return) ;;
                     warn) sAction=echo;;
                        *) sAction=return;;
 esac

 case "$1" in
  return|rewarn|warn|echo|exit) sAction=$1;shift;;
 esac
 ## TODO [ -n "${FUNCNAME[1]}" ]
 [[ "$sAction" == "return" && "${FUNCNAME[1]}" == "main" ]] && sAction='exit'
 [[ "$sAction" == "rewarn" && "${FUNCNAME[1]}" == "main" ]] && sAction='echo'

 case "$sAction" in
    echo|warn) sAction="";               sMessage="echo ${*};";;
       rewarn) sAction="; return \$?";   sMessage="echo ${*};";;
  exit|return) sAction="; $sAction \$?"; sMessage="";;
 esac
 printf "%s udfSetLastError ${*}%s\n" "$sMessage" "${sAction}"
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
#    local re="[[:graph:]]+ [0-9]+ [0-9]+:[0-9]+:[[:digit:]]+ foo bar"
#    udfTimeStamp foo bar >| grep -E "$re"                                      #? true
#  SOURCE
udfTimeStamp() {
 LANG=C LC_TIME=C date "+%b %d %H:%M:%S $*"
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
#    Выводит значения аргументов, если они являются переменными
#  INPUTS
#    args - имена переменных
#  OUTPUT
#    Имя переменной и значение в виде <Имя>=<Значение>
#  EXAMPLE
#    local sTest='test'
#    udfShowVariable sTest >| grep -w 'sTest=test'                              #? true
#  SOURCE
udfShowVariable() {
 local bashlyk_aSE10yGYS4AwxLJA_a bashlyk_G9WOnrBkEFSt9oKw_s
 for bashlyk_G9WOnrBkEFSt9oKw_s in $*; do
  bashlyk_aSE10yGYS4AwxLJA_a+="\t${bashlyk_G9WOnrBkEFSt9oKw_s}=${!bashlyk_G9WOnrBkEFSt9oKw_s}\n"
 done
 echo -e "Variable listing:\n${bashlyk_aSE10yGYS4AwxLJA_a}"
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
#    iErrorNonValidVariable       - аргумент невалидный идентификатор
#    iErrorEmptyOrMissingArgument - аргумент не задан
#  EXAMPLE
#    udfIsValidVariable                                                         #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfIsValidVariable "12"                                                    #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable "a"                                                     #? true
#    udfIsValidVariable "k1"                                                    #? true
#  SOURCE
udfIsValidVariable() {
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 echo "$1" | grep -E '^[_a-zA-Z]+[_a-zA-Z0-9]+?$' >/dev/null 2>&1 || eval $(udfOnError return iErrorNonValidVariable $1)
 return 0
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
 [[ -n "$(echo "$*" | grep -e [[:space:]])" ]] && echo "\"$*\"" || echo "$*"
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
#    type=file|dir     - тип объекта: файл или каталог
#    keep=true|false   - удалять/не удалять временные объекты после завершения
#                        сценария (удалять по умолчанию)
#  OUTPUT
#    вывод происходит если нет аргументов или отсутствует именной аргумент
#    varname, если временный объект не создан, то ничего не выдается
#
#  RETURN VALUE
#    0                            - выполнено успешно
#    iErrorNotExistNotCreated     - временный объект файловой системы не создан
#    iErrorNonValidVariable       - аргумент <varname> не является валидным
#                                   идентификатором переменной
#    iErrorUnexpected             - неожиданная ошибка
#    iErrorEmptyOrMissingArgument - аргумент отсутствует или файл конфигурации
#                                   не найден
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
#    ## TODO проверить все коды возврата
#  SOURCE
udfMakeTemp() {
 local bashlyk_foResult_ioAUaE5R bashlyk_optDir_ioAUaE5R bashlyk_s_ioAUaE5R
 local bashlyk_bNoKeep_ioAUaE5R bashlyk_sVar_ioAUaE5R bashlyk_sGroup_ioAUaE5R
 local bashlyk_sCreateMode_ioAUaE5R bashlyk_path_ioAUaE5R bashlyk_sUser_ioAUaE5R
 local bashlyk_sPrefix_ioAUaE5R bashlyk_sSuffix_ioAUaE5R bashlyk_rc_ioAUaE5R
 local bashlyk_octMode_ioAUaE5R
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
    eval $(udfOnError return iErrorUnexpected $bashlyk_sCreateMode_ioAUaE5R)
  ;;
 esac
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
 [[ -n "$1" ]] || eval $(udfOnError exit iErrorEmptyOrMissingArgument "$1")
 udfIsValidVariable "$1" || eval $(udfOnError exit iErrorNonValidVariable "$1")
 #
 local sKeep sType sPrefix
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
#    udfPrepare2Exec - | args
#  DESCRIPTION
#    ## TODO STDIN ? ';' : '\n'
#    Преобразование при необходимости метапоследовательностей _bashlyk_&#XX_
#    из "csv;"-потока со стандартного входа или аргументов командной строки
#    в символы '[]()=;\'
#  INPUTS
#    args - командная строка
#       - - данные поступают со стандартного входа
#  OUTPUT
#    Если данные поступают со стандартного входа, то csv;-строка, иначе поток
#    строк - каждое поле входной csv;-строки - отдельная строка
#  EXAMPLE
#    local s="_bashlyk_&#91__bashlyk_&#93__bashlyk_&#59__bashlyk_&#40__bashlyk_&#41__bashlyk_&#61_"
#    echo $s | udfPrepare2Exec -                                                #? true
#    udfPrepare2Exec $s | grep -e '\[\];()='                                    #? true
#  SOURCE
udfPrepare2Exec() {
 local s cIFS cmd="$*" cmdSed=''
 if [[ "$1" == "-" ]]; then
  udfBashlykUnquote
 else
  cIFS=$IFS
  IFS=';'
  for s in $cmd
  do
   echo "$s" | udfBashlykUnquote
  done
 fi
 IFS=$cIFS
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
 [[ -n "$*" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 local rc fn
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
#    echo $(udfAddFile2Clean $fnTemp)
#    test -f $fnTemp                                                            #? false
#  SOURCE
udfAddFile2Clean() {
 [[ -n "$1" ]] || return 0
 _bashlyk_afnClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
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
#    local pathTemp
#    udfMakeTemp pathTemp keep=true type=dir
#    echo $(udfAddPath2Clean $pathTemp)
#    test -d $pathTemp                                                          #? false
#  SOURCE
udfAddPath2Clean() {
 [[ -n "$1" ]] || return 0
 _bashlyk_apathClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* libstd/udfAddJob2Clean
#  SYNOPSIS
#    udfAddJob2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных заданий к списку удаляемых при
#    завершении сценария.
#  INPUTS
#    args - идентификаторы заданий
#  EXAMPLE
#    sleep 99 &
#    udfAddJob2Clean "%1"                                                       #? true
#    echo "$(_ ajobClean)" | grep -w "%1"                                       #? true
#  SOURCE
udfAddJob2Clean() {
 [[ -n "$1" ]] || return 0
 _bashlyk_ajobClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* libstd/udfAddPid2Clean
#  SYNOPSIS
#    udfAddPid2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных процессов к списку завершаемых при
#    завершении сценария.
#  INPUTS
#    args - идентификаторы процессов
#  EXAMPLE
#    sleep 99 &
#    local pid=$!
#    test -n "$pid"                                                             #? true
#    udfAddPid2Clean $pid                                                       #? true
#    echo "$(_ apidClean)" >| grep -w "$pid"                                    #? true
#  SOURCE
udfAddPid2Clean() {
 [[ -n "$1" ]] || return 0
 _bashlyk_apidClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
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
#****f* libstd/udfOnTrap
#  SYNOPSIS
#    udfOnTrap
#  DESCRIPTION
#    Процедура очистки при завершении вызвавшего сценария.
#    Предназначен только для вызова командой trap.
#    * Производится удаление файлов и пустых каталогов; заданий и процессов,
#    указанных в соответствующих глобальных переменных
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
 local i s
 #
 for s in ${_bashlyk_ajobClean}; do
  kill $s 2>/dev/null
 done
 #
 for s in ${_bashlyk_apidClean}; do
  for i in 15 9; do
   [[ -n "$(ps -o pid= --ppid $$ | xargs | grep -w $s)" ]] && {
    kill -${i} $s 2>/dev/null
    sleep 0.2
   }
  done
 done
 #
 [[ "$_bashlyk_iLastError" != 0 && "$_bashlyk_bNotUseLog" == "0" ]] && {
  echo "Call Trace: $_bashlyk_sCallTrace" > $_bashlyk_fnLogSock 2>/dev/null
  echo "Last Error: $_bashlyk_sLastError ($_bashlyk_iLastError) " > $_bashlyk_fnLogSock 2>/dev/null
 }
 #
 for s in ${_bashlyk_afnClean}; do
  rm -f $s
 done
 #
 for s in ${_bashlyk_apathClean}; do
  rmdir $s 2>/dev/null
 done
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
#    local sS sWSpaceAlias
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
#  SOURCE
_(){
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 if (( $# > 1 )); then
  eval "_bashlyk_${1##*=}=\"${2}\""
 else
  case "$1" in
   *=*)
        local k v
        k=${1%=*}
        v=${1##*=}
        [[ -n "$k" ]] || k=$v
        udfIsValidVariable $k || eval $(udfOnError return $? $k)
        eval "export $k="'$_bashlyk_'"${v}"
        ;;
     *) eval "echo "'$_bashlyk_'"${1}";;
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
#    ## TODO проверить все коды возврата
#  SOURCE
udfCheckCsv() {
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 local bashlyk_s_Q1eiphgO bashlyk_cIFS_Q1eiphgO bashlyk_k_Q1eiphgO
 local bashlyk_v_Q1eiphgO bashlyk_i_Q1eiphgO bashlyk_csvResult_Q1eiphgO
 #
 bashlyk_cIFS_Q1eiphgO=$IFS
 IFS=';'
 bashlyk_i_Q1eiphgO=0
 bashlyk_csvResult_Q1eiphgO=''
 #
 for bashlyk_s_Q1eiphgO in $1; do
  bashlyk_s_Q1eiphgO=$(echo $bashlyk_s_Q1eiphgO | tr -d "'" | tr -d '"' | sed  \
  -e "s/^\[.*\];//")
  bashlyk_k_Q1eiphgO="$(echo ${bashlyk_s_Q1eiphgO%%=*}|xargs)"
  bashlyk_v_Q1eiphgO="$(echo ${bashlyk_s_Q1eiphgO#*=}|xargs)"
  [[ -n "$bashlyk_k_Q1eiphgO" ]] || continue
  if [[ "$bashlyk_k_Q1eiphgO" == "$bashlyk_v_Q1eiphgO" || -n "$(echo "$bashlyk_k_Q1eiphgO" | grep '.*[[:space:]+].*')" ]]; then
   bashlyk_k_Q1eiphgO=${_bashlyk_sUnnamedKeyword}${bashlyk_i_Q1eiphgO}
   bashlyk_i_Q1eiphgO=$((bashlyk_i_Q1eiphgO+1))
  fi
  bashlyk_csvResult_Q1eiphgO+="$bashlyk_k_Q1eiphgO=$(udfQuoteIfNeeded \
   $bashlyk_v_Q1eiphgO);"
 done
 IFS=$bashlyk_cIFS_Q1eiphgO
 if [[ -n "$2" ]]; then
  udfIsValidVariable "$2" || eval $(udfOnError return iErrorNonValidVariable "$2")
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
#    iErrorFileNotFound           - путь не доступен
#    0                            - успешная операция
#  EXAMPLE
#    # TODO требуется более точная проверка
#    local path=$(udfMakeTemp type=dir)
#    touch ${path}/testfile
#    udfAddFile2Clean ${path}/testfile
#    udfAddPath2Clean ${path}
#    udfGetPathMd5 $path                                                        #? true
#  SOURCE
udfGetPathMd5() {
 [[ -n "$1" && -d "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 local pathSrc="$(pwd)" pathDst s
 cd "$1" 2>/dev/null || eval $(udfOnError return iErrorFileNotFound "$1")
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
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 local s=($1)
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
#    udfSerialize sUname sDate s >| grep "^sUname=.*s=100;$"                    #? true
#  SOURCE
udfSerialize() {
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 local bashlyk_s_Serialize csv
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
#    Преобразование при необходимости метапоследовательностей _bashlyk_&#XX_
#    из "csv;"-потока со стандартного входа в символы '"[]()=;\'
#  EXAMPLE
#    local s="_bashlyk_&#34__bashlyk_&#91__bashlyk_&#93__bashlyk_&#59__bashlyk_&#40__bashlyk_&#41__bashlyk_&#61_"
#    echo $s | udfBashlykUnquote >| grep -e '\"\[\];()='                          #? true
#  SOURCE
udfBashlykUnquote() {
 local a cmd="sed" i
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
#shopt -s expand_aliases
#alias onError="eval $(udfOnError"
