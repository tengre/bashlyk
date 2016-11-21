#
# $Id: libtst.sh 596 2016-11-21 23:21:04+04:00 toor $
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
: ${_bashlyk_aExport_msg:="udfTest ini.group"}
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
ini.section.free() {

  local s

  for s in "${_h[@]}"; do

    [[ $s == '__id__' ]] && continue

    unset -v $s

  done

  unset -v _h

}
#******
ini.section.init() {

  ini.section.free
  #declare -A -g -- _h="()"
  declare -A -g -- _h="( [__id__]=__id__ )"

}
#******
ini.section.select() {

local s

if [[ ! ${_h[$1]} ]]; then

  s=$(md5sum <<< "$1")
  s="_ini${s:0:32}"
  _h[$1]="$s"

  eval "declare -A -g -- $s=()"

else

  s=${_h[$1]}

fi

eval "ini.section.set() { $s[\$1]="\$2"; }; ini.section.get() { echo "\${$s[\$1]}"; };"
eval "ini.section.exists() { (( \${#$s[@]} > 0 )); return $?; };"

}
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
#   c=':void,main exec:- main:sTxt,b,iYo replace:- unify:= asstoass:+'          #-
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
# #-
#[asstoass]                                                                     #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    EOFini                                                                     #-
#   sed -i -e "s/_____/     /" $ini                                             #-
#   cat $ini
#   ini.section.init
#   ini.read $ini $c                                                            #? true
#    declare -p _h
#    for s in "${!_h[@]}"; do                                                   #-
#      [[ $s == '__id__' ]] && continue                                         #-
#      echo "section ${s}:"
#      eval "declare -p ${_h[$s]}"
#    done                                                                       #-
#  SOURCE
ini.read() {

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $2

  local -A h hKeyValue hRawMode
  local bActiveSection csv fn i reComment reKeyValue reRawMode reSection s
  #
  fn=$1
  shift

   reSection='^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
  reKeyValue='^[[:space:]]*([[:alnum:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
   reComment='(^|[[:space:]]+)[\#\;].*$'
   reRawMode='^[=\-+]$'

  for s in "$@"; do

    [[ $s =~ ^(.*)?:(([=+\-]?)|([^=+\-].*))$ ]] || udfOn InvalidArgument throw $s

    sSection=${BASH_REMATCH[1]}
    : ${sSection:=__global__}
    hRawMode[$sSection]="${BASH_REMATCH[3]}"
    s="${BASH_REMATCH[4]}"
    s="${s//,/\|}"

    [[ $s ]] && hKeyValue[$sSection]=${reKeyValue/\[\[:alnum:\]\]+/$s}

  done

  i=0
  s="__global__"

  ini.section.select $s

  while read -t 4; do

    if [[ $REPLY =~ $reSection ]]; then

      (( i > 0 )) && ini.section.set __unnamed_cnt $i

      s="${BASH_REMATCH[2]}"

      [[ ${BASH_REMATCH[1]} == ":" ]] && bActiveSection=close
      [[ ${BASH_REMATCH[3]} == ":" ]] && bActiveSection=open

      if [[ $bActiveSection == "close" ]]; then

        bActiveSection=
        continue

      fi

      ini.section.select "$s"

      i=$( ini.section.get __unnamed_cnt )

      if ! udfIsNumber $i; then

        i=0
        ini.section.set __unnamed_cnt $i

      fi

      [[ ${hRawMode[$s]} =~ ^(\+|=)$ ]] || i=0

    else

      [[ $REPLY =~ $reComment ]] && continue

      if [[ ${hKeyValue[$s]} ]]; then

        [[ $REPLY =~ ${hKeyValue[$s]} ]] && ini.section.set "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"

      else

        : ${i:=0}

        if [[ ${hRawMode[$s]} =~ ^=$ ]]; then

          REPLY=${REPLY##*( )}
          REPLY=${REPLY%%*( )}
          ini.section.set "__unnamed_key=${REPLY}" "$REPLY"

        else

          ini.section.set "__unnamed_idx=${i}" "$REPLY"

        fi

        : $(( i++ ))

      fi

    fi

  done < $fn

  [[ ini.section.exists ]] &&  ini.section.set __unnamed_cnt $i

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
#   local c ini s S                                                             #-
#   c=':void,main exec:- main:sTxt,b,iYo replace:- unify:= asstoass:+'          #-
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
#[asstoass]                                                                     #-
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
#[asstoass]                                                                     #-
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
#   ini.group "${ini%/*}/child.${ini##*/}" $c                                   #? true
#    declare -p _h
#    for s in "${!_h[@]}"; do                                                   #-
#      [[ $s == '__id__' ]] && continue                                         #-
#      echo "section ${s}:"
#      eval "declare -p ${_h[$s]}"
#    done                                                                       #-
#  SOURCE
ini.group() {

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $2

  local -a a
  local i ini path s

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

    shift

    ## TODO init hash per section here
    ini.section.init

    for (( i = ${#a[@]}-1; i >= 0; i-- )); do

      [[ ${a[i]} ]] || continue
      [[ $ini    ]] && ini="${a[i]}.${ini}" || ini="${a[i]}"
      [[ -s "${path}/${ini}" ]] && ini.read "${path}/${ini}" $@

    done

  fi

  ## TODO add CLI config without temporary config
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
