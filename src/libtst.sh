#
# $Id: libtst.sh 744 2017-04-24 21:34:07+04:00 toor $
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

  #local -a a
  local rc=$? re rs sAction=$_bashlyk_onError sMessage='' s IFS=$' \t\n'
  re='^(echo|exit|echo\+exit|warn\+exit|echo\+return|warn\+return|return|warn|throw)$'

  s="$( sed -n "${BASH_LINENO[0]}p" ${BASH_SOURCE[1]} )"

  s="${s##*on error }"; s="${s%%>*}"

  eval set -- "$s"

  [[ ${1,,} =~ $re ]] && sAction=${1,,} && shift

  udfSetLastError $1; rs=$?

  if [[ $rs == $_bashlyk_iErrorUnknown ]]; then

    s="(bad error code applied, i try to use the previous..): "

    if [[ ${_bashlyk_hError[$rc]} ]]; then

      rs=$rc
      s+="${_bashlyk_hError[$rc]}, detail: $* .. ($rc)"

    else

      s+="$* .. ($rc)"

    fi

  else

    shift

    if [[ ${_bashlyk_hError[$rs]} ]]; then

      s="${_bashlyk_hError[$rs]}, detail: $* .. ($rs)"

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

  printf -- '%s >&2; udfSetLastError %s %s; %s; : '                            \
            "${sMessage}${s}" "$rs" "$s" "$sAction"

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
#    warn on CommandNotFound notexist                                           #? true
#  SOURCE
err::handler() {

  local -a aErrHandler=( $* )
  local re='^(echo|warn)$|^((echo|warn)[+])?(exit|return)$|^throw$'
  ## TODO add reAction and reState for safely arguments parsing

  [[ $1 =~ $re ]] && shift || on error throw InvalidArgument "1 - $1"
  [[ $1 == on  ]] && shift || on error throw InvalidArgument "2 - $1"
  [[ $1        ]] && shift || on error throw MissingArgument "3 - $1"

  if ! declare -pf err::${aErrHandler[2]} >/dev/null 2>&1; then

    on error throw InvalidArgument "${aErrHandler[2]}"

  fi

  unset aErrHandler[1]

  ## TODO many arguments checking mode
  err::${aErrHandler[2]} $* || on error ${aErrHandler[@]}

}
#******
