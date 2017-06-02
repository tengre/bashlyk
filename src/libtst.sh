#
# $Id: libtst.sh 764 2017-05-11 17:28:10+04:00 toor $
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
declare -rg _bashlyk_exports_tst="tst::test"
#******
#****f* libtst/tst::test
#  SYNOPSIS
#    tst::test args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    tst::test                                                                    #? $_bashlyk_iErrorMissingArgument
#    tst::test test                                                               #? true
#  SOURCE
tst::test() {

  errorify on MissingArgument $1 || return

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

