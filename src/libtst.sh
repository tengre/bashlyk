#
# $Id: libtst.sh 668 2017-01-26 23:36:40+04:00 toor $
#
#****h* BASHLYK/libtst
#  DESCRIPTION
#    template for testing
#  USES
#    libstd
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
#  $_BASHLYK_LIBTST provides protection against re-using of this module
[[ $_BASHLYK_LIBTST ]] && return 0 || _BASHLYK_LIBTST=1
#****L* libtst/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libini.sh ]] && . "${_bashlyk_pathLib}/libini.sh"
#******
#****v* libtst/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}

__globals="cli.arguments cli.shortname error.action msg.email.subject"

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

  udfOn MissingArgument $1 || return $?

  return 0

}
#******
#****f* libtst/cnf::get
#  SYNOPSIS
#    cnf::get args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
###    cnf::get                                                                   #? $_bashlyk_iErrorMissingArgument
#    cnf::get                                                                   #? true
#  SOURCE
cnf::get() {

  #udfOn MissingArgument $1 || return $?

  INI ini

  ini.read bashlyk.test.conf                                                #? true

  ini.show                                                                  #? true

  return 0

}
#******
#****f* libtst/bashlyk.global.variable
#  SYNOPSIS
#    bashlyk.global.variable [_+=] [args]
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    bashlyk.global.variable = input                                            #? true
#    bashlyk.global.variable + more input data                                  #? true
#    bashlyk.global.variable , comma separate input data                        #? true
#    bashlyk.global.variable                                                    #? true
#    bashlyk.global.variable _                                                  #? true
#    bashlyk.global.variable                                                    #? true
#  SOURCE
bashlyk.global.variable() {

  local o=_${FUNCNAME[0]//./_}

  case $1 in

     =) eval 'shift; declare -g $o="${*/=/}"';;
     +) eval 'shift; declare -g $o+=" ${*/+/}"';;
     ,) eval 'shift; declare -g $o+=",${*/+/}"';;
     _) eval 'shift; declare -g $o=""';;
    '') echo "${!o}";;

  esac

}
#******
#****f* libtst/__
#  SYNOPSIS
#    __
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#  __                                                                           #? true
#  bashlyk.cli.arguments = test                                                 #? true
#  _bashlyk_cli_shortname=shortname                                             #? true
#  bashlyk.cli.shortname                                                        #? true
#  bashlyk.error.action = action                                                #? true
#  bashlyk.msg.email.subject = subject                                          #? true
#  bashlyk.cli.arguments                                                        #? true
#  bashlyk.error.action                                                         #? true
#  bashlyk.msg.email.subject                                                    #? true
#  SOURCE
__() {

  local f=$(declare -pf bashlyk.global.variable) s

  for s in $__globals; do

    eval "${f/bashlyk.global.variable/bashlyk.$s}"

  done

}
#******
