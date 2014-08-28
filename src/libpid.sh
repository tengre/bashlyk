#
# $Id$
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
: ${_bashlyk_s0:=$(basename $0)}
: ${_bashlyk_pathRun:=/tmp}
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_aRequiredCmd_pid:="[ echo file grep head mkdir ps rm rmdir w"}
: ${_bashlyk_aExport_pid:="udfCheckStarted udfSetPid udfExitIfAlreadyStarted"}
#******
#****f* libpid/udfCheckStarted
#  SYNOPSIS
#    udfCheckStarted PID [command [args]]
#  DESCRIPTION
#    Проверка наличия процесса с указанными PID и командной строкой
#    PID процесса, в котором производится проверка, исключается из рассмотрения
#  INPUTS
#    PID     - PID
#    command - command
#    args    - arguments
#  RETURN VALUE
#    0                    - Процесс существует для указанной командной строки
#    iErrorNoSuchProcess  - Процесс для указанной командной строки не обнаружен.
#    iErrorCurrentProcess - Процесс для данной командной строки идентичен PID
#                           текущего процесса
#  EXAMPLE
#    (sleep 8)&
#    local pid=$!
#    ps -p $pid -o pid= -o args=
#    udfCheckStarted $pid sleep 8                                               #? true
#    udfCheckStarted $pid sleep 88                                              #? $_bashlyk_iErrorNoSuchProcess
#    udfCheckStarted $$ $0                                                      #? $_bashlyk_iErrorCurrentProcess
#  SOURCE
udfCheckStarted() {
 [[ -n "$*"      ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 [[ "$$" == "$1" ]] && eval $(udfOnError return iErrorCurrentProcess)
 local pid="$1"
 shift
 ps -p $pid -o args= | grep "${*}$" >/dev/null 2>&1 || eval $(udfOnError return iErrorNoSuchProcess)
 return 0
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
 local fnPid pid
 if [[ -n "$_bashlyk_sArg" ]]; then
  fnPid="${_bashlyk_pathRun}/$(udfGetMd5 ${_bashlyk_s0} ${_bashlyk_sArg}).pid"
 else
  fnPid="${_bashlyk_pathRun}/${_bashlyk_s0}.pid"
 fi
 mkdir -p "${_bashlyk_pathRun}" || eval $(udfOnError return iErrorNotExistNotCreated "${_bashlyk_pathRun}")
 [[ -f "$fnPid" ]] && pid=$(head -n 1 "$fnPid")
 if [[ -n "$pid" ]]; then
  udfCheckStarted $pid ${_bashlyk_s0} ${_bashlyk_sArg} && {
   echo "$0 : Already started with pid = $pid"
   udfLastError iErrorAlreadyStarted "$pid"
   return $?
  }
 fi
 echo $$ > $fnPid || {
  udfWarn "Warn: pid file $fnPid not created..."
  eval $(udfOnError return iErrorNotExistNotCreated "$fnPid")
 }
 echo "$0 ${_bashlyk_sArg}" >> $fnPid
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
 local fn
 local a="${_bashlyk_afnClean} ${_bashlyk_apathClean} $*"
 for fn in $a
 do
  [[ -n "$fn" && -f "$fn" ]] && rm -f $1 "$fn"
  [[ -n "$fn" && -d "$fn" ]] && rmdir "$fn" >/dev/null 2>&1
 done
 return $?
}
#******
