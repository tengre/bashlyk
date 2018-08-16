#
# $Id: libtst.sh 849 2018-08-09 01:47:33+04:00 yds $
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
#****G* libtst/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
declare -rg _bashlyk_aRequiredCmd_tst=""
declare -rg _bashlyk_methods_tst=""
declare -rg _bashlyk_aExport_tst=""
#******
