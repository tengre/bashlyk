#
# $Git: liberr.sh 1.94-44-934 2019-11-29 23:18:16+04:00 yds $
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
#    $_BASHLYK_liberr provides protection against re-using of this module
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
alias         error='eval $( err::generate "$@" )'
alias          show='err::postfix echo'
alias          warn='err::postfix warn'
alias         abort='err::postfix exit'
alias         throw='err::postfix throw'
alias      errorify='err::postfix return'
alias     exit+echo='err::postfix echo+exit'
alias     exit+warn='err::postfix warn+exit'
alias errorify+echo='err::postfix echo+return'
alias errorify+warn='err::postfix warn+return'
alias         catch='; eval "$( err::__convert_try_to_func )" ||'
#******
#****G* liberr/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
declare -rg _bashlyk_aRequiredCmd_err="[ rm sed"

declare -rg _bashlyk_methods_err="

    __add_throw_to_command CommandNotFound __convert_try_to_func debug
    EmptyArgument EmptyOrMissingArgument EmptyResult EmptyVariable
    exception.message generate __generate InvalidVariable MissingArgument
    NotExistNotCreated NotNumber AlreadyExist NoSuchFileOrDir NoSuchFile
    NoSuchDir orr postfix sourcecode stacktrace status status.show
"

declare -rg _bashlyk_aExport_err="

    abort catch err::{exception.message,stacktrace,status,sourcecode} errorify
    errorify+echo errorify+warn exit+echo exit+warn error show throw try warn

"

declare -rg _bashlyk_err_reAct='^((echo|warn)|(((echo|warn)[+])?(exit|return))|(throw))$'
declare -rg _bashlyk_err_reArg='(error|err::generate|\$\(.?err::generate.\"\$\@\".?\))[[:space:]]*?([^\>]*)[[:space:]]*?[\>\|]?'

: ${_bashlyk_onError:=throw}
: ${_bashlyk_iPidMax:=999999}
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
_bashlyk_iErrorNotInteger=195
_bashlyk_iErrorNotDecimal=194
_bashlyk_iErrorNotExistNotCreated=190
_bashlyk_iErrorAlreadyExist=188
_bashlyk_iErrorNoSuchDir=187
_bashlyk_iErrorNoSuchFile=186
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
_bashlyk_iErrorTimeExpired=167
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
_bashlyk_hError[$_bashlyk_iErrorNotInteger]="not integer"
_bashlyk_hError[$_bashlyk_iErrorNotDecimal]="not decimal number"
_bashlyk_hError[$_bashlyk_iErrorNotExistNotCreated]="not exist and not created"
_bashlyk_hError[$_bashlyk_iErrorAlreadyExist]="already exist"
_bashlyk_hError[$_bashlyk_iErrorNoSuchDir]="no such directory"
_bashlyk_hError[$_bashlyk_iErrorNoSuchFile]="no such file"
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
_bashlyk_hError[$_bashlyk_iErrorTimeExpired]="time expired"
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
#    echo "$_bashlyk_iPidMax" | {{ "^[[:digit:]]*$" }}
#    err::status iErrorInvalidVariable "12Invalid"                              #? $_bashlyk_iErrorInvalidVariable
#    err::status.show                                                           #? $_bashlyk_iErrorInvalidVariable
#    err::status.show invalid argument                                          #? $_bashlyk_iErrorInvalidVariable
#    err::status.show $$                                                        #? $_bashlyk_iErrorInvalidVariable
#  SOURCE
err::status.show() {

  local pid

  [[ $1 =~ ^[0-9]+$ ]] && (( $1 < $_bashlyk_iPidMax )) && pid=$1 || pid=$BASHPID

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
#    err::status                                                                #? $_bashlyk_iErrorInvalidVariable
#    err::status invalid argument                                               #? $_bashlyk_iErrorUnknown
#    err::status 555                                                            #? $_bashlyk_iErrorUnexpected
#    err::status AlreadyStarted "$$"                                            #? $_bashlyk_iErrorAlreadyStarted
#    err::status iErrorInvalidVariable 12Invalid test                           #? $_bashlyk_iErrorInvalidVariable
#    err::status | {{ '^invalid variable - 12Invalid test (200)$' }}
#    err::status NotAvailable test unit
#    echo $(err::status) | {{'^target is not available - test unit (166)$'}}
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
## TODO improves required
#    err::stacktrace | {{'1: code err::stacktrace_test'}}
#  SOURCE
err::stacktrace() {

  local i s=$( printf -- '\u00a0' )

  printf -- 'Stack trace by %s from %s {\n' "${FUNCNAME[0]}" "${BASH_SOURCE[0]}"

  for (( i=${#FUNCNAME[@]}-1; i >= 0; i-- )); do

    (( ${BASH_LINENO[i]} == 0 )) && continue

    printf -- '%s%d: call %s:%s %s ..\n%s%d: code %s\n'                        \
              "$s" "$i" "${BASH_SOURCE[$i+1]:=<shell>}"                        \
              "${BASH_LINENO[$i]}" "${FUNCNAME[$i]}"                           \
              "$s" "$i" "$( err::sourcecode $i || echo ....... )"

    s+=" "

  done

  printf -- '}\n\n'

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
#    err::sourcecode | {{'^err::sourcecode_test$'}}
#  SOURCE
err::sourcecode() {

  local fn i

  [[ $1 =~ ^[0-9]+ ]] && i=$(( $1 + 1 )) || i=1

  if [[ -s ${BASH_SOURCE[i+1]} ]]; then

    fn=${BASH_SOURCE[i+1]}

  else

    fn=${_bashlyk_PWD}/${BASH_SOURCE[i+1]##*/}

  fi

  if [[ $fn && -f $fn  && -s $fn ]]; then

    std::isNumber ${BASH_LINENO[i]} && sed -n "${BASH_LINENO[i]}p" $fn

  else

    return $_bashlyk_iErrorNoSuchFile

  fi

}
#******
#****e* liberr/err::generate
#  SYNOPSIS
#    err::generate [<state>] [<action>] [--] [<message>]
#  DESCRIPTION
#    Generate code for flexible error handling, which depends on the global
#    variable or arguments. Possible to combine with each other the following
#    types of code:
#        * Output the warning message
#        * Function termination with error code
#        * Completion of the script with error code
#        * Call stack trace
#    The generated code is intended for execution by the eval utility
#  NOTES
#    public method
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
#    <state> - number or predefined name as 'iError<Name>' or '<Name>' by which
#              one can get the error code from the global variable
#              $_bashlyk_iError<..> and its description from global hash
#              $_bashlyk_hError
#              If the error code is not specified, it is set to the return code
#              of the last executed command. In the end, the resulting numeric
#              code initializes a global variable $_bashlyk_iLastError[$BASHPID]
#
#    <message> - An error detail, such as the file name. When specifying a
#                message, you should keep in mind that the error table
#                ($_bashlyk_hError) has already prepared the descriptions.
#                Important!!! Only one line is expected, additional lines can be
#                processed by the interpreter. To avoid execution of these lines
#                as a code, you need to remove linefeeds from variables, do not
#                apply double quotes around them (see examples).
#
#  OUTPUT
#    command line, which can be performed using the eval <...>
#  EXAMPLE
#    local fn s
#    false || error NoSuchFileOrDir warn /notexist                              #? true
#    _bashlyk_onError=debug
#    false || error NoSuchFileOrDir exit /notexist                              #? $_bashlyk_iErrorNoSuchFileOrDir
#    err::orr 100 || error echo                                                 #? true
#    err::orr 101 || error 115 echo+return                                      #? 115
#    err::orr 102 || error 116                                                  #? 116
#    err::orr 103 || error bla-bla bla                                          #? 103
#    err::orr 103 || error CommandNotFound bla-bla bla                          #? $_bashlyk_iErrorCommandNotFound
#    err::orr 104 || error                                                      #? 104
#    std::temp fn
#    w > $fn                                                                    #-
#    error InvalidArgument warn "$(std::inline< <(w))"                          #? true ## See test log for the absence of multiline artefacts
#    error InvalidArgument warn -- $(w)                                         #? true ## See test log for the absence of multiline artefacts
#    error InvalidArgument warn "$(std::inline lf_tag < $fn)"                   #? true ## See test log for the absence of multiline artefacts
#    error InvalidArgument warn "test "$(w)" test"                              #? true ## See test log for the absence of multiline artefacts
#  SOURCE
err::generate() {

  local bashlyk_err_gen_rc=$?

  if   [[ $- =~ i ]]; then

    _ onError return
    echo "echo [!]"

  elif [[ "$( err::sourcecode )" =~ $_bashlyk_err_reArg ]]; then

    err::__generate $bashlyk_err_gen_rc $( eval echo "${BASH_REMATCH[2]}" )

  else

    echo "echo \"$@ - invalid arguments for error handling, abort...\"; exit $_bashlyk_iErrorInvalidArgument;"

  fi

}
#******
#****p* liberr/err::__generate
#  SYNOPSIS
#    err::__generate [<state>] [<action>] [[hint=]<message>]
#  DESCRIPTION
#    The internal part of the function err::generate for protecting variables in
#    arguments from local variables of this functions when calling the "eval"
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
#    local cmd
#    cmd='err::__generate 1 NoSuchFileOrDir warn /notexist'
#    _bashlyk_onError=debug
#    $cmd                                                                       | {{{
#    err::stacktrace | msg::warn -  Warn: no\ such\ file\ or\ directory\ -\ /notexist\ ..\ \(185\) >&2; err::status 185 "/notexist"; :; #
# }}}
#    _bashlyk_onError=echo
#    $cmd                                                                       | {{{
#    msg::warn  Warn: no\ such\ file\ or\ directory\ -\ /notexist\ ..\ \(185\) >&2; err::status 185 "/notexist"; :; #
# }}}
#  SOURCE
err::__generate() {

  local i IFS sAction sMessage s rc rs fn echo warn
  local -a a
  #
  std::isNumber $1 && rc=$1 && shift || rc=$_bashlyk_iErrorUnknown
  #
      IFS=$' \t\n'
        a=( ${*/--/} )
     echo='echo'
     warn='msg::warn'
  sAction=$_bashlyk_onError

  if   [[ ${a[0]} =~ $_bashlyk_err_reAct ]]; then

    sAction=${BASH_REMATCH[1]}
    rs=$rc
    i=1

  elif [[ ${a[1]} =~ $_bashlyk_err_reAct ]]; then

    sAction=${BASH_REMATCH[1]}
    [[ ${a[0]} ]] && rs=${a[0]} || rs=$rc
    i=2

  else

    i=0
    [[ ${a[0]} ]] && rs=${a[0]} && i=1 || rs=$rc

  fi

  err::orr $rs; rs=$?

  if (( rs >= $_bashlyk_iErrorUnknown )); then

    s="(may be previous..) "

    if [[ ${_bashlyk_hError[$rc]} ]]; then

      rs=$rc
      s+="${_bashlyk_hError[$rc]} - ${a[@]} .. ($rc)"

    else

      (( rs == 255 )) && rs=$rc
      s+="${a[@]} .. ($rc)"

    fi

  else

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
    sAction=${sAction/return/err::orr}

  fi

  printf -- '%s >&2; err::status %s "%s"; %s; #' \
            "${sMessage}${s}" "$rs" "${i//\;/}" "$sAction"

}
#******
#****p* liberr/err::CommandNotFound
#  SYNOPSIS
#    err::CommandNotFound <filename>
#  DESCRIPTION
#    return true if argument is not empty, exists and executable
#    designed to check the conditions in the function err::postfix
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
#****p* liberr/err::AlreadyExist
#  SYNOPSIS
#    err::AlreadyExist <filename>
#  DESCRIPTION
#    return true if argument is empty, not exists, designed to check the
#    conditions in the function err::postfix
#  NOTES
#    private method
#  ARGUMENTS
#    <filename> - filesystem object for checking
#  RETURN VALUE
#    AlreadyExist - specified filesystem object is exists
#    0            - no arguments, specified filesystem object are not found
#  EXAMPLE
#    local cmdYes='/bin/sh' pathNo1="/tmp" cmdNo1="bin_${RANDOM}"
#    err::AlreadyExist                                                          #? true
#    err::AlreadyExist $cmdNo1                                                  #? true
#    $(err::AlreadyExist $pathNo1 || exit 123)                                  #? 123
#    err::AlreadyExist $cmdYes                                                  #? $_bashlyk_iErrorAlreadyExist
#  SOURCE
err::AlreadyExist() {

  [[ $* && -e "$*" ]] && return $_bashlyk_iErrorAlreadyExist || return 0

}
#******
#****p* liberr/err::NoSuchFileOrDir
#  SYNOPSIS
#    err::NoSuchFileOrDir <filename>
#  DESCRIPTION
#    return true if argument is non empty, exists, designed to check the
#    conditions in the function err::postfix
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
#****p* liberr/err::NoSuchFile
#  SYNOPSIS
#    err::NoSuchFile <filename>
#  DESCRIPTION
#    return true if argument is non empty, exists, designed to check the
#    conditions in the function err::postfix
#  NOTES
#    private method
#  ARGUMENTS
#    <filename> - filesystem object for checking
#  RETURN VALUE
#    NoSuchFile - no arguments, specified file is nonexistent
#    0          - specified file are found
#  EXAMPLE
#    local cmdYes='/bin/sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    err::NoSuchFile                                                            #? $_bashlyk_iErrorNoSuchFile
#    err::NoSuchFile $cmdNo1                                                    #? $_bashlyk_iErrorNoSuchFile
#    $(err::NoSuchFile $cmdNo2 || exit 123)                                     #? 123
#    err::NoSuchFile $cmdYes                                                    #? true
#  SOURCE
err::NoSuchFile() {

  [[ $* && -f "$*" ]] || return $_bashlyk_iErrorNoSuchFile

}
#******
#****p* liberr/err::NoSuchDir
#  SYNOPSIS
#    err::NoSuchDir <directory>
#  DESCRIPTION
#    return true if argument is non empty, exists, designed to check the
#    conditions in the function err::postfix
#  NOTES
#    private method
#  ARGUMENTS
#    <directory> - directory for checking
#  RETURN VALUE
#    NoSuchDir - no arguments, specified directory is nonexistent
#    0         - specified directory are found
#  EXAMPLE
#    local pathYes='/tmp' pathNo1="/bin_${RANDOM}" pathNo2="/bin_${RANDOM}"
#    err::NoSuchDir                                                             #? $_bashlyk_iErrorNoSuchDir
#    err::NoSuchDir $pathNo1                                                    #? $_bashlyk_iErrorNoSuchDir
#    $(err::NoSuchDir $pathNo2 || exit 123)                                     #? 123
#    err::NoSuchDir $pathYes                                                    #? true
#  SOURCE
err::NoSuchDir() {

  [[ $* && -d "$*" ]] || return $_bashlyk_iErrorNoSuchDir

}
#******
#****p* liberr/err::NotExistNotCreated
#  SYNOPSIS
#    err::NotExistNotCreated <path>
#  DESCRIPTION
#    return true if argument is non empty, exists or succesfully created.
#    Designed to check the conditions in the function err::postfix
#  NOTES
#    private method
#  ARGUMENTS
#    <path> - filesystem directory for checking
#  RETURN VALUE
#    NotExistNotCreated - no arguments, the specified path does not exist and is
#                         not created
#    0                  - specified path are found or created
#  EXAMPLE
#    local pathYes='/tmp' pathNo1=""
#    err::NotExistNotCreated                                                    #? $_bashlyk_iErrorNotExistNotCreated
#    err::NotExistNotCreated $pathNo1                                           #? $_bashlyk_iErrorNotExistNotCreated
#    $(err::NotExistNotCreated $pathNo1 || exit 123)                            #? 123
#    err::NotExistNotCreated $pathYes                                           #? true
#  SOURCE
err::NotExistNotCreated() {

  [[ $* ]] || return $_bashlyk_iErrorNotExistNotCreated

  if ! mkdir -p "$@" >/dev/null 2>&1; then

    return $_bashlyk_iErrorNotExistNotCreated

  else

    return 0

  fi

}
#******
#****p* liberr/err::InvalidVariable
#  SYNOPSIS
#    err::InvalidVariable <variable>
#  DESCRIPTION
#    return true if argument is non empty, valid variable, designed to check the
#    conditions in the function err::postfix
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
#****p* liberr/err::NotNumber
#  SYNOPSIS
#    err::NotNumber <argument>
#  DESCRIPTION
#    return true if argument is non empty, valid number, designed to check the
#    conditions in the function err::postfix
#  NOTES
#    private method
#  INPUTS
#    <argument> - expected number
#  RETURN VALUE
#    NotNumber  - argument is empty or not number
#    0          - valid number
#  EXAMPLE
#    err::NotNumber                                                             #? $_bashlyk_iErrorNotNumber
#    err::NotNumber 1a                                                          #? $_bashlyk_iErrorNotNumber
#    err::NotNumber 12                                                          #? true
#    $(err::NotNumber 2b || exit 123)                                           #? 123
#    $(err::NotNumber 33 && exit 123)                                           #? 123
#  SOURCE
err::NotNumber() {

  std::isNumber $* || return $_bashlyk_iErrorNotNumber

}
#******
#****p* liberr/err::EmptyVariable
#  SYNOPSIS
#    err::EmptyVariable <variable>
#  DESCRIPTION
#    return true if argument is non empty, valid variable
#    designed to check the conditions in the function err::postfix
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
#    designed to check the conditions in the function err::postfix
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
#    designed to check the conditions in the function err::postfix
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
#****p* liberr/err::postfix
#  SYNOPSIS
#    err::postfix <action> on <state> <argument>
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
#    see error ...
#  EXAMPLE
#    local fn1 fn2
#    std::temp fn1
#    std::temp fn2
#    err::postfix warn on NoSuchFileOrDir /err.handler                          #? true
#    errorify+echo on CommandNotFound notexist.return                           #? $_bashlyk_iErrorCommandNotFound
#    warn on NoSuchFileOrDir /notexist.warn                                     #? true
#    $(throw on NoSuchFileOrDir "$fn1" "$fn2")                                  #? true
#    errorify on NoSuchFileOrDir "/notexist.echo" "/notexist.warn"              #? $_bashlyk_iErrorNoSuchFileOrDir
#    $(throw on NoSuchFileOrDir "/notexist.throw.child")                        #? $_bashlyk_iErrorNoSuchFileOrDir
#    $(exit+echo on CommandNotFound notexist.exit+echo.child)                   #? $_bashlyk_iErrorCommandNotFound
#    $(errorify on CommandNotFound notexist.errorify.child || return)           #? $_bashlyk_iErrorCommandNotFound
#    $(errorify on NotNumber q123 || return)                                    #? $_bashlyk_iErrorNotNumber
#    $(errorify on NotExistNotCreated || return)                                #? $_bashlyk_iErrorNotExistNotCreated
#    warn on CommandNotFound notexist nomoreexist                               #? true
#  SOURCE
err::postfix() {

  local -a aErrHandler=( $* )
  local re='^(echo|warn)$|^((echo|warn)[+])?(exit|return)$|^throw$' i=0 j=0 s
  ## TODO add reAction and reState for safely arguments parsing

  [[ $1 =~ $re ]] && shift || error InvalidArgument throw ${1:-first argument}
  [[ $1 == on  ]] && shift || error InvalidArgument throw ${1:-second argument}
  [[ $1        ]] && shift || error MissingArgument throw ${1:-third argument}

  if ! declare -f err::${aErrHandler[2]} >/dev/null 2>&1; then

    error InvalidArgument throw ${aErrHandler[2]}

  fi

  [[ $* ]] || error ${aErrHandler[2]} ${aErrHandler[0]} ${aErrHandler[@]:3}

  for s in "$@"; do

    : $(( j++ ))

    if ! err::${aErrHandler[2]} $s; then

      [[ $s ]] || s=$j

      (( i++ == 0 )) && aErrHandler[3]=$s || aErrHandler[3]+=", $s"

    fi

  done

  if (( i > 0 )); then

    (( i > 1 )) && aErrHandler[3]+=" [total $i]"
    error ${aErrHandler[2]} ${aErrHandler[0]} ${aErrHandler[3]}

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
#    $cmd $s                                                                    | {{{
#    _bashlyk_sLastError[$BASHPID]="command: $(std::trim command --with -a -- arguments)\n output: {\n$(command --with -a -- arguments 2>&1)\n}" && echo -n . || return $?;
# }}}
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
#    err::__convert_try_to_func                                                 | {{"^${TMPDIR}/.*ok.*fail.*; false; }$"}}
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

  done< <( declare -f try 2>/dev/null)

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
#   . $fn                                                                       | {{{
#   ... fail..(210)
#
#   try block exception:
#   ~~~~~~~~~~~~~~~~~~~~
#    status: 210
#   command: error4test
#    output: {
#    testunit.sh: special error for testing
#   }
# }}}
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

  [[ $* ]] && printf -- '%s\n' "$*" >&2

  return 0

}
#******
#****f* liberr/err::debugf
#  SYNOPSIS
#    err::debugf <level> <format> <values>
#  DESCRIPTION
#    show a formatted message on the stderr if the <level> is equal or less than
#    the $DEBUGLEVEL value otherwise return code 1
#  INPUTS
#    <level>  - decimal number of the debug level ( 0 for wrong argument)
#    <format> - printf format string
#    <values> - values for format string
#  OUTPUT
#    show a formatted message on the stderr
#  RETURN VALUE
#    0               - <level> equal or less than $DEBUGLEVEL value
#    1               - <level> more than $DEBUGLEVEL value
#    MissingArgument - no arguments
#  EXAMPLE
#    DEBUGLEVEL=0
#    err::debugf                                                                #? $_bashlyk_iErrorMissingArgument
#    err::debugf 0 '%s: %s\n' 'level0' "$(date -R)" 2>&1                        | {{ ^level0: }}
#    err::debugf 1 '%s\n' 'level 1'                                             #? 1
#    DEBUGLEVEL=5
#    err::debugf 4 "%s: %s\n" "level5" "$(date -R)" 2>&1                        | {{ ^level5: }}
#    err::debugf 6 '%s:\n' 'level6'                                             #? 1
#    err::debugf '%s:\n' 'default0' 2>&1                                        | {{ ^default0: }}
#  SOURCE
err::debugf() {

  local IFS=$' \t\n'

  errorify on MissingArgument $* || return

  if [[ $1 =~ ^[0-9]+$ ]]; then

    (( ${DEBUGLEVEL:=0} >= $1 )) && shift || return 1

  fi

  [[ $* ]] && eval 'printf -- "$@" >&2'

  return $?

}
#******
