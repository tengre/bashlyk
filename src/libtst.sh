#
# $Id: libtst.sh 637 2016-12-22 17:25:06+04:00 toor $
#
#****h* BASHLYK/libtst
#  DESCRIPTION
#    template for testing
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libtst/ Compatibility сheck
#  DESCRIPTION
#    - $BASH_VERSION    - no value is incompatible with the current shell
#    - $BASH_VERSION    - required Bash major version 4 or more for this script
#    - $_BASHLYK_LIBCNF - global variable provides protection against re-use of
#                         this module
#  SOURCE
[ -n "$BASH_VERSION" ] || eval 'echo "BASH interpreter for this script ($0) required ..."; exit 255'
(( ${BASH_VERSINFO[0]} >= 4 )) || eval 'echo "required BASH version 4 or more for this script ($0) ..."; exit 255'
[[ $_BASHLYK_LIBTST ]] && return 0 || _BASHLYK_LIBTST=1
#******
#****** libtst/ Loading external modules
# DESCRIPTION
#   read and execute required external modules
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
#******
#****v* libtst/ Global Variables - init section
#  DESCRIPTION
#    init of the required global variables
#  SOURCE
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_envXSession:=}
: ${_bashlyk_aRequiredCmd_tst:=""}
: ${_bashlyk_aExport_tst:="udfTest"}
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
#    udfTest #? true
#  SOURCE
udfTest() {
 return 0
}
#******
