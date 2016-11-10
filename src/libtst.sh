#
# $Id: libtst.sh 580 2016-11-10 17:23:57+04:00 toor $
#
#****h* BASHLYK/libtst
#  DESCRIPTION
#    template for testing
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libtst/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'

[[ -n "$_BASHLYK_LIBTST" ]] && return 0 || _BASHLYK_LIBTST=1
#******
#****** libtst/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
#******
#****v* libtst/Init section
#  DESCRIPTION
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_envXSession:=}
: ${_bashlyk_aRequiredCmd_msg:="[ "}
: ${_bashlyk_aExport_msg:="udfTest udfRead"}
declare -A ini_h
declare -A ini_hClass
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
#****f* libtst/udfRead
#  SYNOPSIS
#    ini.read args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#   local ini s=""                                                              #-
#   udfMakeTemp ini                                                             #-
#    cat <<'EOFini' > ${ini}                                                    #-
#    void	=	1                                                       #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt	=	$(date -R)                                              #-
#    b		=	false                                                   #-
#    iXo Xo	=	19                                                      #-
#    iYo	=	80                                                      #-
#    `simple line`                                                              #-
#[replace]                                                                      #-
#    before replacing                                                           #-
#[unify]                                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#[acc]                                                                          #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#                                                                               #-
#    EOFini                                                                     #-
#   ini_hClass["__void__"]=""
#   ini_hClass["exec"]="!"
#   ini_hClass["main"]=""
#   ini_hClass["replace"]="-"
#   ini_hClass["unify"]="="
#   ini_hClass["acc"]="+"
#   cat $ini
#   udfRead $ini ini_h ini_hClass                                               #? true
#  SOURCE
udfRead() {

#	return undef unless @_ == 3
#						&& defined( $_[0] )
#						&& udfIsFD( $_[0] )
#						#&& defined( $_[1] )
#						#&&     ref( $_[1] ) eq 'HASH'
#						&& defined( $_[2] )
#						&&     ref( $_[2] ) eq 'HASH';
#
	#udfOn NoSuchFileOrDir $1 || return $?
	udfOn NoSuchFileOrDir throw $1
	typeset -A $2 || eval $( udfOnError throw InvalidArgument "$2 must be hash" )
	typeset -A $3 || eval $( udfOnError throw InvalidArgument "$3 must be hash" )
	#udfOn MissingArgument $3 || return $?

	#my ( $fh, $p, $phC ) = @_;
	#my ( $i, $s, $ph, %h, @a ) = ( 0, "", {}, (), () );
	#my $sKeyLast = undef;

	local -a a
	local -A h
	local bA chClass fn i p ph s sKeyLast sNewSection
	#
	i=0
	## TODO - check unnamed section
	s="__void__"
	#
	fn=$1
	#chClass=$3
#	seek($fh, 0, 0) or die "$!\n" unless $fh eq 'DATA';

	##$ph = ( $p->{$s} && $phC->{$s} && $phC->{$s} =~ /^[^!\-]/ ) ? $p->{$s} : {};
	##push( @a, $s);

	a[0]=$s

	#while (<$fh>) {
	while read -t 4; do

		#if ( m/^\s*:?\[\s*(.+?)\s*\]:?\s*$/ ) {
		if [[ $REPLY =~ ^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$ ]]; then

			## TODO h[section.key]=value ?
			#my $sNewSection = $1;

			sNewSection=${BASH_REMATCH[2]}

			#$ph->{__class_active}++ if m/^\s*:\[\s*(.+?)\s*\]\s*$/;
			[[ ${BASH_REMATCH[1]} == ":" ]] && h[${s}".__class_active"]=1

			##$h{$s} = $ph if scalar keys %{$ph};
			[[ "${!h[@]}" =~ ${s}\..* ]] && bOk=1

			s=$sNewSection;
			i=0
			##$ph = ( $p->{$s} && $phC->{$s} && $phC->{$s} =~ /^[^!\-]/ ) ? $p->{$s} : {};

			#$ph->{__class_active}++ if m/^\s*\[\s*(.+?)\s*\]:\s*$/;
			[[ ${BASH_REMATCH[3]} == ":" ]] && h[${s}".__class_active"]=2

			#push( @a, $s );
			a[${#a[@]}]="$s"
			#$sKeyLast = undef;
			sKeyLast=""

#		} else {
		else

			#s/(^|\s+)[#;].*$//g if ( ! $phC->{$s} || $phC->{$s} ne '!' );
			#chomp();
			#next unless length;

			[[ $REPLY =~ (^|[[:space:]]+)[\#\;].*$ && ! ${ini_hClass[$s]} =~ ^\!$ ]] && continue

			#if (
			#	     ! $ph->{__class_active}
			#	&& ( ! $phC->{$s} || $phC->{$s} !~ /[=!\-\+]/ )
			#	&& /^\s*(\S+)\s*=\s*(.*)\s*$/
			#) {
			## TODO line with multi '='
			## TODO key with spaces...
			## TODO active sections...
			if [[ ! ${h[${s}".__class_active"]} =~ ^(1|2)$ && ! ${ini_hClass[$s]} =~ ^[=\!\-\+]$ && $REPLY =~ ^[[:space:]]*([[:print:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$ ]]; then

				#$ph->{$1} = $2;
				#$sKeyLast = $1;
				sKeyLast=${BASH_REMATCH[1]}
				h[${s}.${sKeyLast}]=${BASH_REMATCH[2]}

			#} else {
			else

#				if (
#					     $sKeyLast
#					&& ! $ph->{__class_active}
#					&& ( ! $phC->{$s} || $phC->{$s} !~ /[=!\-\+]/ )
#				) {
#					$ph->{$sKeyLast} .= "\n$_" ;
#				}

				if [[ -n "$sKeyLast" && ! ${h[${s}".__class_active"]} =~ ^(1|2)$ && ! ${ini_hClass[$s]} =~ ^[=!\-\+]$ ]]; then

					h[${s}.${sKeyLast}]+="\n${REPLY}"

				fi

#				if ( ! $phC->{$s} || $phC->{$s} =~ /^=$/ ) {
#					s/^\s+//;
#					s/\s+$//;
#				}

				if [[ ! $chClass =~ ^=$ ]]; then

					REPLY=${REPLY##*( )}
					REPLY=${REPLY%%*( )}
				fi

				#$ph->{"__unnamed_idx_".$ph->{__unnamed_items}++} = $_;
				: $(( i++ ))
				h[${s}".__unnamed_idx_"${i}]=$REPLY

			fi
		fi
	done < $fn

	#$h{$s} = $ph if scalar keys %{$ph};

#	foreach $s ( keys %{$p} ) {
#
#		next if grep { $_ eq $s } @a;
#
#		$h{$s} = $p->{$s};
#
#	}
#
#	for s in ${!h[@]}; do
#
#		[[ ${a[@]} =~ ^${s%%.*}$ ]] && continue
#
#		$h{$s} = $p->{$s};
#
#	done

	#return \%h;
	echo "dbg keys ${!h[@]} : ${#h[@]}"
	echo "---"
	echo "dbg vals ${h[@]}  : ${#h[@]}"
	for s in ${!h[@]}; do

		echo "pair: $s = ${h[$s]}"

	done
}
#******
