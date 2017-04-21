#
# $Id: libtst.sh 742 2017-04-21 16:20:01+04:00 toor $
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
#****f* liberr/err::action
#  SYNOPSIS
#    err::action [<action>] [<state>] [<message>]
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
#    err::action <<< "retecho InvalidArgument message error"
#    echo "$LINENO :: $COMP_LINE"
#    declare -pa BASH_LINENO
#    onError retecho InvalidArgument message error
#  SOURCE
shopt -s expand_aliases
alias onError='err::action <<< "$(sed -n "${BASH_LINENO[1]}p" ${BASH_SOURCE[1]})"'

err::action() {

  local re rs=$? sAction=$_bashlyk_onError sMessage='' s IFS=$' \t\n'
  re='^(echo|exit|exitecho|exitwarn|retecho|retwarn|return|warn|throw)$'

  read -t 1
  echo "dbg $REPLY" >> /tmp/tst.log
  eval set -- "$REPLY"

  [[ ${1,,} =~ $re ]] && sAction=${1,,} && shift

  udfSetLastError $1; s=$?

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
  rs=${rs//\;/\\\;}

  if [[ "${FUNCNAME[1]}" == "main" || -z "${FUNCNAME[1]}" ]]; then

    [[ "$sAction" == "retecho" ]] && sAction='exitecho'
    [[ "$sAction" == "retwarn" ]] && sAction='exitwarn'
    [[ "$sAction" == "return"  ]] && sAction='exitecho'

  fi

  case "${sAction,,}" in

           echo) sAction=': ';        sMessage="udfLog  Warn: ";;
        retecho) sAction='return $?'; sMessage="udfLog Error: ";;
       exitecho) sAction='exit $?';   sMessage="udfLog Error: ";;
           warn) sAction=':';         sMessage="udfWarn  Warn: ";;
        retwarn) sAction='return $?'; sMessage="udfWarn Error: ";;
       exitwarn) sAction='exit $?';   sMessage="udfWarn Error: ";;
    exit|return) sAction="$sAction \$?"; sMessage=": ";;
              *)
                 sAction='exit $?'
                 sMessage='udfStackTrace | udfWarn - Error: '
          ;;

  esac

  printf -- '%s >&2; udfSetLastError %s %s; %s\n' "${sMessage}${rs}" "$s" "$rs" "$sAction"

}
#******
