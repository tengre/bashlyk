#
# $Id: libtst.sh 535 2016-06-30 16:56:53+04:00 toor $
#
#****h* BASHLYK/libmsg
#  DESCRIPTION
#    стандартный набор функций, включает автоматически управляемые функции вывода сообщений
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libmsg/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'

[[ -n "$_BASHLYK_LIBTST" ]] && return 0 || _BASHLYK_LIBTST=1
#******
#****** libmsg/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libmsg.sh ]] && . "${_bashlyk_pathLib}/libmsg.sh"
#******
#****v* libmsg/Init section
#  DESCRIPTION
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_envXSession:=}
: ${_bashlyk_aRequiredCmd_msg:="[ "}
: ${_bashlyk_aExport_msg:="udfEcho udfWarn udfThrow udfOnEmptyVariable udfThrowOnEmptyVariable udfWarnOnEmptyVariable udfMail \
    udfMessage udfNotify2X udfNotifyCommand udfGetXSessionProperties udfOnCommandNotFound udfThrowOnCommandNotFound           \
    udfWarnOnCommandNotFound"}
#******
#****f* libmsg/udfThrow
#  SYNOPSIS
#    udfThrow [-] args
#  DESCRIPTION
#    Stop the script. Returns an error code of the last command if value of
#    the special variable $_bashlyk_iLastError[$BASHPID] not defined
#    Perhaps set the the message. In the case of non-interactive execution
#    message is sent notification system.
#  INPUTS
#    -    - read message from stdin
#    args - message string. With stdin data ("-" option required) used as header
#  OUTPUT
#    show input message or data from special variable
#  RETURN VALUE
#   return ${_bashlyk_iLastError[$BASHPID]} or last non zero return code or 255
#  EXAMPLE
#    local rc=222
#    echo $(false || udfThrow rc=$?; echo ok=$?) >| grep "^Error: rc=1 .. (1)$" #? true
#    echo $rc
#    echo $(udfSetLastError $rc || udfThrow $?; echo rc=$?) >| grep -w "$rc"    #? true
#  SOURCE
udfThrow() {

	local i=$? rc
	rc=${_bashlyk_iLastError[$BASHPID]}
	udfIsNumber $rc || rc=$i
	eval $(udfOnError exitwarn $rc $*)

}
#******
