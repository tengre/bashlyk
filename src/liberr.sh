#
# $Id: liberr.sh 774 2017-06-07 15:09:08+04:00 toor $
#
#****h* BASHLYK/liberr
#  DESCRIPTION
#    a set of functions to handle errors
#  USES
#    libstd libmsg
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* liberr/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBERR provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBERR" ] && return 0 || _BASHLYK_LIBERR=1
[ -n "$_BASHLYK" ] || . ${_bashlyk_pathLib}/bashlyk || eval '                  \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
shopt -s expand_aliases
#****A* liberr/Aliases
#  DESCRIPTION
#    usable aliases for exported functions
#  SOURCE
alias           try='try()'
alias            on='eval $( err::eval )'
alias          show='err::handler echo'
alias          warn='err::handler warn'
alias         abort='err::handler exit'
alias         throw='err::handler throw'
alias      errorify='err::handler return'
alias     exit+echo='err::handler echo+exit'
alias     exit+warn='err::handler warn+exit'
alias errorify+echo='err::handler echo+return'
alias errorify+warn='err::handler warn+return'
alias         catch='; eval "$( err::__convert_try_to_func )" ||'
#******
#****G* liberr/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
declare -rg _bashlyk_aRequiredCmd_err="rm sed"

declare -rg _bashlyk_methods_err="                                             \
                                                                               \
    err::{__add_throw_to_command,CommandNotFound,__convert_try_to_func,        \
    EmptyArgument,EmptyResult,EmptyVariable,eval,exception.message,debug,      \
    handler,InvalidVariable,MissingArgument,NoSuchFileOrDir,orr,stacktrace,    \
    status,status.show,sourcecode}                                             \
"

declare -rg _bashlyk_aExport_err="                                             \
                                                                               \
    abort catch err::{exception.message,stacktrace,status,sourcecode} errorify \
    errorify+echo errorify+warn exit+echo exit+warn on show throw try warn     \
                                                                               \
"
: ${_bashlyk_onError:=throw}
#

# Error states definition
#
_bashlyk_iError=255
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
_bashlyk_iErrorInvalidOption=201
_bashlyk_iErrorNonValidVariable=200
_bashlyk_iErrorInvalidVariable=200
_bashlyk_iErrorInvalidFunction=199
_bashlyk_iErrorInvalidHash=198
_bashlyk_iErrorEmptyVariable=197
_bashlyk_iErrorNotNumber=196
_bashlyk_iErrorNotExistNotCreated=190
_bashlyk_iErrorNoSuchFileOrDir=185
_bashlyk_iErrorNoSuchProcess=184
_bashlyk_iErrorCurrentProcess=183
_bashlyk_iErrorAlreadyStarted=182
_bashlyk_iErrorNotChildProcess=181
_bashlyk_iErrorCommandNotFound=180
_bashlyk_iErrorAlreadyLocked=179
_bashlyk_iErrorUserXsessionNotFound=171
_bashlyk_iErrorXsessionNotFound=170
_bashlyk_iErrorIncompatibleVersion=169
_bashlyk_iErrorTryBlockException=168
_bashlyk_iErrorNotAvailable=166
_bashlyk_iErrorNotDetected=0
_bashlyk_iErrorSuccess=0
_bashlyk_hError[$_bashlyk_iErrorUnknown]="unknown (unexpected) error"
_bashlyk_hError[$_bashlyk_iErrorMissingArgument]="empty or missing argument"
_bashlyk_hError[$_bashlyk_iErrorInvalidArgument]="invalid argument"
_bashlyk_hError[$_bashlyk_iErrorEmptyVariable]="empty variable"
_bashlyk_hError[$_bashlyk_iErrorEmptyResult]="empty result"
_bashlyk_hError[$_bashlyk_iErrorNotSupported]="not supported"
_bashlyk_hError[$_bashlyk_iErrorNotPermitted]="not permitted"
_bashlyk_hError[$_bashlyk_iErrorBrokenIntegrity]="broken integrity"
_bashlyk_hError[$_bashlyk_iErrorAbortedBySignal]="aborted by signal"
_bashlyk_hError[$_bashlyk_iErrorInvalidOption]="parsing CLI is failed - invalid option(s)"
_bashlyk_hError[$_bashlyk_iErrorInvalidVariable]="invalid variable"
_bashlyk_hError[$_bashlyk_iErrorInvalidFunction]="invalid function"
_bashlyk_hError[$_bashlyk_iErrorInvalidHash]="invalid hash"
_bashlyk_hError[$_bashlyk_iErrorNotNumber]="not number"
_bashlyk_hError[$_bashlyk_iErrorNotExistNotCreated]="not exist and not created"
_bashlyk_hError[$_bashlyk_iErrorNoSuchFileOrDir]="no such file or directory"
_bashlyk_hError[$_bashlyk_iErrorNoSuchProcess]="no such process"
_bashlyk_hError[$_bashlyk_iErrorNotChildProcess]="not child process"
_bashlyk_hError[$_bashlyk_iErrorCurrentProcess]="this current process"
_bashlyk_hError[$_bashlyk_iErrorAlreadyStarted]="already started with PID"
_bashlyk_hError[$_bashlyk_iErrorCommandNotFound]="command not found"
_bashlyk_hError[$_bashlyk_iErrorAlreadyLocked]="already locked"
_bashlyk_hError[$_bashlyk_iErrorUserXsessionNotFound]="user X-Session not found"
_bashlyk_hError[$_bashlyk_iErrorXsessionNotFound]="X-Session not found"
_bashlyk_hError[$_bashlyk_iErrorIncompatibleVersion]="incompatible version"
_bashlyk_hError[$_bashlyk_iErrorTryBlockException]="try block exception"
_bashlyk_hError[$_bashlyk_iErrorNotAvailable]="target is not available"
_bashlyk_hError[$_bashlyk_iErrorNotDetected]="unknown (unexpected) error, maybe everything is fine"
#******
#****L* liberr/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libmsg.sh ]] && . "${_bashlyk_pathLib}/libmsg.sh"
#******
#****p* liberr/err::orr
#  SYNOPSIS
#    err::orr [<arg>]
#  DESCRIPTION
#    return status from 0 to 255 (default 255)
#  ARGUMENTS
#    arg - expected 0-254
#  NOTES
#    public method
#  ERROR
#    255 - first argument is not valid
#  EXAMPLE
#    err::orr                                                                   #? 255
#    err::orr 0                                                                 #? true
#    err::orr 123                                                               #? 123
#    err::orr 256                                                               #? 255
#  SOURCE
err::orr() {

  local i

  if [[ $1 =~ ^[0-9]+$ ]]; then

    i=$1

  else

    eval "i=\"\$_bashlyk_iError${1}\""
    [[ $i ]] || eval "i=\"\$_bashlyk_${1}\""

  fi

  [[ $i =~ ^[0-9]+$ ]] && (( i < 256 )) || i=255

  return $i

}
#******
#****p* liberr/err::status.show
#  SYNOPSIS
#    err::status.show [<pid>]
#  DESCRIPTION
#    Show last saved error state for process with <pid> or $BASHPID default
#  INPUTS
#    <pid> - select process, default current bash subshell $BASHPID
#  NOTES
#    private method
#  ERRORS
#    Unknown         - first argument is non valid
#    1-254           - valid value of first argument
#  EXAMPLE
#    local pid=$BASHPID
#    err::status iErrorInvalidVariable "12Invalid"                              #? $_bashlyk_iErrorInvalidVariable
#    err::status.show                                                           #? $_bashlyk_iErrorInvalidVariable
#    err::status.show invalid argument                                          #? $_bashlyk_iErrorInvalidVariable
#    err::status.show $$                                                        #? $_bashlyk_iErrorInvalidVariable
#  SOURCE
err::status.show() {

  local pid

  [[ $1 =~ ^[0-9]+$ ]] && (( $1 < 65536 )) && pid=$1 || pid=$BASHPID

  local i s

  i=${_bashlyk_iLastError[$pid]}
  s=${_bashlyk_sLastError[$pid]}

  if [[ $i =~ ^[0-9]+$ ]] && (( $i < 255 )); then

    echo "${_bashlyk_hError[$i]} - $s ($i)"
    return $i

  else

    echo "$s ($i)"
    return $_bashlyk_iErrorUnexpected

  fi

}
#******
#****e* liberr/err::status
#  SYNOPSIS
#    err::status <number> <string>
#  DESCRIPTION
#    Set in global variables $_bashlyk_{i,s}Error[$BASHPID] arbitrary values as
#    error states - number and string
#  INPUTS
#    <number> - error code - number or predefined name as 'iErrorXXX' or 'XXX'
#    <string> - error text
#  NOTES
#    public method
#  ERRORS
#    MissingArgument - arguments missing
#    Unknown         - first argument is non valid
#    1-255           - valid value of first argument
#  EXAMPLE
#    local pid=$BASHPID
#    err::status
#    err::status                                                                #? $_bashlyk_iErrorInvalidVariable
#    err::status non valid argument                                             #? $_bashlyk_iErrorUnknown
#    err::status 555                                                            #? $_bashlyk_iErrorUnexpected
#    err::status AlreadyStarted "$$"                                            #? $_bashlyk_iErrorAlreadyStarted
#    err::status iErrorInvalidVariable 12Invalid test                           #? $_bashlyk_iErrorInvalidVariable
#    err::status          >| grep '^invalid variable - 12Invalid test (200)$'   #? true
#    err::status NotAvailable test unit
#    echo $(err::status)  >| grep '^target is not available - test unit (166)$' #? true
#  SOURCE
err::status() {

  if [[ ! $1 ]]; then

    if [[ ${_bashlyk_iLastError[$BASHPID]} ]]; then

      err::status.show $BASHPID

    elif [[ ${_bashlyk_iLastError[$$]} ]]; then

      err::status.show $$

    fi

    return

  fi

  err::orr $1

  local i=$?

  (( i == 255 )) && i=$_bashlyk_iErrorUnknown || shift

  _bashlyk_iLastError[$BASHPID]=$i

  [[ $* ]] && _bashlyk_sLastError[$BASHPID]="$*"

  return $i

}
#******
#****e* liberr/err::stacktrace
#  SYNOPSIS
#    err::stacktrace
#  DESCRIPTION
#    OUTPUT BASH Stack Trace
#  NOTES
#    public method
#  OUTPUT
#    BASH Stack Trace
#  EXAMPLE
#    err::stacktrace                     >| grep '1: code err::stacktrace_test' #? true
#  SOURCE
err::stacktrace() {

  local i s=$( printf -- '\u00a0' )

  printf -- '\nStack trace by %s from %s:\n+-->>-----\n'                       \
            "${FUNCNAME[0]}" "${BASH_SOURCE[0]}"

  for (( i=${#FUNCNAME[@]}-1; i >= 0; i-- )); do

    (( ${BASH_LINENO[i]} == 0 )) && continue

    printf -- '%s%d: call %s:%s %s ..\n%s%d: code %s\n'                        \
              "$s" "$i"                                                        \
              "${BASH_SOURCE[$i+1]}" "${BASH_LINENO[$i]}" "${FUNCNAME[$i]}"    \
              "$s" "$i"                                                        \
              "$( err::sourcecode $i )"

    s+=" "

  done

  printf -- '+-->>-----\n'

}
#******
#****e* liberr/err::sourcecode
#  SYNOPSIS
#    err::sourcecode [<level>]
#  DESCRIPTION
#    get source code line for selected stack level ( 0 default )
#  NOTES
#    public method
#  OUTPUT
#    source code line
#  EXAMPLE
#    err::sourcecode                             >| grep ^err::sourcecode_test$ #? true
#  SOURCE
err::sourcecode() {

  local fn i

  [[ $1 =~ ^[0-9]+ ]] && i=$(( $1 + 1 )) || i=1

  if [[ -s ${BASH_SOURCE[i+1]} ]]; then

    fn=${BASH_SOURCE[i+1]}

  else

    fn=${_bashlyk_PWD}/${BASH_SOURCE[i+1]##*/}

  fi

  [[ -s $fn ]] && sed -n "${BASH_LINENO[i]}p" $fn || return $_bashlyk_iErrorNoSuchFileOrDir

}
#******
## TODO Incomplete list of arguments is not handled correctly
#****p* liberr/err::eval
#  SYNOPSIS
#    err::eval [<action>] [<state>] [<message>]
#  DESCRIPTION
#    Flexible error handling. Processing is controlled by global variables or
#    arguments, and consists in a warning message, the function returns, or the
#    end of the script with a certain return code. Messages may include a stack
#    trace and printed to stderr
#  NOTES
#    private method
#  INPUTS
#    <action> - directly determines how the error handling. Possible actions:
#
#     echo        - just prepare a message from the string argument to STDERR
#     warn        - prepare a message from the string argument for transmission
#                   to the notification system
#     return      - set return from the function. In the global context - the
#                   end of the script (exit)
#     echo+return - the combined action of 'echo'+'return', however, if the code
#                   is not within the function, it is only the transfer of
#                   messages from a string of arguments to STDERR
#     warn+return - the combined action of 'warn'+'return', however, if the code
#                   is not within the function, it is only the transfer of
#                   messages from a string of arguments to the notification
#                   system
#     exit        - set unconditional completion of the script
#     echo+exit   - the same as 'exit', but with the transfer of messages from a
#                   string of arguments to STDERR
#     warn+exit   - the same as 'echo+exit', but with the transfer of messages
#                   to the notification system
#     throw       - the same as 'warn+exit', but with the transfer of messages
#                   and the call stack to the notification system
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
#    false || on error warn NoSuchFileOrDir /notexist                           #? true
#    _bashlyk_onError=debug
#    false || on error exit NoSuchFileOrDir /notexist                           #? $_bashlyk_iErrorNoSuchFileOrDir
#    #_bashlyk_onError=echo
#    err::orr 166 || on error echo                                              #? true
#    err::orr 11 || on error 123                                                #? 123
#    err::orr 123 || on error bla-bla bla                                       #? 123
#    err::orr 123 || on error                                                   #? 123
#  SOURCE
err::eval() {

  local rc=$? rs echo='echo' warn='msg::warn' fn
  local i IFS=$' \t\n' reAct reArg sAction=$_bashlyk_onError sMessage s

  reAct='^(echo|warn)$|^((echo|warn)[+])?(exit|return)$|^throw$'
  reArg='((on|\$\(.?err::eval.?\)).error|err::eval)[[:space:]]*?([^\>]*)[[:space:]]*?[\>\|]?'

  if [[ "$( err::sourcecode )" =~ $reArg ]]; then

    local -a a=( $( eval echo "\"${BASH_REMATCH[3]//\"/}\"" ) )

  else

    echo "echo \"$fn - invalid arguments for error handling, abort...\"; exit $( _ iErrorInvalidArgument );"

  fi

  [[ ${a[0],,} =~ $reAct ]] && sAction=${a[0],,} && i=1 || i=0

  [[ ${a[$i]} ]] || a[$i]=$rc

  err::orr ${a[$i]}; rs=$?

  if (( rs >= $_bashlyk_iErrorUnknown )); then

    s="(may be previous..) "

    if [[ ${_bashlyk_hError[$rc]} ]]; then

      rs=$rc
      s+="${_bashlyk_hError[$rc]} - ${a[@]:$i} .. ($rc)"

    else

      (( rs == 255 )) && rs=$rc
      s+="${a[@]:$i} .. ($rc)"

    fi

  else

    : $(( i++ ))

    if [[ ${_bashlyk_hError[$rs]} ]]; then

      s="${_bashlyk_hError[$rs]} - ${a[@]:$i} .. ($rs)"

    else

      s="${a[@]:$i} .. ($rs)"

    fi

  fi

  printf -v s "%q" "$s"

  if [[ "${FUNCNAME[1]}" == "main" || -z "${FUNCNAME[1]}" ]]; then

    [[ $sAction =~ ^((echo|warn)\+)?return$ ]] && sAction=${sAction/return/exit}

  fi

  if [[ $_bashlyk_onError == debug ]]; then

    echo='err::stacktrace | std::cat'
    warn='err::stacktrace | msg::warn -'

  fi

  case "${sAction,,}" in

           echo) sAction=': ';        sMessage="$echo  Warn: ";;
    echo+return) sAction='return $?'; sMessage="$echo Error: ";;
      echo+exit) sAction='exit $?';   sMessage="$echo Error: ";;
           warn) sAction=': ';        sMessage="$warn  Warn: ";;
    warn+return) sAction='return $?'; sMessage="$warn Error: ";;
      warn+exit) sAction='exit $?';   sMessage="$warn Error: ";;
    exit|return) sAction="${sAction,,} \$?"; sMessage=": ";;
              *)
                 sAction='exit $?'
                 sMessage='err::stacktrace | msg::warn - Error: '
          ;;

  esac

  i=${a[@]:$i}

  if [[ $_bashlyk_onError == debug ]]; then

    sAction=${sAction/exit/err::orr}

  fi

  printf -- '%s >&2; err::status %s "%s"; %s; #' \
            "${sMessage}${s}" "$rs" "${i//\;/}" "$sAction"

}
#******
#****p* liberr/err::CommandNotFound
#  SYNOPSIS
#    err::CommandNotFound <filename>
#  DESCRIPTION
#    return true if argument is not empty, exists and executable (## TODO test)
#    designed to check the conditions in the function err::handler
#  NOTES
#    private method
#  INPUTS
#    filename - argument for executable file matching by searching the PATH
#  RETURN VALUE
#    CommandNotFound - no arguments, specified filename is nonexistent or not
#                      executable
#    0               - specified filename are found and executable
#  EXAMPLE
#    local cmdYes='sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    err::CommandNotFound                                                       #? $_bashlyk_iErrorCommandNotFound
#    err::CommandNotFound $cmdNo1                                               #? $_bashlyk_iErrorCommandNotFound
#    $( err::CommandNotFound $cmdNo2 || exit 123 )                              #? 123
#    err::CommandNotFound $cmdYes                                               #? true
#  SOURCE
err::CommandNotFound() {

  [[ $* ]] && hash "$*" 2>/dev/null || return $_bashlyk_iErrorCommandNotFound

}
#******
#****p* liberr/err::NoSuchFileOrDir
#  SYNOPSIS
#    err::NoSuchFileOrDir <filename>
#  DESCRIPTION
#    return true if argument is non empty, exists, designed to check the
#    conditions in the function err::handler
#  NOTES
#    private method
#  ARGUMENTS
#    <filename> - filesystem object for checking
#  RETURN VALUE
#    NoSuchFileOrDir - no arguments, specified filesystem object is nonexistent
#    0               - specified filesystem object are found
#  EXAMPLE
#    local cmdYes='/bin/sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    err::NoSuchFileOrDir                                                       #? $_bashlyk_iErrorNoSuchFileOrDir
#    err::NoSuchFileOrDir $cmdNo1                                               #? $_bashlyk_iErrorNoSuchFileOrDir
#    $(err::NoSuchFileOrDir $cmdNo2 || exit 123)                                #? 123
#    err::NoSuchFileOrDir $cmdYes                                               #? true
#  SOURCE
err::NoSuchFileOrDir() {

  [[ $* && -e "$*" ]] || return $_bashlyk_iErrorNoSuchFileOrDir

}
#******
#****p* liberr/err::InvalidVariable
#  SYNOPSIS
#    err::InvalidVariable <variable>
#  DESCRIPTION
#    return true if argument is non empty, valid variable, designed to check the
#    conditions in the function err::handler
#  NOTES
#    private method
#  INPUTS
#    <variable> - expected variable name
#  RETURN VALUE
#    InvalidVariable - argument is empty or invalid variable
#    0               - valid variable
#  EXAMPLE
#    err::InvalidVariable                                                       #? $_bashlyk_iErrorInvalidVariable
#    err::InvalidVariable 1a                                                    #? $_bashlyk_iErrorInvalidVariable
#    err::InvalidVariable a1                                                    #? true
#    $(err::InvalidVariable 2b || exit 123)                                     #? 123
#    $(err::InvalidVariable c3 && exit 123)                                     #? 123
#  SOURCE
err::InvalidVariable() {

  [[ $* ]] && std::isVariable "$*" || return $_bashlyk_iErrorInvalidVariable

}
#******
#****p* liberr/err::EmptyVariable
#  SYNOPSIS
#    err::EmptyVariable <variable>
#  DESCRIPTION
#    return true if argument is non empty, valid variable
#    designed to check the conditions in the function err::handler
#  NOTES
#    private method
#  INPUTS
#    variable - expected variable name
#  RETURN VALUE
#    EmptyVariable - argument is empty, invalid or empty variable
#    0             - valid not empty variable
#  EXAMPLE
#    local a b="$RANDOM"
#    err::EmptyVariable                                                         #? $_bashlyk_iErrorEmptyVariable
#    err::EmptyVariable a                                                       #? $_bashlyk_iErrorEmptyVariable
#    $(err::EmptyVariable a || exit 123)                                        #? 123
#    $(err::EmptyVariable b && exit 123)                                        #? 123
#    err::EmptyVariable b                                                       #? true
#  SOURCE
err::EmptyVariable() {

  [[ $1 ]] && std::isVariable "$1" && [[ ${!1} ]] || return $_bashlyk_iErrorEmptyVariable

}
#******
#****p* liberr/err::MissingArgument
#  SYNOPSIS
#    err::MissingArgument <argument>
#  DESCRIPTION
#    return true if argument is not empty
#    designed to check the conditions in the function err::handler
#  NOTES
#    private method
#  INPUTS
#    argument - one argument
#  RETURN VALUE
#    MissingArgument - argument is empty
#    0               - non empty argument
#  EXAMPLE
#    local a b="$RANDOM"
#    err::MissingArgument                                                       #? $_bashlyk_iErrorMissingArgument
#    err::MissingArgument $a                                                    #? $_bashlyk_iErrorMissingArgument
#    $(err::MissingArgument $a || exit 123)                                     #? 123
#    $(err::MissingArgument $b && exit 123)                                     #? 123
#    err::MissingArgument $b                                                    #? true
#  SOURCE
err::MissingArgument() {

  [[ $* ]] || return $_bashlyk_iErrorMissingArgument

}
#******
err::EmptyOrMissingArgument() { err::MissingArgument $*; }
err::EmptyArgument()          { err::MissingArgument $*; }
#****p* liberr/err::EmptyResult
#  SYNOPSIS
#    err::EmptyResult <argument>
#  DESCRIPTION
#    return true if argument is not empty
#    designed to check the conditions in the function err::handler
#  NOTES
#    private method
#  INPUTS
#    <argument> - one argument
#  RETURN VALUE
#    EmptyResult - argument is empty
#    0           - non empty argument
#  EXAMPLE
#    local a b="$RANDOM"
#    err::EmptyResult                                                           #? $_bashlyk_iErrorEmptyResult
#    err::EmptyResult $a                                                        #? $_bashlyk_iErrorEmptyResult
#    $(err::EmptyResult $a || exit 123)                                         #? 123
#    $(err::EmptyResult $b && exit 123)                                         #? 123
#    err::EmptyResult $b                                                        #? true
#  SOURCE
err::EmptyResult() {

  [[ $* ]] || return $_bashlyk_iErrorEmptyResult

}
#******
#****p* liberr/err::handler
#  SYNOPSIS
#    err::handler <action> on <state> <argument>
#  DESCRIPTION
#    Flexible error handling. Processing is controlled by global variables or
#    arguments, and consists in a warning message, the function returns, or the
#    end of the script with a certain return code. Messages may include a stack
#    trace and printed to stderr
#  NOTES
#    private method
#  INPUTS
#    <action> - directly determines how the error handling. Possible actions:
#     echo        - just prepare a message from the string argument to STDERR
#     warn        - prepare a message from the string argument for transmission
#                   to the notification system
#     return      - set return from the function. In the global context - the
#                   end of the script (exit)
#     echo+return - the combined action of 'echo'+'return', however, if the code
#                   is not within the function, it is only the transfer of
#                   messages from a string of arguments to STDERR
#     warn+return - the combined action of 'warn'+'return', however, if the code
#                   is not within the function, it is only the transfer of
#                   messages from a string of arguments to the notification
#                   system
#     exit        - set unconditional completion of the script
#     echo+exit   - the same as 'exit', but with the transfer of messages from a
#                   string of arguments to STDERR
#     warn+exit   - the same as 'echo+exit', but with the transfer of messages
#                   to the notification system
#     throw       - the same as 'warn+exit', but with the transfer of messages
#                   and the call stack to the notification system
#    <state>      - handled error type, are supported:
#                     CommandNotFound
#                     NoSuchFileOrDir
#                     InvalidVariable
#                     EmptyVariable
#                     MissingArgument
#                     EmptyResult
#    <argument>   - checked value by type (see <state>)
#  OUTPUT
#    see on error ...
#  EXAMPLE
#    ## TODO improve tests
#    err::handler warn on NoSuchFileOrDir /err.handler                          #? true
#    errorify+echo on CommandNotFound notexist.return                           #? $_bashlyk_iErrorCommandNotFound
#    warn on NoSuchFileOrDir /notexist.warn                                     #? true
#    show on NoSuchFileOrDir /notexist.echo                                     #? true
#    $(throw on NoSuchFileOrDir /notexist.throw.child)                          #? $_bashlyk_iErrorNoSuchFileOrDir
#    $(exit+echo on CommandNotFound notexist.exit+echo.child)                   #? $_bashlyk_iErrorCommandNotFound
#    $(errorify on CommandNotFound notexist.errorify.child || return)           #? $_bashlyk_iErrorCommandNotFound
#    warn on CommandNotFound notexist nomoreexist                               #? true
#  SOURCE
err::handler() {

  local -a aErrHandler=( $* )
  local re='^(echo|warn)$|^((echo|warn)[+])?(exit|return)$|^throw$' i=0 j=0 s
  ## TODO add reAction and reState for safely arguments parsing

  [[ $1 =~ $re ]] && shift || on error throw InvalidArgument "1 - $1"
  [[ $1 == on  ]] && shift || on error throw InvalidArgument "2 - $1"
  [[ $1        ]] && shift || on error throw MissingArgument "3 - $1"

  if ! declare -pf err::${aErrHandler[2]} >/dev/null 2>&1; then

    on error throw InvalidArgument "${aErrHandler[2]}"

  fi

  unset aErrHandler[1]

  [[ $* ]] || on error ${aErrHandler[@]}

  for s in "$@"; do

    : $(( j++ ))

    if ! err::${aErrHandler[2]} $s; then

      [[ $s ]] || s=$j

      (( i++ == 0 )) && aErrHandler[3]=$s || aErrHandler[3]+=", $s"

    fi

  done

  if (( i > 0 )); then

    (( i > 1 )) && aErrHandler[3]+=" [total $i]"
    on error ${aErrHandler[@]:0:3}

  fi

}
#******
#****p* liberr/err::__add_throw_to_command
#  SYNOPSIS
#    err::__add_throw_to_command <command line>
#  DESCRIPTION
#    add controlled trap for errors of the <commandline>
#  NOTES
#    private method
#  INPUTS
#    <commandline> - source command line
#  OUTPUT
#    changed command line
#  NOTES
#    private method, used for 'try ..catch' emulation
#  EXAMPLE
#    local s='command --with -a -- arguments' cmd='err::__add_throw_to_command'
#    $cmd $s             >| md5sum | grep ^9491e10494aa59365481cd0418cedd9a.*-$ #? true
#  SOURCE
err::__add_throw_to_command() {

  local s

  s='_bashlyk_sLastError[$BASHPID]="command: $(std::trim '${*/;/}')\n output: '
  s+='{\n$('${*/;/}' 2>&1)\n}" && echo -n . || return $?;'

  echo $s

}
#******
#****p* liberr/err::__convert_try_to_func
#  SYNOPSIS
#    err::__convert_try_to_func
#  DESCRIPTION
#    convert "try" block to the function with controlled traps of the errors
#  OUTPUT
#    function definition for evaluate
#  NOTES
#    private method, used for 'try ..catch' emulation
#  TODO
#    error handling for input 'try' function checking not worked
#  EXAMPLE
#    err::__convert_try_to_func >| grep "^${TMPDIR}/.*ok.*fail.*; false; }$"    #? true
#  SOURCE
err::__convert_try_to_func() {

  local s
  std::temp -v s

  while read -t 4; do

    if [[ ! $REPLY =~ ^[[:space:]]*(try \(\)|\{|\})[[:space:]]*$ ]]; then

      err::__add_throw_to_command $REPLY

    else

      #echo "${REPLY/try/try${s//\//.}}"
      echo "${REPLY/try/$s}"

    fi

  done< <( declare -pf try 2>/dev/null)

  echo $s' && echo " ok." || { err::status $?; echo " fail..($?)"; false; }'
  rm -f $s

}
#******
#****e* liberr/err::exception.message
#  SYNOPSIS
#    err::exception.message
#  DESCRIPTION
#    show last error status
#  NOTES
#    public method
#  INPUTS
#    used global variables $_bashlyk_{i,s}LastError
#  OUTPUT
#    try show commandline, status(error code) and output
#  ERRORS
#    MissingArgument - _bashlyk_iLastError[$BASHPID] empty
#    NotNumber       - _bashlyk_iLastError[$BASHPID] is not number
#  EXAMPLE
#   _bashlyk_iLastError[$BASHPID]=''
#   err::exception.message                                                      #? $_bashlyk_iErrorMissingArgument
#   _bashlyk_iLastError[$BASHPID]='not number'
#   err::exception.message                                                      #? $_bashlyk_iErrorNotNumber
#   local s fn                                                                  #-
#   error4test() { echo "${0##*/}: special error for testing"; return 210; };   #-
#   std::temp fn                                                                #-
#   cat <<-'EOFtry' > $fn                                                       #-
#   try {                                                                       #-
#     uname -a                                                                  #-
#     date -R                                                                   #-
#     uname                                                                     #-
#     error4test                                                                #-
#     true                                                                      #-
#   } catch {                                                                   #-
#                                                                               #-
#     err::exception.message                                                    #-
#                                                                               #-
#   }                                                                           #-
#   EOFtry                                                                      #-
#  . $fn                  >| md5sum -| grep ^65128961dfcf8819e88831025ad5f1.*-$ #? true
#  SOURCE
err::exception.message() {

  local msg=${_bashlyk_sLastError[$BASHPID]} rc=${_bashlyk_iLastError[$BASHPID]}

  std::isNumber $rc || return

  printf -- "\ntry block exception:\n~~~~~~~~~~~~~~~~~~~~\n status: %s\n" "$rc"

  [[ $msg ]] && printf -- "${msg}\n"

  return $rc

}
#******
#****f* liberr/err::debug
#  SYNOPSIS
#    err::debug <level> <message>
#  DESCRIPTION
#    show a <message> on stderr if the <level> is equal or less than the
#    $DEBUGLEVEL value otherwise return code 1
#  INPUTS
#    <level>   - decimal number of the debug level ( 0 for wrong argument)
#    <message> - debug message
#  OUTPUT
#    show a <message> on stderr
#  RETURN VALUE
#    0               - <level> equal or less than $DEBUGLEVEL value
#    1               - <level> more than $DEBUGLEVEL value
#    MissingArgument - no arguments
#  EXAMPLE
#    DEBUGLEVEL=0
#    err::debug                                                                 #? $_bashlyk_iErrorMissingArgument
#    err::debug 0 echo level 0                                                  #? true
#    err::debug 1 silence level 0                                               #? 1
#    DEBUGLEVEL=5
#    err::debug 0 echo level 5                                                  #? true
#    err::debug 6 echo 5                                                        #? 1
#    err::debug default level test '(0)'                                        #? true
#  SOURCE
err::debug() {

  errorify on MissingArgument $* || return

  if [[ $1 =~ ^[0-9]+$ ]]; then

    (( ${DEBUGLEVEL:=0} >= $1 )) && shift || return 1

  fi

  [[ $* ]] && echo "$*" >&2

  return 0

}
#******
