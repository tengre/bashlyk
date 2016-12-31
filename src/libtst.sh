#
# $Id: libtst.sh 651 2016-12-31 15:05:29+04:00 toor $
#
#****h* BASHLYK/libtst
#  DESCRIPTION
#    template for testing
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
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
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

declare -r _bashlyk_externals_tst=""
declare -r _bashlyk_exports_tst="udfTest"
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
