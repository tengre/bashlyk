#!/bin/bash
#
# $Id$
#
#****h* bashlyk/liblog
#  DESCRIPTION
#    bashlyk Log library
#    Функции определения режима вывода, ведения логов
#    отправки предупреждений, сообщений об ошибках
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/liblog/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#  SOURCE
[ -n "$_BASHLYK_LIBLOG" ] && return 0 || _BASHLYK_LIBLOG=1
#******
#****** bashlyk/liblog/External modules
#  DESCRIPTION
#    Using modules section
#    Здесь указываются модули, код которых используется данной библиотекой
#  SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/libstd.sh" ] && . "${_bashlyk_pathLib}/libstd.sh"
[ -s "${_bashlyk_pathLib}/libmd5.sh" ] && . "${_bashlyk_pathLib}/libmd5.sh"
#******
#****v*  bashlyk/liblog/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${HOSTNAME:=$(hostname)}
: ${DEBUGLEVEL:=0}
: ${_bashlyk_afnClean:=}
: ${_bashlyk_apathClean:=}
: ${_bashlyk_ajobClean:=}
: ${_bashlyk_apidClean:=}
: ${_bashlyk_bUseSyslog:=0}
: ${_bashlyk_bNotUseLog:=}
: ${_bashlyk_pathLog:=/tmp}
: ${_bashlyk_s0:=$(basename $0)}
: ${_bashlyk_sId:=$(basename $0 .sh)}
: ${_bashlyk_pathRun:=/tmp}
: ${_bashlyk_pathDat:=/tmp}
: ${_bashlyk_pidLogSock:=}
: ${_bashlyk_fnLogSock:=}
: ${_bashlyk_iStartTimeStamp:=$(date "+%s")}
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_fnLog:="${_bashlyk_pathLog}/${_bashlyk_s0}.log"}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_aRequiredCmd_log:="basename date echo hostname false printf logger mail mkfifo sleep tee true jobs ["}
#******
#****f* bashlyk/liblog/udfLogger
#  SYNOPSIS
#    udfLogger args
#  DESCRIPTION
#    Селектор вывода строки аргументов в зависимости от режима работы.
#  INPUTS
#    args - строка для вывода
#  OUTPUT
#    Возможны четыре варианта:
#     * Вывод только на консоль терминала
#     * Вывод только в файл $_bashlyk_fnLog
#     * Вывод в системный журнал (syslog) и на консоль терминала
#     * Вывод в системный журнал (syslog) и в файл $_bashlyk_fnLog
#  SOURCE
udfLogger() {
 local envLang bSysLog bUseLog sTagLog
 envLang=$LANG
 LANG=C
 bSysLog=0
 bUseLog=0
 sTagLog="${_bashlyk_s0}[$(printf "%05d" $$)]"
 [ -z "$_bashlyk_bUseSyslog" -o ${_bashlyk_bUseSyslog} -eq 0 ] \
  && bSysLog=0 || bSysLog=1
 if [ -z "$_bashlyk_bNotUseLog" ]; then
  udfCheck4LogUse && bUseLog=1 || bUseLog=0
 else
  [ ${_bashlyk_bNotUseLog} -ne 0 ] && bUseLog=0 || bUseLog=1
 fi
 [ -d "${_bashlyk_pathLog}" ] || mkdir -p "${_bashlyk_pathLog}" \
  || udfThrow "Error: do not create path ${_bashlyk_pathLog}"
 udfAddPath2Clean ${_bashlyk_pathLog}
 case "${bSysLog}${bUseLog}" in
  00)
   echo "$*"
  ;;
  01)
   echo "$(udfDate "$HOSTNAME $sTagLog: $*")" >> ${_bashlyk_fnLog}
  ;;
  10)
   echo "$*"
   logger -s -t "$sTagLog" "$*" 2>/dev/null
  ;;
  11)
   echo "$(udfDate "$HOSTNAME $sTagLog: $*")" >> ${_bashlyk_fnLog}
   logger -s -t "$sTagLog" "$*" 2>/dev/null
  ;;
 esac
 LANG=$envLang
}
#******
#****f* bashlyk/liblog/udfLog
#  SYNOPSIS
#    udfLog [-] args
#  DESCRIPTION
#    Передача данных селектору вывода udfLogger
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то строка считается префиксом (тэгом) для каждой строки
#           из стандартного ввода
#  OUTPUT
#   Зависит от параметров вывода
#  SOURCE
udfLog() {
 if [ "$1" = "-" ]; then
  shift
  local s sPrefix
  [ -n "$*" ] && sPrefix="$* " || sPrefix=
  while read s; do [ -n "$s" ] && udfLogger "${sPrefix}${s}"; done
 else
  [ -n "$*" ] && udfLogger "$*"
 fi
}
#******
#****f* bashlyk/liblog/udfEcho
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
#****f* bashlyk/liblog/udfMail
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
 udfMakeTempV fnTmp
 udfEcho "$*" | tee -a $fnTmp
 cat $fnTmp | mail -e -s "${_bashlyk_emailSubj}" ${_bashlyk_emailRcpt}
 rm -f $fnTmp
}
#******
#****f* bashlyk/liblog/udfWarn
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
#****f* bashlyk/liblog/udfThrow
#  SYNOPSIS
#    udfThrow [-] args
#  DESCRIPTION
#    Вывод аварийного сообщения с завершением работы. Если терминал отсутствует, то
#    сообщение передается по почте.
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
#****f* bashlyk/liblog/udfIsInteract
#  SYNOPSIS
#    udfIsInteract
#  DESCRIPTION
#    Проверка режима работы устройств стандартного ввода и вывода
#  RETURN VALUE
#    0 - "неинтерактивный" режим, имеется перенаправление стандартных ввода и/или вывода
#    1 - "интерактивный" режим, перенаправление стандартных ввода и/или вывода не обнаружено
#  SOURCE
udfIsInteract() {
 [ -t 1 -a -t 0 ] && [ -n "$TERM" ] && [ "$TERM" != "dumb" ] \
  && _bashlyk_bInteract=1 || _bashlyk_bInteract=0
 return $_bashlyk_bInteract
}
#******
#****f* bashlyk/liblog/udfIsTerminal
#  SYNOPSIS
#    udfIsTerminal
#  DESCRIPTION
#    Проверка наличия управляющего терминала
#  RETURN VALUE
#    0 - терминал отсутствует
#    1 - терминал обнаружен
#  SOURCE
udfIsTerminal() {
 tty > /dev/null 2>&1 && _bashlyk_bTerminal=1 || _bashlyk_bTerminal=0
 return $_bashlyk_bTerminal
}
#******
#****f* bashlyk/liblog/udfCheck4LogUse
#  SYNOPSIS
#    udfCheck4LogUse
#  DESCRIPTION
#    Проверка условий использования лог-файла
#  RETURN VALUE
#    0 - не требуется
#    1 - вести запись лог-файла
#  SOURCE
udfCheck4LogUse() {
 udfIsTerminal
 udfIsInteract
 #
 case ${_bashlyk_sCond4Log} in
  redirect)
           _bashlyk_bNotUseLog=$_bashlyk_bInteract ;;
    noterm)
           _bashlyk_bNotUseLog=$_bashlyk_bTerminal ;;
         *)
           _bashlyk_bNotUseLog=$_bashlyk_bInteract ;;
 esac
 return $_bashlyk_bNotUseLog
}
#******
#****f* bashlyk/liblog/udfOnTrap
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
#****f* bashlyk/liblog/udfAddFile2Clean
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
#****f* bashlyk/liblog/udfAddPath2Clean
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
#****f* bashlyk/liblog/udfAddJob2Clean
#  SYNOPSIS
#    udfAddJob2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных заданий к списку удаляемых при завершении сценария.
#  INPUTS
#    args - идентификаторы заданий
#  SOURCE
udfAddJob2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_ajobClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* bashlyk/liblog/udfAddPid2Clean
#  SYNOPSIS
#    udfAddPid2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных процессов к списку завершаемых при завершении сценария.
#  INPUTS
#    args - идентификаторы процессов
#  SOURCE
udfAddPid2Clean() {
 [ -n "$1" ] || return 0
 _bashlyk_apidClean+=" $*"
 trap "udfOnTrap" 0 1 2 5 15
}
#******
#****f* bashlyk/liblog/udfCleanQueue
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
#****f* bashlyk/liblog/udfUptime
#  SYNOPSIS
#    udfUptime args
#  DESCRIPTION
#    Подсчёт количества секунд, прошедших с момента запуска сценария
#  INPUTS
#    args - префикс для выводимого сообщения о прошедших секундах
#  SOURCE
udfUptime() {
 local iDiffTime=$(($(date "+%s")-${_bashlyk_iStartTimeStamp}))
 [ -n "$1" ] && echo "$* ($iDiffTime sec)" || echo $iDiffTime
}
#******
#****f* bashlyk/liblog/udfFinally
#  SYNOPSIS
#    udfFinally args
#  DESCRIPTION
#    Псевдоним для udfUptime (Устаревшее)
#  INPUTS
#    args - префикс для выводимого сообщения о прошедших секундах
#  SOURCE
udfFinally() {
 udfUptime $*
}
#******
#****f* bashlyk/liblog/udfSetLogSocket
#  SYNOPSIS
#    udfSetLogSocket
#  DESCRIPTION
#    Установка механизма ведения лога согласно ранее установленных условий.
#    Используется специальный сокет для того чтобы отмечать тегами строки журнала.
#  Return VALUE
#     0   - Выполнено
#     1   - Сокет не создан, но стандартный вывод перенаправляется в файл лога (без тегирования)
#     255 - Каталог для сокета не существует и не может быть создан
#  SOURCE
udfSetLogSocket() {
 local fnSock
 [ -n "$_bashlyk_sArg" ] \
  && fnSock="${_bashlyk_pathRun}/$(udfGetMd5 ${_bashlyk_s0} ${_bashlyk_sArg}).${$}.socket" \
  || fnSock="${_bashlyk_pathRun}/${_bashlyk_s0}.${$}.socket"
 mkdir -p ${_bashlyk_pathRun} \
  || eval 'udfWarn "Warn: path for Sockets ${_bashlyk_pathRun} not created..."; return 255'
 [ -a $fnSock ] && rm -f $fnSock
 if mkfifo -m 0600 $fnSock >/dev/null 2>&1; then
  ( udfLog - < $fnSock )&
  _bashlyk_pidLogSock=$!
  exec >>$fnSock 2>&1
 else
  udfWarn "Warn: Socket $fnSock not created..."
  exec >>$_bashlyk_fnLog 2>&1
  return 1
 fi
 _bashlyk_fnLogSock=$fnSock
 udfAddFile2Clean $fnSock
 return 0
}
#******
#****f* bashlyk/liblog/udfSetLog
#  SYNOPSIS
#    udfSetLog [arg]
#  DESCRIPTION
#    Установка файла лога
#  RETURN VALUE
#     0   - Выполнено
#     255 - невозможно использовать файл лога, аварийное завершение сценария
#  SOURCE
udfSetLog() {
 if [ -n "$1" ]; then
  if [ "$1" = "${1##*/}" ]; then
   _bashlyk_fnLog="${_bashlyk_pathLog}/$1"
  else
   _bashlyk_fnLog="$1"
   _bashlyk_pathLog=$(dirname ${_bashlyk_fnLog})
  fi
 fi
 [ -d "${_bashlyk_pathLog}" ] || mkdir -p "${_bashlyk_pathLog}" \
  || udfThrow "Error: do not create path ${_bashlyk_pathLog}"
 touch "${_bashlyk_fnLog}" || udfThrow "Error: ${_bashlyk_fnLog} not usable for logging"
 udfSetLogSocket
 return 0
}
#******
#****f* bashlyk/liblog/udfMakeTemp
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
 local bashlyk_s2jyV6IRNTtdBaql_fo optDir bNoKeep=true s sVar sCreateMode=direct
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
            local rc
            udfIsNumber "$2"
            rc=$?
            if [ -z "$3" -a -n "$2" -a $rc -eq 0 ]; then 
             # oldstyle
             octMode="$2"
            fi
            sVar="$1"
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
   [ -s "$octMode" ] && chmod $octMode $s
  ;;
    mktemp)
   [ -n "$path"    ] && path="-p $path"
   s=$(mktemp $path $optDir -t "${sPrefix}XXXXXXXX${sSuffix}")
   [ -s "$octMode" ] && chmod $octMode $s
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
 [ -s "$sUser"  ] && chown $sUser  $s
 [ -s "$sGroup" ] && chgrp $sGroup $s

 if   [ -f $s ]; then 
  $bNoKeep && udfAddFile2Clean $s
 elif [ -d $s ]; then
  $bNoKeep && udfAddPath2Clean $s
 else
  udfThrow "Error: temporary file object $s cannot created..."
 fi

 bashlyk_s2jyV6IRNTtdBaql_fo=$s
 if [ -n "$sVar" ]; then
  eval 'export ${sVar}=${bashlyk_s2jyV6IRNTtdBaql_fo}' 2>/dev/null
 else
  echo ${bashlyk_s2jyV6IRNTtdBaql_fo}
 fi
 return $?
}
#******
#****f* bashlyk/liblog/udfMakeTempV
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
#****f* bashlyk/liblog/udfShellExec
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
 fn=$(udfMakeTemp .shellexec)
 udfAddFile2Clean $fn
 echo $* > $fn
 . $fn
 rc=$?
 rm -f $fn
 return $rc
}
#******
#****f* bashlyk/liblog/_ARGUMENTS
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
#****f* bashlyk/liblog/_s0
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
#****f* bashlyk/liblog/_fnLog
#  SYNOPSIS
#    _fnLog
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_fnLog -
#    полное имя лог-файла
#  OUTPUT
#    Вывод значения переменной $_bashlyk_fnLog
#  EXAMPLE
#    stat $(_ARGUMENTS)
#    Вывести информацию о лог-файле
#  SOURCE
_fnLog() {
 [ -n "$1" ] && _bashlyk_fnLog=$1 || echo ${_bashlyk_fnLog}
}
#******
#****f* bashlyk/liblog/_pathDat
#  SYNOPSIS
#    _pathDat
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_pathDat - 
#    полное имя каталога данных сценария
#  OUTPUT
#    Вывод значения переменной $_bashlyk_pathDat
#  EXAMPLE
#    stat $(_pathDat)
#    Вывести информацию о каталоге данных сценария
#  SOURCE
_pathDat() {
 [ -n "$1" ] && _bashlyk_pathDat="$*" || echo ${_bashlyk_pathDat}
}
#******
#****f* bashlyk/liblog/udfDebug
#  SYNOPSIS
#    udfDebug level message
#  DESCRIPTION
#    Позволяет выводить сообщение, если его уровень не больше значения 
#    глобальной переменной DEBUGLEVEL
#  INPUTS
#    level   - уровень отладочных сообщений, десятичное число, если неправильно 
#    задан, то принимается значение 0
#    message - текст отладочного сообщения
#  OUTPUT
#    Текст отладочного сообщения (аргумент "message"), если его уровень 
#    (аргумент "level") не больше заданного для сценария переменной DEBUGLEVEL
#  RETURN VALUE
#    0 - уровень "level" не больше значению глобальной переменной DEBUGLEVEL
#    1 - уровень "level" больше значения глобальной переменной DEBUGLEVEL
#    2 - аргументы отсутствуют
#  SOURCE
udfDebug() {
 local i re='^[0-9]+$'
 [ -n "$*" ] && i=$1 || return 2
 shift
 [ -n "$(echo $i | grep -E $re)" ] || i=0
 [ $DEBUGLEVEL -ge $i ] || return 1
 [ -n "$*" ] && echo "$*"
 return 0
}
#******
#****u* bashlyk/liblog/udfLibLog
#  SYNOPSIS
#    udfLibLog
# DESCRIPTION
#   bashlyk LOG library test unit
#   Запуск проверочных операций модуля выполняется если только аргументы 
#   командной строки cодержат строку вида "--bashlyk-test=[.*,]log[,.*]",
#   где * - ярлыки на другие тестируемые библиотеки
#  SOURCE
udfLibLog() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -E -e "--bashlyk-test=.*log")" ] \
  && return 0
 local s pathLog fnLog emailRcpt emailSubj b=1 sS
 printf "\n- liblog.sh tests:\n\n"
 : ${_bashlyk_bInteract:=1}
 : ${_bashlyk_bTerminal:=1}
 : ${_bashlyk_bNotUseLog:=1}
 echo -n "Global variable testing: "
 for s in                \
  "$_bashlyk_bUseSyslog" \
  "$_bashlyk_pathLog"    \
  "$_bashlyk_fnLog"      \
  "$_bashlyk_emailRcpt"  \
  "$_bashlyk_emailSubj"  \
  "$_bashlyk_bTerminal"  \
  "$_bashlyk_pathDat"    \
  "$_bashlyk_bInteract"
  do
   [ -n "$s" ] && echo -n '.' || { echo -n '?'; b=0; }
 done
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 mkdir -p ${_bashlyk_pathDat}
 udfAddPath2Clean ${_bashlyk_pathDat} 2>/dev/null
 echo -n "function testing on control terminal: "
 _bashlyk_bTerminal=1
 _bashlyk_bNotUseLog=1
 b=1
 for s in udfLog udfUptime udfFinally udfWarn; do
  sS=$($s testing liblog $s)
  [ -n "$(echo "$sS" | grep "testing liblog $s")" ] && echo -n '.' || { echo -n '?'; b=0; }
 done

 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 echo "test without control terminal (cat $_bashlyk_fnLog ): "
 _bashlyk_bTerminal=0
 _bashlyk_bNotUseLog=0
 b=1
 udfSetLog 2>/dev/null && echo -n '.' || { echo -n '?'; b=0; }
 [ $b -eq 1 ] && {
  echo 'ok.'
  for s in udfLog udfUptime udfFinally udfWarn; do
   $s testing liblog $s; echo "return code ... $?"
  done
 } || echo 'fail.'
 _bashlyk_bTerminal=0
 _bashlyk_bUseSyslog=1
  echo "--- test without control terminal and syslog using: ---"
 for s in udfLog udfUptime udfFinally udfIsTerminal udfIsInteract udfWarn; do
  echo "--- check $s: ---"
  $s testing liblog $s; echo "return code ... $?"
 done
 _bashlyk_bTerminal=1
 for s in                             \
  bUseSyslog=$_bashlyk_bUseSyslog     \
  pathLog=$_bashlyk_pathLog           \
  fnLog=$_bashlyk_fnLog               \
  emailRcpt=$_bashlyk_emailRcpt       \
  emailSubj=$_bashlyk_emailSubj       \
  bTerminal=$_bashlyk_bTerminal       \
  bInteract=$_bashlyk_bInteract
  do
   echo "$s"
 done
 echo "--"
 return 0
}
#******
#****** bashlyk/liblog/Main section
# DESCRIPTION
#   Running LOG library test unit if $_bashlyk_sArg ($*) contains
#   substrings "--bashlyk-test=" and "log" - command for test using
#  SOURCE
udfLibLog
#******
