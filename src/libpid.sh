#
# $Id$
#
#****h* bashlyk/libpid
#  DESCRIPTION
#    bashlyk PID library
#    Обслуживание процессов
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/libpid/Require Once
#  DESCRIPTION
#    Глобальная переменная $_BASHLYK_LIBPID обеспечивает
#    защиту от повторного использования данного модуля
#  SOURCE
[ -n "$_BASHLYK_LIBPID" ] && return 0 || _BASHLYK_LIBPID=1
#******
#****v*  bashlyk/libpid/Init section
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
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
: ${_bashlyk_aRequiredCmd_pid:="cat date echo grep head mkdir ps rm sed sleep ["}
#******
#****** bashlyk/libpid/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
[ -s "${_bashlyk_pathLib}/liblog.sh" ] && . "${_bashlyk_pathLib}/liblog.sh"
[ -s "${_bashlyk_pathLib}/libmd5.sh" ] && . "${_bashlyk_pathLib}/libmd5.sh"
#******
#****f* bashlyk/libpid/udfCheckStarted
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
#    0 - Процесс с PID существует для указанной командной строки (command args)
#    1 - Процесс с PID для проверяемой командной строки не обнаружен.
#  EXAMPLE
#    udfCheckStarted $pid $0 $* \
#    && eval 'echo "$0 : Already started with pid = $pid"; return 1'
#  SOURCE
udfCheckStarted() {
 [ -n "$*" ] || return -1
 local pid=$1
 local cmd=${2:-}
 shift 2
 [ -n "$(ps -p $pid -o pid= -o args= | grep -vw $$ | grep -w -e "$cmd" | grep -e "$*" | head -n 1)" ] && return 0 || return 1
}
#******
#****f* bashlyk/libpid/udfSetPid
#  SYNOPSIS
#    udfSetPid
#  DESCRIPTION
#    Защита от повторного вызова сценария с данными аргументами.
#    Если такой скрипт не запущен, то создается PID файл.
#    Причём, если скрипт имеет аргументы, то этот файл создаётся в отдельном подкаталоге
#    с именем файла в виде md5-хеша командной строки, иначе pid файл создается в самом #    #    каталоге для PID-файлов с именем, производным от имени скрипта.
#  RETURN VALUE
#    0 - PID file for command line successfully created
#    1 - PID file exist and command line process already started
#   -1 - PID file don't created. Error status
#  EXAMPLE
#    udfSetPid
#  SOURCE
udfSetPid() {
 local fnPid pid
 [ -n "$_bashlyk_sArg" ] \
  && fnPid="${_bashlyk_pathRun}/$(udfGetMd5 ${_bashlyk_s0} ${_bashlyk_sArg}).pid" \
  || fnPid="${_bashlyk_pathRun}/${_bashlyk_s0}.pid"
 mkdir -p ${_bashlyk_pathRun} \
  || eval 'udfWarn "Warn: path for PIDs ${_bashlyk_pathRun} not created..."; return -1'
 [ -f "$fnPid" ] && pid=$(head -n 1 ${fnPid})
 if [ -n "$pid" ]; then
  udfCheckStarted $pid ${_bashlyk_s0} ${_bashlyk_sArg} \
   && eval 'echo "$0 : Already started with pid = $pid"; return 1'
 fi
 echo $$ > ${fnPid} \
 || eval 'udfWarn "Warn: pid file $fnPid not created..."; return -1'
 echo "$0 ${_bashlyk_sArg}" >> $fnPid
 _bashlyk_fnPid=$fnPid
 udfAddFile2Clean $fnPid
 return 0
}
#******
#****f* bashlyk/libpid/udfExitIfAlreadyStarted
#  SYNOPSIS
#    udfExitIfAlreadyStarted
#  DESCRIPTION
#    Alias-wrapper for udfSetPid with extended behavior:
#    If command line process already exist then
#    this current process with identical command line stopped
#    else created pid file and current process don`t stopped.
#  RETURN VALUE
#    0 - PID file for command line successfully created
#    1 - PID file exist and command line process already started,
#        current process stopped
#   -1 - PID file don't created. Error status - current process stopped
#  EXAMPLE
#    udfExitIfAlreadyStarted
#  SOURCE
udfExitIfAlreadyStarted() {
 udfSetPid $*
 case $? in
  -1) exit  -1 ;;
   0) return 0 ;;
   1) exit   0 ;;
 esac
}
#******
#****f* bashlyk/libpid/udfClean
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
  [ -n "$fn" -a -f "$fn" ] && rm -f $1 "$fn"
  [ -n "$fn" -a -d "$fn" ] && rmdir "$fn" >/dev/null 2>&1
 done
 return $?
}
#******
#****u* bashlyk/libpid/udfLibPid
#  SYNOPSIS
#    udfLibPid
# DESCRIPTION
#   bashlyk PID library test unit
#   Запуск проверочных операций модуля выполняется если только аргументы 
#   командной строки cодержат строку вида "--bashlyk-test=[.*,]pid[,.*]",
#   где * - ярлыки на другие тестируемые библиотеки
#  SOURCE
udfLibPid() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -E -e "--bashlyk-test=.*pid")" ] \
  && return 0
 local sArg="${_bashlyk_sArg}" b=1
 printf "\n- libpid.sh tests:\n\n"
 echo -n "Check udfExitIfAlreadyStarted: "
 udfExitIfAlreadyStarted
 echo -n '.'
 [ "$$" -eq "$(head -n 1 ${_bashlyk_fnPid})" ] \
  && echo -n "." || { echo -n '?'; b=0; } 
 #printf "Pid file: ${_bashlyk_fnPid}\n\n"
 _bashlyk_sArg=
 udfExitIfAlreadyStarted
 _bashlyk_sArg="$sArg"
 echo -n '.'
 [ "$$" -eq "$(head -n 1 ${_bashlyk_fnPid})" ] \
  && echo -n "." || { echo -n '?'; b=0; } 
 #printf "Pid file: ${_bashlyk_fnPid}\n"
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 printf "\n--\n\n"
 return 0
}
#******
#****** bashlyk/libpid/Main section
# DESCRIPTION
#   Running PID library test unit if $_bashlyk_sArg ($*) contains
#   substrings "--bashlyk-test=" and "pid" - command for test using
#  SOURCE
udfLibPid
#******
