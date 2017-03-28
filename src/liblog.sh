#
# $Id: liblog.sh 717 2017-03-28 16:49:13+04:00 toor $
#
#****h* BASHLYK/liblog
#  DESCRIPTION
#    The library contains a set of functions for controlling the output of the
#    script messages
#  USES
#    libstd libmsg
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* liblog/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBLOG provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBLOG" ] && return 0 || _BASHLYK_LIBLOG=1
[ -n "$_BASHLYK" ] || . bashlyk || eval '                                      \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* liblog/Used libraries
#  DESCRIPTION
#    Loading external libraries
#  SOURCE
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libmsg.sh ]] && . "${_bashlyk_pathLib}/libmsg.sh"
#******
#****G* liblog/Global variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
#: ${_bashlyk_fnLogSock:=}
#: ${_bashlyk_pidLogSock:=}
: ${HOSTNAME:=localhost}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_fnLog:="${_bashlyk_pathLog}/${_bashlyk_s0}.log"}
: ${_bashlyk_bUseSyslog:=0}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_sCond4Log:=redirect}

declare -rg _bashlyk_aRequiredCmd_log="                                        \
                                                                               \
    hostname logger mkdir mkfifo rm touch tty                                  \
                                                                               \
"

declare -rg _bashlyk_aExport_log="                                             \
                                                                               \
    udfCheck4LogUse udfDebug udfLog udfLogger udfSetLog                        \
    udfSetLogSocket udfIsTerminal udfIsInteract _fnLog                         \
                                                                               \
"
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

  local bSysLog bUseLog sTagLog IFS=$' \t\n'

  bSysLog=0
  bUseLog=0

  sTagLog="${_bashlyk_s0}[$(printf -- "%05d" $$)]"

  if [[ -z "$_bashlyk_bUseSyslog" || "$_bashlyk_bUseSyslog" -eq 0 ]]; then

    bSysLog=0

  else

    bSysLog=1

  fi

  if [[ $_bashlyk_bNotUseLog ]]; then

    (( $_bashlyk_bNotUseLog != 0 )) && bUseLog=0 || bUseLog=1

  else

    udfCheck4LogUse && bUseLog=1 || bUseLog=0

  fi

  mkdir -p "$_bashlyk_pathLog" \
    || eval $( udfOnError throw NotExistNotCreated "${_bashlyk_pathLog}" )

  udfAddPath2Clean $_bashlyk_pathLog

  case "${bSysLog}${bUseLog}" in

    00)
        echo "$@"
     ;;

    01)
        udfTimeStamp "$HOSTNAME $sTagLog: ${*//%/%%}" >> $_bashlyk_fnLog
     ;;

    10)
        echo "$*"
        logger -t "$sTagLog" "$*"
     ;;

    11)
        udfTimeStamp "$HOSTNAME $sTagLog: ${*//%/%%}" >> $_bashlyk_fnLog
        logger -t "$sTagLog" "$*"
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
#    echo -n . | udfLog -                                  >| grep '^\.$'       #? true
#    echo test | udfLog - tag                              >| grep '^tag test$' #? true
#  SOURCE
udfLog() {

  local s

  if [[ "$1" == "-" ]]; then

    shift
    [[ $* ]] && s="$* "

    while IFS= read -d '' || [[ $REPLY ]]; do udfLogger "${s}${REPLY}"; done

  else

    [[ $* ]] && udfLogger "$*"

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

  [[ -t 1 && -t 0 && $TERM && "$TERM" != "dumb" ]] \
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
#    _bashlyk_sCond4Log='redirect'
#    udfCheck4LogUse                                                            #? true
#    udfCheck4LogUse                                                            #= false
#  SOURCE
udfCheck4LogUse() {

  udfIsTerminal
  udfIsInteract

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
#****f* liblog/udfSetLogSocket
#  SYNOPSIS
#    udfSetLogSocket
#  DESCRIPTION
#    Установка механизма ведения лога согласно ранее установленных условий.
#    Используется специальный сокет для того чтобы отмечать тегами строки
#    журнала.
#  ERRORS
#     1                  - Сокет не создан, но стандартный вывод
#                          перенаправляется в файл лога (без тегирования)
#     NotExistNotCreated - Каталог для сокета не существует и не может
#                          быть создан
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)               #? true
#    _ fnLog $fnLog                                                             #? true
#    udfSetLogSocket                                                            #? true
#    ls -l $fnLog                                                               #? true
#    rm -f $fnLog
#  SOURCE
udfSetLogSocket() {

  local fnSock IFS=$' \t\n'

  if [[ $_bashlyk_sArg ]]; then

    fnSock="$(udfGetMd5 ${_bashlyk_s0} ${_bashlyk_sArg}).${$}.socket"
    fnSock="${_bashlyk_pathRun}/${fnSock}"

  else

    fnSock="${_bashlyk_pathRun}/${_bashlyk_s0}.${$}.socket"

  fi

  mkdir -p ${_bashlyk_pathRun} \
    || eval $( udfOnError retwarn NotExistNotCreated "${_bashlyk_pathRun}" )

  [[ -a "$fnSock" ]] && rm -f $fnSock

  if mkfifo -m 0600 $fnSock >/dev/null 2>&1; then

    ( udfLog - < $fnSock )&
    _bashlyk_pidLogSock=$!
    exec >>$fnSock 2>&1

  else

    udfWarn "Warn: Socket $fnSock not created..."

    exec >>$_bashlyk_fnLog 2>&1

    _bashlyk_fnLogSock=$_bashlyk_fnLog

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
#  ERRORS
#     NotExistNotCreated - файл лога создать не удается, аварийное завершение
#                          сценария
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)               #? true
#    rm -f $fnLog
#    udfSetLog $fnLog                                                           #? true
#    ls -l $fnLog                                                               #? true
#    rm -f $fnLog
#  SOURCE
udfSetLog() {
  local IFS=$' \t\n'

  case "$1" in
          '') ;;
    ${1##*/}) _bashlyk_fnLog="${_bashlyk_pathLog}/$1";;
           *)
              _bashlyk_fnLog="$1"
              _bashlyk_pathLog=${_bashlyk_fnLog%/*}
           ;;
  esac

  mkdir -p "$_bashlyk_pathLog" \
    || eval $(udfOnError throw NotExistNotCreated "$_bashlyk_pathLog")

  touch "$_bashlyk_fnLog" \
    || eval $(udfOnError throw NotExistNotCreated "$_bashlyk_fnLog")

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

  [[ $1 ]] && udfSetLog "$1" || _ fnLog

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
#    0               - уровень "level" не больше DEBUGLEVEL
#    1               - уровень "level"    больше DEBUGLEVEL
#    MissingArgument - аргументы отсутствуют
#  EXAMPLE
#    DEBUGLEVEL=0
#    udfDebug                                                                   #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfDebug 0 echo level 0                                                    #? true
#    udfDebug 1 silence level 0                                                 #? 1
#    DEBUGLEVEL=5
#    udfDebug 0 echo level 5                                                    #? true
#    udfDebug 6 echo 5                                                          #? 1
#    udfDebug non valid test level 5                                            #? true
#  SOURCE
udfDebug() {

  local i re='^[0-9]+$' IFS=$' \t\n'

  [[ $* ]] && i=$1 || eval $(udfOnError return MissingArgument)
  shift

  [[ "$i" =~ ^[0-9]+$ ]]  || i=0
  (( $DEBUGLEVEL >= $i )) || return 1
  [[ $* ]] && echo "$*" >&2

  return 0

}
#******
