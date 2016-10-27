#
# $Id: libpid.sh 569 2016-10-27 23:32:44+04:00 toor $
#
#****h* BASHLYK/libpid
#  DESCRIPTION
#    Контроль запуска рабочего сценария, возможность защиты от повторного
#    запуска
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libpid/Require Once
#  DESCRIPTION
#    Глобальная переменная $_BASHLYK_LIBPID обеспечивает
#    защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
[[ -n "$_BASHLYK_LIBPID" ]] && return 0 || _BASHLYK_LIBPID=1
#******
#****** libpid/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****v* libpid/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_afoClean:=}
: ${_bashlyk_afdClean:=}
: ${_bashlyk_fnPid:=}
: ${_bashlyk_fnSock:=}
: ${_bashlyk_s0:=${0##*/}}
: ${_bashlyk_pathRun:=/tmp}
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_aRequiredCmd_pid:="head kill mkdir printf pgrep ps rm rmdir sleep xargs"}
: ${_bashlyk_aExport_pid:="udfCheckStarted udfExitIfAlreadyStarted udfGetFreeFD udfSetPid udfStopProcess"}
#******
#****f* libpid/udfCheckStarted
#  SYNOPSIS
#    udfCheckStarted PID [command [args]]
#  DESCRIPTION
#    Checking process with given PID and the command line
#    PID of the process in which a check is excluded from an examination
#  INPUTS
#    PID     - PID
#    command - command
#    args    - arguments
#  RETURN VALUE
#    0                 - Process PID exists for the specified command line
#    NoSuchProcess     - Process for the specified command line is not detected.
#    CurrentProcess    - The process for this command line is identical to the
#                        PID of the current process
#    iErrorNotValid... - PID is not number
#    EmptyOrMissing... - no arguments
#  EXAMPLE
#    (sleep 8)&                                                                 #-
#    local pid=$!                                                               #-
#    ps -p $pid -o pid= -o args=
#    udfCheckStarted                                                            #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfCheckStarted $pid sleep 8                                               #? true
#    udfCheckStarted $pid sleep 88                                              #? $_bashlyk_iErrorNoSuchProcess
#    udfCheckStarted $$ $0                                                      #? $_bashlyk_iErrorCurrentProcess
#    udfCheckStarted notvalid $0                                                #? $_bashlyk_iErrorInvalidArgument

#  SOURCE
udfCheckStarted() {

	udfOn EmptyOrMissingArgument "$*" || return $?

	local pid=$1

	udfIsNumber $1 || return $( _ iErrorNotValidArgument )

	[[ "$$" == "$1" ]] && return $( _ iErrorCurrentProcess )

	shift

	[[ "$(ps -p $pid -o args=)" =~ ${*}$ ]] && return 0 || return $(_ iErrorNoSuchProcess)

	return 0

}
#******
#****f* libpid/udfStopProcess
#  SYNOPSIS
#    udfStopProcess [pid=PID[,PID,..]] [childs] <command-line>
#  DESCRIPTION
#    Stop the processes associated with the specified command line. Options
#    allow you to manage the list of processes to stop.
#    PID of the process in which a check is excluded from an examination
#  ARGUMENTS
#    pid=PID[,..]   - comma separated list of PID. Only these processes will be
#                     stopped if they are associated with the command line
#    childs         - stop only child processes
#    <command-line> - command line for checking
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
#    ## TODO - required unique command for testing                              #-
#    local a cmd fn i pid                                                       #-
#    udfMakeTemp cmd                                                            #-
#    printf '#!/bin/sh\nread -t $1 -N 0 </dev/zero\n' | tee $cmd
#    chmod +x $cmd                                                              #-
#    for i in 800 700 600 500; do                                               #-
#     $cmd $i &                                                                 #-
#     a+="${!},"
#    done                                                                       #-
#    echo $a
#    $cmd 400 &                                                                 #-
#    pid=$!
#    udfMakeTemp fn
#    printf -- "#!/bin/sh\nfor i in 900 700 600 500; do\n$cmd \$i &\ndone\n" | tee $fn
#    chmod +x $fn
#    $fn
#    udfStopProcess                                                             #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfStopProcess childs pid=$pid $cmd 400                                    #? true
#    udfStopProcess pid=$pid $cmd 88                                            #? $_bashlyk_iErrorNoSuchProcess
#    udfStopProcess $cmd 88                                                     #? $_bashlyk_iErrorNoSuchProcess
#    udfStopProcess pid=$$ $0                                                   #? $_bashlyk_iErrorCurrentProcess
#    udfStopProcess pid=invalid $0                                              #? $_bashlyk_iErrorInvalidArgument
#    udfStopProcess childs $cmd 800                                             #? true
#    udfStopProcess childs $cmd 600                                             #? $_bashlyk_iErrorNotChildProcess
#    udfStopProcess $cmd                                                        #? true
#  SOURCE
udfStopProcess() {

	udfOn EmptyOrMissingArgument "$@" || return $?

	local bChild i pid rc s
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

	udfOn EmptyOrMissingArgument "${a[*]}" || a=( $( pgrep -f "$*") )
	udfOn EmptyOrMissingArgument "${a[*]}" || return $( _ iErrorNoSuchProcess )

	for (( i=0; i<${#a[*]}; i++ )) ; do

		rc=$( _ iErrorInvalidArgument )

		pid=${a[i]}

		udfIsNumber $pid || continue

		if (( pid == $$ )); then

			rc=$( _ iErrorCurrentProcess )
			continue

		fi

		for s in 15 9; do

			local re="\\b${pid}\\b"

			if [[ -n "$bChild" && ! "$(pgrep -P $$)" =~ $re ]]; then

				rc=$( _ iErrorNotChildProcess )
				continue

			fi

			if [[ "$(pgrep -f "$*")" =~ $re ]]; then

				if kill -${s} $pid; then

					a[i]=""
					rc=0

				else

					rc=$( _ iErrorNotPermitted )
					sleep 0.1

				fi

			else

				rc=$( _ iErrorNoSuchProcess )
				break

			fi

		done

	done

	s="${a[*]}"
	[[ -z "${s// /}" ]] && return 0 || return $rc

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
#    local fn s='#!/bin/bash\n_bashlyk_log=nouse . bashlyk\nudfSetPid || exit $?\nsleep 8\n' #-
#    udfMakeTemp fn                                                             #? true
#    export _bashlyk_pathLib                                                    #? true
#    printf -- "$s" > $fn                                                       #-
#    chmod +x $fn                                                               #? true
#    ($fn)&                                                                     #? true
#    sleep 0.1
#    ( $fn || false )                                                           #? false
#    udfSetPid                                                                  #? true
#    test -f $_bashlyk_fnPid                                                    #? true
#    head -n 1 $_bashlyk_fnPid >| grep -w $$                                    #? true
#    rm -f $_bashlyk_fnPid
#    ## TODO проверить коды возврата
#  SOURCE
udfSetPid() {

	local fnPid pid

	if [[ -n "$( _ sArg )" ]]; then

		fnPid="$( _ pathRun )/$( udfGetMd5 $( _ s0 ) $( _ sArg ) ).pid"

	else

		fnPid="$( _ pathRun )/$( _ s0 ).pid"

	fi

	mkdir -p "${fnPid%/*}" || eval $( udfOnError retecho NotExistNotCreated "${fnPid%/*}" )

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
# TODO проверить на используемость udfClean
#****f* libpid/udfGetFreeFD
#  SYNOPSIS
#    udfGetFreeFD
#  DESCRIPTION
#    get unused filedescriptor
#  OUTPUT
#    show given filedescriptor
#  EXAMPLE
#    udfGetFreeFD | grep -P "^\d+$"                                             #? true
#  SOURCE
udfGetFreeFD() {

	local i=0 iMax=$(ulimit -n)
	#
	: ${iMax:=255}
	#
	for (( i = 3; i < iMax; i++ )); do

		if [[ -e /proc/$$/fd/$i ]]; then

			continue

		else

			echo $i
			break

		fi

	done

}
#******

