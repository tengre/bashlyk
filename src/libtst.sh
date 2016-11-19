#
# $Id: libtst.sh 593 2016-11-20 01:11:51+04:00 toor $
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

[[ $_BASHLYK_LIBTST ]] && return 0 || _BASHLYK_LIBTST=1
#******
#declare -g -A _h
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
  s=${s// /_&#20_}
  s=${s//\*/_&#2A_}
  s=${s//\"/_&#34_}
  s=${s//\(/_&#40_}
  s=${s//\)/_&#41_}
  s=${s//\;/_&#59_}
  s=${s//\=/_&#61_}
  s=${s//\|/_&#7C_}
  s=${s//\[/_&#91_}
  s=${s//\\/_&#92_}
  s=${s//\]/_&#93_}
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
  s=${s//_&#20_/ }
  s=${s//_&#2A_/\*}
  s=${s//_&#34_/\"}
  s=${s//_&#40_/\(}
  s=${s//_&#41_/\)}
  s=${s//_&#59_/\;}
  s=${s//_&#61_/\=}
  s=${s//_&#7C_/\|}
  s=${s//_&#91_/\[}
  s=${s//_&#92_/\\}
  s=${s//_&#93_/\]}
  #s=${s//\$\(/-S-(}
  #s=${s//\`/^_}

  echo "$s"
}
#******
ini.section.init() {
  local s
  for s in "${_h[@]}"; do

    unset -v $s

  done
}
ini.selectsection() {

local s

[[ $( declare -p _h 2>/dev/null) ]] || declare -A -g -- _h=()

if [[ ! ${_h[$1]} ]]; then

  s=$(md5sum <<< "$1")
  s="_ini${s:0:32}"
  _h[$1]="$s"

  eval "declare -A -g -- $s"

  #declare -p _h
else

  s=${_h[$1]}

fi

#echo "ini.section() { case "\$1" in get) echo "\${$s[\$2]}";; set) $s[\$2]="\$3";; esac; }"
#eval "ini.section() { case "\$1" in get) echo "\${$s[\$2]}";; set) $s[\$2]="\$3";; esac; }"
eval "ini.section.set() { $s[\$1]="\$2"; }; ini.section.get() { echo "\${$s[\$1]}"; };"
eval "ini.section.exists() { (( \${#$s[@]} > 0 )); return $?; };"

}

#****f* libtst/ini.get
#  SYNOPSIS
#    ini.get args
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
#   local -A hT
#   c='([__global__]="" [exec]="-" [main]="" [replace]="-" [unify]="=" [acc to ass]="+")' #-
#   udfMakeTemp ini suffix=".ini"                                               #-
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
#[acc to ass]                                                                   #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#                                                                               #-
#    EOFini                                                                     #-
#   sed -i -e "s/_____/     /" $ini                                             #-
#   cat $ini
#   ini.get $ini "$c"                                                           #? true
#    declare -p _h
#    for s in "${!_h[@]}"; do                                                   #-
#      echo "section ${s}:"
#      eval "declare -p ${_h[$s]}"
#    done                                                                       #-
#  SOURCE
ini.get() {

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $2
  #typeset -A $2 || eval $( udfOnError throw InvalidArgument "$2 must be hash" )
  #typeset -A $3 || eval $( udfOnError throw InvalidArgument "$3 must be hash" )

  local -A h hRC hS
  local bActiveSection fn i k reComment reKeyVal reRawClass reSection s v
  #

  if [[ $2 ]]; then

   [[ $2 =~ ^declare.-A.[[:alnum:]]+= ]] && s="${2#*=}" || s="$2"
   eval "local -A hRC=$s"

  fi

  #
  i=0
  s="__global__"
  #
  fn=$1
  #ini.section.init
  ini.selectsection $s

   reSection='^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
    reKeyVal='^[[:space:]]*([[:alnum:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
   reComment='(^|[[:space:]]+)[\#\;].*$'
  reRawClass='^[=\-+]$'

  while read -t 4; do

    if [[ $REPLY =~ $reSection ]]; then

      (( i > 0 )) && ini.section.set __unnamed_cnt $i
      i=0

      s="${BASH_REMATCH[2]}"
      ini.selectsection "$s"

      [[ ${BASH_REMATCH[1]} == ":" ]] && bActiveSection=close
      [[ ${BASH_REMATCH[3]} == ":" ]] && bActiveSection=open

      if [[ $bActiveSection == "close" ]]; then

        bActiveSection=
        continue

      fi

      i=$( ini.section.get __unnamed_cnt )

      if ! udfIsNumber $i; then
        i=0
        ini.section.set __unnamed_cnt $i
      fi

      [[ ${hRC[$s]} =~ ^(\+|=)$ ]] || i=0

    else

      [[ $REPLY =~ $reComment ]] && continue

      if [[ ! $bActiveSection && ! ${hRC[$s]} =~ $reRawClass && $REPLY =~ $reKeyVal ]]; then

        k=${BASH_REMATCH[1]}
        v=${BASH_REMATCH[2]}

        ini.section.set "$k" "$v"

      else

        if   [[ ${hRC[$s]} =~ ^=$ ]]; then

          REPLY=${REPLY##*( )}
          REPLY=${REPLY%%*( )}
          ini.section.set "__unnamed_key=${REPLY}" "$REPLY"

        else

          : ${i:=0}
          ini.section.set "__unnamed_idx=${i}" "$REPLY"

        fi

        : $(( i++ ))

      fi

    fi

  done < $fn

  [[ ini.section.exists ]] &&  ini.section.set __unnamed_cnt $i

  #for s in "${_h[@]}"; do
  #  eval "declare -p $s" >> /tmp/hashes.log
  #done
}
#******
#****f* libtst/ini.group2
#  SYNOPSIS
#    ini.group2 args
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
#   local -A hT hS                                                                #-
#   c='([__global__]="" [exec]="-" [main]="" [replace]="-" [unify]="=" [acc to ass]="+")'
#   udfMakeTemp ini suffix=.ini                                                 #-
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
#[acc to ass]                                                                   #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#                                                                               #-
#    EOFini                                                                     #-
#    cat <<'EOFiniChild' > "${ini%/*}/child.${ini##*/}"                         #-
#    void  =  2                                                                 #-
#    main  =  main                                                              #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345679'                                          #-
#    sUname="$(uname)"                                                          #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#    _____export HOSTNAME=$(hostname -f)                                        #-
#    fi                                                                         #-
#    echo $sUname                                                               #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt   =  $(date "+%s") =test = a =                                        #-
#    b      =  true                                                             #-
#    iXo Xo =  19                                                               #-
#    iYo    =  81                                                               #-
#    simple line                                                                #-
#[replace]                                                                      #-
#    after replacing                                                            #-
#[unify]                                                                        #-
#    *.xxx                                                                      #-
#    *.tmp                                                                      #-
#[acc to ass]                                                                   #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    *.com                                                                      #-
#    *.exe                                                                      #-
#    *.jpg                                                                      #-
#    *.png                                                                      #-
#    *.mp3                                                                      #-
#    *.dll                                                                      #-
#    *.asp                                                                      #-
#    EOFiniChild                                                                #-
#   sed -i -e "s/_____/     /g" "${ini%/*}/child.${ini##*/}"                    #-
#   cat $ini "${ini%/*}/child.${ini##*/}"
#   ini.group2 "${ini%/*}/child.${ini##*/}" "$c"                                #? true
#    declare -p _h
#    for s in "${!_h[@]}"; do                                                   #-
#      echo "section ${s}:"
#      eval "declare -p ${_h[$s]}"
#    done                                                                       #-
#  SOURCE
ini.group2() {

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $2

  local -a a
  local i ini path s sIni sRawClass

  [[ $2 ]] && sRawClass="$2"

  [[ "$1" == "${1##*/}" && -f "$(_ pathIni)/$1" ]] && path=$(_ pathIni)
  [[ "$1" == "${1##*/}" && -f "$1"              ]] && path=$(pwd)
  [[ "$1" != "${1##*/}" && -f "$1"              ]] && path=${1%/*}

  if [[ ! $( stat -c %U ${path}/${1##*/} ) == $( _ sUser ) ]]; then

	eval $( udfOnError NotPermitted throw "$1 owned by $( stat -c %U ${path}/${1##*/} )" )

  fi
  #
  if [[ ! $path && -f "/etc/$(_ pathPrefix)/$1" ]]; then

    path="/etc/$(_ pathPrefix)"

  fi

  if [[ $path ]]; then

    s=${1##*/}
    a=( ${s//./ } )

    for (( i = ${#a[@]}-1; i >= 0; i-- )); do

      [[ ${a[i]} ]] || continue
      [[ $ini    ]] && ini="${a[i]}.${ini}" || ini="${a[i]}"
      [[ -s "${path}/${ini}" ]] && ini.get "${path}/${ini}" "$sRawClass"

    done

 fi

# echo "$sIni"

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
#****f* libtst/ini.getsafe
#  SYNOPSIS
#    ini.getsafe args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#
#  SOURCE
#sub prepare {
#ini.getsafe() {
#
#	return undef unless @_ == 2
#						&& defined( $_[0] )
#						&&     ref( $_[0] )
#						&& defined( $_[1] );
#
#	my ( $ph, $s ) = @_;
#	my $p = undef;
#	my %h = ();
#	my @a = ();
#
#  local -a a
#  local -A hI hO
#  local s
  #
#  if [[ $1 ]]; then
#
#    [[ $1 =~ ^declare.-A.[[:alnum:]]+= ]] && s="${1#*=}" || s="$1"
#    eval "local -A hI=$s"
#
#  fi
#
#  s=$2
#
##	if ( $s !~ /^[\-\+=!]/ ) {
#  if [[ ! $s =~ ^[\!\-\+=] ]]; then
##
##		my @aValidOptions = ( $s =~ m/^(.*)$/ ) ? split( ',', $1 ) : ();
#                ## TODO keys without spaces!
#    for s in ${s//,/ }; do
#
#      hO[$s]=${hI[$s]}
#
#    done
#
#    declare -p hO
##		$h{$_} = $ph->{$_} foreach ( @aValidOptions );
##		$p = \%h;
##
##	} else {
#  else
#
##		push( @a, $ph->{$_} ) foreach sort { substr( $a, 14 ) <=> substr( $b, 14 ) } ( grep { /__unnamed_idx_/ } keys %{$ph} );
#    for s in $( echo "${!h[@]}" | tr ' ' '\n' | grep "__unnamed_idx=${S}$" | sort -t= -k2n); do   #-
#
#		@a = grep { ! $h{$_}++ } @a if "$s" =~ /=/;
#		$p = \@a;
#
#	}
#
#	return $p;
#
#}
##******
#****f* libtst/ini.getOnlyWhatYouNeed2
#  SYNOPSIS
#    ini.getOnlyWhatYouNeed2 args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#
#  SOURCE
ini.getOnlyWhatYouNeed2() {
#
#	return () unless @_ > 1;
#  udfOn MissingArgument $@ || return $?
#  udfOn NoSuchFileOrDir $1 || return $?
#
##
##	my ( $fn, $ph, %h ) = ( "$_[0]", undef, () );
  local -a a
  local -A hI hO
  local csv fn s
#
  fn=$1
#
#	shift;
  shift
#
#	foreach (@_) {
#		my $s  = ( m/^(.*?):.*$/           ) ? $1 : "";
#		$h{$s} = ( m/^.*?:([=\-\+]|.*)$/ ) ? $1 : "";
#	}
#
#	$ph = readRelated( $fn, $ph, \%h );
#	if ( defined $ph && scalar keys %{$ph} ) {
#		$ph->{$_} = prepare( $ph->{$_}, $h{$_} ) foreach keys %{$ph};
#	}
#
  for s in "$@"; do

    if [[ $s =~ ^(.*)?:([=+\-]?)([^=+\-].*)$ ]]; then

     sSection=${BASH_REMATCH[1]}
     : ${sSection:=__global__}
     sRawClass=${BASH_REMATCH[2]}
     csvOptions=${BASH_REMATCH[3]}

    else

      udfOn InvalidArgument throw $s

    fi

    hRawClass[$sSection]="$sRawClass"
    hOptions[$sSection]="$csvOptions"

  done

  $sIni=$(ini.group2 $ini "$sIni" "$(declare -A hRawClass)" )

#  [[ $sIni =~ ^declare.-A.[[:alnum:]]+= ]] && s="${sIni#*=}" || s="$sIni"
#    eval "local -A hI=$s"
#
#  eval "local -A h=$sIni"
#
#  for sSection in "${!hOptions[@]}"; do
#    csv=${hOptions[$sSection]}
#    for s in ${csv//,/ }; do
#
#      ini.getOnlyWhatYouNeed2
#
#    done
#
#  done

##	return $ph;

}
#
