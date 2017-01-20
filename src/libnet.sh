#
# $Id: libnet.sh 657 2017-01-20 15:00:51+04:00 toor $
#
#****h* BASHLYK/libnet
#  DESCRIPTION
#    network tools
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
#  $_BASHLYK_LIBNET provides protection against re-using of this module
[[ $_BASHLYK_LIBNET ]] && return 0 || _BASHLYK_LIBNET=1
#****L* libnet/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****G* libnet/Global variables
#  DESCRIPTION
#    global variables of the library
#  SOURCE
: ${_bashlyk_sArg:="$@"}
: ${_bashlyk_pathCnf:=$(pwd)}

declare -r _reIPv4='[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
declare -r _peIPv4='\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
declare -r _bashlyk_externals_net="dig echo grep ipcalc sipcalc xargs"
declare -r _bashlyk_exports_net="udfGetValidIPsOnly udfGetValidCIDR"
#******
#****f* libnet/udfGetValidIPsOnly
#  SYNOPSIS
#    udfGetValidIPsOnly args ...
#  DESCRIPTION
#    resolve arguments as IPv4 address and return only valid values list
#  INPUTS
#    args - IP addresses and domain names (if resolved)
#  OUTPUT
#    separated by white space list of valid IPv4 addresses
#  ERRORS
#    MissingArgument - no arguments
#    EmptyResult     - no result
#  EXAMPLE
#    udfGetValidIPsOnly                                                         #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfGetValidIPsOnly 999.8.7.6                                               #? $_bashlyk_iErrorEmptyResult
#    udfGetValidIPsOnly 1.2.3.4                                                 #? true
#    udfGetValidIPsOnly localhost                                               #? true
#    udfGetValidIPsOnly localhost >| grep '127\.0\.0\.1'                        #? true
#  SOURCE
udfGetValidIPsOnly() {

  udfOn MissingArgument "$*" || return $?

  local s sDig
  local -A h

  for s in $*; do

    [[ $s =~ ^[0-9.]+$ ]] && ipcalc "$s" | grep '^INVALID ADDRESS:' && continue

    sipcalc -d4 "$s" | grep '^-\[ERR :' && continue

    sDig=$( dig +short $s ) && s="$sDig"

    h[$s]=$s

  done >/dev/null 2>&1

  echo "${h[@]}"

  udfOn EmptyResult return "${h[@]}"

}
#******
#****f* libnet/udfGetValidCIDR
#  SYNOPSIS
#    udfGetValidCIDR args ...
#  DESCRIPTION
#    resolve arguments as IPv4 CIDR (address/mask) and return valid values list
#  INPUTS
#    args - IPv4 CIDR or addresses
#  OUTPUT
#    separated by white space list of valid IPv4 CIDR
#  ERRORS
#    MissingArgument - no arguments
#    EmptyResult     - no result
#  EXAMPLE
#    udfGetValidCIDR                                                            #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfGetValidCIDR 999.8.7.6                                                  #? $_bashlyk_iErrorEmptyResult
#    udfGetValidCIDR 999.8.7.6/32                                               #? $_bashlyk_iErrorEmptyResult
#    udfGetValidCIDR 999.8.7.6/33                                               #? $_bashlyk_iErrorEmptyResult
#    udfGetValidCIDR 1.2.3.4                                                    #? true
#    udfGetValidCIDR 1.2.3.4/23                                                 #? true
#    udfGetValidCIDR 1.2.3.4/43                                                 #? $_bashlyk_iErrorEmptyResult
#  SOURCE
udfGetValidCIDR() {

  udfThrowOnEmptyVariable _reIPv4
  udfOn MissingArgument "$*" || return $?

  local s i
  local -A h

  for s in $*; do

  [[ $s =~ $_reIPv4 ]] || continue

  i=${s##*/}

  if [[ $s == $i ]]; then

    s=$( udfGetValidIPsOnly $s ) || continue

  else

    udfIsNumber $i && (( i <= 32 )) || continue

    s=$( udfGetValidIPsOnly ${s%/*} ) || continue
    s="${s}/${i}"

  fi

  [[ $s ]] && h[$s]="$s"

  done

  echo "${h[@]}"

  udfOn EmptyResult return "${h[@]}"

}
#******
