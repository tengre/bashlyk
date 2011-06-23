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
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_iStartTimeStamp:=$(date "+%s")}
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_fnLog:="${_bashlyk_pathLog}/${_bashlyk_s0}.log"}
: ${_bashlyk_aRequiredCmd_log:="basename date echo hostname false printf logger \
 mail mkfifo sleep tee true jobs ["}
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
 local envLang=$LANG
 LANG=C
 local bSysLog=0
 local bUseLog=0
 local sTagLog="${_bashlyk_s0}[$(printf "%05d" $$)]"
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
 local fnTmp=$(udfMakeTemp)
 udfAddFile2Clean $fnTmp
 udfEcho $* | tee -a $fnTmp
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
 #echo "clean file ${_bashlyk_afnClean}"
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
  if [ "$1" = "$(basename $1)" ]; then
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
#    udfMakeTemp [<prefix>] [<mask>] [<owner[.group]>]
#  DESCRIPTION
#    Создание временного файла
#  INPUTS
#    prefix - префикс имени временного файла
#    mask   - маска прав на файл
#    owner  - владелец файла
#    group  - группа файла
#  OUTPUT
#    имя файла в виде [prefix].${_bashlyk_s0}.<8 символов>
#  EXAMPLE
#    fnTemp=$(udfMakeTemp temp)
#    присваивает значение вида "temp.<имя сценария>.<8 символов>" переменной $fnTemp
#    и создаёт соответствующий файл
#  SOURCE
udfMakeTemp() {
 local fn sMask
 [ -n "$2" ] && {
  sMask=$(umask)
  umask $2 >/dev/null 2>&1
 }
 fn=$(mktemp -q -t "${1}.${_bashlyk_s0}.XXXXXXXX") || \
  udfThrow "Error: temporary file $fn do not created..."
 {
  [ -n "$sMask" ] && umask $sMask
  [ -n "$3" ] && chown $3 $fn
 } >/dev/null 2>&1
 echo $fn
}
#******
#****f* bashlyk/liblog/udfMakeTempO
#  SYNOPSIS
#    udfMakeTempO [file|dir|persist|persistfile|persistdir] [<prefix>]
#  DESCRIPTION
#    Создание временного файла или каталога с автоматическим удалением
#    по завершению сценария
#  INPUTS
#    file     - создавать файл (по умолчанию)
#    dir      - создавать каталог
#    persist* - не включать автоматическое удаление
#    prefix   - префикс имени временного файла
#  OUTPUT
#    случайное слово в 8 символов
#  EXAMPLE
#    fnTemp=$(udfMakeTempO dir temp)
#    присваивает значение вида "temp<8 симолов>" переменной $fnTemp и создаёт 
#    соответствующий временный каталог
#  SOURCE
udfMakeTempO() {
 local fo sDir='' bPersist=0
 [ -n "$2" ] && sPrefix="$2"
 case "$1" in 
          dir) sDir='-d' ;;
      persist) bPersist=1;;
  persistfile) bPersist=1;;
   persistdir) bPersist=1; sDir="-d";;
            *) sPrefix="$1"
 esac
 fo=$(mktemp $sDir -q -t "${sPrefix}XXXXXXXX") || \
  udfThrow "Error: temporary file object $fo do not created..."
 if [ $bPersist -eq 0 ]; then
  [ -f $fo ] && udfAddFile2Clean $fo
  [ -d $fo ] && udfAddPath2Clean $fo
 fi
 echo $fo
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
 echo "$*"
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
 for s in udfLog udfUptime udfFinally udfWarn udfIsTerminal udfIsInteract; do
  echo "--- check $s: ---"
  $s testing liblog $s; echo "return code ... $?"
 done
 _bashlyk_bTerminal=1
 #udfOnTrap
 #exec >&1 2>&1
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
 printf "\n--\n\n"
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
