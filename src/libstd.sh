#!/bin/bash
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
#  SOURCE
[ -n "$_BASHLYK_LIBSTD" ] && return 0 || _BASHLYK_LIBSTD=1
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
: ${_bashlyk_aRequiredCmd_opt:="echo getopt grep mktemp tr sed umask ["}
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
#    Аргумент считается числом, если он содержит
#  INPUTS
#    number - проверяемое значение
#    tag    - набор символов, один из которых можно применить
#             после цифр для указания признака числа, например, 
#             порядка
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
#    выполнение: echo a___b______cd | udfWSpace2Alias -
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
#    udfMakeTemp [varname ] options...
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
#
#  EXAMPLE
#   udfMakeTemp fnTemp prefix=temp mode=0644 keep=true path=$HOME
#
#   pathTemp=$(udfMakeTemp path=/var/tmp/$USER)
#   udfAddPath2Clean $pathTemp
#
#  SOURCE
udfMakeTemp() {
 unset bashlyk_JtiMe1FiQYcdjOf1_fo
 local bashlyk_JtiMe1FiQYcdjOf1_fo optDir bNoKeep=true s sVar sCreateMode=direct 
 local path sPrefix sSuffix octMode sUser sGroup
 #
 for s in $*; do
  case "$s" in 
     path=*) path=${s#*=};;
   prefix=*) sPrefix=${s#*=};;
   suffix=*) sSuffix=${s#*=};;
     mode=*) octMode=${s#*=};;
    type=d*) optDir='-d';;
    type=f*) optDir='';;
     user=*) sUser=${s#*=};;
    group=*) sGroup=${s#*=};;
    keep=t*) bNoKeep=false;;
    keep=f*) bNoKeep=true;;
  varname=*) sVar=${s#*=};;
          *)
            sVar="$1"          
            local rc
            udfIsNumber "$2"
            rc=$?
            if [ -z "$3" -a -n "$2" -a $rc -eq 0 ]; then 
             # oldstyle
             octMode="$2"
             sVar=''
             sPrefix="$1"
            fi
          ;;
  esac
 done

 [ -n "$sVar" ] || bNoKeep=false
 
 if [ -f "$(which mktemp)" ]; then
  sCreateMode=mktemp
 elif [ -f "$(which tempfile)" ]; then
  [ -z "$optDir" ] && sCreateMode=tempfile || sCreateMode=direct
 fi
 
 case "$sCreateMode" in
    direct)
   [ -n "$path"    ] && s="${path}/" || s="/tmp/"
   s+="${sPrefix}${$}${sSuffix}"
   [ -n "$optDir"  ] && mkdir -p $s || touch $s
   [ -n "$octMode" ] && chmod $octMode $s
  ;;
    mktemp)
   [ -n "$path"    ] && path="-p $path"
   #s=$(mktemp $path $optDir -t "${sPrefix}XXXXXXXX${sSuffix}")
   s=$(mktemp $path $optDir -t "${sPrefix}${sSuffix}XXXXXXXX")
   [ -n "$octMode" ] && chmod $octMode $s
  ;;
  tempfile)
   [ -n "$sPrefix" ] && sPrefix="-p $sPrefix"
   [ -n "$sSuffix" ] && sSuffix="-s $sSuffix"
   s=$(tempfile $optDir $sPrefix $sSuffix) 
  ;;
  *)
   udfThrow "$0: Cannot create temporary file object.."                                                                                 
  ;;                                                                                                                      
 esac                                                                                                                        
 [ -n "$sUser"  ] && chown $sUser  $s
 [ -n "$sGroup" ] && chgrp $sGroup $s

 if   [ -f "$s" ]; then 
  $bNoKeep && udfAddFile2Clean $s
 elif [ -d "$s" ]; then
  $bNoKeep && udfAddPath2Clean $s
 else
  udfThrow "Error: temporary file object $s cannot created..."
 fi

 bashlyk_JtiMe1FiQYcdjOf1_fo=$s
 if [ -n "$sVar" ]; then
  eval 'export ${sVar}=${bashlyk_JtiMe1FiQYcdjOf1_fo}' 2>/dev/null
 else
  echo ${bashlyk_JtiMe1FiQYcdjOf1_fo}
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
 unset bashlyk_s2jyV6IRNTtdBaql_fo
 local bashlyk_s2jyV6IRNTtdBaql_fo sDir='' bKeep=0 pathTmp
 [ -n "$3" ] && sPrefix="$3"
 case "$2" in 
          dir) sDir='-d' ;;
  keep|keepf*) bKeep=1;;
       keepd*) bKeep=1; sDir="-d";;
            *) sPrefix="$2";;
 esac
 if [ -d "$sPrefix" ]; then
  TMPDIR=$sPrefix
  sPrefix=$(basename $sPrefix)
  pathTmp=TMPDIR
 fi
 bashlyk_s2jyV6IRNTtdBaql_fo=$(mktemp $sDir -q -t "${sPrefix}XXXXXXXX") || \
  udfThrow "Error: temporary file object $bashlyk_s2jyV6IRNTtdBaql_fo do not created..."
 TMPDIR=pathTmp
 if [ $bKeep -eq 0 ]; then
  [ -f $bashlyk_s2jyV6IRNTtdBaql_fo ] && udfAddFile2Clean $bashlyk_s2jyV6IRNTtdBaql_fo
  [ -d $bashlyk_s2jyV6IRNTtdBaql_fo ] && udfAddPath2Clean $bashlyk_s2jyV6IRNTtdBaql_fo
 fi
 eval 'export ${1}=${bashlyk_s2jyV6IRNTtdBaql_fo}' 2>/dev/null
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
#****u* bashlyk/libstd/udfLibStd
#  SYNOPSIS
#    udfLibStd
# DESCRIPTION
#   bashlyk STD library test unit
#   Запуск проверочных операций модуля выполняется если только аргументы 
#   командной строки cодержат строку вида "--bashlyk-test=[.*,]std[,.*]",
#   где * - ярлыки на другие тестируемые библиотеки
#  SOURCE
udfLibStd() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -E -e "--bashlyk-test=.*std")" ] \
  && return 0
 local s b=1 s0='' s1="test" fnTmp
 printf "\n- libstd.sh tests: "
 fnTmp=/tmp/$$.$(date +%s).tmp
 {
  udfIsNumber "$(date +%S)"      && echo -n '.' || { echo -n '?'; b=0; }
  udfIsNumber "$(date +%S)k" kMG && echo -n '.' || { echo -n '?'; b=0; }
  udfIsNumber "$(date +%S)M"     && { echo -n '?'; b=0; } || echo -n '.'
  udfIsNumber "$(date +%b)G" kMG && { echo -n '?'; b=0; } || echo -n '.'
  udfIsNumber "$(date +%b)"      && { echo -n '?'; b=0; } || echo -n '.'
 [ -n "$(udfShowVariable s1 | grep 's1=test')" ] && echo -n '.' || { echo -n '?'; b=0; }
  udfOnEmptyVariable Warn s0     && { echo -n '?'; b=0; } || echo -n '.' 
  udfOnEmptyVariable Warn s1     && echo -n '.' || { echo -n '?'; b=0; }
 } 2>/dev/null
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 echo "--"
 return 0
}
#******
#****** bashlyk/libstd/Main section
# DESCRIPTION
#   Running LOG library test unit if $_bashlyk_sArg ($*) contains
#   substrings "--bashlyk-test=" and "std" - command for test using
#  SOURCE
udfLibStd
#******

