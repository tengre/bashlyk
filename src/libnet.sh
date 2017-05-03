#
# $Id: libnet.sh 755 2017-05-03 16:40:47+04:00 toor $
#
#****h* BASHLYK/libnet
#  DESCRIPTION
#    interface to sipcalc command
#  USES
#    libstd
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libnet/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBNET provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBNET" ] && return 0 || _BASHLYK_LIBNET=1
[ -n "$_BASHLYK" ] || . bashlyk || eval '                                      \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* libnet/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****G* libnet/Global variables
#  DESCRIPTION
#    global variables of the library
#  SOURCE
declare -rg _bashlyk_net_reAddress='[[:space:]]address[[:space:]]+-[[:space:]]([0-9.]+)$'
declare -rg _bashlyk_net_reHost="^Host${_bashlyk_net_reAddress}"
declare -rg _bashlyk_net_reNetwork="^Network${_bashlyk_net_reAddress}"
declare -rg _bashlyk_net_reBroadcast="^Broadcast${_bashlyk_net_reAddress}"
declare -rg _bashlyk_net_reMask='^Network[[:space:]]mask[[:space:]]+-[[:space:]]([0-9.]+)$'
declare -rg _bashlyk_net_reMaskBit='^Network[[:space:]]mask[[:space:]]\(bits\)[[:space:]]+-[[:space:]]([0-9]+)$'
declare -rg _bashlyk_net_reRange='^Usable[[:space:]]range[[:space:]]+-[[:space:]]([0-9.]+)[[:space:]]-[[:space:]]([0-9.]+)$'
declare -rg _bashlyk_net_exports='net::ipv4.broadcast net::ipv4.cidr net::ipv4.host net::ipv4.mask net::ipv4.network net::ipv4.range'
declare -rg _bashlyk_net_externals='sipcalc'
#******
shopt -s expand_aliases
alias udfGetValidIPsOnly="net::ipv4.host"
alias udfGetValidCIDR="net::ipv4.cidr"
#****f* libnet/net::ipv4.host
#  SYNOPSIS
#    net::ipv4.host <arg> ...
#  DESCRIPTION
#    validate arguments as IPv4 address and return only valid values list
#  INPUTS
#    <arg> ... - every argument is a IP, DNS hostnames or CIDR -
#                (<IPv4>|<hostname>)[/<network mask bits>] - default mask /32
#  OUTPUT
#    separated by white space list of valid IPv4 host addresses
#  ERRORS
#    MissingArgument - no arguments
#    EmptyResult     - no result
#  EXAMPLE
#    net::ipv4.host                                                             #? $_bashlyk_iErrorMissingArgument
#    net::ipv4.host 999.8.7.6                                                   #? $_bashlyk_iErrorEmptyResult
#    net::ipv4.host 192.168.116.116             >| grep '^192\.168\.116\.116$'  #? true
#    net::ipv4.host localhost                                                   #? true
#    net::ipv4.host localhost/32                >| grep '^127\.0\.0\.1$'        #? true
#    udfGetValidIPsOnly localhost/32            >| grep '^127\.0\.0\.1$'        #? true
#  SOURCE
net::ipv4.host() {

  RETURN on MissingArgument $* || return

  local -A h

  while read -t 32; do

    [[ $REPLY =~ $_bashlyk_net_reHost ]] && h[${BASH_REMATCH[1]}]='ok'

  done< <( sipcalc -d4 $* )

  echo "${!h[@]}"

  RETURN on EmptyResult "${!h[@]}"

}
#******
#****f* libnet/net::ipv4.mask
#  SYNOPSIS
#    net::ipv4.mask <arg> ...
#  DESCRIPTION
#    get network mask for source arguments
#  INPUTS
#    <arg> ... - every arguments is a IP, DNS hostnames or CIDR -
#                (<IPv4>|<hostname>)[/<network mask bits>] - default mask /32
#  OUTPUT
#    separated by white space list of the network mask
#  ERRORS
#    MissingArgument - no arguments
#    EmptyResult     - no result
#  EXAMPLE
#    net::ipv4.mask                                                             #? $_bashlyk_iErrorMissingArgument
#    net::ipv4.mask 999.8.7.6                                                   #? $_bashlyk_iErrorEmptyResult
#    net::ipv4.mask 192.168.116.116/27          >| grep '^255\.255\.255\.224$'  #? true
#    net::ipv4.mask localhost                                                   #? true
#    net::ipv4.mask localhost/32                >| grep '^255\.255\.255\.255$'  #? true
#  SOURCE
net::ipv4.mask() {

  RETURN on MissingArgument $* || return

  local -A h

  while read -t 32; do

    [[ $REPLY =~ $_bashlyk_net_reMask ]] && h[${BASH_REMATCH[1]}]='ok'

  done< <( sipcalc -d4 $* )

  echo "${!h[@]}"

  RETURN on EmptyResult "${!h[@]}"

}
#******
#****f* libnet/net::ipv4.network
#  SYNOPSIS
#    net::ipv4.network <arg> ...
#  DESCRIPTION
#    try get IPv4 network addresses
#  INPUTS
#    <arg> ... - every words is a IP, DNS hostnames or CIDR -
#                (<IPv4>|<hostname>)[/<network mask bits>] - default mask /32
#  OUTPUT
#    separated by white space list of valid IPv4 network addresses
#  ERRORS
#    MissingArgument - no arguments
#    EmptyResult     - no result
#  EXAMPLE
#    net::ipv4.network                                                          #? $_bashlyk_iErrorMissingArgument
#    net::ipv4.network 999.8.7.6                                                #? $_bashlyk_iErrorEmptyResult
#    net::ipv4.network 192.168.116.116/27         >| grep '^192\.168\.116\.96$' #? true
#    net::ipv4.network localhost                                                #? true
#    net::ipv4.network localhost/32               >| grep '^127\.0\.0\.1$'      #? true
#  SOURCE
net::ipv4.network() {

  RETURN on MissingArgument $* || return

  local -A h

  while read -t 32; do

    [[ $REPLY =~ $_bashlyk_net_reNetwork ]] && h[${BASH_REMATCH[1]}]='ok'

  done< <( sipcalc -d4 $* )

  echo "${!h[@]}"

  RETURN on EmptyResult "${!h[@]}"

}
#******
#****f* libnet/net::ipv4.broadcast
#  SYNOPSIS
#    net::ipv4.broadcast <arg> ...
#  DESCRIPTION
#    try get IPv4 broadcast address
#  INPUTS
#    <arg> ... - every argument is a IP, DNS hostnames or CIDR -
#                (<IPv4>|<hostname>)[/<network mask bits>] - default mask /32
#  OUTPUT
#    separated by white space list of valid IPv4 broadcast addresses
#  ERRORS
#    EmptyResult - no result (or arguments)
#  EXAMPLE
#    net::ipv4.broadcast                                                        #? $_bashlyk_iErrorMissingArgument
#    net::ipv4.broadcast 999.8.7.6                                              #? $_bashlyk_iErrorEmptyResult
#    net::ipv4.broadcast 192.168.116.116/27      >| grep '^192\.168\.116\.127$' #? true
#    net::ipv4.broadcast localhost                                              #? true
#    net::ipv4.broadcast localhost/32            >| grep '^127\.0\.0\.1$'       #? true
#  SOURCE
net::ipv4.broadcast() {

  RETURN on MissingArgument $* || return

  local -A h

  while read -t 32; do

    [[ $REPLY =~ $_bashlyk_net_reBroadcast ]] && h[${BASH_REMATCH[1]}]='ok'

  done< <( sipcalc -d4 $* )

  echo "${!h[@]}"

  RETURN on EmptyResult "${!h[@]}"

}
#******
#****f* libnet/net::ipv4.cidr
#  SYNOPSIS
#    net::ipv4.cidr <arg> ...
#  DESCRIPTION
#    resolve arguments as IPv4 CIDR (address/mask) and return valid values list
#  INPUTS
#    <arg> ... - every argument is a IP, DNS hostnames or CIDR -
#                (<IPv4>|<hostname>)[/<network mask bits>] - default mask /32
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
#    udfGetValidCIDR 1.2.3.4/23                      >| grep '^1\.2\.3\.4/23$'  #? true
#    net::ipv4.cidr 1.2.3.4/43                                                  #? $_bashlyk_iErrorEmptyResult
#  SOURCE
net::ipv4.cidr() {

  RETURN on MissingArgument $* || return

  local s
  local -A h

  while read -t 32; do

    if   [[ $REPLY =~ $_bashlyk_net_reHost ]]; then

      s=${BASH_REMATCH[1]}

    elif [[ $REPLY =~ $_bashlyk_net_reMaskBit ]]; then

      [[ $s ]] && h["${s}/${BASH_REMATCH[1]}"]='ok'
      unset s

    else

      continue

    fi

  done< <( sipcalc -d4 $* )

  echo "${!h[@]}"

  RETURN on EmptyResult "${!h[@]}"

}
#******
#****f* libnet/net::ipv4.range
#  SYNOPSIS
#    net::ipv4.range (<IPv4>|<hostname>)[/<network mask bits>]
#  DESCRIPTION
#    resolve first valid argument (only!) as IPv4 CIDR (address/mask) and return
#    list of the usable range of the IPv4 addresses for network of source
#    argument
#  INPUTS
#    (<IPv4>|<hostname>)[/<network mask bits>] - IP, DNS hostnames or CIDR -
#                                                (default mask /32)
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
#    net::ipv4.range 192.168.116.116/27    >| grep '^192\.168\.116\.97.*\.126$' #? true
#    net::ipv4.range 1.2.3.4/43                                                 #? $_bashlyk_iErrorEmptyResult
#  SOURCE
net::ipv4.range() {

  RETURN on MissingArgument $* || return

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

  RETURN on EmptyResult "$s"

}
#******
