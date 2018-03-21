#
# $Id: libpid.sh 813 2018-03-21 19:02:16+04:00 toor $
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
[ -n "$_BASHLYK" ] || . ${_bashlyk_pathLib}/bashlyk || eval '                  \
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
    [ flock head kill mkdir pgrep rm rmdir sleep                               \
                                                                               \
"

declare -rg _bashlyk_exports_pid="                                             \
                                                                               \
    pid::{file,onExit.close,onExit.stop,onExit.unlink,onStarted.exit,status,   \
          stop,trap}                                                           \
                                                                               \
"
#******
#****e* libpid/pid::status
#  SYNOPSIS
#    pid::status <PID> <pattern>
#  DESCRIPTION
#    Compare the <PID> with a command line <pattern> which must contain the
#    process name
#  NOTES
#    public
#  ARGUMENTS
#    <PID>     - process id
#    <pattern> - command line pattern with process name
#  RETURN VALUE
#    Success         - a process with a <PID> and a name that satisfies the
#                      <pattern> exists and it is not the current process.
#    NoSuchProcess   - a process with a <PID> and a name that satisfies the
#                      <pattern> not found.
#    CurrentProcess  - a process with a <PID> and a name that satisfies the
#                      <pattern> identical to the PID of the current process.
#    InvalidArgument - <PID> is not number
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
#    err::status
#    pid::status 999999 $0                                                      #? $_bashlyk_iErrorInvalidArgument
#    err::status

#  SOURCE
pid::status() {

  errorify on MissingArgument $* || return

  std::isNumber $1 && (( $1 < 65536 )) || error InvalidArgument action=return $1

  local re="\\b${1}\\b"

  (( $$ == $1 )) && return $_bashlyk_iErrorCurrentProcess

  shift

  if [[ $(pgrep -d' ' -f "$*") =~ $re && $(pgrep -d' ' ${1##*/}) =~ $re ]]; then

    return 0

  else

    return $_bashlyk_iErrorNoSuchProcess

  fi
}
#******
#****e* libpid/pid::stop
#  SYNOPSIS
#    pid::stop [pid=PID[,PID,..]] [childs] <command-line>
#  DESCRIPTION
#    Stop the processes associated with the specified command line which must
#    contain the process name. Options allow you to manage the list of processes
#    to stop. The process of the script itself is excluded
#  NOTES
#    public
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
#    std::temp cmd1 path=$TMPEXEC
#    std::temp cmd2 path=$TMPEXEC
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
#    ## TODO wait for cmd1 starting
#    sleep 0.5
#    pid=$!
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

  rc=$_bashlyk_iErrorNoSuchProcess

  errorify on MissingArgument "${a[*]}" || a=( $( pgrep -d' ' ${1##*/} ) )
  errorify on MissingArgument "${a[*]}" || return $rc

  iStopped=0
  for (( i=0; i<${#a[*]}; i++ )) ; do

    pid=${a[i]}

    if ! std::isNumber $pid; then

      rc=$_bashlyk_iErrorInvalidArgument
      continue

    fi

    if (( pid == $$ )); then

      rc=$_bashlyk_iErrorCurrentProcess
      continue

    fi

    re="\\b${pid}\\b"

    if [[ $bChild && ! "$( pgrep -P $$ )" =~ $re ]]; then

      rc=$_bashlyk_iErrorNotChildProcess
      continue

    fi

    for s in 15 9; do

      if [[ $(pgrep -d' ' ${1##*/}) =~ $re && $(pgrep -d' ' -f "$*") =~ $re ]]
      then

        if kill -${s} $pid; then

          a[i]=""
          : $(( iStopped++ ))

        else

          rc=$_bashlyk_iErrorNotPermitted

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
#****e* libpid/pid::file
#  SYNOPSIS
#    pid::file
#  DESCRIPTION
#    Protection against re-run the script with the given arguments. PID file is
#    created when this script is not already running. If the script has
#    arguments, the PID file is created with the name of a MD5-hash this command
#    line, or it is derived from the name of the script.
#  NOTES
#    public
#  ERRORS
#    AlreadyStarted     - process of command line already started
#    AlreadyLocked      - PID file locked by flock
#    NotExistNotCreated - PID file don't created
#  EXAMPLE
#    local cmd fmt='#!/bin/bash\n%s . bashlyk\n%s || exit $?\n%s\n'             #-
#    std::temp cmd path=$TMPEXEC                                                #? true
#    printf -- "$fmt" '_bashlyk_log=nouse' 'pid::file' 'sleep 8' | tee $cmd
#    chmod +x $cmd                                                              #? true
#    ($cmd)&                                                                    #? true
#    sleep 0.5                                                                  #-
#    ( $cmd || false )                                                          #? false
#    pid::file                                                                  #? true
#    test -f $_bashlyk_fnPid                                                    #? true
#    head -n 1 $_bashlyk_fnPid                                    | {{ -w $$ }}
#    rm -f $_bashlyk_fnPid
#  SOURCE
pid::file() {

  local fnPid pid

  if [[ -n "$( _ sArg )" ]]; then

    fnPid="$( _ pathRun )/$( std::getMD5 $( _ s0 ) $( _ sArg ) ).pid"

  else

    fnPid="$( _ pathRun )/$( _ s0 ).pid"

  fi

  mkdir -p "${fnPid%/*}" || error NotExistNotCreated action=echo+return ${fnPid%/*}

  fd=$( std::getFreeFD )

  throw on EmptyVariable fd

  eval "exec $fd>>${fnPid}"

  [[ -s $fnPid ]] && pid=$( exec -c head -n 1 $fnPid )

  if eval "flock -n $fd"; then

    if pid::status "$pid" $( _ s0 ) $( _ sArg ); then

      error AlreadyStarted action=echo+return $pid

    fi

    if printf -- "%s\n%s\n" "$$" "$0 $( _ sArg )" > $fnPid; then

      _ fnPid $fnPid
      pid::onExit.unlink $fnPid
      pid::onExit.close  $fd

    else

      error NotExistNotCreated action=echo+return $fnPid

    fi

  else

    if pid::status "$pid" $( _ s0 ) $( _ sArg ); then

      error AlreadyStarted action=echo+return $pid

    else

      error AlreadyLocked action=echo+return $fnPid

    fi

  fi

  return 0

}
#******
#****e* libpid/pid::onStarted.exit
#  SYNOPSIS
#    pid::onStarted.exit
#  DESCRIPTION
#    Alias-wrapper for pid::file with extended behavior:
#    If command line process already exist then
#    this current process with identical command line stopped
#    else created pid file and current process don`t stopped.
#  NOTES
#    public
#  ERRORS
#    AlreadyStarted     - PID file exist and command line process already
#                         started, current process stopped
#    NotExistNotCreated - PID file don't created, current process stopped
#  EXAMPLE
#    pid::onStarted.exit                                                        #? true
#    ## TODO проверка кодов возврата
#  SOURCE
pid::onStarted.exit() {

  pid::file || exit

}
#******
#****e* libpid/pid::onExit.stop
#  SYNOPSIS
#    pid::onExit.stop <PID(s)>
#  DESCRIPTION
#    Adds <PID(s)> to the cleanup list when the current process is terminated.
#  NOTES
#    public
#  INPUTS
#    <PID(s)> - whitespace separated PID list
#  EXAMPLE
#    sleep 99 &
#    pid::onExit.stop $!
#    test "${_bashlyk_apidClean[$BASHPID]}" -eq "$!"                            #? true
#    ps -p $! -o pid=                                           | {{ -w $! }}
#    echo $(pid::onExit.stop $!; echo "$BASHPID : $! ")
#    ps -p $! -o pid=                                           | {{ -w $! }}1
#  SOURCE
pid::onExit.stop() {

  [[ $* ]] || return $_bashlyk_iErrorMissingArgument

  _bashlyk_apidClean[$BASHPID]+=" $*"

  trap "pid::trap" EXIT INT TERM

}
#******
#****e* libpid/pid::onExit.close
#  SYNOPSIS
#    pid::onExit.close <FILEDESCRIPTOR(s)>
#  DESCRIPTION
#    add list of <FILEDESCRIPTOR(s)> for close on exit
#  NOTES
#    public
#  ARGUMENTS
#    <FILEDESCRIPTOR(s)> - whitespace separated file descriptors list
#  SOURCE
pid::onExit.close() {

  [[ $* ]] || return $_bashlyk_iErrorMissingArgument

  _bashlyk_afdClean[$BASHPID]+=" $*"

  trap "pid::trap" EXIT INT TERM

}
#******
#****e* libpid/pid::onExit.unlink
#  SYNOPSIS
#    pid::onExit.unlink <file(s)>
#  DESCRIPTION
#    add list of filesystem objects for removing on exit
#  NOTES
#    public
#  INPUTS
#    <file(s)> - whitespace separated files and/or directories list
#  EXAMPLE
#    local a fnTemp1 fnTemp2 pathTemp1 pathTemp2 s=$RANDOM
#    std::temp fnTemp1 keep=true suffix=.${s}1
#    test -f $fnTemp1
#    echo $(pid::onExit.unlink $fnTemp1 )
#    ls -l ${TMPDIR}/*.${s}1 2>/dev/null                    | {{ ".*\.${s}1" }}1
#    echo $(std::temp fnTemp2 suffix=.${s}2)
#    ls -l ${TMPDIR}/*.${s}2 2>/dev/null                    | {{ ".*\.${s}2" }}1
#    echo $(std::temp fnTemp2 suffix=.${s}3 keep=true)
#    ls -l ${TMPDIR}/*.${s}3 2>/dev/null                    | {{ ".*\.${s}3" }}
#    a=$(ls -1 ${TMPDIR}/*.${s}3)
#    echo $(pid::onExit.unlink $a )
#    ls -l ${TMPDIR}/*.${s}3 2>/dev/null                    | {{ ".*\.${s}3" }}1
#    std::temp pathTemp1 keep=true suffix=.${s}1 type=dir
#    test -d $pathTemp1
#    echo $(pid::onExit.unlink $pathTemp1 )
#    ls -1ld ${TMPDIR}/*.${s}1 2>/dev/null                  | {{ ".*\.${s}1" }}1
#    echo $(std::temp pathTemp2 suffix=.${s}2 type=dir)
#    ls -1ld ${TMPDIR}/*.${s}2 2>/dev/null                  | {{ ".*\.${s}2" }}1
#    echo $(std::temp pathTemp2 suffix=.${s}3 keep=true type=dir)
#    ls -1ld ${TMPDIR}/*.${s}3 2>/dev/null                  | {{ ".*\.${s}3" }}
#    a=$(ls -1ld ${TMPDIR}/*.${s}3)
#    echo $(pid::onExit.unlink $a )
#    ls -1ld ${TMPDIR}/*.${s}3 2>/dev/null                  | {{ ".*\.${s}3" }}1
#    ## TODO names with whitespaces
#  SOURCE
pid::onExit.unlink() {

  [[ $* ]] || return $_bashlyk_iErrorMissingArgument

  _bashlyk_afoClean[$BASHPID]+=" $@"

  trap "pid::trap" EXIT INT TERM

}
#******
#****e* libpid/pid::trap
#  SYNOPSIS
#    pid::trap
#  DESCRIPTION
#    The cleaning procedure at the end of the calling script.
#    Suitable for trap command call.
#    Produced deletion of files and empty directories; stop child processes,
#    closure of open file descriptors listed in the corresponding global
#    variables. All processes must be related and descended from the working
#    script process. Closes the socket script log if it was used.
#  NOTES
#    public
#  EXAMPLE
#    local fd fn1 fn2 path pid pipe
#    std::temp fn1
#    std::temp fn2
#    std::temp path type=dir
#    std::temp pipe type=pipe
#    fd=$( std::getFreeFD )
#    eval "exec ${fd}>$fn2"
#    (sleep 1024)&
#    pid=$!
#    test -f $fn1
#    test -d $path
#    ps -p $pid -o pid=                                         | {{ -w $pid }}
#    ls /proc/$$/fd                                             | {{ -w $fd  }}
#    pid::onExit.close $fd
#    pid::onExit.stop $pid
#    pid::onExit.unlink $fn1
#    pid::onExit.unlink $path
#    pid::onExit.unlink $pipe
#    pid::trap
#    ls /proc/$$/fd                                              | {{ -w $fd }}!
#    ps -p $pid -o pid=                                          | {{ -w $pid}}!
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

    std::isNumber $s && eval "exec ${s}>&-"

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
