#
# $Id$
#
#****h* bashlyk/libstd
#  DESCRIPTION
#    bashlyk Std library
#    стандартный набор функций
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/libstd/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$_BASHLYK_LIBSTD" ] && return 0 || _BASHLYK_LIBSTD=1
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
#******
#****v*  bashlyk/libstd/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#    * $_bashlyk_sArg - аргументы командной строки вызова сценария
#    * $_bashlyk_sWSpaceAlias - заменяющая пробел последовательность символов
#    * $_bashlyk_aRequiredCmd_opt - список используемых в данном модуле внешних
#    утилит
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_sWSpaceAlias:=___}
: ${_bashlyk_s0:=$(basename $0)}
: ${_bashlyk_sId:=$(basename $0 .sh)}
: ${_bashlyk_afnClean:=}
: ${_bashlyk_apathClean:=}
: ${_bashlyk_ajobClean:=}
: ${_bashlyk_apidClean:=}
: ${_bashlyk_pidLogSock:=}
: ${_bashlyk_sUser:=$USER}
: ${HOSTNAME:=$(hostname)}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_aRequiredCmd_std:="[ basename cat chgrp chmod chown date dir echo false file grep kill mail mkdir mktemp printf ps rm rmdir sed sleep tee tempfile touch true w which xargs"
: ${_bashlyk_aExport_std:="udfBaseId udfDate udfEcho udfMail udfWarn udfThrow udfOnEmptyVariable udfThrowOnEmptyVariable udfWarnOnEmptyVariable udfShowVariable udfIsNumber udfIsValidVariable udfQuoteIfNeeded udfWSpace2Alias udfAlias2WSpace udfMakeTemp udfMakeTempV udfShellExec udfAddFile2Clean udfAddPath2Clean udfAddJob2Clean udfAddPid2Clean udfCleanQueue udfOnTrap _ARGUMENTS _s0"}
#******
#****f* bashlyk/libstd/udfBaseId
#  SYNOPSIS
#    udfBaseId
#  DESCRIPTION
#    Alias для команды basename
#  OUTPUT
#    Короткое имя запущенного сценария без расширения ".sh"
#  SOURCE
udfBaseId() {
 basename $0 .sh
}
#******
#****f* bashlyk/libstd/udfDate
#  SYNOPSIS
#    udfDate <args>
#  DESCRIPTION
#    Alias для команды date
#  INPUTS
#    <args> - суффикс к форматной строке текущей даты
#  OUTPUT
#    текущая дата с возможным суффиксом
#  SOURCE
udfDate() {
 date "+%b %d %H:%M:%S $*"
}
#******
#****f* bashlyk/libstd/udfEcho
#  SYNOPSIS
#    udfEcho [-] args
#  DESCRIPTION
#    Сборка сообщения из аргументов и стандартного ввода
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то эта строка выводится заголовком для данных
#           из стандартного ввода
#  OUTPUT
#   Зависит от параметров вывода
#  SOURCE
udfEcho() {
 if [ "$1" = "-" ]; then
  shift
  [ -n "$1" ] && printf "%s\n----\n" "$*"
  cat
 else
  [ -n "$1" ] && echo $*
 fi
}
#******
#****f* bashlyk/libstd/udfMail
#  SYNOPSIS
#    udfMail [[-] args]
#  DESCRIPTION
#    Передача сообщения по почте
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то эта строка выводится заголовком для данных
#           из стандартного ввода
#  SOURCE
udfMail() {
 local fnTmp
 udfMakeTemp fnTmp
 udfEcho "$*" | tee -a $fnTmp
 cat $fnTmp | mail -e -s "${_bashlyk_emailSubj}" ${_bashlyk_emailRcpt}
 rm -f $fnTmp
}
#******
#****f* bashlyk/libstd/udfWarn
#  SYNOPSIS
#    udfWarn [-] args
#  DESCRIPTION
#    Вывод предупреждающего сообщения. Если терминал отсутствует, то
#    сообщение передается по почте.
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то строка выводится заголовком для данных
#           из стандартного ввода
#  OUTPUT
#   Зависит от параметров вывода
#  SOURCE
udfWarn() {
 [ $_bashlyk_bNotUseLog -ne 0 ] && udfEcho $* || udfMail $*
}
#******
#****f* bashlyk/libstd/udfThrow
#  SYNOPSIS
#    udfThrow [-] args
#  DESCRIPTION
#    Вывод аварийного сообщения с завершением работы. Если терминал отсутствует,
#    то сообщение передается по почте.
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то строка выводится заголовком для данных
#           из стандартного ввода
#  OUTPUT
#   Зависит от параметров вывода
#  SOURCE
udfThrow() {
 udfWarn $*
 exit 255
}
#******
#****f* bashlyk/libstd/udfOnEmptyVariable
#  SYNOPSIS
#    udfOnEmptyVariable [Warn | Throw ] args
#  DESCRIPTION
#    Вызывает останов или выдает предупреждение, если аргументы - имена 
#    переменных - содержат пустые значения
#  INPUTS
#    Warn  - вывод предупреждения
#    Throw - останов сценария (по умолчанию)
#    args  - имена переменных
#  OUTPUT
#    Сообщение об ошибке с перечислением имен переменных, 
#    которые содержат пустые значения
#  RETURN VALUE
#    0   - переменные не содержат пустые значения
#    255 - есть не инициализированные переменные
#  SOURCE
udfOnEmptyVariable() {
 local bashlyk_EysrBRwAuGMRNQoG_a bashlyk_tfAFyKrLgSeOatp2_s s='Throw'
 case "$1" in
  "Warn")
   s='Warn'; shift;;
  "Throw")
   s='Throw'; shift;;
 esac
 for bashlyk_tfAFyKrLgSeOatp2_s in $*; do
  [ -z "${!bashlyk_tfAFyKrLgSeOatp2_s}" ] \
   && bashlyk_EysrBRwAuGMRNQoG_a+=" $bashlyk_tfAFyKrLgSeOatp2_s"
 done
 [ -n "$bashlyk_EysrBRwAuGMRNQoG_a" ] && {
  udf${s} "Error: Variable(s) or option(s) ($bashlyk_EysrBRwAuGMRNQoG_a ) is empty..."
  return 255
 }
 return 0
}
#******
#****f* bashlyk/libstd/udfThrowOnEmptyVariable
#  SYNOPSIS
#    udfThrowOnEmptyVariable args
#  DESCRIPTION
#    Вызывает останов сценария, если аргументы, как имена переменных, содержат
#    пустые значения
#  INPUTS
#    args - имена переменных
#  OUTPUT
#    Сообщение об ошибке с перечислением имен переменных, которые содержат
#    пустые значения
#  RETURN VALUE
#    0   - переменные не содержат пустые значения
#    255 - есть не инициализированные переменные
#  SOURCE
udfThrowOnEmptyVariable() {
 udfOnEmptyVariable Throw $*
}
#******
#****f* bashlyk/libstd/udfWarnOnEmptyVariable
#  SYNOPSIS
#    udfWarnOnEmptyVariable args
#  DESCRIPTION
#    Выдаёт предупреждение, если аргументы - имена переменных - содержат пустые
#    значения
#  INPUTS
#    args - имена переменных
#  OUTPUT
#    Сообщение об ошибке с перечислением имен переменных, которые содержат
#    пустые значения
#  RETURN VALUE
#    0   - переменные не содержат пустые значения
#    255 - есть не инициализированные переменные
#  SOURCE
udfWarnOnEmptyVariable() {
 udfOnEmptyVariable Warn $*
}
#******
#****f* bashlyk/libstd/udfShowVariable
#  SYNOPSIS
#    udfShowVariable args
#  DESCRIPTION
#    Выводит значения аргументов, если они являются переменными
#  INPUTS
#    args - имена переменных
#  OUTPUT
#    Имя переменной и значение в виде <Имя>=<Значение>
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
#****f* bashlyk/libstd/udfIsNumber
#  SYNOPSIS
#    udfIsNumber <number> [<tag>]
#  DESCRIPTION
#    Проверка аргумента на то, что он является натуральным числом
#    Аргумент считается числом, если он содержит цифры и может иметь в конце
#    символ - признак порядка, например, k M G (kilo-, Mega-, Giga-)
#  INPUTS
#    number - проверяемое значение
#    tag    - набор символов, один из которых можно применить
#             после цифр для указания признака числа, например, 
#             порядка.
#  RETURN VALUE
#    0 - аргумент является натуральным числом
#    1 - аргумент не является натуральным числом
#    2 - аргумент не задан
#  EXAMPLE
#    udfIsNumber $iSize kMG
#    Возвращает 0 если $iSize содержит число вида 12,34k,67M или 89G
#  SOURCE
udfIsNumber() {
 [ -n "$1" ] || return 2
 local s=''
 [ -n "$2" ] && s="[$2]?"
 case "$(echo "$1" | grep -E "^[[:digit:]]+${s}$")" in
  '') return 1;;
   *) return 0;;
 esac
}
#******
#****f* bashlyk/libstd/udfIsValidVariable
#  SYNOPSIS
#    udfIsVariable <arg>
#  DESCRIPTION
#    Проверка аргумента на то, что он может быть валидным идентификатором
#    переменной 
#  INPUTS
#    arg - проверяемое значение
#  RETURN VALUE
#    0 - аргумент является валидным идентификатором
#    1 - аргумент не является валидным идентификатором
#    2 - аргумент не задан
#  SOURCE
udfIsValidVariable() {
 [ -n "$1" ] || return 2
 case "$(echo "$1" | grep -E '^[_a-zA-Z]+[_a-zA-Z0-9]+$')" in
  '') return 1;;
   *) return 0;;
 esac
}
#******
#****f* bashlyk/libstd/udfQuoteIfNeeded
#  SYNOPSIS
#    udfQuoteIfNeeded <arg>
#  DESCRIPTION
#   Аргумент, содержащий пробел(ы) отмечается кавычками
#  INPUTS
#    arg - argument
#  OUTPUT
#    аргумент с кавычками, если есть пробелы
#  EXAMPLE
#    udfQuoteIfNeeded $(date)
#  SOURCE
udfQuoteIfNeeded() {
 [ -n "$(echo "$*" | grep -e [[:space:]])" ] && echo "\"$*\"" || echo "$*"
}
#******
#****f* bashlyk/libstd/udfWSpace2Alias
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
#    выполнение: udfWSpace2Alias a b  cd
#         вывод: a___b______cd
#  SOURCE
udfWSpace2Alias() {
 case "$1" in
 -) sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
 *) echo "$*" | sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
 esac
}
#******
#****f* bashlyk/libstd/udfAlias2WSpace
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
#    выполнение: udfWSpace2Alias a___b______cd
#         вывод: "a b  cd"
#    выполнение: echo a___b______cd | udfAlias2WSpace -
#         вывод: a b  cd
#  SOURCE
udfAlias2WSpace() {
 case "$1" in
 -) sed -e "s/$_bashlyk_sWSpaceAlias/ /g";;
 *) udfQuoteIfNeeded $(echo "$*" | sed -e "s/$_bashlyk_sWSpaceAlias/ /g");;
 esac 
}
#******
#****f* bashlyk/libstd/udfMakeTemp
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
#     0  - Выполнено успешно
#     1  - временный объект файловой системы не создан
#     2  - Ошибка: аргумент <varname> не является валидным идентификатором
#          переменной
#    254 - неожиданная ошибка
#    255 - Ошибка: аргумент отсутствует или файл конфигурации не найден
#
#  EXAMPLE
#   udfMakeTemp fnTemp prefix=temp mode=0644 keep=true path=$HOME
#
#   pathTemp=$(udfMakeTemp path=/var/tmp/$USER)
#   udfAddPath2Clean $pathTemp
#
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
            if [ -z "$3" -a -n "$2" -a $bashlyk_rc_ioAUaE5R -eq 0 ]; then
             # oldstyle
             bashlyk_octMode_ioAUaE5R="$2"
             bashlyk_sVar_ioAUaE5R=''
             bashlyk_sPrefix_ioAUaE5R="$1"
            fi
          ;;
  esac
 done

 if [ -n "$bashlyk_sVar_ioAUaE5R" ]; then
  udfIsValidVariable "$bashlyk_sVar_ioAUaE5R" || return 2
 else
  bashlyk_bNoKeep_ioAUaE5R=false
 fi

 if [ -f "$(which mktemp)" ]; then
  bashlyk_sCreateMode_ioAUaE5R=mktemp
 elif [ -f "$(which tempfile)" ]; then
  [ -z "$bashlyk_optDir_ioAUaE5R" ] \
   && bashlyk_sCreateMode_ioAUaE5R=tempfile \
   || bashlyk_sCreateMode_ioAUaE5R=direct
 fi

 case "$bashlyk_sCreateMode_ioAUaE5R" in
    direct)
   [ -n "$bashlyk_path_ioAUaE5R"    ] \
    && bashlyk_s_ioAUaE5R="${bashlyk_path_ioAUaE5R}/" \
    || bashlyk_s_ioAUaE5R="/tmp/"
   bashlyk_s_ioAUaE5R+="${bashlyk_sPrefix_ioAUaE5R}${$}${bashlyk_sSuffix_ioAUaE5R}"
   [ -n "$bashlyk_optDir_ioAUaE5R"  ] \
    && mkdir -p $bashlyk_s_ioAUaE5R \
    || touch $bashlyk_s_ioAUaE5R
   [ -n "$bashlyk_octMode_ioAUaE5R" ] \
    && chmod $bashlyk_octMode_ioAUaE5R $bashlyk_s_ioAUaE5R
  ;;
    mktemp)
   if [ -n "$bashlyk_path_ioAUaE5R" ]; then
    mkdir -p $bashlyk_path_ioAUaE5R
    bashlyk_path_ioAUaE5R="-p $bashlyk_path_ioAUaE5R"
   fi
   #bashlyk_s_ioAUaE5R=$(mktemp $bashlyk_path_ioAUaE5R $bashlyk_optDir_ioAUaE5R -t "${bashlyk_sPrefix_ioAUaE5R}XXXXXXXX${bashlyk_sSuffix_ioAUaE5R}")
   bashlyk_s_ioAUaE5R=$(mktemp $bashlyk_path_ioAUaE5R $bashlyk_optDir_ioAUaE5R \
    -t "${bashlyk_sPrefix_ioAUaE5R}${bashlyk_sSuffix_ioAUaE5R}XXXXXXXX")

   [ -n "$bashlyk_octMode_ioAUaE5R" ] \
    && chmod $bashlyk_octMode_ioAUaE5R $bashlyk_s_ioAUaE5R
  ;;
  tempfile)
   [ -n "$bashlyk_sPrefix_ioAUaE5R" ] \
    && bashlyk_sPrefix_ioAUaE5R="-p $bashlyk_sPrefix_ioAUaE5R"
   [ -n "$bashlyk_sSuffix_ioAUaE5R" ] \
    && bashlyk_sSuffix_ioAUaE5R="-s $bashlyk_sSuffix_ioAUaE5R"
   bashlyk_s_ioAUaE5R=$(tempfile $bashlyk_optDir_ioAUaE5R \
    $bashlyk_sPrefix_ioAUaE5R $bashlyk_sSuffix_ioAUaE5R)
  ;;
  *)
    return 254
  ;;
 esac
 [ -n "$bashlyk_sUser_ioAUaE5R"  ] \
  && chown $bashlyk_sUser_ioAUaE5R  $bashlyk_s_ioAUaE5R
 [ -n "$bashlyk_sGroup_ioAUaE5R" ] \
  && chgrp $bashlyk_sGroup_ioAUaE5R $bashlyk_s_ioAUaE5R

 if   [ -f "$bashlyk_s_ioAUaE5R" ]; then
  $bashlyk_bNoKeep_ioAUaE5R && udfAddFile2Clean $bashlyk_s_ioAUaE5R
 elif [ -d "$bashlyk_s_ioAUaE5R" ]; then
  $bashlyk_bNoKeep_ioAUaE5R && udfAddPath2Clean $bashlyk_s_ioAUaE5R
 else
  return 1
 fi

 bashlyk_foResult_ioAUaE5R=$bashlyk_s_ioAUaE5R
 if [ -n "$bashlyk_sVar_ioAUaE5R" ]; then
  eval 'export ${bashlyk_sVar_ioAUaE5R}=${bashlyk_foResult_ioAUaE5R}'
 else
  echo ${bashlyk_foResult_ioAUaE5R}
 fi
 return $?
}
#******
#****f* bashlyk/libstd/udfMakeTempV
#  SYNOPSIS
#    udfMakeTempV <var> [file|dir|keep|keepf[ile*]|keepd[ir]] [<prefix>]
#  DESCRIPTION
#    Создание временного файла или каталога с автоматическим удалением
#    по завершению сценария
#  INPUTS
#    var        - переменная (без $) для имени временного объекта
#    file       - создавать файл (по умолчанию)
#    dir        - создавать каталог
#    keep[file] - не включать автоматическое удаление временного файла
#    keepdir    - не включать автоматическое удаление временного каталога
#    prefix     - префикс имени временного файла
#  RETURN VALUE
#    255 - аргумент не задан
#      1 - ошибка идентификатора для временного объекта
#      0 - Выполнено успешно
#  EXAMPLE
#    udfMakeTempV pathTmp keepdir temp
#    присваивает значение вида "temp<8 символов>" переменной $pathTmp и создаёт 
#    соответствующий временный каталог, который не будет удаляться по завершении
#    сценария автоматически
#    udfMakeTempV fnTmp $(date +%s)-
#    присваивает значение вида "<секунды эпохи>-<8 симолов>" переменной $fnTmp и
#    создаёт соответствующий временный файл, который может быть удалён по 
#    завершении сценария автоматически
#  SOURCE
udfMakeTempV() {
 [ -n "$1" ] || return 255
 udfIsValidVariable "$1" \
  || udfThrow "Error: required valid variable name \"$1\""

 local bashlyk_foResult_bPfWZngu bashlyk_sDir_bPfWZngu bashlyk_bKeep_bPfWZngu
 local bashlyk_pathTmp_bPfWZngu bashlyk_sPrefix_bPfWZngu
 #
 bashlyk_sDir_bPfWZngu=''
 bashlyk_bKeep_bPfWZngu=0
 #
 [ -n "$3" ] && bashlyk_sPrefix_bPfWZngu="$3"
 case "$2" in 
          dir) bashlyk_sDir_bPfWZngu='-d' ;;
  keep|keepf*) bashlyk_bKeep_bPfWZngu=1;;
       keepd*) bashlyk_bKeep_bPfWZngu=1; bashlyk_sDir_bPfWZngu="-d";;
            *) bashlyk_sPrefix_bPfWZngu="$2";;
 esac
 if [ -d "$bashlyk_sPrefix_bPfWZngu" ]; then
  TMPDIR=$bashlyk_sPrefix_bPfWZngu
  bashlyk_sPrefix_bPfWZngu=$(basename $bashlyk_sPrefix_bPfWZngu)
  bashlyk_pathTmp_bPfWZngu=TMPDIR
 fi
 bashlyk_foResult_bPfWZngu=$(mktemp $bashlyk_sDir_bPfWZngu -q \
  -t "${bashlyk_sPrefix_bPfWZngu}XXXXXXXX") || udfThrow \
   "Error: temporary file object $bashlyk_foResult_bPfWZngu do not created..."
 TMPDIR=bashlyk_pathTmp_bPfWZngu
 if [ $bashlyk_bKeep_bPfWZngu -eq 0 ]; then
  [ -f $bashlyk_foResult_bPfWZngu ] \
   && udfAddFile2Clean $bashlyk_foResult_bPfWZngu
  [ -d $bashlyk_foResult_bPfWZngu ] \
   && udfAddPath2Clean $bashlyk_foResult_bPfWZngu
 fi
 eval 'export ${1}=${bashlyk_foResult_bPfWZngu}' 2>/dev/null
 return $?
}
#******
#****f* bashlyk/libstd/udfShellExec
#  SYNOPSIS
#    udfShellExec args
#  DESCRIPTION
#    Выполнение командной строки во внешнем временном файле
#    в текущей среде интерпретатора оболочки
#  INPUTS
#    args - командная строка
#  RETURN VALUE
#    255 - аргумент не задан
#    в остальных случаях код возврата командной строки с учетом доступа к временному файлу
#  EXAMPLE
#    [ -n "$preExec" ] && udfShellExec $preExec
#    Если переменная $preExec не пуста, то записать его значение во временный файл
#    и выполнить его
#  SOURCE
udfShellExec() {
 [ -n "$*" ] || return 255
 local fn rc
 udfMakeTemp fn
 echo $* > $fn
 . $fn
 rc=$?
 rm -f $fn
 return $rc
}
#******
#****f* bashlyk/libstd/udfAddFile2Clean
#  SYNOPSIS
#    udfAddFile2Clean args
#  DESCRIPTION
#    Добавляет имена файлов к списку удаляемых при завершении сценария
#    Предназначен для удаления временных файлов.
#  INPUTS
#    args - имена файлов
#  SOURCE
udfAddFile2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_afnClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* bashlyk/libstd/udfAddPath2Clean
#  SYNOPSIS
#    udfAddPath2Clean args
#  DESCRIPTION
#    Добавляет имена каталогов к списку удаляемых при завершении сценария.
#    Предназначен для удаления временных каталогов (если они пустые).
#  INPUTS
#    args - имена каталогов
#  SOURCE
udfAddPath2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_apathClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* bashlyk/libstd/udfAddJob2Clean
#  SYNOPSIS
#    udfAddJob2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных заданий к списку удаляемых при
#    завершении сценария.
#  INPUTS
#    args - идентификаторы заданий
#  SOURCE
udfAddJob2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_ajobClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* bashlyk/libstd/udfAddPid2Clean
#  SYNOPSIS
#    udfAddPid2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных процессов к списку завершаемых при
#    завершении сценария.
#  INPUTS
#    args - идентификаторы процессов
#  SOURCE
udfAddPid2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_apidClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* bashlyk/libstd/udfCleanQueue
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
#****f* bashlyk/libstd/udfOnTrap
#  SYNOPSIS
#    udfOnTrap
#  DESCRIPTION
#    Процедура очистки при завершении вызвавшего сценария.
#    Предназначен только для вызова командой trap.
#    * Производится удаление файлов и пустых каталогов; заданий и процессов,
#    указанных в соответствующих глобальных переменных
#    * Закрывается сокет журнала сценария, если он использовался.
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
   [ -n "$(ps -o pid= --ppid $$ | xargs | grep -w $s)" ] && {
    kill -${i} $s 2>/dev/null
    sleep 0.2
   }
  done
 done
 #
 for s in ${_bashlyk_afnClean}; do
  rm -f $s
 done
 #
 for s in ${_bashlyk_apathClean}; do
  rmdir $s 2>/dev/null
 done
 #
 [ -n "${_bashlyk_pidLogSock}" ] && {
  exec >/dev/null 2>&1
  wait ${_bashlyk_pidLogSock}
 }
}
#******
#****f* bashlyk/libstd/_ARGUMENTS
#  SYNOPSIS
#    _ARGUMENTS [args]
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_sArg -
#    командная строка сценария
#  INPUTS
#    args - новая командная строка
#  OUTPUT
#    Вывод значения переменной $_bashlyk_sArg
#  EXAMPLE
#    for arg in $(_ARGUMENTS); do ... done
#    Обработка аргументов командной строки
#  SOURCE
_ARGUMENTS() {
 [ -n "$1" ] && _bashlyk_sArg="$*" || echo ${_bashlyk_sArg}
}
#******
#****f* bashlyk/libstd/_s0
#  SYNOPSIS
#    _s0
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_s0 -
#    короткое имя сценария
#  OUTPUT
#    Вывод значения переменной $_bashlyk_s0
#  EXAMPLE
#    echo "Usage: $(_s0) ..."
#    Вставить в вывод короткое имя сценария
#  SOURCE
_s0() {
 [ -n "$1" ] && _bashlyk_s0="$*" || echo ${_bashlyk_s0}
}
#******

