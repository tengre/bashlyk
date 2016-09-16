#
# $Id: libnet.sh 550 2016-09-16 16:10:46+04:00 toor $
#
#****h* BASHLYK/libnet
#  DESCRIPTION
#    network tools
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libnet/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'

[[ -n "$_BASHLYK_LIBTST" ]] && return 0 || _BASHLYK_LIBTST=1
#******
#****** libnet/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
#******
_reIPv4='[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
_peIPv4='\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
#****v* libnet/Init section
#  DESCRIPTION
: ${_bashlyk_aRequiredCmd_msg:="dig echo grep ipcalc sipcalc xargs"}
: ${_bashlyk_aExport_msg:="udfGetValidIPsOnly udfGetValidCIDR"}
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
#  RETURN VALUE
#    MissingArgument - no arguments
#    EmptyResult     - no result
#    0               - found valid IPv4 addresses
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
		sDig=$( dig +short $s | xargs )
		[[ -n "$sDig" ]] && s="$sDig"
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
#  RETURN VALUE
#    MissingArgument - no arguments
#    EmptyResult     - no result
#    0               - found valid IPv4 CIDR
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

	[[ -n "$s" ]] && h[$s]="$s"

	done

	echo "${h[@]}"

	udfOn EmptyResult return "${h[@]}"

}
#******
