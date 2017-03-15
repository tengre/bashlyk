#
# $Id: libnet.sh 709 2017-03-15 17:09:18+04:00 toor $
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
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****G* libnet/Global variables
#  DESCRIPTION
#    global variables of the library
#  SOURCE
: ${_bashlyk_sArg:="$@"}

declare -rg _bashlyk_net_reHost='^Host[[:space:]]address[[:space:]]+-[[:space:]]([0-9.]+)$'
declare -rg _bashlyk_net_reMask='^Network[[:space:]]mask[[:space:]]\(bits\)[[:space:]]+-[[:space:]]([0-9]+)$'
declare -rg _bashlyk_net_reRange='^Usable[[:space:]]range[[:space:]]+-[[:space:]]([0-9.]+)[[:space:]]-[[:space:]]([0-9.]+)$'
declare -rg _bashlyk_net_exports='net::ipv4.validate net::ipv4.cidr net::ipv4.range'
declare -rg _bashlyk_net_externals='sipcalc'
#******
#****f* libnet/net::ipv4.validate
#  SYNOPSIS
#    net::ipv4.validate args ...
#  DESCRIPTION
#    resolve arguments as IPv4 address and return only valid values list
#  INPUTS
#    args - IP addresses and domain names (if resolved)
#  OUTPUT
#    separated by white space list of valid IPv4 addresses
#  ERRORS
#    EmptyResult     - no result (or arguments)
#  EXAMPLE
#    net::ipv4.validate                                                         #? $_bashlyk_iErrorMissingArgument
#    net::ipv4.validate 999.8.7.6                                               #? $_bashlyk_iErrorEmptyResult
#    net::ipv4.validate 1.2.3.4                                                 #? true
#    net::ipv4.validate localhost                                               #? true
#    net::ipv4.validate localhost/32 >| grep '^127\.0\.0\.1$'                   #? true
#  SOURCE
net::ipv4.validate() {

  udfOn MissingArgument $* || return

  local -A h

  while read -t 32; do

    [[ $REPLY =~ $_bashlyk_net_reHost ]] && h[${BASH_REMATCH[1]}]='ok'

  done< <( sipcalc -d4 $* )

  echo "${!h[@]}"

  udfOn EmptyResult return "${!h[@]}"

}
#******
#****f* libnet/net::ipv4.cidr
#  SYNOPSIS
#    net::ipv4.cidr <arg> ...
#  DESCRIPTION
#    resolve arguments as IPv4 CIDR (address/mask) and return valid values list
#  INPUTS
#    <arg> - IPv4 CIDR or addresses (default mask bits 32)
#  OUTPUT
#    separated by white space list of valid IPv4 CIDR
#  ERRORS
#    MissingArgument - no arguments
#    EmptyResult     - no result
#  EXAMPLE
#    net::ipv4.cidr                                                             #? $_bashlyk_iErrorMissingArgument
#    net::ipv4.cidr 999.8.7.6                                                   #? $_bashlyk_iErrorEmptyResult
#    net::ipv4.cidr 999.8.7.6/23                                                #? $_bashlyk_iErrorEmptyResult
#    net::ipv4.cidr 1.2.3.4                          >| grep '^1\.2\.3\.4/32$'  #? true
#    net::ipv4.cidr 1.2.3.4/23                       >| grep '^1\.2\.3\.4/23$'  #? true
#    net::ipv4.cidr 1.2.3.4/43                                                  #? $_bashlyk_iErrorEmptyResult
#  SOURCE
net::ipv4.cidr() {

  udfOn MissingArgument $* || return

  local s
  local -A h

  while read -t 32; do

    if   [[ $REPLY =~ $_bashlyk_net_reHost ]]; then

      s=${BASH_REMATCH[1]}

    elif [[ $REPLY =~ $_bashlyk_net_reMask ]]; then

      [[ $s ]] && h["${s}/${BASH_REMATCH[1]}"]='ok'
      unset s

    else

      continue

    fi

  done< <( sipcalc -d4 $* )

  echo "${!h[@]}"

  udfOn EmptyResult return "${!h[@]}"

}
#******
#****f* libnet/net::ipv4.range
#  SYNOPSIS
#    net::ipv4.range <CIDR>
#  DESCRIPTION
#    resolve first argument (only!) as IPv4 CIDR (address/mask) and return list 
#    of the usable range of the IPv4 addresses from <CIDR>
#  INPUTS
#    <CIDR> - IPv4 CIDR or IPv4 address
#  OUTPUT
#    separated by white space list of the valid IPv4
#  ERRORS
#    MissingArgument - no arguments
#    EmptyResult     - no result
#  EXAMPLE
#    net::ipv4.range                                                            #? $_bashlyk_iErrorMissingArgument
#    net::ipv4.range 999.8.7.6                                                  #? $_bashlyk_iErrorEmptyResult
#    net::ipv4.range 999.8.7.6/33                                               #? $_bashlyk_iErrorEmptyResult
#    net::ipv4.range 1.2.3.4                                                    #? $_bashlyk_iErrorEmptyResult
#    net::ipv4.range 1.2.3.4/29              >| grep '^1\.2\.3\.1.*1\.2\.3\.6$' #? true
#    net::ipv4.range 1.2.3.4/43                                                 #? $_bashlyk_iErrorEmptyResult
#  SOURCE
net::ipv4.range() {

  udfOn MissingArgument $* || return

  local IFS i s 
  local -a aA aB
  local -A h

  while read -t 32; do

    if   [[ $REPLY =~ $_bashlyk_net_reRange ]]; then

      IFS='.'
      aA=( ${BASH_REMATCH[1]} )
      aB=( ${BASH_REMATCH[2]} )
      IFS=$' \t\n'

      break
      
    else

     continue

    fi

  done< <( sipcalc -d4 $* )

  for (( i = 0; i < ${#aA[@]}; i++ )); do

    if [[ ${aA[$i]} == ${aB[$i]} ]]; then
    
      s+="${aB[$i]} "
      
    else

      s+="{${aA[$i]}..${aB[$i]}} "

    fi

  done

  s="$( udfTrim "$s" )"
  eval "echo ${s// /.}"

  udfOn EmptyResult return "$s"

}
#******
shopt -s expand_aliases
alias udfGetValidIPsOnly="net::ipv4.validate"
alias udfGetValidCIDR="net::ipv4.cidr"
