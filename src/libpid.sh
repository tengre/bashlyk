#
# $Id: libpid.sh 562 2016-10-24 22:23:26+04:00 toor $
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
: ${_bashlyk_afnClean:=}
: ${_bashlyk_apathClean:=}
: ${_bashlyk_fnPid:=}
: ${_bashlyk_fnSock:=}
: ${_bashlyk_s0:=${0##*/}}
: ${_bashlyk_pathRun:=/tmp}
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_aRequiredCmd_pid:="head kill mkdir printf ps rm rmdir sleep xargs"}
: ${_bashlyk_aExport_pid:="udfCheckStarted udfClean udfExitIfAlreadyStarted udfSetPid udfStopProcess"}
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
#    (sleep 8)&
#    local pid=$!
#    ps -p $pid -o pid= -o args=
#    udfCheckStarted                                                            #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfCheckStarted $pid sleep 8                                               #? true
#    udfCheckStarted $pid sleep 88                                              #? $_bashlyk_iErrorNoSuchProcess
#    udfCheckStarted $$ $0                                                      #? $_bashlyk_iErrorCurrentProcess
#    udfCheckStarted notvalid $0                                                #? $_bashlyk_iErrorInvalidArgument

#  SOURCE
udfCheckStarted() {

	udfOn EmptyOrMissingArgument "$*" || return $?

	local pid="$1" IFS=$' \t\n'

	udfIsNumber $1 || return $( _ iErrorNotValidArgument )

	[[ "$$" == "$1" ]] && return $( _ iErrorCurrentProcess )

	shift

	[[ "$(ps -p $pid -o args=)" =~ ${*}$ ]] && return 0 || return $(_ iErrorNoSuchProcess)

	return 0

}
#******
#****f* libpid/udfStopProcess
#  SYNOPSIS
#    udfStopProcess [pid=PID[,PID,..]] [childs] [noargs] <command-line>
#  DESCRIPTION
#    stop process with given PID (optional) and the command line
#    PID of the process in which a check is excluded from an examination
#  INPUTS
#    pid=PID[,..]   - comma separated list of PID
#    childs         - stop only child processes
#    noargs         - check only command name (without arguments)
#    <command-line> - command line for checking
#  RETURN VALUE
#    0                 - stopped all inctances of the specified command line
#    NoSuchProcess     - processes for the specified command is not detected
#    NoChildProcess    - child processes for the specified command line is not
#                        detected.
#    CurrentProcess    - process for this command line is identical to the PID
#                        of the current process
#    InvalidArgument   - PID is not number
#    EmptyOrMissing... - no arguments
#  EXAMPLE
#    ## TODO - required unique command for testing                              #-
#    local a fn i pid                                                           #-
#    for i in 800 700 600 500; do                                               #-
#    sleep $i &                                                                 #-
#    done                                                                       #-
#    (sleep 400)&
#    pid=$!
#    udfMakeTemp fn
#    printf '#!/bin/sh\nfor i in 900 700 600 500; do\nsleep $i &\ndone\n' | tee $fn
#    sh $fn
#    udfStopProcess                                                             #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfStopProcess childs pid=$pid sleep 400                                   #? true
#    udfStopProcess pid=$pid sleep 88                                           #? $_bashlyk_iErrorNoSuchProcess
#    udfStopProcess sleep 88                                                    #? $_bashlyk_iErrorNoSuchProcess
#    udfStopProcess pid=$$ $0                                                   #? $_bashlyk_iErrorCurrentProcess
#    udfStopProcess pid=invalid $0                                              #? $_bashlyk_iErrorInvalidArgument
#    udfStopProcess childs pid=$a sleep 800                                     #? true
#    udfStopProcess childs pid=$a sleep 600                                     #? $_bashlyk_iErrorNotChildProcess
#    udfStopProcess noargs sleep                                                #? true
#  SOURCE
udfStopProcess() {

	udfOn EmptyOrMissingArgument "$@" || return $?

	local bChild i pid rc s sMode=args
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

			noargs)
				sMode=comm
				shift
			;;

		esac

	done

	udfOn EmptyOrMissingArgument "${a[*]}" || a=( $( ps -C "$1" -o pid,args= | grep "$*" | cut -f 1 -d' ' | xargs ) )
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

			if [[ -n "$bChild" && -z "$( ps --ppid $$ -o pid= | xargs | grep -w $pid )" ]]; then

				rc=$( _ iErrorNotChildProcess )
				continue

			fi

			[[ "$( ps -p $pid -o ${sMode}= )" =~ ${*}$ ]] && rc=0 || rc=$( _ iErrorNoSuchProcess )

			if [[ $rc == 0 ]]; then

				kill -${s} $pid
				rc=$?
				a[i]=""
				sleep 0.1

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
#    Защита от повторного вызова сценария с данными аргументами.
#    Если такой скрипт не запущен, то создается PID файл.
#    Причём, если скрипт имеет аргументы, то этот файл создаётся в отдельном
#    подкаталоге
#    с именем файла в виде md5-хеша командной строки, иначе pid файл создается в
#    самом каталоге для PID-файлов с именем, производным от имени скрипта.
#  RETURN VALUE
#    0                        - PID file for command line successfully created
#    iErrorAlreadyStarted     - PID file exist and command line process already
#                               started
#    iErrorNotExistNotCreated - PID file don't created
#  EXAMPLE
#    udfSetPid                                                                  #? true
#    test -f $_bashlyk_fnPid                                                    #? true
#    head -n 1 $_bashlyk_fnPid >| grep -w $$                                    #? true
#    ## TODO проверить коды возврата
#  SOURCE
udfSetPid() {
 local fnPid pid IFS=$' \t\n'
 if [[ -n "$_bashlyk_sArg" ]]; then
  fnPid="${_bashlyk_pathRun}/$(udfGetMd5 ${_bashlyk_s0} ${_bashlyk_sArg}).pid"
 else
  fnPid="${_bashlyk_pathRun}/${_bashlyk_s0}.pid"
 fi
 mkdir -p "${_bashlyk_pathRun}" || eval $(udfOnError return iErrorNotExistNotCreated '${_bashlyk_pathRun}')
 [[ -f "$fnPid" ]] && pid=$(head -n 1 "$fnPid")
 if [[ -n "$pid" ]]; then
  udfCheckStarted $pid ${_bashlyk_s0} ${_bashlyk_sArg} && {
   eval $(udfOnError retecho iErrorAlreadyStarted '$0 : Already started with pid = $pid')
  }
 fi
 printf -- "%s\n%s\n" "$$" "$0 ${_bashlyk_sArg}" > $fnPid \
  || eval $(udfOnError rewarn iErrorNotExistNotCreated 'pid file $fnPid is not created...')
 _bashlyk_fnPid=$fnPid
 udfAddFile2Clean $fnPid
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
# TODO проверить на используемость
#****f* libpid/udfClean
#  SYNOPSIS
#    udfClean
#  DESCRIPTION
#    Remove files and folder listed on the variables
#    $_bashlyk_afnClean and  $_bashlyk_apathClean
#  RETURN VALUE
#    Last delete operation status
#  EXAMPLE
#    udfClean
#  SOURCE
udfClean() {
 local fn IFS=$' \t\n' a="${_bashlyk_afnClean} ${_bashlyk_apathClean} $*"
 for fn in $a
 do
  [[ -n "$fn" && -f "$fn" ]] && rm -f $1 "$fn"
  [[ -n "$fn" && -d "$fn" ]] && rmdir "$fn" >/dev/null 2>&1
 done
 return $?
}
#******
