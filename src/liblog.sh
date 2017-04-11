#
# $Id: liblog.sh 727 2017-04-11 17:26:51+04:00 toor $
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
    udfCheck4LogUse udfDateR udfDebug udfFinally udfIsInteract udfIsTerminal   \
    udfLog udfLogger udfSetLog udfSetLogSocket udfTimeStamp udfUptime          \
                                                                               \
"
#******
#****f* liblog/udfLogger
#  SYNOPSIS
#    udfLogger <text>
#  DESCRIPTION
#    add <text> to log file with standart stamps if logging is setted
#  INPUTS
#    <text> - input text
#  OUTPUT
#    There are four possibilities:
#     * stdout only
#     * $_bashlyk_fnLog only
#     * syslog by logger and stdout
#     * syslog by logger and $_bashlyk_fnLog
#  EXAMPLE
#    local bInteract bNotUseLog bTerminal
#    _ =bInteract
#    _ =bNotUseLog
#    _ =bTerminal
#    local b=true fnExec reT reP s
#    fnExec=$(mktemp --suffix=.sh || tempfile -s .test.sh)
#    reT='[ADFJMNOS][abceglnoprtuyv]{2} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'
#    reP="[[:space:]]$HOSTNAME ${0##*/}\[[[:digit:]]{5}\]:[[:space:]].*"
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
#    sleep 0.1
#    while read -t9 s; do [[ $s =~ ^${reT}${reP}$ ]] || b=false; done < $fnLog  #-
#    [[ $b == true ]]                                                           #? true
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

  udfAddFO2Clean $_bashlyk_pathLog

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
#    udfLog [-] [<text>]
#  DESCRIPTION
#    Wrapper around udfLogger to support stream from standard input
#  INPUTS
#    -      - data is expected from standard input
#    <text> - String (tag) for output.
#             If there is a "-" as the first argument, then the string is
#             considered a prefix (tag) for each line from the standard input.
#  OUTPUT
#   Depends on output parameters
#  EXAMPLE
#    # TODO improved test
#    echo -n . | udfLog -                                  >| grep '^\.$'       #? true
#    echo test | udfLog - tag                              >| grep '^tag test$' #? true
#  SOURCE
udfLog() {

  local sTag s

  if [[ "$1" == "-" ]]; then

    shift
    [[ $* ]] && sTag="$* "

    while read s || [[ $s ]]; do [[ $s ]] && udfLogger "${sTag}${s}"; done

  else

    [[ $* ]] && udfLogger "$*"

  fi

}
#******
#****f* liblog/udfIsInteract
#  SYNOPSIS
#    udfIsInteract
#  DESCRIPTION
#    Checking the operating mode of standard input and output devices
#  RETURN VALUE
#    0 - "non-interactive" mode, there is redirection of standard input and/or
#         output
#    1 - "interactive" mode, redirection of standard input and/or output is not
#        detected
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
#    Checking the presence of a control terminal
#  RETURN VALUE
#    0 - terminal not detected
#    1 - terminal detected
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
#    Check the conditions for using the log file
#  RETURN VALUE
#    0 - save stdout and stderr to log file
#    1 - logging do not required
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
#    Creating a named pipe for redirecting the output of stdout and stderr to a
#     log file with automatic addition of standard stamps.
#  ERRORS
#     1                  - The socket is not created, but the output of the
#                          stdout and the stderr is redirected to the log file
#                          (without stamps)
#     NotExistNotCreated - The socket directory does not exist and can not be
#                          created
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)
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

    _bashlyk_fnLogSock=$fnSock
     udfAddFO2Clean $fnSock

     return 0

  else

    udfWarn "Warn: Socket $fnSock not created..."

    exec >>$_bashlyk_fnLog 2>&1

    _bashlyk_fnLogSock=$_bashlyk_fnLog

    return 1

  fi

}
#******
#****f* liblog/udfSetLog
#  SYNOPSIS
#    udfSetLog [<filename>]
#  DESCRIPTION
#    Wrapper around udfSetLogSocket to activate output redirection to the log
#    file with error handling
#  ERRORS
#     NotExistNotCreated - log file can not be created, abort
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)
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
#****f* liblog/udfDebug
#  SYNOPSIS
#    udfDebug <level> <message>
#  DESCRIPTION
#    show a <message> on stderr if the <level> is equal or less than the
#    $DEBUGLEVEL value otherwise return code 1
#  INPUTS
#    <level>   - decimal number of the debug level ( 0 for wrong argument)
#    <message> - debug message
#  OUTPUT
#    show a <message> on stderr
#  RETURN VALUE
#    0               - <level> equal or less than $DEBUGLEVEL value
#    1               - <level> more than $DEBUGLEVEL value
#    MissingArgument - no arguments
#  EXAMPLE
#    DEBUGLEVEL=0
#    udfDebug                                                                   #? $_bashlyk_iErrorMissingArgument
#    udfDebug 0 echo level 0                                                    #? true
#    udfDebug 1 silence level 0                                                 #? 1
#    DEBUGLEVEL=5
#    udfDebug 0 echo level 5                                                    #? true
#    udfDebug 6 echo 5                                                          #? 1
#    udfDebug default level test '(0)'                                          #? true
#  SOURCE
udfDebug() {

  udfOn MissingArgument $* || return

  if [[ $1 =~ ^[0-9]+$ ]]; then

    (( ${DEBUGLEVEL:=0} >= $1 )) && shift || return 1

  fi

  [[ $* ]] && echo "$*" >&2

  return 0

}
#******
#****f* liblog/udfTimeStamp
#  SYNOPSIS
#    udfTimeStamp <text>
#  DESCRIPTION
#    Show input <text> with time stamp in format 'Mar 28 10:03:40' (LC_ALL=C)
#  INPUTS
#    <text> - suffix to the header
#  OUTPUT
#    input <text> with time stamp in format 'Mar 28 10:03:40' (LC_ALL=C)
#  EXAMPLE
#    local re
#    re='^[ADFJMNOS][abceglnoprtuyv]{2} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} AB$'
#    udfTimeStamp AB >| grep -E "$re"                                           #? true
#  SOURCE

if (( _bashlyk_ShellVersion > 4002000 )); then

udfTimeStamp() { LC_ALL=C printf -- '%(%b %d %H:%M:%S)T %s\n' '-1' "$*"; }

udfDateR() { LC_ALL=C printf -- '%(%a, %d %b %Y %T %z)T\n' '-1'; }

udfUptime() { echo $(( $(printf '%(%s)T' '-1') - $(printf '%(%s)T' '-2') )); }

else

readonly _bashlyk_iStartTimeStamp=$( exec -c date "+%s" )

udfTimeStamp() { LC_ALL=C date "+%b %d %H:%M:%S $*"; }

udfDateR() { exec -c date -R; }

udfUptime() { echo $(( $(exec -c date "+%s") - _bashlyk_iStartTimeStamp )); }

fi
#******
#****f* liblog/udfDateR
#  SYNOPSIS
#    udfDateR
#  DESCRIPTION
#    show 'date -R' like output
#  EXAMPLE
#    udfDateR >| grep -P "^\S{3}, \d{2} \S{3} \d{4} \d{2}:\d{2}:\d{2} .\d{4}$"  #? true
#  SOURCE
#******
#****f* liblog/udfUptime
#  SYNOPSIS
#    udfUptime
#  DESCRIPTION
#    show uptime value in the seconds
#  EXAMPLE
#    udfUptime >| grep "^[[:digit:]]*$"                                         #? true
#  SOURCE
#******
#****f* liblog/udfFinally
#  SYNOPSIS
#    udfFinally <text>
#  DESCRIPTION
#    show uptime with input text
#  INPUTS
#    <text> - prefix text before " uptime <number> sec"
#  EXAMPLE
#    udfFinally $RANDOM >| grep "^[[:digit:]]* uptime [[:digit:]]* sec$"        #? true
#  SOURCE
udfFinally() { echo "$@ uptime $( udfUptime ) sec"; }
#******
