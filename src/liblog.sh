#
# $Id: liblog.sh 768 2017-06-02 14:29:30+04:00 toor $
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
[ -n "$_BASHLYK" ] || . ${_bashlyk_pathLib}/bashlyk || eval '                  \
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
    log::{add,file,ger,init,interactivity,necessity,terminality}               \
                                                                               \
"
#******
#****f* liblog/log::ger
#  SYNOPSIS
#    log::ger <text>
#  DESCRIPTION
#    log engine for adding <text> to log file with standart stamps if logging is
#    setted
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
#    log::init                                                                  #-
#    _ fnLog                                                                    #-
#    log::ger test                                                              #-
#    date                                                                       #-
#    echo $_bashlyk_pidLogSock                                                  #-
#    echo '%d'                                                                  #-
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
#    ## TODO test syslog mode
#  SOURCE
log::ger() {

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

    log::necessity && bUseLog=1 || bUseLog=0

  fi

  mkdir -p "$_bashlyk_pathLog" || on error throw NotExistNotCreated $_bashlyk_pathLog

  pid::onExit.unlink $_bashlyk_pathLog

  case "${bSysLog}${bUseLog}" in

    00)
        echo "$@"
     ;;

    01)
        log::stamp "$HOSTNAME $sTagLog: $*" >> $_bashlyk_fnLog
     ;;

    10)
        echo "$*"
        logger -t "$sTagLog" "$*"
     ;;

    11)
        log::stamp "$HOSTNAME $sTagLog: $*" >> $_bashlyk_fnLog
        logger -t "$sTagLog" "$*"
     ;;

  esac

}
#******
## TODO improve description
#****f* liblog/log::add
#  SYNOPSIS
#    log::add [-] [<text>]
#  DESCRIPTION
#    Wrapper around log::ger to support stream from standard input
#  INPUTS
#    -      - data is expected from standard input
#    <text> - String (tag) for output.
#             If there is a "-" as the first argument, then the string is
#             considered a prefix (tag) for each line from the standard input.
#  OUTPUT
#   Depends on output parameters
#  EXAMPLE
#    # TODO improve test
#    echo -n . | log::add -                                >| grep '^\.$'       #? true
#    echo test | log::add - tag                            >| grep '^tag test$' #? true
#  SOURCE
log::add() {

  local sTag s

  if [[ "$1" == "-" ]]; then

    shift
    [[ $* ]] && sTag="$* "

    while read s || [[ $s ]]; do [[ $s ]] && log::ger "${sTag}${s}"; done

  else

    [[ $* ]] && log::ger "$*"

  fi

}
#******
#****f* liblog/log::interactivity
#  SYNOPSIS
#    log::interactivity
#  DESCRIPTION
#    Checking the operating mode of standard input and output devices
#  RETURN VALUE
#    0 - "non-interactive" mode, there is redirection of standard input and/or
#         output
#    1 - "interactive" mode, redirection of standard input and/or output is not
#        detected
#  EXAMPLE
#    log::interactivity                                                         #? true
#    log::interactivity                                                         #= false
#  SOURCE
log::interactivity() {

  [[ -t 1 && -t 0 && $TERM && "$TERM" != "dumb" ]] \
    && _bashlyk_bInteract=1 || _bashlyk_bInteract=0

  return $_bashlyk_bInteract

}
#******
#****f* liblog/log::terminality
#  SYNOPSIS
#    log::terminality
#  DESCRIPTION
#    Checking the presence of a control terminal
#  RETURN VALUE
#    0 - terminal not detected
#    1 - terminal detected
#  EXAMPLE
#    log::terminality                                                           #? false
#    log::terminality                                                           #= false
#  SOURCE
log::terminality() {

  tty > /dev/null 2>&1 && _bashlyk_bTerminal=1 || _bashlyk_bTerminal=0
  return $_bashlyk_bTerminal

}
#******
#****f* liblog/log::necessity
#  SYNOPSIS
#    log::necessity
#  DESCRIPTION
#    Check the conditions for using the log file
#  RETURN VALUE
#    0 - save stdout and stderr to log file
#    1 - logging do not required
#  EXAMPLE
#    _bashlyk_sCond4Log='redirect'
#    log::necessity                                                             #? true
#    log::necessity                                                             #= false
#  SOURCE
log::necessity() {

  log::terminality
  log::interactivity

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
#****f* liblog/log::init
#  SYNOPSIS
#    log::init
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
#    log::init                                                                  #? true
#    ls -l $fnLog                                                               #? true
#    rm -f $fnLog
#  SOURCE
log::init() {

  local fnSock IFS=$' \t\n'

  if [[ $_bashlyk_sArg ]]; then

    fnSock="$(std::getMD5 ${_bashlyk_s0} ${_bashlyk_sArg}).${$}.socket"
    fnSock="${_bashlyk_pathRun}/${fnSock}"

  else

    fnSock="${_bashlyk_pathRun}/${_bashlyk_s0}.${$}.socket"

  fi

  mkdir -p $_bashlyk_pathRun || on error return+warn NotExistNotCreated $_bashlyk_pathRun

  [[ -a "$fnSock" ]] && rm -f $fnSock

  if mkfifo -m 0600 $fnSock >/dev/null 2>&1; then

    ( log::add - < $fnSock )&
    _bashlyk_pidLogSock=$!
    exec >>$fnSock 2>&1

    _bashlyk_fnLogSock=$fnSock
    pid::onExit.unlink $fnSock

    return 0

  else

    on error warn NotExistNotCreated Socket $fnSock not created..

    exec >>$_bashlyk_fnLog 2>&1

    _bashlyk_fnLogSock=$_bashlyk_fnLog

    return 1

  fi

}
#******
#****f* liblog/log::file
#  SYNOPSIS
#    log::file [<filename>]
#  DESCRIPTION
#    Wrapper around log::init to activate output redirection to the log
#    <filename> with error handling
#  ERRORS
#     NotExistNotCreated - log file can not be created, abort
#  EXAMPLE
#    local fnLog=$(mktemp --suffix=.log || tempfile -s .test.log)
#    rm -f $fnLog
#    log::file $fnLog                                                           #? true
#    ls -l $fnLog                                                               #? true
#    rm -f $fnLog
#  SOURCE
log::file() {

  local IFS=$' \t\n'

  case "$1" in
          '') ;;
    ${1##*/}) _bashlyk_fnLog="${_bashlyk_pathLog}/$1";;
           *)
              _bashlyk_fnLog="$1"
              _bashlyk_pathLog=${_bashlyk_fnLog%/*}
           ;;
  esac

  {

    mkdir -p "$_bashlyk_pathLog"
    touch "$_bashlyk_fnLog"

  } || on error throw NotExistNotCreated $_bashlyk_fnLog

  log::init

  return 0

}
#******
#****f* liblog/log::stamp
#  SYNOPSIS
#    log::stamp <text>
#  DESCRIPTION
#    Show input <text> with time stamp in format 'Mar 28 10:03:40' (LC_ALL=C)
#  INPUTS
#    <text> - suffix to the header
#  OUTPUT
#    input <text> with time stamp in format 'Mar 28 10:03:40' (LC_ALL=C)
#  EXAMPLE
#    local re
#    re='^[ADFJMNOS][abceglnoprtuyv]{2} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} AB$'
#    log::stamp AB >| grep -E "$re"                                             #? true
#  SOURCE

if (( _bashlyk_ShellVersion > 4002000 )); then

  log::stamp() { LC_ALL=C printf -- '%(%b %d %H:%M:%S)T %s\n' '-1' "$*"; }

else

  log::stamp() { LC_ALL=C date "+%b %d %H:%M:%S ${*//%/%%}"; }

fi
#******
