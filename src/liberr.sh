#
# $Id: liberr.sh 537 2016-08-17 01:37:18+04:00 toor $
#
#****h* BASHLYK/liberr
#  DESCRIPTION
#    стандартный набор функций, включает автоматически управляемые функции
#    вывода сообщений, контроля корректности входных данных, создания временных
#    объектов и автоматического их удаления после завершения сценария или
#    фонового процесса, обработки ошибок
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* liberr/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
[[ -n "$_BASHLYK_LIBERR" ]] && return 0 || _BASHLYK_LIBERR=1
#******
#****** liberr/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libmsg.sh ]] && . "${_bashlyk_pathLib}/libmsg.sh"
#******
#****v* liberr/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#    * $_bashlyk_sArg - аргументы командной строки вызова сценария
#    * $_bashlyk_sWSpaceAlias - заменяющая пробел последовательность символов
#    * $_bashlyk_aRequiredCmd_opt - список используемых в данном модуле внешних
#    утилит
#  SOURCE
_bashlyk_iErrorUnknown=255
_bashlyk_iErrorUnexpected=255
_bashlyk_iErrorEmptyOrMissingArgument=254
_bashlyk_iErrorNonValidArgument=253
_bashlyk_iErrorEmptyResult=252
_bashlyk_iErrorNotSupported=241
_bashlyk_iErrorNotPermitted=240
_bashlyk_iErrorBrokenIntegrity=230
_bashlyk_iErrorAbortedBySignal=220
_bashlyk_iErrorNonValidVariable=200
_bashlyk_iErrorNotExistNotCreated=190
_bashlyk_iErrorNoSuchFileOrDir=185
_bashlyk_iErrorNoSuchProcess=184
_bashlyk_iErrorCurrentProcess=183
_bashlyk_iErrorAlreadyStarted=182
_bashlyk_iErrorCommandNotFound=180
_bashlyk_iErrorUserXsessionNotFound=171
_bashlyk_iErrorXsessionNotFound=170
_bashlyk_iErrorIncompatibleVersion=169

_bashlyk_hError[$_bashlyk_iErrorUnknown]="unknown (unexpected) error"
_bashlyk_hError[$_bashlyk_iErrorEmptyOrMissingArgument]="empty or missing argument"
_bashlyk_hError[$_bashlyk_iErrorNonValidArgument]="non valid argument"
_bashlyk_hError[$_bashlyk_iErrorEmptyResult]="empty Result"
_bashlyk_hError[$_bashlyk_iErrorNotSupported]="not supported"
_bashlyk_hError[$_bashlyk_iErrorNotPermitted]="not permitted"
_bashlyk_hError[$_bashlyk_iErrorBrokenIntegrity]="broken integrity"
_bashlyk_hError[$_bashlyk_iErrorAbortedBySignal]="aborted by signal"
_bashlyk_hError[$_bashlyk_iErrorNonValidVariable]="non valid variable"
_bashlyk_hError[$_bashlyk_iErrorNotExistNotCreated]="not exist and not created"
_bashlyk_hError[$_bashlyk_iErrorNoSuchFileOrDir]="no such file or directory"
_bashlyk_hError[$_bashlyk_iErrorNoSuchProcess]="no such process"
_bashlyk_hError[$_bashlyk_iErrorCurrentProcess]="this current process"
_bashlyk_hError[$_bashlyk_iErrorAlreadyStarted]="already started"
_bashlyk_hError[$_bashlyk_iErrorCommandNotFound]="command not found"
_bashlyk_hError[$_bashlyk_iErrorUserXsessionNotFound]="user X-Session not found"
_bashlyk_hError[$_bashlyk_iErrorXsessionNotFound]="X-Session not found"
_bashlyk_hError[$_bashlyk_iErrorIncompatibleVersion]="incompatible version"

#
: ${_bashlyk_onError:=throw}
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_aRequiredCmd_err:="echo printf sed"}
: ${_bashlyk_aExport_err:="udfSetLastError udfStackTrace udfOnError udfOnError2"}
#******
#****f* liberr/udfSetLastError
#  SYNOPSIS
#    udfSetLastError <number> <string>
#  DESCRIPTION
#    Set in global variables $_bashlyk_{i,s}Error[$BASHPID] arbitrary values as
#    error states - number and string
#  INPUTS
#    <number> - error code - number or predefined name as 'iErrorXXX' or 'XXX'
#    <string> - error text
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - arguments missing
#    iErrorUnknown                - first argument is non valid
#    1-255                        - valid value of first argument
#  EXAMPLE
#    local pid=$BASHPID
#    udfSetLastError                                                            #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfSetLastError non valid argument                                         #? $_bashlyk_iErrorUnknown
#    udfSetLastError 555                                                        #? $_bashlyk_iErrorUnexpected
#    udfSetLastError AlreadyStarted "$$"                                        #? $_bashlyk_iErrorAlreadyStarted
#    udfSetLastError iErrorNonValidVariable "12NonValid Variable"               #? $_bashlyk_iErrorNonValidVariable
#    _ iLastError[$pid] >| grep -w "$_bashlyk_iErrorNonValidVariable"           #? true
#    _ sLastError[$pid] >| grep "^12NonValid Variable$"                         #? true
#  SOURCE
udfSetLastError() {

	[[ -n "$1" ]] || return $_bashlyk_iErrorEmptyOrMissingArgument

	local i

	if [[ "$1" =~ ^[0-9]+$ ]]; then

		i=$1

	else

		eval "i=\$_bashlyk_iError${1}"
		[[ -n "$i" ]] || eval "i=\$_bashlyk_${1}"

	fi

	[[ "$i" =~ ^[0-9]+$ && $i -le 255 ]] && shift || i=$_bashlyk_iErrorUnknown

	_bashlyk_iLastError[$BASHPID]=$i
	_bashlyk_sLastError[$BASHPID]="$*"

	return $i

}
#******
#****f* liberr/udfStackTrace
#  SYNOPSIS
#    udfStackTrace
#  DESCRIPTION
#    OUTPUT BASH Stack Trace
#  OUTPUT
#    BASH Stack Trace
#  EXAMPLE
#    udfStackTrace
#  SOURCE
udfStackTrace() {
 local i s
 echo "Stack Trace for ${BASH_SOURCE[0]}::${FUNCNAME[0]}:"
 for (( i=${#FUNCNAME[@]}-1; i >= 0; i-- )); do
  [[ ${BASH_LINENO[i]} == 0 ]] && continue
  echo "$s $i: call ${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}(...)"
  echo "$s $i: code $(sed -n "${BASH_LINENO[$i]}p" ${BASH_SOURCE[$i+1]})"
  s+=" "
 done
}
#******
#****f* liberr/udfOnError
#  SYNOPSIS
#    udfOnError [<action>] [<state>] [<message>]
#  DESCRIPTION
#    Flexible error handling. Processing is controlled by global variables or
#    arguments, and consists in a warning message, the function returns, or the
#    end of the script with a certain return code. Messages may include a stack
#    trace.
#  INPUTS
#    <action> - directly determines how the error handling. Possible actions:
#
#     echo     - just prepare a message from the string argument to STDOUT
#     warn     - prepare a message from the string argument for transmission to
#                the notification system
#     return   - set return from the function. In the global context - the end
#                of the script (exit)
#     retecho  - the combined action of 'echo'+'return', however, if the code is
#                not within the function, it is only the transfer of messages
#                from a string of arguments to STDOUT
#     retwarn  - the combined action of 'warn'+'return', however, if the code is
#                not within the function, it is only the transfer of messages
#                from a string of arguments to the notification system
#     exit     - set unconditional completion of the script
#     exitecho - the same as 'exit', but with the transfer of messages from a
#                string of arguments to STDOUT
#     exitwarn - the same as 'exitecho', but with the transfer of messages to
#                the notification system
#     throw    - the same as 'exitwarn', but with the transfer of messages and
#                the call stack to the notification system
#
#    If an action is not specified, it uses stored in the global variable
#    $_bashlyk_onError action. If it is not valid, then use action 'throw'
#
#    state - number or predefined name as 'iError<Name>' or '<Name>' by which
#            one can get the error code from the global variable
#            $_bashlyk_iError<..> and its description from global hash
#            $_bashlyk_hError
#            If the error code is not specified, it is set to the return code of
#            the last executed command. In the end, the resulting numeric code
#            initializes a global variable $_bashlyk_iLastError[$BASHPID]
#
#    message - error detail, such as the filename. When specifying message
#    should bear in mind that in the error table ($_bashlyk_hError) are already
#    prepared descriptions <...>
#
#  OUTPUT
#    command line, which can be performed using the eval <...>
#  EXAMPLE
#    eval $(udfOnError echo iErrorNonValidArgument "test unit")                          #? $_bashlyk_iErrorNonValidArgument
#    udfIsNumber 020h || eval $(udfOnError echo $? "020h")                               #? $_bashlyk_iErrorNonValidArgument
#    udfIsValidVariable 1NonValid || eval $(udfOnError warn $? "1NonValid")              #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable 2NonValid || eval $(udfOnError warn "2NonValid")                 #? $_bashlyk_iErrorNonValidVariable
#    udfOnError exit    NonValidArgument "test unit" >| grep " exit \$?"         #? true
#    udfOnError return  NonValidArgument "test unit" >| grep " return \$?"       #? true
#    udfOnError retecho NonValidArgument "test unit" >| grep "echo.* return \$?" #? true
#    udfOnError retwarn NonValidArgument "test unit" >| grep "Warn.* return \$?" #? true
#    udfOnError throw   NonValidArgument "test unit" >| grep "dfWarn.* exit \$?" #? true
#    eval $(udfOnError exitecho EmptyOrMissingArgument) >| grep "E.*: em.*o.*mi" #? true
#    _ onError warn
#    eval $(udfOnError iErrorNonValidArgument "test unit")                               #? $_bashlyk_iErrorNonValidArgument
#  SOURCE
udfOnError() {

	local rs=$? sAction=$_bashlyk_onError sMessage='' s IFS=$' \t\n'

	case "$sAction" in

		echo|exit|exitecho|exitwarn|retecho|retwarn|return|warn|throw)
		;;

        *)
			sAction=throw
        ;;

	esac

	case "$1" in

		echo|exit|exitecho|exitwarn|retecho|retwarn|return|warn|throw)

			sAction=$1
			shift
		;;

	esac

	udfSetLastError $1
	s=$?

	if [[ $s == $_bashlyk_iErrorUnknown ]]; then

		if [[ -n "${_bashlyk_hError[$rs]}" ]]; then

			s=$rs
			rs="${_bashlyk_hError[$rs]} - $* .. ($rs)"

		else

			(( $rs == 0 )) && rs=$_bashlyk_iErrorUnexpected
			rs="$* .. ($rs)"
			s=$_bashlyk_iErrorUnexpected

		fi

	else

		shift

		if [[ -n "${_bashlyk_hError[$s]}" ]]; then

			rs="${_bashlyk_hError[$s]} - $* .. ($s)"

		else

			(( $s == 0 )) && s=$_bashlyk_iErrorUnexpected
			rs="$* .. ($s)"

		fi
	fi

	rs=${rs//\(/\\\(}
	rs=${rs//\)/\\\)}

	if [[ "${FUNCNAME[1]}" == "main" || -z "${FUNCNAME[1]}" ]]; then

		[[ "$sAction" == "retecho" ]] && sAction='exitecho'
		[[ "$sAction" == "retwarn" ]] && sAction='exitwarn'
		[[ "$sAction" == "return"  ]] && sAction='exit'
	fi

	case "$sAction" in

		       echo) sAction="";               sMessage="echo  Warn: ${rs};";;
		    retecho) sAction="; return \$?";   sMessage="echo Error: ${rs};";;
		   exitecho) sAction="; exit \$?";     sMessage="echo Error: ${rs};";;
		       warn) sAction="";               sMessage="udfWarn Warn: ${rs};";;
		    retwarn) sAction="; return \$?";   sMessage="udfWarn Error: ${rs};";;
		   exitwarn) sAction="; exit \$?";     sMessage="udfWarn Error: ${rs};";;
		      throw) sAction="; exit \$?";     sMessage="udfStackTrace | udfWarn - Error: ${rs};";;
		exit|return) sAction="; $sAction \$?"; sMessage="";;

	esac

	printf "%s udfSetLastError %s %s%s\n" "$sMessage" "$s" "$rs" "${sAction}"

}
#******
#****f* liberr/udfOnError2
#  SYNOPSIS
#    udfOnError2 [<action>] [<state>] [<message>]
#  DESCRIPTION
#    Flexible error handling. Processing is controlled by global variables or
#    arguments, and consists in a warning message, the function returns, or the
#    end of the script with a certain return code. Messages may include a stack
#    trace. Unlike udfOnError, all output is sent to stderr
#  INPUTS
#    <action> - directly determines how the error handling. Possible actions:
#
#     echo     - just prepare a message from the string argument to STDOUT
#     warn     - prepare a message from the string argument for transmission to
#                the notification system
#     return   - set return from the function. In the global context - the end
#                of the script (exit)
#     retecho  - the combined action of 'echo'+'return', however, if the code is
#                not within the function, it is only the transfer of messages
#                from a string of arguments to STDOUT
#     retwarn  - the combined action of 'warn'+'return', however, if the code is
#                not within the function, it is only the transfer of messages
#                from a string of arguments to the notification system
#     exit     - set unconditional completion of the script
#     exitecho - the same as 'exit', but with the transfer of messages from a
#                string of arguments to STDOUT
#     exitwarn - the same as 'exitecho', but with the transfer of messages to
#                the notification system
#     throw    - the same as 'exitwarn', but with the transfer of messages and
#                the call stack to the notification system
#
#    If an action is not specified, it uses stored in the global variable
#    $_bashlyk_onError action. If it is not valid, then use action 'throw'
#
#    state - number or predefined name as 'iError<Name>' or '<Name>' by which
#            one can get the error code from the global variable
#            $_bashlyk_iError<..> and its description from global hash
#            $_bashlyk_hError
#            If the error code is not specified, it is set to the return code of
#            the last executed command. In the end, the resulting numeric code
#            initializes a global variable $_bashlyk_iLastError[$BASHPID]
#
#    message - error detail, such as the filename. When specifying message
#    should bear in mind that in the error table ($_bashlyk_hError) are already
#    prepared descriptions <...>
#
#  OUTPUT
#    command line, which can be performed using the eval <...>
#  EXAMPLE
#    eval $(udfOnError2 echo iErrorNonValidArgument "test unit")                          #? $_bashlyk_iErrorNonValidArgument
#    udfIsNumber 020h || eval $(udfOnError2 echo $? "020h")                               #? $_bashlyk_iErrorNonValidArgument
#    udfIsValidVariable 1NonValid || eval $(udfOnError2 warn $? "1NonValid")              #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable 2NonValid || eval $(udfOnError2 warn "2NonValid")                 #? $_bashlyk_iErrorNonValidVariable
#    udfOnError2 exit    NonValidArgument "test unit" >| grep " exit \$?"         #? true
#    udfOnError2 return  NonValidArgument "test unit" >| grep " return \$?"       #? true
#    udfOnError2 retecho NonValidArgument "test unit" >| grep "echo.* return \$?" #? true
#    udfOnError2 retwarn NonValidArgument "test unit" >| grep "Warn.* return \$?" #? true
#    udfOnError2 throw   NonValidArgument "test unit" >| grep "dfWarn.* exit \$?" #? true
#    eval $(udfOnError2 exitecho EmptyOrMissingArgument) 2>&1 >| grep "E.*: em.*o.*mi" #? true
#    _ onError warn
#    eval $(udfOnError2 iErrorNonValidArgument "test unit")                               #? $_bashlyk_iErrorNonValidArgument
#  SOURCE
udfOnError2() {

	udfOnError "$@" | sed -re "s/;/ >\&2;/"

}
#******
