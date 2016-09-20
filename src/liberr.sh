#
# $Id: liberr.sh 554 2016-09-20 21:37:14+04:00 toor $
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
_bashlyk_iErrorUnknown=254
_bashlyk_iErrorUnexpected=254
_bashlyk_iErrorEmptyOrMissingArgument=253
_bashlyk_iErrorMissingArgument=253
_bashlyk_iErrorEmptyArgument=253
_bashlyk_iErrorNonValidArgument=252
_bashlyk_iErrorNotValidArgument=252
_bashlyk_iErrorInvalidArgument=252
_bashlyk_iErrorEmptyResult=251
_bashlyk_iErrorNotSupported=241
_bashlyk_iErrorNotPermitted=240
_bashlyk_iErrorBrokenIntegrity=230
_bashlyk_iErrorAbortedBySignal=220
_bashlyk_iErrorNonValidVariable=200
_bashlyk_iErrorInvalidVariable=200
_bashlyk_iErrorInvalidFunction=199
_bashlyk_iErrorEmptyVariable=198
_bashlyk_iErrorNotExistNotCreated=190
_bashlyk_iErrorNoSuchFileOrDir=185
_bashlyk_iErrorNoSuchProcess=184
_bashlyk_iErrorCurrentProcess=183
_bashlyk_iErrorAlreadyStarted=182
_bashlyk_iErrorCommandNotFound=180
_bashlyk_iErrorUserXsessionNotFound=171
_bashlyk_iErrorXsessionNotFound=170
_bashlyk_iErrorIncompatibleVersion=169
_bashlyk_iErrorTryBoxException=168
_bashlyk_Success=0

_bashlyk_hError[$_bashlyk_iErrorUnknown]="unknown (unexpected) error"
_bashlyk_hError[$_bashlyk_iErrorMissingArgument]="empty or missing argument"
_bashlyk_hError[$_bashlyk_iErrorInvalidArgument]="invalid argument"
_bashlyk_hError[$_bashlyk_iErrorEmptyVariable]="empty variable"
_bashlyk_hError[$_bashlyk_iErrorEmptyResult]="empty Result"
_bashlyk_hError[$_bashlyk_iErrorNotSupported]="not supported"
_bashlyk_hError[$_bashlyk_iErrorNotPermitted]="not permitted"
_bashlyk_hError[$_bashlyk_iErrorBrokenIntegrity]="broken integrity"
_bashlyk_hError[$_bashlyk_iErrorAbortedBySignal]="aborted by signal"
_bashlyk_hError[$_bashlyk_iErrorInvalidVariable]="invalid variable"
_bashlyk_hError[$_bashlyk_iErrorInvalidFunction]="invalid function"
_bashlyk_hError[$_bashlyk_iErrorNotExistNotCreated]="not exist and not created"
_bashlyk_hError[$_bashlyk_iErrorNoSuchFileOrDir]="no such file or directory"
_bashlyk_hError[$_bashlyk_iErrorNoSuchProcess]="no such process"
_bashlyk_hError[$_bashlyk_iErrorCurrentProcess]="this current process"
_bashlyk_hError[$_bashlyk_iErrorAlreadyStarted]="already started"
_bashlyk_hError[$_bashlyk_iErrorCommandNotFound]="command not found"
_bashlyk_hError[$_bashlyk_iErrorUserXsessionNotFound]="user X-Session not found"
_bashlyk_hError[$_bashlyk_iErrorXsessionNotFound]="X-Session not found"
_bashlyk_hError[$_bashlyk_iErrorIncompatibleVersion]="incompatible version"
_bashlyk_hError[$_bashlyk_iErrorTryBoxException]="try box exception"
#
: ${_bashlyk_onError:=throw}
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_aRequiredCmd_err:="echo exit printf sed which"}
: ${_bashlyk_aExport_err:="udfCommandNotFound udfEmptyOrMissingArgument udfOn  \
  udfEmptyVariable udfOnCommandNotFound udfOnEmptyOrMissingArgument            \
  udfOnEmptyVariable udfOnError udfOnError2 udfSetLastError udfStackTrace      \
  udfThrow udfThrowOnCommandNotFound udfThrowOnEmptyOrMissingArgument          \
  udfThrowOnEmptyVariable udfWarnOnCommandNotFound                             \
  udfWarnOnEmptyOrMissingArgument udfWarnOnEmptyVariable"}
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

	printf -- "%s udfSetLastError %s %s%s\n" "$sMessage" "$s" "$rs" "${sAction}"

}
#******
#****f* liberr/udfOnError2
#  SYNOPSIS
#    udfOnError2 [<action>] [<state>] [<message>]
#  DESCRIPTION
#    Same as udfOnError except output to stderr
#  INPUTS
#    see udfOnError
#  OUTPUT
#    see udfOnError
#  EXAMPLE
#    #see udfOnError
#    eval $(udfOnError2 exitecho EmptyOrMissingArgument) 2>&1 >| grep "E.*: em.*o.*mi" #? true
#    _ onError warn
#  SOURCE
udfOnError2() {

	udfOnError "$@" | sed -re "s/;/ >\&2;/"

}
#******
#****f* liberr/udfThrow
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
#    local rc=$(echo "$RANDOM / 256" | bc)
#    echo $(false || udfThrow rc=$?; echo ok=$?) >| grep "^Error: rc=1 .. (1)$" #? true
#    echo $(udfSetLastError $rc || udfThrow $?; echo rc=$?) >| grep -w "$rc"    #? true
#  SOURCE
udfThrow() {

	local i=$? rc

	rc=${_bashlyk_iLastError[$BASHPID]}

	udfIsNumber $rc || rc=$i

	eval $(udfOnError exitwarn $rc $*)

}
#******
shopt -s expand_aliases
alias try-every-line="udfTryEveryLine <<-catch-every-line"
#****f* liberr/udfTryEveryLine
#  SYNOPSIS
#    try-every-line
#    <commands>
#    ...
#    catch-every-line
#  DESCRIPTION
#    evaluate every line on fly between try... and catch...
#    expected that these lines are independent external commands.
#    expected that these lines are independent external commands, the output of
#    which is suppressed.
#    Successful execution of the every command marked by the dot without
#    linefeed, on error execution stopped and displayed description of the error
#    and generated call stack
#  EXAMPLE
#    local fn s                                                                 #-
#    fn=$(mktemp --suffix=.sh || tempfile -s test.sh)                           #? true
#    s='Error: try box exception - internal line: 3, code: touch /not.*(168)'
#    cat <<-EOF > $fn                                                           #-
#     . bashlyk                                                                 #-
#     try-every-line                                                            #-
#      uname -a                                                                 #-
#      date -R                                                                  #-
#      touch /not-exist.$fn/file                                                #-
#      true                                                                     #-
#     catch-every-line                                                          #-
#    EOF                                                                        #-
#    chmod +x $fn
#    bash -c $fn 2>&1 >| grep "$s"                                              #? true
#    rm -f $fn
#  SOURCE
udfTryEveryLine() {

	local b fn i s

	b=true
	i=0

	udfMakeTemp fn
	#
	while read s; do

		i=$((i+1))

		[[ -n "$s" ]] || continue

		eval "$s" >$fn 2>&1 && echo -n "." || {

			_ iTryBlockLine $i
			b=false
			break
		}

	done

	if ! $b; then

		echo "?"
		[[ -s $fn ]] && udfDebug 0 "Error: try box exception output: $(< $fn)"
 		eval $( udfOnError throw TryBoxException "internal line: ${i}, code: ${s}" )

	else

		echo "ok."

	fi

}
#******
#****f* liberr/udfOn
#  SYNOPSIS
#    udfOn <error> [<action>] <args>
#  DESCRIPTION
#    Checks the list of arguments <args> to the <error> (the first argument) and
#    applies the <action> (the second argument, may be omitted) if the condition
#    is satisfied at least one of this arguments
#  INPUTS
#    <error>  - error condition on which the arguments are checked, now
#               supported CommandNotFound, EmptyVariable, EmptyOrMissingArgument
#    <action> - one of return, echo, warn, exit, throw:
#    return   - set return from the function. In the global context - the end
#               of the script (exit)
#    echo     - just prepare a message from the string argument to STDOUT and
#               set return if the code is within the function
#    warn     - prepare a message from the string argument for transmission to
#               the notification system and set return if the code is within the
#               function
#    exit     - set unconditional completion of the script
#    throw    - set unconditional completion of the script and prepare a message
#               and the call stack for transmission to the notification system
#    <args>   - list of arguments for checking
#  OUTPUT
#    Error or warning message with listing the arguments on which the error is
#    triggered by the condition
#  EXAMPLE
#    ## TODO improved tests
#    local cmdYes='sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    udfOn CommandNotFound                                                     #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfOn CommandNotFound $cmdNo1                                             #? $_bashlyk_iErrorCommandNotFound
#    $(udfOn CommandNotFound $cmdNo2 || exit 123)                              #? 123
#    udfOn CommandNotFound WARN $cmdYes $cmdNo1 $cmdNo2 >| grep "Error.*bin.*" #? true
#    udfOn CommandNotFound Echo $cmdYes $cmdNo1 $cmdNo2 >| grep ', bin'        #? true
#    $(udfOn CommandNotFound  Exit $cmdNo1 >/dev/null 2>&1; true)              #? $_bashlyk_iErrorCommandNotFound
#    $(udfOn CommandNotFound Throw $cmdNo2 >/dev/null 2>&1; true)              #? $_bashlyk_iErrorCommandNotFound
#    udfOn CommandNotFound $cmdYes                                             #? true
#    udfOn MissingArgument ""                                                  #? $_bashlyk_iErrorMissingArgument
#    udfOn EmptyArgument ""                                                    #? $_bashlyk_iErrorMissingArgument
#    udfOn EmptyResult ""                                                      #? $_bashlyk_iErrorEmptyResult
#    udfOn EmptyResult return ""                                               #? $_bashlyk_iErrorEmptyResult
#  SOURCE

udfOn() {

	local cmd csv e i IFS j s

	cmd='return'
	i=0
	j=0
	IFS=$' \t\n'
	e=$1

	if [[ $1 =~ ^(CommandNotFound|Empty(Variable|Argument|OrMissingArgument|Result)|Invalid(Argument|Variable)|MissingArgument)$ ]]; then

		e=$1

	else

		eval $( udfOnError iErrorInvalidArgument "1" )
		return $( _ iErrorInvalidArgument )

	fi

	shift

	case "$1" in

	        [Ee][Cc][Hh][Oo]) cmd='retecho'; shift;;
	        [Ee][Xx][Ii][Tt]) cmd='exit';    shift;;
	        [Ww][Aa][Rr][Nn]) cmd='retwarn'; shift;;
	    [Tt][Hh][Rr][Oo][Ww]) cmd='throw';   shift;;
	[Rr][Ee][Tt][Uu][Rr][Nn]) cmd='return';  shift;;
	                      '')
				  [[ $e =~ ^(Empty|Missing) && ! $e =~ EmptyVariable ]] || e='EmptyOrMissingArgument'
				  eval $( udfOnError $cmd $e 'no arguments' )
				  ;;

	esac

	if [[ -z "$@" ]]; then

		[[ $e =~ ^(Empty|Missing) && ! $e =~ ^EmptyVariable ]] || e='EmptyOrMissingArgument'
		eval $( udfOnError $cmd $e 'no arguments' )

	fi

	for s in "$@"; do

		: $(( j++ ))

		if ! typeset -f "udf${e}" >/dev/null 2>&1; then

			eval $( udfOnError2 InvalidFunction "udf${e}" )
			continue

		fi

		if udf${e} $s; then

			[[ -n "$s" ]] || s=$j

			(( i++ == 0 )) && csv=$s || csv+=", $s"

		fi


	done

	[[ -n "$csv" ]] && eval $( udfOnError $cmd ${e} '$csv (total $i)' )

	return 0
}
#******
#****f* liberr/udfCommandNotFound
#  SYNOPSIS
#    udfCommandNotFound <filename>
#  DESCRIPTION
#    return true if argument is empty, nonexistent or not executable
#    designed to check the conditions in the function udfOn
#  INPUTS
#    filename - argument for executable file matching by searching the PATH
#    (used which)
#  RETURN VALUE
#    0 - no arguments, specified filename is nonexistent or not executable
#    1 - specified filename are found and executable
#  EXAMPLE
#    local cmdYes='sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    udfCommandNotFound                                                         #? true
#    udfCommandNotFound $cmdNo1                                                 #? true
#    $(udfCommandNotFound $cmdNo2 && exit 123)                                  #? 123
#    udfCommandNotFound $cmdYes                                                 #? false
#  SOURCE
udfCommandNotFound() {

	[[ -n "$1" && -n "$( which $1 )" ]] && return 1 || return 0

}
#******
#****f* liberr/udfInvalidVariable
#  SYNOPSIS
#    udfInvalidVariable <variable>
#  DESCRIPTION
#    return true if argument is empty, non valid variable, designed to check the
#    conditions in the function udfOn
#  INPUTS
#    variable - expected variable name
#  RETURN VALUE
#    0 - argument is empty, non valid variable
#    1 - valid variable
#  EXAMPLE
#    udfInvalidVariable                                                         #? true
#    udfInvalidVariable a1                                                      #? false
#    $(udfInvalidVariable 2b && exit 123)                                       #? 123
#    $(udfInvalidVariable c3 || exit 123)                                       #? 123
#  SOURCE
udfInvalidVariable() {

	[[ -n "$1" ]] && udfIsValidVariable "$1" && return 1 || return 0

}
#******
#****f* liberr/udfEmptyVariable
#  SYNOPSIS
#    udfEmptyVariable <variable>
#  DESCRIPTION
#    return true if argument is empty, non valid or empty variable
#    designed to check the conditions in the function udfOn
#  INPUTS
#    variable - expected variable name
#  RETURN VALUE
#    0 - argument is empty, non valid or empty variable
#    1 - valid not empty variable
#  EXAMPLE
#    local a b="$RANDOM"
#    eval set -- b
#    udfEmptyVariable                                                           #? true
#    udfEmptyVariable a                                                         #? true
#    $(udfEmptyVariable a && exit 123)                                          #? 123
#    $(udfEmptyVariable b || exit 123)                                          #? 123
#    udfEmptyVariable b                                                         #? false
#  SOURCE
udfEmptyVariable() {

	[[ -n "$1" ]] && udfIsValidVariable "$1" && [[ -n "${!1}" ]] && return 1 || return 0

}
#******
#****f* liberr/udfEmptyOrMissingArgument
#  SYNOPSIS
#    udfEmptyOrMissingArgument <argument>
#  DESCRIPTION
#    return true if argument is empty
#    designed to check the conditions in the function udfOn
#  INPUTS
#    argument - one argument
#  RETURN VALUE
#    0 - argument is empty
#    1 - not empty argument
#  EXAMPLE
#    local a b="$RANDOM"
#    eval set -- b
#    udfEmptyOrMissingArgument                                                  #? true
#    udfEmptyOrMissingArgument $a                                               #? true
#    $(udfEmptyOrMissingArgument $a && exit 123)                                #? 123
#    $(udfEmptyOrMissingArgument $b || exit 123)                                #? 123
#    udfEmptyOrMissingArgument $b                                               #? false
#  SOURCE
udfEmptyOrMissingArgument() {

	[[ -n "$1" ]] && return 1 || return 0

}
#******
udfMissingArgument() { udfEmptyOrMissingArgument $@; }
udfEmptyArgument()   { udfEmptyOrMissingArgument $@; }
udfEmptyResult()     { udfEmptyOrMissingArgument $@; }
#****f* liberr/udfOnCommandNotFound
#  SYNOPSIS
#    udfOnCommandNotFound [<action>] <filenames>
#  DESCRIPTION
#    wrapper to call 'udfOn CommandNotFound ...'
#    see udfOn and udfCommandNotFound
#  INPUTS
#    <action> - same as udfOn
#    <filenames> - list of short filenames
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    EmptyOrMissingArgument - arguments not specified
#    CommandNotFound        - one or more of all specified filename is
#                             nonexistent or not executable
#    0                      - all specified filenames are found and executable
#  EXAMPLE
#    # see also udfOn CommandNotFound ...
#    local cmdYes='sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    udfOnCommandNotFound                                                       #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfOnCommandNotFound $cmdNo1                                               #? $_bashlyk_iErrorCommandNotFound
#    $(udfOnCommandNotFound $cmdNo2 || exit 123)                                #? 123
#    udfOnCommandNotFound WARN $cmdYes $cmdNo1 $cmdNo2 >| grep "Error.*bin.*"   #? true
#    $(udfOnCommandNotFound Throw $cmdNo2 >/dev/null 2>&1; true)                #? $_bashlyk_iErrorCommandNotFound
#    udfOnCommandNotFound $cmdYes                                               #? true
#  SOURCE
udfOnCommandNotFound() {

	udfOn CommandNotFound "$@"

}
#******
#****f* liberr/udfThrowOnCommandNotFound
#  SYNOPSIS
#    udfThrowOnCommandNotFound <filenames>
#  DESCRIPTION
#    wrapper to call 'udfOn CommandNotFound throw ...'
#    see udfOn and udfCommandNotFound
#  INPUTS
#    <filenames> - list of short filenames
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnCommandNotFound
#  EXAMPLE
#    local cmdYes="sh" cmdNo="bin_${RANDOM}"
#    udfThrowOnCommandNotFound $cmdYes                                          #? true
#    $(udfThrowOnCommandNotFound >/dev/null 2>&1)                               #? $_bashlyk_iErrorEmptyOrMissingArgument
#    $(udfThrowOnCommandNotFound $cmdNo >/dev/null 2>&1)                        #? $_bashlyk_iErrorCommandNotFound
#  SOURCE
udfThrowOnCommandNotFound() {

	udfOnCommandNotFound throw $*

}
#******
#****f* liberr/udfWarnOnCommandNotFound
#  SYNOPSIS
#    udfWarnOnCommandNotFound <filenames>
#  DESCRIPTION
#    wrapper to call 'udfOn CommandNotFound warn ...'
#    see udfOn udfOnCommandNotFound udfCommandNotFound
#  INPUTS
#    <filenames> - list of short filenames
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnCommandNotFound
#  EXAMPLE
#    local cmdYes="sh" cmdNo="bin_${RANDOM}"
#    udfWarnOnCommandNotFound $cmdYes                                           #? true
#    udfWarnOnCommandNotFound $cmdNo >| grep "Error.* command not found - bin_" #? true
#    udfWarnOnCommandNotFound                                                   #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
udfWarnOnCommandNotFound() {

	udfOnCommandNotFound warn $*

}
#******
#****f* liberr/udfOnEmptyVariable
#  SYNOPSIS
#    udfOnEmptyVariable [<action>] <args>
#  DESCRIPTION
#    wrapper to call 'udfOn EmptyVariable ...'
#    see udfOn udfEmptyVariable
#  INPUTS
#    <action> - same as udfOn
#    <args>   - list of variable names
#  RETURN VALUE
#    EmptyOrMissingArgument - no arguments
#    EmptyVariable          - one or more of all specified arguments empty or
#                             non valid variable
#    0                      - all arguments are valid and not empty variable
#  OUTPUT
#    see udfOn
#  EXAMPLE
#    # see also udfOn EmptyVariable
#    local sNoEmpty='test' sEmpty='' sMoreEmpty=''
#    udfOnEmptyVariable                                                         #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfOnEmptyVariable sEmpty                                                  #? $_bashlyk_iErrorEmptyVariable
#    $(udfOnEmptyVariable sEmpty || exit 111)                                   #? 111
#    udfOnEmptyVariable WARN sEmpty sNoEmpty sMoreEmpty >| grep "Error.*y, s"   #? true
#    udfOnEmptyVariable Echo sEmpty sMoreEmpty >| grep 'y, s'                   #? true
#    $(udfOnEmptyVariable  Exit sEmpty >/dev/null 2>&1; true)                   #? $_bashlyk_iErrorEmptyVariable
#    $(udfOnEmptyVariable Throw sEmpty >/dev/null 2>&1; true)                   #? $_bashlyk_iErrorEmptyVariable
#    udfOnEmptyVariable sNoEmpty                                                #? true
#  SOURCE
udfOnEmptyVariable() {

	udfOn EmptyVariable "$@"

}
#******
#****f* liberr/udfThrowOnEmptyVariable
#  SYNOPSIS
#    udfThrowOnEmptyVariable <args>
#  DESCRIPTION
#    stop the script with stack trace call
#    wrapper for 'udfOn EmptyVariable throw ...'
#    see also udfOn udfOnEmptyVariable udfEmptyVariable
#  INPUTS
#    <args> - list of variable names
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnEmptyVariable
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''
#    udfThrowOnEmptyVariable sNoEmpty                                           #? true
#    $(udfThrowOnEmptyVariable sEmpty >/dev/null 2>&1)                          #? $_bashlyk_iErrorEmptyVariable
#  SOURCE
udfThrowOnEmptyVariable() {

	udfOnEmptyVariable throw "$@"
}
#******
#****f* liberr/udfWarnOnEmptyVariable
#  SYNOPSIS
#    udfWarnOnEmptyVariable <args>
#  DESCRIPTION
#    send warning to notification system
#    wrapper for 'udfOn EmptyVariable warn ...'
#    see also udfOn udfOnEmptyVariable udfEmptyVariable
#  INPUTS
#    <args> - list of variable names
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnEmptyVariable
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''
#    udfWarnOnEmptyVariable sNoEmpty                                            #? true
#    udfWarnOnEmptyVariable sEmpty >| grep "Error: empty variable - sEmpty.*"   #? true
#  SOURCE
udfWarnOnEmptyVariable() {

	udfOnEmptyVariable Warn "$@"

}
#******
#****f* liberr/udfOnEmptyOrMissingArgument
#  SYNOPSIS
#    udfOnEmptyOrMissingArgument [<action>] <args>
#  DESCRIPTION
#    wrapper to call 'udfOn EmptyOrMissingArgument ...'
#    see udfOn udfEmptyOrMissingArgument
#  INPUTS
#    <action> - same as udfOn
#    <args>   - list of arguments
#  RETURN VALUE
#    EmptyOrMissingArgument - one or more of all specified arguments empty
#    0                      - all arguments are not empty
#  OUTPUT
#   see udfOn
#  EXAMPLE
#    local sNoEmpty='test' sEmpty='' sMoreEmpty=''
#    udfOnEmptyOrMissingArgument                                                #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfOnEmptyOrMissingArgument "$sEmpty"                                      #? $_bashlyk_iErrorEmptyOrMissingArgument
#    $(udfOnEmptyOrMissingArgument "$sEmpty" || exit 111)                       #? 111
#    udfOnEmptyOrMissingArgument WARN "$sEmpty" "$sNoEmpty" "$sMoreEmpty" >| grep "Error.*1, 3" #? true
#    udfOnEmptyOrMissingArgument Echo "$sEmpty" "$sMoreEmpty" >| grep '1, 2'    #? true
#    udfOnEmptyOrMissingArgument WARN "$sEmpty" "$sNoEmpty" "$sMoreEmpty"       #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfOnEmptyOrMissingArgument Echo "$sEmpty" "$sMoreEmpty"                   #? $_bashlyk_iErrorEmptyOrMissingArgument
#    $(udfOnEmptyOrMissingArgument Exit "$sEmpty" >/dev/null 2>&1; true)        #? $_bashlyk_iErrorEmptyOrMissingArgument
#    $(udfOnEmptyOrMissingArgument Throw "$sEmpty" >/dev/null 2>&1; true)       #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfOnEmptyOrMissingArgument "$sNoEmpty"                                    #? true
#  SOURCE
udfOnEmptyOrMissingArgument() {

	udfOn EmptyOrMissingArgument "$@"

}
#******
#****f* liberr/udfThrowOnEmptyMissingArgument
#  SYNOPSIS
#    udfThrowOnEmptyOrMissingArgument <args>
#  DESCRIPTION
#    wrapper to call 'udfOn EmptyOrMissingArgument throw ...'
#    see udfOn udfOnEmptyOrMissingArgument udfEmptyOrMissingArgument
#  INPUTS
#    <args>   - list of arguments
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnEmptyOrMissingArgument
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''
#    udfThrowOnEmptyVariable sNoEmpty                                           #? true
#    $(udfThrowOnEmptyOrMissingArgument "$sEmpty" >/dev/null 2>&1)              #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
udfThrowOnEmptyOrMissingArgument() {

	udfOnEmptyOrMissingArgument throw "$@"

}
#******
#****f* liberr/udfWarnOnEmptyOrMissingArgument
#  SYNOPSIS
#    udfWarnOnEmptyOrMissingArgument <args>
#  DESCRIPTION
#    wrapper to call 'udfOn EmptyOrMissingArgument warn ...'
#    see udfOn udfOnEmptyOrMissingArgument udfEmptyOrMissingArgument
#  INPUTS
#    <args>   - list of arguments
#  OUTPUT
#    see udfOn
#  RETURN VALUE
#    same as udfOnEmptyOrMissingArgument
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''
#    udfWarnOnEmptyOrMissingArgument "$sNoEmpty"                                #? true
#    udfWarnOnEmptyOrMissingArgument "$sEmpty" >| grep "Error: empty or miss.*" #? true
#  SOURCE
udfWarnOnEmptyOrMissingArgument() {

	udfOnEmptyOrMissingArgument Warn "$@"

}
#******
