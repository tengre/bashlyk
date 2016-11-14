#
# $Id: libtst.sh 585 2016-11-14 23:44:21+04:00 toor $
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
#****f* libtst/udfEncode
#  SYNOPSIS
#    udfEncode args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    local s='if [[ re  =~  (a|b b|\") ]]; then ok; fi'
#    udfEncode "$s" #? true
#  SOURCE
udfEncode() {

  local s="$@"
  s=${s//\"/_\&#34_}
  s=${s//\(/_\&#40_}
  s=${s//\)/_\&#41_}
  s=${s//\;/_\&#59_}
  s=${s//\=/_\&#61_}
  s=${s//\|/_\&#7C_}
  s=${s//\[/_\&#91_}
  s=${s//\\/_\&#92_}
  s=${s//\]/_\&#93_}
  #s=${s//\$\(/-S-(}
  #s=${s//\`/^_}

  echo "$s"
}
#******
#****f* libtst/udfDecode
#  SYNOPSIS
#    udfDecode args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    local s='if _&#91__&#91_ re  _&#61_~  _&#40_a_&#7C_b b_&#7C__&#92__&#34__&#41_ _&#93__&#93__&#59_ then ok_&#59_ fi'
#    udfDecode "$s" #? true
#  SOURCE
udfDecode() {

  local s="$@"
  s=${s//_\&#34_/\"}
  s=${s//_\&#40_/\(}
  s=${s//_\&#41_/\)}
  s=${s//_\&#59_/\;}
  s=${s//_\&#61_/\=}
  s=${s//_\&#7C_/\|}
  s=${s//_\&#91_/\[}
  s=${s//_\&#92_/\\}
  s=${s//_\&#93_/\]}
  #s=${s//\$\(/-S-(}
  #s=${s//\`/^_}

  echo "$s"
}
#******
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
#   local c ini s S                                                             #-
#   local -A hTest
#   c='([_:unnamed:_]="" [exec]="!" [main]="" [replace]="-" [unify]="=" [acc]="+")' #-
#   udfMakeTemp ini                                                             #-
#    cat <<'EOFini' > ${ini}                                                    #-
#    void  =  1                                                                 #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#    _____export HOSTNAME=$(hostname)                                           #-
#    fi                                                                         #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt   =  $(date-R)                                                        #-
#    b      =  false                                                            #-
#    iXo Xo =  19                                                               #-
#    iYo    =  80                                                               #-
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
#   sed -i -e "s/_____/     /" $ini                                             #-
#   cat $ini
#   s=$( ini.read $ini "" "$c" )                                                #? true
#   echo ${s/h/hTest}
#   eval "${s/h/hTest}"                                                         #-
#   for S in ${hTest[__sections__]}; do                                         #-
#     for s in $(echo ${!hTest[@]} | tr ' ' '\n' | grep "^${S}\." | sort); do   #-
#       echo "$s = ${hTest[$s]}"
#     done                                                                      #-
#   done                                                                        #-
#  SOURCE
ini.read() {

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $3
  #typeset -A $2 || eval $( udfOnError throw InvalidArgument "$2 must be hash" )
  #typeset -A $3 || eval $( udfOnError throw InvalidArgument "$3 must be hash" )

  local -A h hRC
  local bActiveSection fn i k reComment reKeyVal reRawClass reSection s v
  #
  [[ $2 ]] && eval "local -A h=$2"
  eval "local -A hRC=$3"
  #
  i=0
  s="_:unnamed:_"
  #
  fn=$1
  h[__sections__]="$s"

   reSection='^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
    reKeyVal='^[[:space:]]*([[:alnum:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
   reComment='(^|[[:space:]]+)[\#\;].*$'
  reRawClass='^[=\!\-\+]$'

  while read -t 4; do

    if [[ $REPLY =~ $reSection ]]; then

      s=${BASH_REMATCH[2]}

      [[ ${BASH_REMATCH[1]} == ":" ]] && bActiveSection=
      [[ ${BASH_REMATCH[3]} == ":" ]] && bActiveSection=true

      i=0

      [[ $bActiveSection ]] && continue

      h[__sections__]+=" $s"

    else

      [[ $REPLY =~ $reComment ]] && continue

      if [[ ! $bActiveSection && ! ${hRC[$s]} =~ $reRawClass && $REPLY =~ $reKeyVal ]]; then

        k=${BASH_REMATCH[1]}
        v=${BASH_REMATCH[2]}

        if [[ $k =~ "=" ]]; then

          k=${REPLY%%=*}
          k=${k%% *}
          v=${REPLY#*=}
          v=${v#* }
          h[${s}.${k}]=$v

        else

          h[${s}.${k}]="$v"

        fi

      else

#        if   [[ ${ini_hClass[$s]} =~ ^=$ ]]; then
#
#          REPLY=${REPLY##*( )}
#          REPLY=${REPLY%%*( )}
#
#        fi

        h[${s}".__unnamed_idx_"${i}]="$REPLY"
        : $(( i++ ))

      fi

    fi

  done < $fn

  declare -p h

}
#******
#****f* libtst/ini.group
#  SYNOPSIS
#    ini.group args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#  SOURCE
ini.group() {
#
#	return undef unless @_ == 3
#						&& defined( $_[0] )
#						#&& defined( $_[1] )
#						#&&     ref( $_[1] ) eq 'HASH'
#						&& defined( $_[2] )
#						&&     ref( $_[2] ) eq 'HASH';
#

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $3
  #typeset -A $2 || eval $( udfOnError throw InvalidArgument "$2 must be hash" )
  #typeset -A $3 || eval $( udfOnError throw InvalidArgument "$3 must be hash" )

  local -A h hRC
  local bActiveSection fn i k path pathIni reComment reKeyVal reRawClass reSection s v
  [[ $2 ]] && eval "local -A h=$2"
  eval "local -A hRC=$3"

#	my ( $fn, $ph, $phClass, $fh, $path, $ini ) = ( $_[0], $_[1], $_[2], undef, "", "" );
#
#	$path = $_pathIni           if ( $fn !~ m{/} && -f "${_pathIni}/${fn}" );
#	$path = $1                  if ( $fn =~ m{/} && -f "${fn}" && m{(.*)/.*} );
#	$path = "/etc/$_pathPrefix" if ( $path eq "" && -f "/etc/${_pathPrefix}/${fn}" );
#
  [[ "$1" == "${1##*/}" && -f "$(_ pathIni)/$1" ]] && pathIni=$(_ pathIni)
  [[ "$1" == "${1##*/}" && -f "$1"              ]] && pathIni=$(pwd)
  [[ "$1" != "${1##*/}" && -f "$1"              ]] && pathIni=$(dirname $1)
  #
  if [[ -z "$pathIni" ]]; then
   [[ -f "/etc/$(_ pathPrefix)/$1" ]] && pathIni="/etc/$(_ pathPrefix)"
  fi

#	if ( -d "$path" ) {
#
#		my @a = ( $fn =~ m{(.*/)?(.*)} ) ? reverse( split( /\./, $2 ) ) : ();
#
#		foreach ( @a ) {
#
#			next if $_ eq "";
#			$ini = ( $ini ne "" ) ? "${_}.${ini}" : "$_";
#			if ( -s "${path}/${ini}" ) {
#
#				open( $fh, "<${path}/${ini}" ) or die "${ini}: $!\n";
#				$ph = readSource( $fh, $ph, $phClass );
#				close( $fh );
#
#			}
#		}
#
#		$ph->{configfile} = "${path}/${ini}";
#
#	}
#
#	if ( scalar keys %_hCLI ) {
#
#		( $fh, $fn ) = tempfile();
#		writeTarget( $fh, \%_hCLI );
#		seek( $fh, 0, 0 ) or die "${fn}: seek error $!\n";
#		$ph = readSource( $fh, $ph, $phClass );
#		close( $fh );
#		unlink( $fn );
#
#	}
#
#	return $ph;
#
}
#******
