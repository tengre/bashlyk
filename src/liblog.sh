#
# $Id$
#
#****h* BASHLYK/liblog
#  DESCRIPTION
#    Функции определения или задания режима работы рабочего сценария,
#    автоматического создания журнала для сохранения потоков вывода сообщений,
#    управление уровнем вывода сообщений.
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* liblog/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$_BASHLYK_LIBLOG" ] && return 0 || _BASHLYK_LIBLOG=1
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
#******
#****** liblog/External modules
#  DESCRIPTION
#    Using modules section
#    Здесь указываются модули, код которых используется данной библиотекой
#  SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/libstd.sh" ] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****v* liblog/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${HOSTNAME:=$(hostname)}
: ${DEBUGLEVEL:=0}
: ${_bashlyk_pathLog:=/tmp}
: ${_bashlyk_s0:=$(basename $0)}
: ${_bashlyk_sId:=$(basename $0 .sh)}
: ${_bashlyk_pathRun:=/tmp}
: ${_bashlyk_pidLogSock:=}
: ${_bashlyk_fnLogSock:=}
: ${_bashlyk_iStartTimeStamp:=$(date "+%s")}
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_fnLog:="${_bashlyk_pathLog}/${_bashlyk_s0}.log"}
: ${_bashlyk_bUseSyslog:=0}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_sCond4Log:=redirect}
: ${_bashlyk_aRequiredCmd_log:="basename date echo hostname false printf logger\
  mail mkfifo sleep tee true jobs ["}
: ${_bashlyk_aExport_log:="udfLogger udfLog udfIsInteract udfIsTerminal _fnLog \
  udfCheck4LogUse udfFinally udfSetLogSocket udfSetLog  udfUptime udfDebug"}
#******
#****f* liblog/udfLogger
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
#  EXAMPLE
#    # TODO восстанавливать значения системных переменных _bashlyk_*
#    local bInteract bNotUseLog bTerminal
#    _ =bInteract
#    _ =bNotUseLog
#    _ =bTerminal
#    local fnExec=$(mktemp --suffix=.sh || tempfile -s .test.sh)                #? true
#    cat <<'EOF' > $fnExec                                                      #-
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)               #-
#    _ fnLog $fnLog                                                             #-
#    _ bInteract 0                                                              #-
#    _ bNotUseLog 0                                                             #-
#    _ bTerminal 0                                                              #-
#    udfSetLogSocket                                                            #-
#    _ fnLog                                                                    #-
#    udfLogger test                                                             #-
#    date                                                                       #-
#    echo $_bashlyk_pidLogSock                                                  #-
#    EOF                                                                        #-
#    . $fnExec
#    kill $_bashlyk_pidLogSock
#    rm -f $_bashlyk_fnLogSock
#    sleep 0.5                                                                  #? true
#    sleep 0.4                                                                  #? true
#    sleep 0.3                                                                  #? true
#    sleep 0.2                                                                  #? true
#    sleep 0.1                                                                  #? true
#    cat $fnLog
#    rm -f $fnExec $fnLog
#    _ bInteract "$bInteract"
#    _ bNotUseLog "$bNotUseLog"
#    _ bTerminal "$bTerminal"
#  SOURCE
udfLogger() {
 local bSysLog bUseLog sTagLog
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
   udfTimeStamp "$HOSTNAME $sTagLog: $*" >> ${_bashlyk_fnLog}
  ;;
  10)
   echo "$*"
   logger -s -t "$sTagLog" "$*" 2>/dev/null
  ;;
  11)
   udfTimeStamp "$HOSTNAME $sTagLog: $*" >> ${_bashlyk_fnLog}
   logger -s -t "$sTagLog" "$*" 2>/dev/null
  ;;
 esac
}
#******
#****f* liblog/udfLog
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
#  EXAMPLE
#    # TODO улучшить тест
#    echo -n . | udfLog -                                                       #-
#    echo test | udfLog - tag >| grep "tag test"                                #? true
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
#****f* liblog/udfIsInteract
#  SYNOPSIS
#    udfIsInteract
#  DESCRIPTION
#    Проверка режима работы устройств стандартного ввода и вывода
#  RETURN VALUE
#    0 - "неинтерактивный" режим, имеется перенаправление стандартных ввода
#        и/или вывода
#    1 - "интерактивный" режим, перенаправление стандартных ввода и/или вывода
#        не обнаружено
#  EXAMPLE
#    udfIsInteract                                                              #? true
#    udfIsInteract                                                              #= false
#  SOURCE
udfIsInteract() {
 [ -t 1 -a -t 0 ] && [ -n "$TERM" ] && [ "$TERM" != "dumb" ] \
  && _bashlyk_bInteract=1 || _bashlyk_bInteract=0
 return $_bashlyk_bInteract
}
#******
#****f* liblog/udfIsTerminal
#  SYNOPSIS
#    udfIsTerminal
#  DESCRIPTION
#    Проверка наличия управляющего терминала
#  RETURN VALUE
#    0 - терминал отсутствует
#    1 - терминал обнаружен
#  EXAMPLE
#    udfIsTerminal                                                              #? false
#    udfIsTerminal                                                              #= false
#  SOURCE
udfIsTerminal() {
 tty > /dev/null 2>&1 && _bashlyk_bTerminal=1 || _bashlyk_bTerminal=0
 return $_bashlyk_bTerminal
}
#******
#****f* liblog/udfCheck4LogUse
#  SYNOPSIS
#    udfCheck4LogUse
#  DESCRIPTION
#    Проверка условий использования лог-файла
#  RETURN VALUE
#    0 - вести запись лог-файла
#    1 - не требуется
#  EXAMPLE
#    udfCheck4LogUse                                                            #? true
#    udfCheck4LogUse                                                            #= false
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
#****f* liblog/udfUptime
#  SYNOPSIS
#    udfUptime args
#  DESCRIPTION
#    Подсчёт количества секунд, прошедших с момента запуска сценария
#  INPUTS
#    args - префикс для выводимого сообщения о прошедших секундах
#  EXAMPLE
#    udfUptime test >| grep "test (.* sec)"                                     #? true
#  SOURCE
udfUptime() {
 local iDiffTime=$(($(date "+%s")-${_bashlyk_iStartTimeStamp}))
 [ -n "$1" ] && echo "$* ($iDiffTime sec)" || echo $iDiffTime
}
#******
#****f* liblog/udfFinally
#  SYNOPSIS
#    udfFinally args
#  DESCRIPTION
#    Псевдоним для udfUptime (Устаревшее)
#  INPUTS
#    args - префикс для выводимого сообщения о прошедших секундах
#  EXAMPLE
#    udfFinally test >| grep "test (.* sec)"                                    #? true
#  SOURCE
udfFinally() {
 udfUptime $*
}
#******
#****f* liblog/udfSetLogSocket
#  SYNOPSIS
#    udfSetLogSocket
#  DESCRIPTION
#    Установка механизма ведения лога согласно ранее установленных условий.
#    Используется специальный сокет для того чтобы отмечать тегами строки
#    журнала.
#  Return VALUE
#     0   - Выполнено
#     1   - Сокет не создан, но стандартный вывод перенаправляется в файл лога
#           (без тегирования)
#     255 - Каталог для сокета не существует и не может быть создан
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)               #? true
#    _ fnLog $fnLog                                                             #? true
#    udfSetLogSocket                                                            #? true
#    ls -l $fnLog                                                               #? true
#    rm -f $fnLog
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
#****f* liblog/udfSetLog
#  SYNOPSIS
#    udfSetLog [arg]
#  DESCRIPTION
#    Установка файла лога
#  RETURN VALUE
#     0   - Выполнено
#     255   - невозможно использовать файл лога, аварийное завершение сценария
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)               #? true
#    rm -f $fnLog
#    udfSetLog $fnLog                                                           #? true
#    ls -l $fnLog                                                               #? true
#    rm -f $fnLog
#  SOURCE
udfSetLog() {
 case "$1" in
        '') ;;
  ${1##*/}) _bashlyk_fnLog="${_bashlyk_pathLog}/$1";;
         *)
            _bashlyk_fnLog="$1"
            _bashlyk_pathLog=$(dirname ${_bashlyk_fnLog})
         ;;
 esac
 [ -d "${_bashlyk_pathLog}" ] || mkdir -p "${_bashlyk_pathLog}" \
  || udfThrow "Error: cannot create path ${_bashlyk_pathLog}"
 touch "${_bashlyk_fnLog}" || udfThrow "Error: ${_bashlyk_fnLog} not usable for logging"
 udfSetLogSocket
 return 0
}
#******
#****f* liblog/_fnLog
#  SYNOPSIS
#    _fnLog
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_fnLog -
#    полное имя лог-файла
#  OUTPUT
#    Вывод значения переменной $_bashlyk_fnLog
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)               #? true
#    rm -f $fnLog
#    _fnLog $fnLog                                                              #? true
#    ls -l $fnLog                                                               #? true
#    rm -f $fnLog
#  SOURCE
_fnLog() {
 if [ -n "$1" ]; then
  udfSetLog "$1"
 else
  echo ${_bashlyk_fnLog}
 fi
}
#******
#****f* liblog/udfDebug
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
#    0 - уровень "level" не больше значения глобальной переменной DEBUGLEVEL
#    1 - уровень "level" больше значения глобальной переменной DEBUGLEVEL
#    2 - аргументы отсутствуют
#  EXAMPLE
#    DEBUGLEVEL=0
#    udfDebug                                                                   #? 2
#    udfDebug 0 echo level 0                                                    #? true
#    udfDebug 1 silence level 0                                                 #? 1
#    DEBUGLEVEL=5
#    udfDebug 0 echo level 5                                                    #? true
#    udfDebug 6 echo 5                                                          #? 1
#    udfDebug non valid test level 5                                            #? true
#  SOURCE
udfDebug() {
 local i re='^[0-9]+$'
 [ -n "$*" ] && i=$1 || return 2
 shift
 echo $i | grep -E $re >/dev/null 2>&1 || i=0
 [ $DEBUGLEVEL -ge $i ] || return 1
 [ -n "$*" ] && echo "$*"
 return 0
}
#******
