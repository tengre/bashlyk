#
# $Id: libtst.sh 812 2018-03-21 18:34:33+04:00 toor $
#
#****h* BASHLYK/libtst
#  DESCRIPTION
#    a set of functions to handle errors
#  USES
#    libstd libmsg
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libtst/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBTST provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBTST" ] && return 0 || _BASHLYK_LIBTST=1
[ -n "$_BASHLYK" ] || . ${_bashlyk_pathLib}/bashlyk || eval '                  \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
shopt -s expand_aliases
#****A* libtst/Aliases
#  DESCRIPTION
#    usable aliases for exported functions
#  SOURCE
alias           try='try()'
alias         error='eval $( tst::generate "$@" )'
alias          show='tst::postfix echo'
alias          warn='tst::postfix warn'
alias         abort='tst::postfix exit'
alias         throw='tst::postfix throw'
alias      errorify='tst::postfix return'
alias     exit+echo='tst::postfix echo+exit'
alias     exit+warn='tst::postfix warn+exit'
alias errorify+echo='tst::postfix echo+return'
alias errorify+warn='tst::postfix warn+return'
alias         catch='; eval "$( tst::__convert_try_to_func )" ||'
#******
#****G* libtst/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
declare -rg _bashlyk_aRequiredCmd_tst="[ rm sed"

declare -rg _bashlyk_methods_tst="                                             \
                                                                               \
    __add_throw_to_command CommandNotFound __convert_try_to_func debug         \
    EmptyArgument EmptyOrMissingArgument EmptyResult EmptyVariable             \
    exception.message generate __generate InvalidVariable MissingArgument      \
    NoSuchFileOrDir orr postfix sourcecode stacktrace status status.show       \
"

declare -rg _bashlyk_aExport_tst="                                             \
                                                                               \
    abort catch tst::{exception.message,stacktrace,status,sourcecode} errorify \
    errorify+echo errorify+warn exit+echo exit+warn error show throw try warn  \
                                                                               \
"

#declare -rg _bashlyk_tst_reAct='^action=(echo|warn)$|action=((echo|warn)[+])?(exit|return)$|^action=throw$'
declare -rg _bashlyk_tst_reAct='^action=((echo|warn)|(((echo|warn)[+])?(exit|return))|(throw))$'
declare -rg _bashlyk_tst_reArg='(error|tst::generate|\$\(.?tst::generate.\"\$\@\".?\))[[:space:]]*?([^\>]*)[[:space:]]*?[\>\|]?'

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
_bashlyk_iErrorNotInteger=195
_bashlyk_iErrorNotDecimal=194
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
_bashlyk_hError[$_bashlyk_iErrorNotInteger]="not integer"
_bashlyk_hError[$_bashlyk_iErrorNotDecimal]="not decimal number"
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
#****L* libtst/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libmsg.sh ]] && . "${_bashlyk_pathLib}/libmsg.sh"
#******
#****p* libtst/tst::orr
#  SYNOPSIS
#    tst::orr [<arg>]
#  DESCRIPTION
#    return status from 0 to 255 (default 255)
#  ARGUMENTS
#    arg - expected 0-254
#  NOTES
#    public method
#  ERROR
#    255 - first argument is not valid
#  EXAMPLE
#    tst::orr                                                                   #? 255
#    tst::orr 0                                                                 #? true
#    tst::orr 123                                                               #? 123
#    tst::orr 256                                                               #? 255
#  SOURCE
tst::orr() {

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
#****p* libtst/tst::status.show
#  SYNOPSIS
#    tst::status.show [<pid>]
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
#    tst::status iErrorInvalidVariable "12Invalid"                              #? $_bashlyk_iErrorInvalidVariable
#    tst::status.show                                                           #? $_bashlyk_iErrorInvalidVariable
#    tst::status.show invalid argument                                          #? $_bashlyk_iErrorInvalidVariable
#    tst::status.show $$                                                        #? $_bashlyk_iErrorInvalidVariable
#  SOURCE
tst::status.show() {

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
#****e* libtst/tst::status
#  SYNOPSIS
#    tst::status <number> <string>
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
#    tst::status                                                                #? $_bashlyk_iErrorInvalidVariable
#    tst::status invalid argument                                               #? $_bashlyk_iErrorUnknown
#    tst::status 555                                                            #? $_bashlyk_iErrorUnexpected
#    tst::status AlreadyStarted "$$"                                            #? $_bashlyk_iErrorAlreadyStarted
#    tst::status iErrorInvalidVariable 12Invalid test                           #? $_bashlyk_iErrorInvalidVariable
#    tst::status | {{ '^invalid variable - 12Invalid test (200)$' }}
#    tst::status NotAvailable test unit
#    echo $(tst::status) | {{'^target is not available - test unit (166)$'}}
#  SOURCE
tst::status() {

  if [[ ! $1 ]]; then

    if [[ ${_bashlyk_iLastError[$BASHPID]} ]]; then

      tst::status.show $BASHPID

    elif [[ ${_bashlyk_iLastError[$$]} ]]; then

      tst::status.show $$

    fi

    return

  fi

  tst::orr $1

  local i=$?

  (( i == 255 )) && i=$_bashlyk_iErrorUnknown || shift

  _bashlyk_iLastError[$BASHPID]=$i

  [[ $* ]] && _bashlyk_sLastError[$BASHPID]="$*"

  return $i

}
#******
#****e* libtst/tst::stacktrace
#  SYNOPSIS
#    tst::stacktrace
#  DESCRIPTION
#    OUTPUT BASH Stack Trace
#  NOTES
#    public method
#  OUTPUT
#    BASH Stack Trace
#  EXAMPLE
## TODO improves required
#    tst::stacktrace | {{'1: code tst::stacktrace_test'}}
#  SOURCE
tst::stacktrace() {

  local i s=$( printf -- '\u00a0' )

  printf -- 'Stack trace by %s from %s {\n' "${FUNCNAME[0]}" "${BASH_SOURCE[0]}"

  for (( i=${#FUNCNAME[@]}-1; i >= 0; i-- )); do

    (( ${BASH_LINENO[i]} == 0 )) && continue

    printf -- '%s%d: call %s:%s %s ..\n%s%d: code %s\n'                        \
              "$s" "$i"                                                        \
              "${BASH_SOURCE[$i+1]}" "${BASH_LINENO[$i]}" "${FUNCNAME[$i]}"    \
              "$s" "$i"                                                        \
              "$( tst::sourcecode $i )"

    s+=" "

  done

  printf -- '}\n\n'

}
#******
#****e* libtst/tst::sourcecode
#  SYNOPSIS
#    tst::sourcecode [<level>]
#  DESCRIPTION
#    get source code line for selected stack level ( 0 default )
#  NOTES
#    public method
#  OUTPUT
#    source code line
#  EXAMPLE
#    tst::sourcecode | {{'^tst::sourcecode_test$'}}
#  SOURCE
tst::sourcecode() {

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
#****e* libtst/tst::generate
#  SYNOPSIS
#    tst::generate [<state>] [[action=]<action>] [<message>]
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
#  OUTPUT
#    command line, which can be performed using the eval <...>
#  EXAMPLE
#    false || error NoSuchFileOrDir action=warn /notexist                       #? true
#    _bashlyk_onError=debug
#    false || error NoSuchFileOrDir action=exit /notexist                       #? $_bashlyk_iErrorNoSuchFileOrDir
#    tst::orr 100 || error action=echo                                          #? true
#    tst::orr 101 || error 115 action=echo+return                               #? 115
#    tst::orr 102 || error 116                                                  #? 116
#    tst::orr 103 || error bla-bla bla                                          #? 103
#    tst::orr 103 || error CommandNotFound bla-bla bla                          #? $_bashlyk_iErrorCommandNotFound
#    tst::orr 104 || error                                                      #? 104
#  SOURCE
tst::generate() {

  local bashlyk_err_gen_rc=$?

  if [[ ! "$( tst::sourcecode )" =~ $_bashlyk_tst_reArg ]]; then

    echo "echo \"$@ - invalid arguments for error handling, abort...\"; exit $_bashlyk_iErrorInvalidArgument;"

  fi

  tst::__generate $bashlyk_err_gen_rc $(eval echo "\"${BASH_REMATCH[2]//\"/}\"")

}
#******
#****p* libtst/tst::__generate
#  SYNOPSIS
#    tst::__generate [<state>] [[action=]<action>] [[hint=]<message>]
#  DESCRIPTION
#    The internal part of the function tst::generate for protecting variables in
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
#    cmd='tst::__generate 1 NoSuchFileOrDir action=warn /notexist'
#    _bashlyk_onError=debug
#    $cmd | {{{
#    tst::stacktrace | msg::warn -  Warn: no\ such\ file\ or\ directory\ -\ /notexist\ ..\ \(185\) >&2; tst::status 185 "/notexist"; : ; #
# }}}
#    _bashlyk_onError=echo
#    $cmd | {{{
#    msg::warn  Warn: no\ such\ file\ or\ directory\ -\ /notexist\ ..\ \(185\) >&2; tst::status 185 "/notexist"; : ; #
# }}}
#  SOURCE
tst::__generate() {

  local i IFS sAction sMessage s rc rs fn echo warn
  local -a a
  #
  std::isNumber $1 && rc=$1 && shift || rc=$_bashlyk_iErrorUnknown
  #
      IFS=$' \t\n'
        a=( $* )
     echo='echo'
     warn='msg::warn'
  sAction=$_bashlyk_onError
  
  if   [[ ${a[0]} =~ $_bashlyk_tst_reAct ]]; then
  
    sAction=${BASH_REMATCH[1]}
    rs=$rc
    i=1
    
  elif [[ ${a[1]} =~ $_bashlyk_tst_reAct ]]; then

    sAction=${BASH_REMATCH[1]}
    [[ ${a[0]} ]] && rs=${a[0]} || rs=$rc
    i=2
  
  else
  
    i=0
    [[ ${a[0]} ]] && rs=${a[0]} && i=1 || rs=$rc
  
  fi
  
  tst::orr $rs; rs=$?

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

    echo='tst::stacktrace | std::cat'
    warn='tst::stacktrace | msg::warn -'

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
                 sMessage='tst::stacktrace | msg::warn - Error: '
          ;;

  esac

  i=${a[@]:$i}

  if [[ $_bashlyk_onError == debug ]]; then

    sAction=${sAction/exit/tst::orr}
    sAction=${sAction/return/tst::orr}

  fi

  printf -- '%s >&2; tst::status %s "%s"; %s; #' \
            "${sMessage}${s}" "$rs" "${i//\;/}" "$sAction"

}
#******
#****p* libtst/tst::CommandNotFound
#  SYNOPSIS
#    tst::CommandNotFound <filename>
#  DESCRIPTION
#    return true if argument is not empty, exists and executable (## TODO test)
#    designed to check the conditions in the function tst::postfix
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
#    tst::CommandNotFound                                                       #? $_bashlyk_iErrorCommandNotFound
#    tst::CommandNotFound $cmdNo1                                               #? $_bashlyk_iErrorCommandNotFound
#    $( tst::CommandNotFound $cmdNo2 || exit 123 )                              #? 123
#    tst::CommandNotFound $cmdYes                                               #? true
#  SOURCE
tst::CommandNotFound() {

  [[ $* ]] && hash "$*" 2>/dev/null || return $_bashlyk_iErrorCommandNotFound

}
#******
#****p* libtst/tst::NoSuchFileOrDir
#  SYNOPSIS
#    tst::NoSuchFileOrDir <filename>
#  DESCRIPTION
#    return true if argument is non empty, exists, designed to check the
#    conditions in the function tst::postfix
#  NOTES
#    private method
#  ARGUMENTS
#    <filename> - filesystem object for checking
#  RETURN VALUE
#    NoSuchFileOrDir - no arguments, specified filesystem object is nonexistent
#    0               - specified filesystem object are found
#  EXAMPLE
#    local cmdYes='/bin/sh' cmdNo1="bin_${RANDOM}" cmdNo2="bin_${RANDOM}"
#    tst::NoSuchFileOrDir                                                       #? $_bashlyk_iErrorNoSuchFileOrDir
#    tst::NoSuchFileOrDir $cmdNo1                                               #? $_bashlyk_iErrorNoSuchFileOrDir
#    $(tst::NoSuchFileOrDir $cmdNo2 || exit 123)                                #? 123
#    tst::NoSuchFileOrDir $cmdYes                                               #? true
#  SOURCE
tst::NoSuchFileOrDir() {

  [[ $* && -e "$*" ]] || return $_bashlyk_iErrorNoSuchFileOrDir

}
#******
#****p* libtst/tst::InvalidVariable
#  SYNOPSIS
#    tst::InvalidVariable <variable>
#  DESCRIPTION
#    return true if argument is non empty, valid variable, designed to check the
#    conditions in the function tst::postfix
#  NOTES
#    private method
#  INPUTS
#    <variable> - expected variable name
#  RETURN VALUE
#    InvalidVariable - argument is empty or invalid variable
#    0               - valid variable
#  EXAMPLE
#    tst::InvalidVariable                                                       #? $_bashlyk_iErrorInvalidVariable
#    tst::InvalidVariable 1a                                                    #? $_bashlyk_iErrorInvalidVariable
#    tst::InvalidVariable a1                                                    #? true
#    $(tst::InvalidVariable 2b || exit 123)                                     #? 123
#    $(tst::InvalidVariable c3 && exit 123)                                     #? 123
#  SOURCE
tst::InvalidVariable() {

  [[ $* ]] && std::isVariable "$*" || return $_bashlyk_iErrorInvalidVariable

}
#******
#****p* libtst/tst::EmptyVariable
#  SYNOPSIS
#    tst::EmptyVariable <variable>
#  DESCRIPTION
#    return true if argument is non empty, valid variable
#    designed to check the conditions in the function tst::postfix
#  NOTES
#    private method
#  INPUTS
#    variable - expected variable name
#  RETURN VALUE
#    EmptyVariable - argument is empty, invalid or empty variable
#    0             - valid not empty variable
#  EXAMPLE
#    local a b="$RANDOM"
#    tst::EmptyVariable                                                         #? $_bashlyk_iErrorEmptyVariable
#    tst::EmptyVariable a                                                       #? $_bashlyk_iErrorEmptyVariable
#    $(tst::EmptyVariable a || exit 123)                                        #? 123
#    $(tst::EmptyVariable b && exit 123)                                        #? 123
#    tst::EmptyVariable b                                                       #? true
#  SOURCE
tst::EmptyVariable() {

  [[ $1 ]] && std::isVariable "$1" && [[ ${!1} ]] || return $_bashlyk_iErrorEmptyVariable

}
#******
#****p* libtst/tst::MissingArgument
#  SYNOPSIS
#    tst::MissingArgument <argument>
#  DESCRIPTION
#    return true if argument is not empty
#    designed to check the conditions in the function tst::postfix
#  NOTES
#    private method
#  INPUTS
#    argument - one argument
#  RETURN VALUE
#    MissingArgument - argument is empty
#    0               - non empty argument
#  EXAMPLE
#    local a b="$RANDOM"
#    tst::MissingArgument                                                       #? $_bashlyk_iErrorMissingArgument
#    tst::MissingArgument $a                                                    #? $_bashlyk_iErrorMissingArgument
#    $(tst::MissingArgument $a || exit 123)                                     #? 123
#    $(tst::MissingArgument $b && exit 123)                                     #? 123
#    tst::MissingArgument $b                                                    #? true
#  SOURCE
tst::MissingArgument() {

  [[ $* ]] || return $_bashlyk_iErrorMissingArgument

}
#******
tst::EmptyOrMissingArgument() { tst::MissingArgument $*; }
tst::EmptyArgument()          { tst::MissingArgument $*; }
#****p* libtst/tst::EmptyResult
#  SYNOPSIS
#    tst::EmptyResult <argument>
#  DESCRIPTION
#    return true if argument is not empty
#    designed to check the conditions in the function tst::postfix
#  NOTES
#    private method
#  INPUTS
#    <argument> - one argument
#  RETURN VALUE
#    EmptyResult - argument is empty
#    0           - non empty argument
#  EXAMPLE
#    local a b="$RANDOM"
#    tst::EmptyResult                                                           #? $_bashlyk_iErrorEmptyResult
#    tst::EmptyResult $a                                                        #? $_bashlyk_iErrorEmptyResult
#    $(tst::EmptyResult $a || exit 123)                                         #? 123
#    $(tst::EmptyResult $b && exit 123)                                         #? 123
#    tst::EmptyResult $b                                                        #? true
#  SOURCE
tst::EmptyResult() {

  [[ $* ]] || return $_bashlyk_iErrorEmptyResult

}
#******
#****p* libtst/tst::postfix
#  SYNOPSIS
#    tst::postfix <action> on <state> <argument>
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
#    ## TODO improve tests
#    local fn1 fn2
#    std::temp fn1
#    std::temp fn2
#    tst::postfix warn on NoSuchFileOrDir /err.handler                          #? true
#    errorify+echo on CommandNotFound notexist.return                           #? $_bashlyk_iErrorCommandNotFound
#    warn on NoSuchFileOrDir /notexist.warn                                     #? true
#    $(throw on NoSuchFileOrDir "$fn1" "$fn2")                                  #? true
#    errorify on NoSuchFileOrDir "/notexist.echo" "/notexist.warn"              #? $_bashlyk_iErrorNoSuchFileOrDir
#    $(throw on NoSuchFileOrDir "/notexist.throw.child")                        #? $_bashlyk_iErrorNoSuchFileOrDir
#    $(exit+echo on CommandNotFound notexist.exit+echo.child)                   #? $_bashlyk_iErrorCommandNotFound
#    $(errorify on CommandNotFound notexist.errorify.child || return)           #? $_bashlyk_iErrorCommandNotFound
#    warn on CommandNotFound notexist nomoreexist                               #? true
#  SOURCE
tst::postfix() {

  local -a aErrHandler=( $* )
  local re='^(echo|warn)$|^((echo|warn)[+])?(exit|return)$|^throw$' i=0 j=0 s
  ## TODO add reAction and reState for safely arguments parsing

  [[ $1 =~ $re ]] && shift || error InvalidArgument action=throw "${1:-first argument}"
  [[ $1 == on  ]] && shift || error InvalidArgument action=throw "${1:-second argument}"
  [[ $1        ]] && shift || error MissingArgument action=throw "${1:-third argument}"

  if ! declare -pf tst::${aErrHandler[2]} >/dev/null 2>&1; then

    error InvalidArgument action=throw "${aErrHandler[2]}"

  fi

  [[ $* ]] || error ${aErrHandler[2]} action=${aErrHandler[0]} ${aErrHandler[@]:3}

  for s in "$@"; do

    : $(( j++ ))

    if ! tst::${aErrHandler[2]} $s; then

      [[ $s ]] || s=$j

      (( i++ == 0 )) && aErrHandler[3]=$s || aErrHandler[3]+=", $s"

    fi

  done

  if (( i > 0 )); then

    (( i > 1 )) && aErrHandler[3]+=" [total $i]"
    error ${aErrHandler[2]} action=${aErrHandler[0]} ${aErrHandler[3]}

  fi

}
#******
#****p* libtst/tst::__add_throw_to_command
#  SYNOPSIS
#    tst::__add_throw_to_command <command line>
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
#    local s='command --with -a -- arguments' cmd='tst::__add_throw_to_command'
#    $cmd $s | {{{
#    _bashlyk_sLastError[$BASHPID]="command: $(std::trim command --with -a -- arguments)\n output: {\n$(command --with -a -- arguments 2>&1)\n}" && echo -n . || return $?;
# }}}
#  SOURCE
tst::__add_throw_to_command() {

  local s

  s='_bashlyk_sLastError[$BASHPID]="command: $(std::trim '${*/;/}')\n output: '
  s+='{\n$('${*/;/}' 2>&1)\n}" && echo -n . || return $?;'

  echo $s

}
#******
#****p* libtst/tst::__convert_try_to_func
#  SYNOPSIS
#    tst::__convert_try_to_func
#  DESCRIPTION
#    convert "try" block to the function with controlled traps of the errors
#  OUTPUT
#    function definition for evaluate
#  NOTES
#    private method, used for 'try ..catch' emulation
#  TODO
#    error handling for input 'try' function checking not worked
#  EXAMPLE
#    tst::__convert_try_to_func | {{"^${TMPDIR}/.*ok.*fail.*; false; }$"}}
#  SOURCE
tst::__convert_try_to_func() {

  local s
  std::temp -v s

  while read -t 4; do

    if [[ ! $REPLY =~ ^[[:space:]]*(try \(\)|\{|\})[[:space:]]*$ ]]; then

      tst::__add_throw_to_command $REPLY

    else

      #echo "${REPLY/try/try${s//\//.}}"
      echo "${REPLY/try/$s}"

    fi

  done< <( declare -pf try 2>/dev/null)

  echo $s' && echo " ok." || { tst::status $?; echo " fail..($?)"; false; }'
  rm -f $s

}
#******
#****e* libtst/tst::exception.message
#  SYNOPSIS
#    tst::exception.message
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
#   tst::exception.message                                                      #? $_bashlyk_iErrorMissingArgument
#   _bashlyk_iLastError[$BASHPID]='not number'
#   tst::exception.message                                                      #? $_bashlyk_iErrorNotNumber
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
#     tst::exception.message                                                    #-
#                                                                               #-
#   }                                                                           #-
#   EOFtry                                                                      #-
#   . $fn | {{{
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
tst::exception.message() {

  local msg=${_bashlyk_sLastError[$BASHPID]} rc=${_bashlyk_iLastError[$BASHPID]}

  std::isNumber $rc || return

  printf -- "\ntry block exception:\n~~~~~~~~~~~~~~~~~~~~\n status: %s\n" "$rc"

  [[ $msg ]] && printf -- "${msg}\n"

  return $rc

}
#******
#****f* libtst/tst::debug
#  SYNOPSIS
#    tst::debug <level> <message>
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
#    tst::debug                                                                 #? $_bashlyk_iErrorMissingArgument
#    tst::debug 0 echo level 0                                                  #? true
#    tst::debug 1 silence level 0                                               #? 1
#    DEBUGLEVEL=5
#    tst::debug 0 echo level 5                                                  #? true
#    tst::debug 6 echo 5                                                        #? 1
#    tst::debug default level test '(0)'                                        #? true
#  SOURCE
tst::debug() {

  errorify on MissingArgument $* || return

  if [[ $1 =~ ^[0-9]+$ ]]; then

    (( ${DEBUGLEVEL:=0} >= $1 )) && shift || return 1

  fi

  [[ $* ]] && echo "$*" >&2

  return 0

}
#******
