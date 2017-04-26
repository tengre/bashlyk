#
# $Id: libtst.sh 751 2017-04-26 15:36:58+04:00 toor $
#
#****h* BASHLYK/libtst
#  DESCRIPTION
#    template for testing
#  USES
#    libstd
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libtst/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBTST provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBTST" ] && return 0 || _BASHLYK_LIBTST=1
[ -n "$_BASHLYK" ] || . bashlyk || eval '                                      \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* libtst/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libini.sh ]] && . "${_bashlyk_pathLib}/libini.sh"
#******
#****v* libtst/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}

## TODO check __global.vars for exists
#__global.vars cli.arguments cli.shortname error.action msg.email.subject

declare -rg _bashlyk_externals_tst=""
declare -rg _bashlyk_exports_tst="udfTest"
#******
shopt -s expand_aliases
alias on='eval $( err::eval )'
alias ECHO='err::handler echo'
alias EXIT='err::handler exit'
alias warn='err::handler warn'
alias throw='err::handler throw'
alias RETURN='err::handler return'
alias echo+exit='err::handler echo+exit'
alias warn+exit='err::handler warn+exit'
alias echo+return='err::handler echo+return'
alias warn+return='err::handler warn+return'
#****f* libtst/udfTest
#  SYNOPSIS
#    udfTest args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    udfTest                                                                    #? $_bashlyk_iErrorMissingArgument
#    udfTest test                                                               #? true
#  SOURCE
udfTest() {

  udfOn MissingArgument $1 || return

  return 0

}
#******
#****f* libtst/__interface
#  SYNOPSIS
#    __interface [_,+=] [args]
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    __interface = input                                                        #? true
#    __interface + more input data                                              #? true
#    __interface ,  comma separate input data                                   #? true
#    __interface                                                                #? true
#    __interface _                                                              #? true
#    __interface                                                                #? true
#  SOURCE
__interface() {

  local o s

  case $1 in
    =) s='="${*/=/}"';;
    +) s='+=" ${*/+/}"';;
    ,) s='+=",${*/+/}"';;
    _) s='=""';;
  esac

  o="_${FUNCNAME[0]//./_}${s}"
  [[ $s ]] && eval "shift; declare -g ${o}" || echo "${!o}"

}
#******
#****f* libtst/__private
#  SYNOPSIS
#    __private
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#  __private cli.arguments cli.shortname error.action msg.email.subject         #? true
#  bashlyk.cli.arguments = test                                                 #? true
#  _bashlyk_cli_shortname=shortname                                             #? true
#  bashlyk.cli.shortname                                                        #? true
#  bashlyk.error.action = action                                                #? true
#  bashlyk.msg.email.subject = subject                                          #? true
#  bashlyk.cli.arguments                                                        #? true
#  bashlyk.error.action                                                         #? true
#  bashlyk.msg.email.subject                                                    #? true
#  SOURCE
__private() {

  __() {

    local o=_${FUNCNAME[0]//./_}

    case $1 in

      =) eval 'shift; declare -g $o="${*/=/}"';;
      +) eval 'shift; declare -g $o+=" ${*/+/}"';;
      ,) eval 'shift; declare -g $o+=",${*/+/}"';;
      _) eval 'shift; declare -g $o=""';;
     '') echo "${!o}";;

    esac

  }

  local f=$(declare -pf __) s

  for s in $*; do

    eval "${f/__/bashlyk.$s}"

  done

}
#******
#****f* liberr/err::status::show
#  SYNOPSIS
#    err::status::show [<pid>]
#  DESCRIPTION
#    Show last saved error state for process with <pid> or $BASHPID default
#  INPUTS
#    <pid> - select process, default current bash subshell $BASHPID
#  ERRORS
#    Unknown         - first argument is non valid
#    1-254           - valid value of first argument
#  EXAMPLE
#    local pid=$BASHPID
#    err::status iErrorInvalidVariable "12Invalid"                              #? $_bashlyk_iErrorInvalidVariable
#    err::status::show                                                          #? $_bashlyk_iErrorInvalidVariable
#    err::status::show invalid argument                                         #? $_bashlyk_iErrorInvalidVariable
#    err::status::show $$                                                       #? $_bashlyk_iErrorInvalidVariable
#  SOURCE
err::status::show() {

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
#****f* liberr/err::status
#  SYNOPSIS
#    err::status <number> <string>
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

      err::status::show $BASHPID

    elif [[ ${_bashlyk_iLastError[$$]} ]]; then

      err::status::show $$

    fi

    return

  fi

  if [[ $1 =~ ^[0-9]+$ ]]; then

    i=$1

  else

    eval "i=\$_bashlyk_iError${1}"
    [[ $i ]] || eval "i=\$_bashlyk_${1}"

  fi

  [[ $i =~ ^[0-9]+$ ]] && (( $i < 255 )) && shift || i=$_bashlyk_iErrorUnknown

  _bashlyk_iLastError[$BASHPID]=$i
  [[ $* ]] && _bashlyk_sLastError[$BASHPID]="$*"

  return $i

}
#******
#****f* liberr/err::stacktrace
#  SYNOPSIS
#    err::stacktrace
#  DESCRIPTION
#    OUTPUT BASH Stack Trace
#  OUTPUT
#    BASH Stack Trace
#  EXAMPLE
#    err::stacktrace
#  SOURCE
err::stacktrace() {

  #local i s=$( printf -- '|' )
  local i s=$( printf -- '\u00a0' )

  printf -- '\nStack trace by %s from %s:\n+-->>-----\n'                       \
            "${FUNCNAME[0]}" "${BASH_SOURCE[0]}"

  for (( i=${#FUNCNAME[@]}-1; i >= 0; i-- )); do

    (( ${BASH_LINENO[i]} == 0 )) && continue

    printf -- '%s%d: call %s:%s %s ..\n%s%d: code %s\n'                        \
              "$s" "$i"                                                        \
              "${BASH_SOURCE[$i+1]}" "${BASH_LINENO[$i]}" "${FUNCNAME[$i]}"    \
              "$s" "$i"                                                        \
              "$( sed -n "${BASH_LINENO[$i]}p" ${BASH_SOURCE[$i+1]} )"

    s+=" "

  done

  printf -- '+-->>-----\n'

}
#******
#****f* liberr/err::eval
#  SYNOPSIS
#    err::eval [<action>] [<state>] [<message>]
#  DESCRIPTION
#    Flexible error handling. Processing is controlled by global variables or
#    arguments, and consists in a warning message, the function returns, or the
#    end of the script with a certain return code. Messages may include a stack
#    trace and printed to stderr
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
#  SOURCE
err::eval() {

  local rc=$? re rs sAction=$_bashlyk_onError sMessage='' s IFS=$' \t\n'
  re='^(echo|warn)$|^((echo|warn)[+])?(exit|return)$|^throw$'

  s="$( sed -n "${BASH_LINENO[0]}p" ${BASH_SOURCE[1]} )"

  s="${s##*on error }"; s="${s%%>*}"

  eval set -- "$s"

  [[ ${1,,} =~ $re ]] && sAction=${1,,} && shift

  err::status $1; rs=$?

  if [[ $rs == $_bashlyk_iErrorUnknown ]]; then

    s="(bad error code applied, i try to use the previous..): "

    if [[ ${_bashlyk_hError[$rc]} ]]; then

      rs=$rc
      s+="${_bashlyk_hError[$rc]} - $* .. ($rc)"

    else

      s+="$* .. ($rc)"

    fi

  else

    shift

    if [[ ${_bashlyk_hError[$rs]} ]]; then

      s="${_bashlyk_hError[$rs]} - $* .. ($rs)"

    else

      s="$* .. ($rs)"

    fi

  fi

  s=${s//\(/\\\(}
  s=${s//\)/\\\)}
  s=${s//\;/\\\;}

  if [[ "${FUNCNAME[1]}" == "main" || -z "${FUNCNAME[1]}" ]]; then

    [[ $sAction =~ ^((echo|warn)\+)?return$ ]] && sAction="${sAction/return/exit}"

  fi

  case "${sAction,,}" in

           echo) sAction=': ';        sMessage="echo  Warn: ";;
    echo+return) sAction='return $?'; sMessage="echo Error: ";;
      echo+exit) sAction='exit $?';   sMessage="echo Error: ";;
           warn) sAction=': ';        sMessage="udfWarn  Warn: ";;
    warn+return) sAction='return $?'; sMessage="udfWarn Error: ";;
      warn+exit) sAction='exit $?';   sMessage="udfWarn Error: ";;
    exit|return) sAction="${sAction,,} \$?"; sMessage=": ";;
              *)
                 sAction='exit $?'
                 sMessage='udfStackTrace | udfWarn - Error: '
          ;;

  esac

  printf -- '%s >&2; err::status %s %s; %s; : ' "${sMessage}${s}" "$rs" "$*" "$sAction"

}
#******
#****f* liberr/err::CommandNotFound
#  SYNOPSIS
#    err::CommandNotFound <filename>
#  DESCRIPTION
#    return true if argument is not empty, exists and executable (## TODO test)
#    designed to check the conditions in the function err::handler
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
#****f* liberr/err::NoSuchFileOrDir
#  SYNOPSIS
#    err::NoSuchFileOrDir <filename>
#  DESCRIPTION
#    return true if argument is non empty, exists, designed to check the
#    conditions in the function err::handler
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
#****f* liberr/err::InvalidVariable
#  SYNOPSIS
#    err::InvalidVariable <variable>
#  DESCRIPTION
#    return true if argument is non empty, valid variable, designed to check the
#    conditions in the function err::handler
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

  [[ $* ]] && udfIsValidVariable "$*" || return $_bashlyk_iErrorInvalidVariable

}
#******
#****f* liberr/err::EmptyVariable
#  SYNOPSIS
#    err::EmptyVariable <variable>
#  DESCRIPTION
#    return true if argument is non empty, valid variable
#    designed to check the conditions in the function err::handler
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

  [[ $1 ]] && udfIsValidVariable "$1" && [[ ${!1} ]] || return $_bashlyk_iErrorEmptyVariable

}
#******
#****f* liberr/err::MissingArgument
#  SYNOPSIS
#    err::MissingArgument <argument>
#  DESCRIPTION
#    return true if argument is not empty
#    designed to check the conditions in the function err::handler
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
#****f* liberr/err::EmptyResult
#  SYNOPSIS
#    err::EmptyResult <argument>
#  DESCRIPTION
#    return true if argument is not empty
#    designed to check the conditions in the function err::handler
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
#****f* liberr/err::handler
#  SYNOPSIS
#    err::handler <action> on <state> <argument>
#  DESCRIPTION
#    Flexible error handling. Processing is controlled by global variables or
#    arguments, and consists in a warning message, the function returns, or the
#    end of the script with a certain return code. Messages may include a stack
#    trace and printed to stderr
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
#    err::handler warn on NoSuchFileOrDir /notexist                             #? true
#    warn on NoSuchFileOrDir /notexist                                          #? true
#    ECHO on NoSuchFileOrDir /notexist                                          #? true
#    $(throw on NoSuchFileOrDir /notexist)                                      #? $_bashlyk_iErrorNoSuchFileOrDir
#    $(EXIT on CommandNotFound notexist)                                        #? $_bashlyk_iErrorCommandNotFound
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
shopt -s expand_aliases
alias try="try()"
alias catch='; eval "$( err::__convert_try_to_func )" ||'
#****f* liberr/err::__add_throw_to_command
#  SYNOPSIS
#    err::__add_throw_to_command <command line>
#  DESCRIPTION
#    add controlled trap for errors of the <commandline>
#  INPUTS
#    <commandline> - source command line
#  OUTPUT
#    changed command line
#  NOTES
#    private method, used for 'try ..catch' emulation
#  EXAMPLE
#    local s='command --with -a -- arguments' cmd='err::__add_throw_to_command'
#    $cmd $s             >| md5sum | grep ^856f03be5778a30bb61dcd1e2e3fdcde.*-$ #? true
#  SOURCE
err::__add_throw_to_command() {

  local s

   s='_bashlyk_sLastError[$BASHPID]="command: $( udfTrim '${*/;/}' )\n output: '
  s+='{\n$('${*/;/}' 2>&1)\n}" && echo -n . || return $?;'

  echo $s

}
#******
#****f* liberr/err::__convert_try_to_func
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
  udfMakeTemp -v s

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
#****f* liberr/err::exception::message
#  SYNOPSIS
#    err::exception::message
#  DESCRIPTION
#    show last error status
#  INPUTS
#    used global variables $_bashlyk_{i,s}LastError
#  OUTPUT
#    try show commandline, status(error code) and output
#  ERRORS
#    MissingArgument - _bashlyk_iLastError[$BASHPID] empty
#    NotNumber       - _bashlyk_iLastError[$BASHPID] is not number
#  EXAMPLE
#   _bashlyk_iLastError[$BASHPID]=''
#   err::exception::message                                                     #? $_bashlyk_iErrorMissingArgument
#   _bashlyk_iLastError[$BASHPID]='not number'
#   err::exception::message                                                     #? $_bashlyk_iErrorNotNumber
#   local s fn                                                                  #-
#   error4test() { echo "${0##*/}: special error for testing"; return 210; };   #-
#   udfMakeTemp fn                                                              #-
#   cat <<-'EOFtry' > $fn                                                       #-
#   try {                                                                       #-
#     uname -a                                                                  #-
#     date -R                                                                   #-
#     uname                                                                     #-
#     error4test                                                                #-
#     true                                                                      #-
#   } catch {                                                                   #-
#                                                                               #-
#     err::exception::message                                                   #-
#                                                                               #-
#   }                                                                           #-
#   EOFtry                                                                      #-
#  . $fn                  >| md5sum -| grep ^65128961dfcf8819e88831025ad5f1.*-$ #? true
#  SOURCE
err::exception::message() {

  local msg=${_bashlyk_sLastError[$BASHPID]} rc=${_bashlyk_iLastError[$BASHPID]}

  udfIsNumber $rc || return

  printf -- "\ntry block exception:\n~~~~~~~~~~~~~~~~~~~~\n status: %s\n" "$rc"

  [[ $msg ]] && printf -- "${msg}\n"

  return $rc

}
#******

