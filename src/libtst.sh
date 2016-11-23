#
# $Id: libtst.sh 598 2016-11-23 17:14:45+04:00 toor $
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
#****f* libtst/ini.section.free
#  SYNOPSIS
#    ini.section.free
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    local -A _h='( [__id__]="__id__" [test]="hI" )' hI='( [__id__]="__id__" )'
#    ini.section.free                                                           #? true
#    [[ ${_h[@]} ]]                                                             #? false
#    [[ ${hI[@]} ]]                                                             #? false
#  SOURCE
ini.section.free() {

  local s

  for s in "${_h[@]}"; do

    [[ $s == '__id__' ]] && continue

    unset -v $s

  done

  unset -v _h

}
#******
#****f* libtst/ini.section.init
#  SYNOPSIS
#    ini.section.init
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    local -A _h='( [__id__]="__id__" [test]="hI" )' hI='( [__id__]="__id__" )'
#    ini.section.init                                                           #? true
#    [[ ${_h[@]} ]]                                                             #? true
#    [[ ${hI[@]} ]]                                                             #? false
#    ini.section.free                                                           #? true
#    [[ ${_h[@]} ]]                                                             #? false
#  SOURCE
ini.section.init() {

  ini.section.free
  declare -A -g -- _h="( [__id__]=__id__ )"

}
#******
#****f* libtst/ini.section.select
#  SYNOPSIS
#    ini.section.select arg
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    local s
#    ini.section.init                                                           #? true
#    ini.section.select test                                                    #? true
#    s=${_h[test]}
#    eval "declare -p $s" >| grep "declare.*2dc0f896fd7cb4cb0031ba249="         #? true
#    [[ ${hI[@]} ]]                                                             #? false
#    ini.section.free                                                           #? true
#    [[ ${_h[@]} ]]                                                             #? false
## TODO add tests for ini.section.{get,set}
#  SOURCE
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
#   c=':void,main exec:- main:sTxt,b,iYo replace:- unify:= asstoass:+'          #-
#   udfMakeTemp ini suffix=".ini"                                               #-
#    cat <<'EOFini' > ${ini}                                                    #-
#    section  =  global                                                         #-
#[main]                                                                         #-
#    sTxt   =  $(date -R)                                                       #-
#    b      =  false                                                            #-
#    iXo Xo =  19                                                               #-
#    iYo    =  80                                                               #-
#    `simple line`                                                              #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#         export HOSTNAME=$(hostname)                                           #-
#    fi                                                                         #-
#:[exec]                                                                        #-
#[replace]                                                                      #-
#    this is a line of the raw data                                             #-
#    replace = true                                                             #-
#[unify]                                                                        #-
#    # this is a comment                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    unify = false                                                              #-
#[asstoass]                                                                     #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    ass = to ass                                                               #-
#    EOFini                                                                     #-
#   ini.section.init
#   ini.read $ini                                                               #? true
#    declare -p _h
#    for s in "${!_h[@]}"; do                                                   #-
#      [[ $s == '__id__' ]] && continue                                         #-
#      echo "section ${s}:"
#      eval "declare -p ${_h[$s]}"
#    done                                                                       #-
#  SOURCE
ini.read() {

  udfOn NoSuchFileOrDir throw $1

  local bActiveSection bIgnore csv fn i reComment reRawMode reSection reValidSections s

  reSection='^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
  reKey_Val='^[[:space:]]*([[:alnum:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
  reComment='(^|[[:space:]]+)[\#\;].*$'
  reRawMode='^[=\-+]$'

  s="__global__"
  fn="$1"

  [[ $2 ]] && reValidSections="$2" || reValidSections="$reSection"
  [[ ${hKeyValue[@]} ]] || local -A hKeyValue
  [[ ${hRawMode[@]}  ]] || local -A hRawMode

  if [[ ! $( stat -c %U $fn ) == $( _ sUser ) ]]; then

    eval $( udfOnError NotPermitted throw "$1 owned by $( stat -c %U $fn )" )

  fi

  i=0
  bIgnore=

  [[ ${hKeyValue[$s]} ]] || hKeyValue[$s]="$reKey_Val"

  ini.section.select "$s"

  while read -t 4; do

    if [[ $REPLY =~ $reSection ]]; then

      bIgnore=1
      [[ $REPLY =~ $reValidSections ]] || continue
      bIgnore=

      s="${BASH_REMATCH[2]}"

      [[ ${BASH_REMATCH[1]} == ":" ]] && bActiveSection=close
      [[ ${BASH_REMATCH[3]} == ":" ]] && hRawMode[$s]="-"

      (( i > 0 )) && ini.section.set __unnamed_cnt $i

      bIgnore=1
      [[ $bActiveSection == "close" ]] && bActiveSection= && continue
      bIgnore=

      ini.section.select "$s"

      if [[ ${hRawMode[$s]} ]]; then

       i=$( ini.section.get __unnamed_cnt )

       if ! udfIsNumber $i; then

         i=0
         ini.section.set __unnamed_cnt $i

       fi

       [[ ${hRawMode[$s]} =~ ^(\+|=)$ ]] || i=0

      else

        hKeyValue[$s]="$reKey_Val"
        i=0

      fi

      continue

    else

      [[ $REPLY =~ $reComment || $bIgnore ]] && continue

    fi

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

  done < $fn

  [[ ${hRawMode[$s]} ]] && ini.section.set __unnamed_cnt $i

  return 0

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
#   local c iniMain iniChild s S                                                #-
#   c=':file,main,child exec:- main:hint,msg,cnt replace:- unify:= asstoass:+'  #-
#   udfMakeTemp -v iniMain suffix=.ini                                          #-
#    cat <<'EOFini' > $iniMain                                                  #-
#    section  =  global                                                         #-
#    file     =  main                                                           #-
#    main     =  true                                                           #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#         export HOSTNAME=$(hostname)                                           #-
#    fi                                                                         #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    hint   =  $(date -R)                                                       #-
#    msg    =  file main                                                        #-
#    iXo Xo =  19                                                               #-
#    cnt    =  66                                                               #-
#    ~simple line~                                                              #-
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
#    iniChild="${iniMain%/*}/child.${iniMain##*/}"                              #-
#    udfAddFile2Clean $iniChild                                                 #-
#    cat <<'EOFiniChild' > $iniChild                                            #-
#    section  =  global                                                         #-
#    file     =  child                                                          #-
#    main     =  false                                                          #-
#    child    =  true                                                           #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345679'                                          #-
#    sUname="$(uname)"                                                          #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#         export HOSTNAME=$(hostname -f)                                        #-
#    fi                                                                         #-
#    echo $sUname                                                               #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    hint   =  $(date "+%s") more = equals =                                    #-
#    msg    =  child file                                                       #-
#    iXo Xo =  19                                                               #-
#    cnt    =  80                                                               #-
#    simple line                                                                #-
#[replace]                                                                      #-
#    after replacing                                                            #-
#[unify]                                                                        #-
#    *.xxx                                                                      #-
#    *.tmp                                                                      #-
#[ignored]                                                                      #-
#    test by test                                                               #-
#    a = b                                                                      #-
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
#[unify]                                                                        #-
#    *.xxx                                                                      #-
#    *.lit                                                                      #-
#    EOFiniChild                                                                #-
#   ini.group $iniChild $c                                                      #? true
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
  local -A h hKeyValue hRawMode
  local csv i ini fmtKeyValue fmtSections path reSection reValidSections s sSection

  fmtSections='^[[:space:]]*(:?)\[[[:space:]]*(%SECTION%)[[:space:]]*\](:?)[[:space:]]*$'
  fmtKeyValue='^[[:space:]]*(%KEY%)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'

  [[ "$1" == "${1##*/}" && -f "$(_ pathIni)/$1" ]] && path=$(_ pathIni)
  [[ "$1" == "${1##*/}" && -f "$1"              ]] && path=$(pwd)
  [[ "$1" != "${1##*/}" && -f "$1"              ]] && path=${1%/*}
  #
  if [[ ! $path && -f "/etc/$(_ pathPrefix)/$1" ]]; then

    path="/etc/$(_ pathPrefix)"

  fi

  if [[ $path ]]; then

    s=${1##*/}
    a=( ${s//./ } )

  fi

  shift

  for s in "$@"; do

    [[ $s =~ ^(.*)?:(([=+\-]?)|([^=+\-].*))$ ]] || udfOn InvalidArgument throw $s

    sSection=${BASH_REMATCH[1]}
    : ${sSection:=__global__}
    ini.section.select "$sSection"

    [[ ${BASH_REMATCH[3]} ]] && hRawMode[$sSection]="${BASH_REMATCH[3]}"
    [[ ${BASH_REMATCH[4]} ]] && s="${BASH_REMATCH[4]}" || s=
    [[ $s ]] && s="${s//,/\|}" && hKeyValue[$sSection]=${fmtKeyValue/\%KEY\%/$s}

    csv+="${sSection}|"

  done

  csv=${csv%*|}

  [[ $csv ]] && reValidSections=${fmtSections/\%SECTION\%/$csv}

  {
   declare -p hRawMode
   declare -p hKeyValue
   echo $reValidSections
  } > /tmp/hashes.log

  ## TODO init hash per section here
  ini.section.init

  for (( i = ${#a[@]}-1; i >= 0; i-- )); do

    [[ ${a[i]} ]] || continue
    [[ $ini    ]] && ini="${a[i]}.${ini}" || ini="${a[i]}"
    [[ -s "${path}/${ini}" ]] && ini.read "${path}/${ini}" "$reValidSections"

  done

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
