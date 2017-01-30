#
# $Id: libpid.sh 672 2017-01-30 12:08:13+04:00 toor $
#
#****h* BASHLYK/libpid
#  DESCRIPTION
#    Контроль запуска рабочего сценария, возможность защиты от повторного
#    запуска
#  USES
#    libstd
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* liberr/BASH Compability
#  DESCRIPTION
#    BASH version 4.xx or more required for this script
#  SOURCE
[ -n "$BASH_VERSION" ] && (( ${BASH_VERSINFO[0]} >= 4 )) || eval '             \
                                                                               \
    echo "[!] BASH shell version 4.xx required for ${0}, abort.."; exit 255    \
                                                                               \
'
#******
#  $_BASHLYK_LIBPID provides protection against re-using of this module
[[ $_BASHLYK_LIBPID ]] && return 0 || _BASHLYK_LIBPID=1
#****L* libpid/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****G* libpid/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
: ${_bashlyk_afoClean:=}
: ${_bashlyk_afdClean:=}
: ${_bashlyk_fnPid:=}
: ${_bashlyk_fnSock:=}

: ${_bashlyk_s0:=${0##*/}}
: ${_bashlyk_pathRun:=/tmp}
: ${_bashlyk_sArg:="$@"}

declare -rg _bashlyk_externals_pid="                                           \
                                                                               \
    head kill mkdir printf pgrep ps rm rmdir sleep xargs                       \
                                                                               \
"
declare -rg _bashlyk_exports_pid="                                             \
                                                                               \
    udfCheckStarted udfExitIfAlreadyStarted udfSetPid udfStopProcess           \
                                                                               \
"
#******
#****f* libpid/udfCheckStarted
#  SYNOPSIS
#    udfCheckStarted <PID> <args>
#  DESCRIPTION
#    Compare the PID of the process with a command line pattern which must
#    contain the process name
#  ARGUMENTS
#    <PID>  - process id
#    <args> - command line pattern with process name
#  RETURN VALUE
#    0               - Process PID exists for the specified command line
#    NoSuchProcess   - Process for the specified command line is not detected.
#    CurrentProcess  - The process for this command line is identical to the
#                      PID of the current process
#    InvalidArgument - PID is not number
#    MissingArgument - no arguments
#  EXAMPLE
#    (sleep 8)&                                                                 #-
#    local pid=$!                                                               #-
#    ps -p $pid -o pid= -o args=
#    udfCheckStarted                                                            #? $_bashlyk_iErrorMissingArgument
#    udfCheckStarted $pid sleep 8                                               #? true
#    udfCheckStarted $pid sleep 88                                              #? $_bashlyk_iErrorNoSuchProcess
#    udfCheckStarted $$ $0                                                      #? $_bashlyk_iErrorCurrentProcess
#    udfCheckStarted notvalid $0                                                #? $_bashlyk_iErrorInvalidArgument

#  SOURCE
udfCheckStarted() {

  udfOn EmptyOrMissingArgument "$*" || return $?

  local re="\\b${1}\\b"

  udfIsNumber $1 || return $( _ iErrorInvalidArgument )

  [[ "$$" == "$1" ]] && return $( _ iErrorCurrentProcess )

  shift

  [[ "$( pgrep -d' ' -f "$*" )" =~ $re && "$( pgrep -d' ' ${1##*/} )" =~ $re ]] \
    || return $(_ iErrorNoSuchProcess)

  return 0

}
#******
#****f* libpid/udfStopProcess
#  SYNOPSIS
#    udfStopProcess [pid=PID[,PID,..]] [childs] <command-line>
#  DESCRIPTION
#    Stop the processes associated with the specified command line which must
#    contain the process name. Options allow you to manage the list of processes
#    to stop. The process of the script itself is excluded
#  ARGUMENTS
#    pid=PID[,..]   - comma separated list of PID. Only these processes will be
#                     stopped if they are associated with the command line
#    childs         - stop only child processes
#    <command-line> - command line pattern with process name
#  RETURN VALUE
#    0                 - stopped all inctances of the specified command line
#    NoSuchProcess     - processes for the specified command is not detected
#    NoChildProcess    - child processes for the specified command line is not
#                        detected.
#    CurrentProcess    - process for this command line is identical to the PID
#                        of the current process, do not stopped
#    InvalidArgument   - PID is not number
#    EmptyOrMissing... - no arguments
#  EXAMPLE
#    local a cmd1 cmd2 fmt1 fmt2 i pid                                          #-
#    fmt1='#!/bin/bash\nread -t %s -N 0 </dev/zero\n'
#    fmt2='#!/bin/bash\nfor i in 900 700 600 500; do\n%s %s &\ndone\n'
#    udfMakeTemp cmd1
#    udfMakeTemp cmd2
#    printf -- "$fmt1" '$1' | tee $cmd1
#    chmod +x $cmd1
#    printf -- "$fmt2" "$cmd1" '$i' | tee $cmd2
#    chmod +x $cmd2
#    for i in 800 700 600 500; do                                               #-
#    $cmd1 $i &                                                                 #-
#    a+="${!},"                                                                 #-
#    done                                                                       #-
#    $cmd2
#    ($cmd1 400)&                                                               #-
#    pid=$!
#    ## TODO wait for cmd1 starting
#    udfStopProcess                                                             #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfStopProcess pid=$pid $cmd1 88                                           #? $_bashlyk_iErrorNoSuchProcess
#    udfStopProcess $cmd1 88                                                    #? $_bashlyk_iErrorNoSuchProcess
#    udfStopProcess pid=$$ $0                                                   #? $_bashlyk_iErrorCurrentProcess
#    udfStopProcess pid=invalid $0                                              #? $_bashlyk_iErrorInvalidArgument
#    udfStopProcess childs pid=$pid $cmd1 400                                   #? true
#    udfStopProcess childs pid=$a $cmd1 800                                     #? true
#    udfStopProcess childs pid=$a $cmd1 600                                     #? $_bashlyk_iErrorNotChildProcess
#    udfStopProcess $cmd1                                                       #? true
#  SOURCE
udfStopProcess() {

  udfOn EmptyOrMissingArgument "$@" || return $?

  local bChild i iStopped pid rc re s
  local -a a

  for s in $*; do

    case "$s" in

      pid=*)
             i="${s#*=}"
             a=( ${i//,/ } )
             shift
      ;;

      childs)
             bChild=1
             shift
      ;;

    esac

  done

  rc=$( _ iErrorNoSuchProcess )

  udfOn EmptyOrMissingArgument "${a[*]}" || a=( $( pgrep -d' ' ${1##*/} ) )
  udfOn EmptyOrMissingArgument "${a[*]}" || return $rc

  iStopped=0
  for (( i=0; i<${#a[*]}; i++ )) ; do

    pid=${a[i]}

    if ! udfIsNumber $pid; then

      rc=$( _ iErrorInvalidArgument )
      continue

    fi

    if (( pid == $$ )); then

      rc=$( _ iErrorCurrentProcess )
      continue

    fi

    re="\\b${pid}\\b"

    if [[ $bChild && ! "$( pgrep -P $$ )" =~ $re ]]; then

      rc=$( _ iErrorNotChildProcess )
      continue

    fi

    for s in 15 9; do

      if [[  "$( pgrep -d' ' ${1##*/} )" =~ $re && "$( pgrep -d' ' -f "$*" )" =~ $re ]]; then

        if kill -${s} $pid; then

          a[i]=""
          : $(( iStopped++ ))

        else

          rc=$( _ iErrorNotPermitted )

        fi

      else

        a[i]=""
        break

      fi

    done

  done

  s="${a[*]}"

  [[ $iStopped != 0 && -z "${s// /}" ]] || return $rc

  return 0

}
#******
#****f* libpid/udfSetPid
#  SYNOPSIS
#    udfSetPid
#  DESCRIPTION
#    Protection against re-run the script with the given arguments. PID file is
#    created when this script is not already running. If the script has
#    arguments, the PID file is created with the name of a MD5-hash this command
#    line, or it is derived from the name of the script.
#  RETURN VALUE
#    AlreadyStarted     - process of command line already started
#    AlreadyLocked      - PID file locked by flock
#    NotExistNotCreated - PID file don't created
#    0                  - PID file for command line successfully created
#  EXAMPLE
#    local cmd fmt='#!/bin/bash\n%s . bashlyk\n%s || exit $?\n%s\n'             #-
#    udfMakeTemp cmd                                                            #? true
#    printf -- "$fmt" '_bashlyk_log=nouse' 'udfSetPid' 'sleep 8' | tee $cmd
#    chmod +x $cmd                                                              #? true
#    ($cmd)&                                                                    #? true
#    sleep 0.5                                                                  #-
#    ( $cmd || false )                                                          #? false
#    udfSetPid                                                                  #? true
#    test -f $_bashlyk_fnPid                                                    #? true
#    head -n 1 $_bashlyk_fnPid >| grep -w $$                                    #? true
#    rm -f $_bashlyk_fnPid
#  SOURCE
udfSetPid() {

  local fnPid pid

  if [[ -n "$( _ sArg )" ]]; then

    fnPid="$( _ pathRun )/$( udfGetMd5 $( _ s0 ) $( _ sArg ) ).pid"

  else

    fnPid="$( _ pathRun )/$( _ s0 ).pid"

  fi

  mkdir -p "${fnPid%/*}" \
    || eval $( udfOnError retecho NotExistNotCreated "${fnPid%/*}" )

  fd=$( udfGetFreeFD )
  udfThrowOnEmptyVariable fd

  eval "exec $fd>>${fnPid}"

  [[ -s $fnPid ]] && pid=$( head -n 1 $fnPid )

  if eval "flock -n $fd"; then

    if udfCheckStarted "$pid" $( _ s0 ) $( _ sArg ); then

      eval $( udfOnError retecho AlreadyStarted "$pid" )

    fi

    if printf -- "%s\n%s\n" "$$" "$0 $( _ sArg )" > $fnPid; then

      _ fnPid $fnPid
      udfAddFO2Clean $fnPid
      udfAddFD2Clean $fd

    else

      eval $( udfOnError retecho NotExistNotCreated "$fnPid" )

    fi

  else

    if udfCheckStarted "$pid" $( _ s0 ) $( _ sArg ); then

      eval $( udfOnError retecho AlreadyStarted "$pid" )

    else

      eval $( udfOnError retecho AlreadyLocked "$fnPid" )

    fi

  fi

  return 0

}
#******
#****f* libpid/udfExitIfAlreadyStarted
#  SYNOPSIS
#    udfExitIfAlreadyStarted
#  DESCRIPTION
#    Alias-wrapper for udfSetPid with extended behavior:
#    If command line process already exist then
#    this current process with identical command line stopped
#    else created pid file and current process don`t stopped.
#  RETURN VALUE
#    0                        - PID file for command line successfully created
#    iErrorAlreadyStarted     - PID file exist and command line process already
#                               started, current process stopped
#    iErrorNotExistNotCreated - PID file don't created, current process stopped
#  EXAMPLE
#    udfExitIfAlreadyStarted                                                    #? true
#    ## TODO проверка кодов возврата
#  SOURCE
udfExitIfAlreadyStarted() {

  udfSetPid || exit $?

}
#******
