#
# $Id: liberr.sh 651 2016-12-31 15:05:26+04:00 toor $
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
#***iV* liberr/BASH Compability
#  DESCRIPTION
#    BASH version 4.xx or more required for this script
#  SOURCE
[ -n "$BASH_VERSION" ] && (( ${BASH_VERSINFO[0]} >= 4 )) || eval '             \
                                                                               \
    echo "[!] BASH shell version 4.xx required for ${0}, abort.."; exit 255    \
                                                                               \
'
#******
#  $_BASHLYK_LIBERR provides protection against re-using of this module
[[ $_BASHLYK_LIBERR ]] && return 0 || _BASHLYK_LIBERR=1
#****L* liberr/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libmsg.sh ]] && . "${_bashlyk_pathLib}/libmsg.sh"
#******
#****G* liberr/Global Variables
#  DESCRIPTION
#    Global variables of the library
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
_bashlyk_iErrorInvalidHash=198
_bashlyk_iErrorEmptyVariable=197
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
_bashlyk_hError[$_bashlyk_iErrorInvalidHash]="invalid hash"
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
_bashlyk_hError[$_bashlyk_iErrorTryBoxException]="try box exception"
#
: ${_bashlyk_onError:=throw}
: ${_bashlyk_sArg:="$@"}

declare -r _bashlyk_aRequiredCmd_err="sed which"
declare -r _bashlyk_aExport_err="                                              \
                                                                               \
    udfCommandNotFound udfEmptyArgument udfEmptyOrMissingArgument              \
    udfEmptyResult udfEmptyVariable udfInvalidVariable udfMissingArgument      \
    udfOn udfOnCommandNotFound udfOnEmptyOrMissingArgument udfOnEmptyVariable  \
    udfOnError udfOnError1 udfOnError2 udfSetLastError udfStackTrace udfThrow  \
    udfThrowOnCommandNotFound udfThrowOnEmptyOrMissingArgument udfTryEveryLine \
    udfThrowOnEmptyVariable udfWarnOnCommandNotFound udfWarnOnEmptyVariable    \
    udfWarnOnEmptyOrMissingArgument                                            \
                                                                               \
"
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
#  ERRORS
#    MissingArgument - arguments missing
#    Unknown         - first argument is non valid
#    1-255           - valid value of first argument
#  EXAMPLE
#    local pid=$BASHPID
#    udfSetLastError                                                            #? $_bashlyk_iErrorMissingArgument
#    udfSetLastError non valid argument                                         #? $_bashlyk_iErrorUnknown
#    udfSetLastError 555                                                        #? $_bashlyk_iErrorUnexpected
#    udfSetLastError AlreadyStarted "$$"                                        #? $_bashlyk_iErrorAlreadyStarted
#    udfSetLastError iErrorNonValidVariable "12NonValid Variable"               #? $_bashlyk_iErrorNonValidVariable
#    _ iLastError[$pid] >| grep -w "$_bashlyk_iErrorNonValidVariable"           #? true
#    _ sLastError[$pid] >| grep "^12NonValid Variable$"                         #? true
#  SOURCE
udfSetLastError() {

  [[ $1 ]] || return $_bashlyk_iErrorMissingArgument

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
#    trace and printed to stderr
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
#    local cmd=udfOnError e=InvalidArgument s="$RANDOM $RANDOM"
#    eval $($cmd echo $e "$s a")                                                #? $_bashlyk_iErrorInvalidArgument
#    udfIsNumber 020h || eval $($cmd echo $? "020h")                            #? $_bashlyk_iErrorInvalidArgument
#    udfIsValidVariable 1Invalid || eval $($cmd warn $? "1Invalid")             #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable 2Invalid || eval $($cmd warn "2Invalid")                #? $_bashlyk_iErrorInvalidVariable
#    $cmd exit    $e "$s b" >| grep " exit \$?"                                 #? true
#    $cmd return  $e "$s c" >| grep " return \$?"                               #? true
#    $cmd retecho $e "$s d" >| grep "echo.* return \$?"                         #? true
#    $cmd retwarn $e "$s e" >| grep "Warn.* return \$?"                         #? true
#    $cmd throw   $e "$s f" >| grep "dfWarn.* exit \$?"                         #? true
#    eval $($cmd exitecho MissingArgument) 2>&1 >| grep "E.*: em.*o.*mi"        #? true
#    _ onError warn
#    eval $($cmd $e "$s g")                                                     #? $_bashlyk_iErrorInvalidArgument
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

    if [[ ${_bashlyk_hError[$rs]} ]]; then

      s=$rs
      rs="${_bashlyk_hError[$rs]} - $* .. ($rs)"

    else

      (( $rs == 0 )) && rs=$_bashlyk_iErrorUnexpected
      rs="$* .. ($rs)"
      s=$_bashlyk_iErrorUnexpected

    fi

  else

    shift

    if [[ ${_bashlyk_hError[$s]} ]]; then

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

           echo) sAction="";             sMessage="echo  Warn: ${rs} >&2;";;
        retecho) sAction="; return \$?"; sMessage="echo Error: ${rs} >&2;";;
       exitecho) sAction="; exit \$?";   sMessage="echo Error: ${rs} >&2;";;
           warn) sAction="";             sMessage="udfWarn  Warn: ${rs} >&2;";;
        retwarn) sAction="; return \$?"; sMessage="udfWarn Error: ${rs} >&2;";;
       exitwarn) sAction="; exit \$?";   sMessage="udfWarn Error: ${rs} >&2;";;
          throw)
                 sAction="; exit \$?"
                 sMessage="udfStackTrace | udfWarn - Error: ${rs} >&2;"
          ;;

    exit|return) sAction="; $sAction \$?"; sMessage="";;

  esac

  printf -- "%s udfSetLastError %s %s%s\n" "$sMessage" "$s" "$rs" "${sAction}"

}
#******
udfOnError2() { udfOnError "$@"; }
#****f* liberr/udfOnError1
#  SYNOPSIS
#    udfOnError1 [<action>] [<state>] [<message>]
#  DESCRIPTION
#    Same as udfOnError except output printed to stdout
#  INPUTS
#    see udfOnError
#  OUTPUT
#    see udfOnError
#  EXAMPLE
#    #see udfOnError
#    eval $(udfOnError1 exitecho MissingArgument) >| grep "E.*: em.*o.*mi"      #? true
#    #_ onError warn
#  SOURCE
udfOnError1() {

  udfOnError "$@" | sed -re "s/ >\&2;/;/"

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
#    local rc=$(( RANDOM / 256 )) cmd=udfSetLastError
#    echo $(false || udfThrow rc=$? 2>&1; echo ok=$?) >| grep "^Error: rc=1.*$" #? true
#    echo $($cmd $rc || udfThrow $? 2>&1; echo rc=$?) >| grep -w "$rc"          #? true
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

    [[ $s ]] || continue

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
#    local cmdYes='sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}" e=CommandNotFound
#    udfOn $e                                                                   #? $_bashlyk_iErrorMissingArgument
#    udfOn $e $cmdNo1                                                           #? $_bashlyk_iErrorCommandNotFound
#    $(udfOn $e $cmdNo2 || exit 123)                                            #? 123
#    udfOn $e WARN $cmdYes $cmdNo1 $cmdNo2 2>&1 >| grep "Error.*bin.*"          #? true
#    udfOn $e Echo $cmdYes $cmdNo1 $cmdNo2 2>&1 >| grep ', bin'                 #? true
#    $(udfOn $e  Exit $cmdNo1 >/dev/null 2>&1; true)                            #? $_bashlyk_iErrorCommandNotFound
#    $(udfOn $e Throw $cmdNo2 >/dev/null 2>&1; true)                            #? $_bashlyk_iErrorCommandNotFound
#    udfOn $e $cmdYes                                                           #? true
#    udfOn MissingArgument ""                                                   #? $_bashlyk_iErrorMissingArgument
#    udfOn EmptyArgument ""                                                     #? $_bashlyk_iErrorMissingArgument
#    udfOn EmptyResult ""                                                       #? $_bashlyk_iErrorEmptyResult
#    udfOn EmptyResult return ""                                                #? $_bashlyk_iErrorEmptyResult
#    udfOn InvalidVariable invalid+variable                                     #? $_bashlyk_iErrorInvalidVariable
#    udfOn NoSuchFileOrDir "/$RANDOM/$RANDOM"                                   #? $_bashlyk_iErrorNoSuchFileOrDir
#  SOURCE

udfOn() {

  local cmd csv e i IFS j s

  cmd='return'
  i=0
  j=0
  IFS=$' \t\n'
  e=$1

  if [[ $1 =~ ^(CommandNotFound|Empty(Variable|Argument|OrMissingArgument|Result)|Invalid(Argument|Variable)|MissingArgument|NoSuchFileOrDir)$ ]]; then

    e=$1

  else

    eval $( udfOnError InvalidArgument "1" )
    return $( _ iErrorInvalidArgument )

  fi

  shift

  case "${1^^}" in

      ECHO) cmd='retecho'; shift;;
      EXIT) cmd='exit';    shift;;
      WARN) cmd='retwarn'; shift;;
     THROW) cmd='throw';   shift;;
    RETURN) cmd='return';  shift;;
        '')

            [[ $e =~ ^(Empty|Missing) && ! $e =~ EmptyVariable ]] \
              || e='MissingArgument'
            eval $( udfOnError $cmd $e 'no arguments' )

          ;;

  esac

  if [[ -z "$@" ]]; then

    [[ $e =~ ^(Empty|Missing) && ! $e =~ ^EmptyVariabl ]] || e='MissingArgument'
    eval $( udfOnError $cmd $e 'no arguments' )

  fi

  for s in "$@"; do

    : $(( j++ ))

    if ! typeset -f "udf${e}" >/dev/null 2>&1; then

      eval $( udfOnError InvalidFunction "udf${e}" )
      continue

    fi

    if udf${e} $s; then

      [[ $s ]] || s=$j

      (( i++ == 0 )) && csv=$s || csv+=", $s"

    fi

  done

  [[ $csv ]] && eval $( udfOnError $cmd ${e} '$csv (total $i)' )

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

  [[ $1 && $( which $1 ) ]] && return 1 || return 0

}
#******
#****f* liberr/udfNoSuchFileOrDir
#  SYNOPSIS
#    udfNoSuchFileOrDir <filename>
#  DESCRIPTION
#    return true if argument is empty, nonexistent, designed to check the
#    conditions in the function udfOn
#  ARGUMENTS
#    filename - filesystem object for checking
#  RETURN VALUE
#    0 - no arguments, specified filesystem object is nonexistent
#    1 - specified filesystem object are found
#  EXAMPLE
#    local cmdYes='/bin/sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    udfNoSuchFileOrDir                                                         #? true
#    udfNoSuchFileOrDir $cmdNo1                                                 #? true
#    $(udfNoSuchFileOrDir $cmdNo2 && exit 123)                                  #? 123
#    udfNoSuchFileOrDir $cmdYes                                                 #? false
#  SOURCE
udfNoSuchFileOrDir() {

  [[ $1 && -e "$1" ]] && return 1 || return 0

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

  [[ $1 ]] && udfIsValidVariable "$1" && return 1 || return 0

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

  [[ $1 ]] && udfIsValidVariable "$1" && [[ ${!1} ]] && return 1 || return 0

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

  [[ $1 ]] && return 1 || return 0

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
#    MissingArgument - arguments not specified
#    CommandNotFound - one or more of all specified filename is
#                      nonexistent or not executable
#    0               - all specified filenames are found and executable
#  EXAMPLE
#    # see also udfOn CommandNotFound ...
#    local cmd=udfOnCommandNotFound
#    local cmdYes='sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    $cmd                                                                       #? $_bashlyk_iErrorMissingArgument
#    $cmd $cmdNo1                                                               #? $_bashlyk_iErrorCommandNotFound
#    $($cmd $cmdNo2 || exit 123)                                                #? 123
#    $cmd WARN $cmdYes $cmdNo1 $cmdNo2 2>&1 >| grep "Error.*bin.*"              #? true
#    $($cmd Throw $cmdNo2 >/dev/null 2>&1; true)                                #? $_bashlyk_iErrorCommandNotFound
#    $cmd $cmdYes                                                               #? true
#  SOURCE
udfOnCommandNotFound() { udfOn CommandNotFound "$@"; }
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
#    $(udfThrowOnCommandNotFound >/dev/null 2>&1)                               #? $_bashlyk_iErrorMissingArgument
#    $(udfThrowOnCommandNotFound $cmdNo >/dev/null 2>&1)                        #? $_bashlyk_iErrorCommandNotFound
#  SOURCE
udfThrowOnCommandNotFound() { udfOnCommandNotFound throw $@; }
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
#    local cmd=udfWarnOnCommandNotFound cmdYes="sh" cmdNo="bin_${RANDOM}"
#    $cmd $cmdYes                                                               #? true
#    $cmd $cmdNo 2>&1 >| grep "Error.* command not found - bin_"                #? true
#    $cmd                                                                       #? $_bashlyk_iErrorMissingArgument
#  SOURCE
udfWarnOnCommandNotFound() { udfOnCommandNotFound warn $@; }
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
#    MissingArgument - no arguments
#    EmptyVariable   - one or more of all specified arguments empty or
#                      non valid variable
#    0               - all arguments are valid and not empty variable
#  OUTPUT
#    see udfOn
#  EXAMPLE
#    # see also udfOn EmptyVariable
#    local cmd=udfOnEmptyVariable sNoEmpty='test' sEmpty='' sMoreEmpty=''
#    $cmd                                                                       #? $_bashlyk_iErrorMissingArgument
#    $cmd sEmpty                                                                #? $_bashlyk_iErrorEmptyVariable
#    $($cmd sEmpty || exit 111)                                                 #? 111
#    $cmd WARN sEmpty sNoEmpty sMoreEmpty 2>&1 >| grep "Error.*y, s"            #? true
#    $cmd Echo sEmpty sMoreEmpty 2>&1 >| grep 'y, s'                            #? true
#    $($cmd  Exit sEmpty >/dev/null 2>&1; true)                                 #? $_bashlyk_iErrorEmptyVariable
#    $($cmd Throw sEmpty >/dev/null 2>&1; true)                                 #? $_bashlyk_iErrorEmptyVariable
#    $cmd sNoEmpty                                                              #? true
#  SOURCE
udfOnEmptyVariable() { udfOn EmptyVariable "$@"; }
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
udfThrowOnEmptyVariable() { udfOnEmptyVariable throw "$@"; }
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
#    local cmd=udfWarnOnEmptyVariable sNoEmpty='test' sEmpty=''
#    $cmd sNoEmpty                                                              #? true
#    $cmd sEmpty 2>&1 >| grep "Error: empty variable - sEmpty.*"                #? true
#  SOURCE
udfWarnOnEmptyVariable() { udfOnEmptyVariable Warn "$@"; }
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
#    MissingArgument - one or more of all specified arguments empty
#    0               - all arguments are not empty
#  OUTPUT
#   see udfOn
#  EXAMPLE
#    local cmd=udfOnEmptyOrMissingArgument sNoEmpty='test' sEmpty sMoreEmpty
#    $cmd                                                                       #? $_bashlyk_iErrorMissingArgument
#    $cmd "$sEmpty"                                                             #? $_bashlyk_iErrorMissingArgument
#    $($cmd "$sEmpty" || exit 111)                                              #? 111
#    $cmd WARN "$sEmpty" "$sNoEmpty" "$sMoreEmpty" 2>&1 >| grep "Error.*1, 3"   #? true
#    $cmd Echo "$sEmpty" "$sMoreEmpty" 2>&1 >| grep '1, 2'                      #? true
#    $cmd WARN "$sEmpty" "$sNoEmpty" "$sMoreEmpty" 2>&1                         #? $_bashlyk_iErrorMissingArgument
#    $cmd Echo "$sEmpty" "$sMoreEmpty" 2>&1                                     #? $_bashlyk_iErrorMissingArgument
#    $($cmd Exit "$sEmpty" >/dev/null 2>&1; true)                               #? $_bashlyk_iErrorMissingArgument
#    $($cmd Throw "$sEmpty" >/dev/null 2>&1; true)                              #? $_bashlyk_iErrorMissingArgument
#    $cmd "$sNoEmpty"                                                           #? true
#  SOURCE
udfOnEmptyOrMissingArgument() { udfOn EmptyOrMissingArgument "$@"; }
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
#    $(udfThrowOnEmptyOrMissingArgument "$sEmpty" >/dev/null 2>&1)              #? $_bashlyk_iErrorMissingArgument
#  SOURCE
udfThrowOnEmptyOrMissingArgument() { udfOnEmptyOrMissingArgument throw "$@"; }
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
#    udfWarnOnEmptyOrMissingArgument "$sEmpty" 2>&1 >| grep "Error: empty or.*" #? true
#  SOURCE
udfWarnOnEmptyOrMissingArgument() { udfOnEmptyOrMissingArgument warn "$@"; }
#******
