#
# $Id: libtst.sh 578 2016-11-09 17:22:43+04:00 toor $
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
: ${_bashlyk_aExport_msg:="udfTest"}
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
declare -A ini_h
#****f* libtst/ini.read
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
#    udfTest #? true
#  SOURCE
ini.read() {

#	return undef unless @_ == 3
#						&& defined( $_[0] )
#						&& udfIsFD( $_[0] )
#						#&& defined( $_[1] )
#						#&&     ref( $_[1] ) eq 'HASH'
#						&& defined( $_[2] )
#						&&     ref( $_[2] ) eq 'HASH';
#
	udfOn MissingArgument $1 || return $?
	typeset -A $2 || eval $( udfOnError return InvalidArgument "$2 must be hash" )

	#my ( $fh, $p, $phC ) = @_;
	#my ( $i, $s, $ph, %h, @a ) = ( 0, "", {}, (), () );
	#my $sKeyLast = undef;

	local -a a
	local -A h
	local fh i p ph phC s sKeyLast
	#
	i=0
	s=""

#	seek($fh, 0, 0) or die "$!\n" unless $fh eq 'DATA';

	$ph = ( $p->{$s} && $phC->{$s} && $phC->{$s} =~ /^[^!\-]/ ) ? $p->{$s} : {};

	ph=

	push( @a, $s);

	while (<$fh>) {

		if ( m/^\s*:?\[\s*(.+?)\s*\]:?\s*$/ ) {

		    my $sNewSection = $1;

			$ph->{__class_active}++ if m/^\s*:\[\s*(.+?)\s*\]\s*$/;
			$h{$s} = $ph if scalar keys %{$ph};

			$s = $sNewSection;
			$ph = ( $p->{$s} && $phC->{$s} && $phC->{$s} =~ /^[^!\-]/ ) ? $p->{$s} : {};
			$ph->{__class_active}++ if m/^\s*\[\s*(.+?)\s*\]:\s*$/;
			push( @a, $s );
			$sKeyLast = undef;

		} else {

			s/(^|\s+)[#;].*$//g if ( ! $phC->{$s} || $phC->{$s} ne '!' );

			chomp();
			next unless length;

			if (
				     ! $ph->{__class_active}
				&& ( ! $phC->{$s} || $phC->{$s} !~ /[=!\-\+]/ )
				&& /^\s*(\S+)\s*=\s*(.*)\s*$/
			) {

				$ph->{$1} = $2;
				$sKeyLast = $1;

			} else {

				if (
					     $sKeyLast
					&& ! $ph->{__class_active}
					&& ( ! $phC->{$s} || $phC->{$s} !~ /[=!\-\+]/ )

				) {

					$ph->{$sKeyLast} .= "\n$_" ;

				}

				if ( ! $phC->{$s} || $phC->{$s} =~ /^=$/ ) {
					s/^\s+//;
					s/\s+$//;
				}

				$ph->{"__unnamed_idx_".$ph->{__unnamed_items}++} = $_;

			}
		}
	}

	$h{$s} = $ph if scalar keys %{$ph};

	foreach $s ( keys %{$p} ) {

		next if grep { $_ eq $s } @a;

		$h{$s} = $p->{$s};

	}

	return \%h;
}
#******
