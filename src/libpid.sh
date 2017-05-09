#
# $Id: libpid.sh 759 2017-05-10 00:06:46+04:00 toor $
#
#****h* BASHLYK/libpid
#  DESCRIPTION
#    A set of functions for process control from shell scripts:
#    * create a PID file
#    * protection against restarting
#    * stop some processes of the specified command
#  USES
#    libstd
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libpid/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBPID provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBPID" ] && return 0 || _BASHLYK_LIBPID=1
[ -n "$_BASHLYK" ] || . bashlyk || eval '                                      \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* libpid/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****G* libpid/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
#: ${_bashlyk_fnPid:=}
#: ${_bashlyk_fnSock:=}
#: ${_bashlyk_afoClean:=}
#: ${_bashlyk_afdClean:=}
#: ${_bashlyk_ajobClean:=}
#: ${_bashlyk_apidClean:=}
#: ${_bashlyk_pidLogSock:=}
: ${_bashlyk_s0:=${0##*/}}

declare -rg _bashlyk_externals_pid="                                           \
                                                                               \
    flock head kill mkdir pgrep rm rmdir sleep                                 \
                                                                               \
"

declare -rg _bashlyk_exports_pid="                                             \
                                                                               \
    pid::clean::onexit::fd pid::clean::onexit::file pid::clean::onexit::proc   \
    pid::status pid::exitIfAlreadyStarted pid::trap pid::file pid::stop        \
                                                                               \
"
#******
#****f* libpid/pid::status
#  SYNOPSIS
#    pid::status <PID> <args>
#  DESCRIPTION
#    Compare the PID of the process with a command line pattern which must
#    contain the process name
#  ARGUMENTS
#    <PID>  - process id
#    <args> - command line pattern with process name
#  ERRORS
#    NoSuchProcess   - Process for the specified command line is not detected.
#    CurrentProcess  - The process for this command line is identical to the
#                      PID of the current process
#    InvalidArgument - PID is not number
#    MissingArgument - no arguments
#  EXAMPLE
#    (sleep 8)&                                                                 #-
#    local pid=$!                                                               #-
#    ps -p $pid -o pid= -o args=
#    pid::status                                                                #? $_bashlyk_iErrorMissingArgument
#    pid::status $pid sleep 8                                                   #? true
#    pid::status $pid sleep 88                                                  #? $_bashlyk_iErrorNoSuchProcess
#    pid::status $$ $0                                                          #? $_bashlyk_iErrorCurrentProcess
#    pid::status notvalid $0                                                    #? $_bashlyk_iErrorInvalidArgument

#  SOURCE
pid::status() {

  errorify on MissingArgument $* || return

  local re="\\b${1}\\b"

  udfIsNumber $1 || return $( _ iErrorInvalidArgument )

  [[ "$$" == "$1" ]] && return $( _ iErrorCurrentProcess )

  shift

  if [[ $(pgrep -d' ' -f "$*") =~ $re && $(pgrep -d' ' ${1##*/}) =~ $re ]]; then

    return 0

  else

    return $( _ iErrorNoSuchProcess )

  fi
}
#******
#****f* libpid/pid::stop
#  SYNOPSIS
#    pid::stop [pid=PID[,PID,..]] [childs] <command-line>
#  DESCRIPTION
#    Stop the processes associated with the specified command line which must
#    contain the process name. Options allow you to manage the list of processes
#    to stop. The process of the script itself is excluded
#  ARGUMENTS
#    pid=PID[,..]   - comma separated list of PID. Only these processes will be
#                     stopped if they are associated with the command line
#    childs         - stop only child processes
#    <command-line> - command line pattern with process name
#  ERRORS
#    NoSuchProcess   - processes for the specified command is not detected
#    NoChildProcess  - child processes for the specified command line is not
#                      detected.
#    CurrentProcess  - process for this command line is identical to the PID
#                      of the current process, do not stopped
#    InvalidArgument - PID is not number
#    MissingArgument - no arguments
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
#    pid::stop                                                                  #? $_bashlyk_iErrorMissingArgument
#    pid::stop pid=$pid                                                         #? $_bashlyk_iErrorMissingArgument
#    pid::stop childs                                                           #? $_bashlyk_iErrorMissingArgument
#    pid::stop pid=$pid $cmd1 88                                                #? $_bashlyk_iErrorNoSuchProcess
#    pid::stop $cmd1 88                                                         #? $_bashlyk_iErrorNoSuchProcess
#    pid::stop pid=$$ $0                                                        #? $_bashlyk_iErrorCurrentProcess
#    pid::stop pid=invalid $0                                                   #? $_bashlyk_iErrorInvalidArgument
#    pid::stop childs pid=$pid $cmd1 400                                        #? true
#    pid::stop childs pid=$a $cmd1 800                                          #? true
#    pid::stop childs pid=$a $cmd1 600                                          #? $_bashlyk_iErrorNotChildProcess
#    pid::stop $cmd1                                                            #? true
#  SOURCE
pid::stop() {

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

  errorify on MissingArgument $* || return

  rc=$( _ iErrorNoSuchProcess )

  errorify on MissingArgument "${a[*]}" || a=( $( pgrep -d' ' ${1##*/} ) )
  errorify on MissingArgument "${a[*]}" || return $rc

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

      if [[ $(pgrep -d' ' ${1##*/}) =~ $re && $(pgrep -d' ' -f "$*") =~ $re ]]
      then

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
#****f* libpid/pid::file
#  SYNOPSIS
#    pid::file
#  DESCRIPTION
#    Protection against re-run the script with the given arguments. PID file is
#    created when this script is not already running. If the script has
#    arguments, the PID file is created with the name of a MD5-hash this command
#    line, or it is derived from the name of the script.
#  ERRORS
#    AlreadyStarted     - process of command line already started
#    AlreadyLocked      - PID file locked by flock
#    NotExistNotCreated - PID file don't created
#  EXAMPLE
#    local cmd fmt='#!/bin/bash\n%s . bashlyk\n%s || exit $?\n%s\n'             #-
#    udfMakeTemp cmd                                                            #? true
#    printf -- "$fmt" '_bashlyk_log=nouse' 'pid::file' 'sleep 8' | tee $cmd
#    chmod +x $cmd                                                              #? true
#    ($cmd)&                                                                    #? true
#    sleep 0.5                                                                  #-
#    ( $cmd || false )                                                          #? false
#    pid::file                                                                  #? true
#    test -f $_bashlyk_fnPid                                                    #? true
#    head -n 1 $_bashlyk_fnPid >| grep -w $$                                    #? true
#    rm -f $_bashlyk_fnPid
#  SOURCE
pid::file() {

  local fnPid pid

  if [[ -n "$( _ sArg )" ]]; then

    fnPid="$( _ pathRun )/$( udfGetMd5 $( _ s0 ) $( _ sArg ) ).pid"

  else

    fnPid="$( _ pathRun )/$( _ s0 ).pid"

  fi

  mkdir -p "${fnPid%/*}" || on error echo+return NotExistNotCreated ${fnPid%/*}

  fd=$( udfGetFreeFD )
  udfThrowOnEmptyVariable fd

  eval "exec $fd>>${fnPid}"

  [[ -s $fnPid ]] && pid=$( exec -c head -n 1 $fnPid )

  if eval "flock -n $fd"; then

    if pid::status "$pid" $( _ s0 ) $( _ sArg ); then

      on error echo+return AlreadyStarted $pid

    fi

    if printf -- "%s\n%s\n" "$$" "$0 $( _ sArg )" > $fnPid; then

      _ fnPid $fnPid
      pid::clean::onexit::file $fnPid
      pid::clean::onexit::fd $fd

    else

      on error echo+return NotExistNotCreated $fnPid

    fi

  else

    if pid::status "$pid" $( _ s0 ) $( _ sArg ); then

      on error echo+return AlreadyStarted $pid

    else

      on error echo+return AlreadyLocked $fnPid

    fi

  fi

  return 0

}
#******
#****f* libpid/pid::exitIfAlreadyStarted
#  SYNOPSIS
#    pid::exitIfAlreadyStarted
#  DESCRIPTION
#    Alias-wrapper for pid::file with extended behavior:
#    If command line process already exist then
#    this current process with identical command line stopped
#    else created pid file and current process don`t stopped.
#  ERRORS
#    AlreadyStarted     - PID file exist and command line process already
#                         started, current process stopped
#    NotExistNotCreated - PID file don't created, current process stopped
#  EXAMPLE
#    pid::exitIfAlreadyStarted                                                  #? true
#    ## TODO проверка кодов возврата
#  SOURCE
pid::exitIfAlreadyStarted() {

  pid::file || exit $?

}
#******
udfAddJob2Clean() { return 0; }
#****f* libpid/pid::clean::onexit::proc
#  SYNOPSIS
#    pid::clean::onexit::proc args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных процессов к списку очистки при
#    завершении текущего процесса.
#  INPUTS
#    args - идентификаторы процессов
#  EXAMPLE
#    sleep 99 &
#    pid::clean::onexit::proc $!
#    test "${_bashlyk_apidClean[$BASHPID]}" -eq "$!"                            #? true
#    ps -p $! -o pid= >| grep -w $!                                             #? true
#    echo $(pid::clean::onexit::proc $!; echo "$BASHPID : $! ")
#    ps -p $! -o pid= >| grep -w $!                                             #? false
#
#  SOURCE
pid::clean::onexit::proc() {

  [[ $1 ]] || return 0

  _bashlyk_apidClean[$BASHPID]+=" $*"

  trap "pid::trap" EXIT INT TERM

}
#******
#****f* libpid/pid::clean::onexit::fd
#  SYNOPSIS
#    pid::clean::onexit::fd <args>
#  DESCRIPTION
#    add list of filedescriptors for cleaning on exit
#  ARGUMENTS
#    <args> - file descriptors
#  SOURCE
pid::clean::onexit::fd() {

  errorify on MissingArgument $* || return

  _bashlyk_afdClean[$BASHPID]+=" $*"

  trap "pid::trap" EXIT INT TERM

}
#******
#****f* libpid/pid::clean::onexit::file
#  SYNOPSIS
#    pid::clean::onexit::file <args>
#  DESCRIPTION
#    add list of filesystem objects for cleaning on exit
#  INPUTS
#    args - files or directories for cleaning on exit
#  EXAMPLE
#    local a fnTemp1 fnTemp2 pathTemp1 pathTemp2 s=$RANDOM
#    udfMakeTemp fnTemp1 keep=true suffix=.${s}1
#    test -f $fnTemp1
#    echo $(pid::clean::onexit::file $fnTemp1 )
#    ls -l ${TMPDIR}/*.${s}1 2>/dev/null >| grep ".*\.${s}1"                    #? false
#    echo $(udfMakeTemp fnTemp2 suffix=.${s}2)
#    ls -l ${TMPDIR}/*.${s}2 2>/dev/null >| grep ".*\.${s}2"                    #? false
#    echo $(udfMakeTemp fnTemp2 suffix=.${s}3 keep=true)
#    ls -l ${TMPDIR}/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                    #? true
#    a=$(ls -1 ${TMPDIR}/*.${s}3)
#    echo $(pid::clean::onexit::file $a )
#    ls -l ${TMPDIR}/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                    #? false
#    udfMakeTemp pathTemp1 keep=true suffix=.${s}1 type=dir
#    test -d $pathTemp1
#    echo $(pid::clean::onexit::file $pathTemp1 )
#    ls -1ld ${TMPDIR}/*.${s}1 2>/dev/null >| grep ".*\.${s}1"                  #? false
#    echo $(udfMakeTemp pathTemp2 suffix=.${s}2 type=dir)
#    ls -1ld ${TMPDIR}/*.${s}2 2>/dev/null >| grep ".*\.${s}2"                  #? false
#    echo $(udfMakeTemp pathTemp2 suffix=.${s}3 keep=true type=dir)
#    ls -1ld ${TMPDIR}/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                  #? true
#    a=$(ls -1ld ${TMPDIR}/*.${s}3)
#    echo $(pid::clean::onexit::file $a )
#    ls -1ld ${TMPDIR}/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                  #? false
#  SOURCE
pid::clean::onexit::file() {

  errorify on MissingArgument $* || return

  _bashlyk_afoClean[$BASHPID]+=" $*"

  trap "pid::trap" EXIT INT TERM

}
#******
#****f* libpid/pid::trap
#  SYNOPSIS
#    pid::trap
#  DESCRIPTION
#    The cleaning procedure at the end of the calling script.
#    Suitable for trap command call.
#    Produced deletion of files and empty directories; stop child processes,
#    closure of open file descriptors listed in the corresponding global
#    variables. All processes must be related and descended from the working
#    script process. Closes the socket script log if it was used.
#  EXAMPLE
#    local fd fn1 fn2 path pid pipe
#    udfMakeTemp fn1
#    udfMakeTemp fn2
#    udfMakeTemp path type=dir
#    udfMakeTemp pipe type=pipe
#    fd=$( udfGetFreeFD )
#    eval "exec ${fd}>$fn2"
#    (sleep 1024)&
#    pid=$!
#    test -f $fn1
#    test -d $path
#    ps -p $pid -o pid= >| grep -w $pid
#    ls /proc/$$/fd >| grep -w $fd
#    pid::clean::onexit::fd $fd
#    pid::clean::onexit::proc $pid
#    pid::clean::onexit::file $fn1
#    pid::clean::onexit::file $path
#    pid::clean::onexit::file $pipe
#    pid::trap
#    ls /proc/$$/fd >| grep -w $fd                                              #? false
#    ps -p $pid -o pid= >| grep -w $pid                                         #? false
#    test -f $fn1                                                               #? false
#    test -d $path                                                              #? false
#  SOURCE
pid::trap() {

  local i IFS=$' \t\n' re s
  local -a a

  a=( ${_bashlyk_apidClean[$BASHPID]} )

  for (( i=${#a[@]}-1; i>=0 ; i-- )) ; do

    re="\\b${a[i]}\\b"

    for s in 15 9; do

      if [[  "$( pgrep -d' ' -P $$ )" =~ $re ]]; then

        if ! kill -${s} ${a[i]} >/dev/null 2>&1; then

          err::status NotPermitted "${a[i]}"
          sleep 0.1

        fi

      fi

    done

  done

  for s in ${_bashlyk_afdClean[$BASHPID]}; do

    udfIsNumber $s && eval "exec ${s}>&-"

  done

  for s in ${_bashlyk_afoClean[$BASHPID]}; do

    [[ -f $s ]] && rm -f $s && continue
    [[ -p $s ]] && rm -f $s && continue
    [[ -d $s ]] && rmdir --ignore-fail-on-non-empty $s 2>/dev/null && continue

  done

  if [[ $_bashlyk_pidLogSock ]]; then

    exec >/dev/null 2>&1
    wait $_bashlyk_pidLogSock

  fi

}
#******
