#
# $Id: libtst.sh 601 2016-11-25 16:18:39+04:00 toor $
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
: ${_bashlyk_aRequiredCmd_msg:="getopt stat"}
: ${_bashlyk_aExport_msg:="ini.section.{add,free,get,init,raw,select,set}       \
  ini.read ini.group ini.bind.cli"}
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
#    removing the resources associated with processing of the INI-configurations
#  RETURN VALUE
#    last unset status
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
#    preparing resources to handle the INI configurations
#  RETURN VALUE
#    declare status
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
#    ini.section.select <section>
#  DESCRIPTION
#    preparing resources to handle the selected section of the INI-file(s)
#  ARGUMENTS
#    section name
#  RETURN VALUE
#    last eval status
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

## TODO '$1' checking required
eval "ini.section.set() { $s[\$1]="\$2"; }; ini.section.get() { echo "\${$s[\$1]}"; };"

}
#******
#****f* libtst/ini.section.raw
#  SYNOPSIS
#    ini.section.raw <raw mode> <data>
#  DESCRIPTION
#    add or update unnamed record of the "raw" data for early selected section
#  ARGUMENTS
#    <raw mode> - the signs of the method of raw data handling:
#                 '-', '+' - add new records with key incrementing
#                 '='      - add new unique record only
#    < data>    - "raw" data, no as "key=value" pairs
#  RETURN VALUE
#    InvalidArgument - unexpected "raw" mode
#    Success for other cases
#  EXAMPLE
#  SOURCE
ini.section.raw() {

  local i s

  i=$( ini.section.get __unnamed_cnt )
  udfIsNumber $i || i=0

  case "$1" in

    =)

       s="${2##*( )}"
       s="${s%%*( )}"
       ini.section.set "__unnamed_key=${s//[\'\"\\]/}" "$s"

    ;;

    -|+)

       ini.section.set "__unnamed_idx=${i}" "$2"

    ;;

    *)

      return $( _ iErrorInvalidArgument )

  esac

  : $(( i++ ))
  ini.section.set __unnamed_cnt $i

  return 0

}
#******
#  SYNOPSIS
#    ini.section.add <section> <key> <value>
#  DESCRIPTION
#    add or update <key> record of the INI section
#  ARGUMENTS
#    <section> - section of the INI-configuration
#    <key>     - named key for "key=value" pairs of the input data. For unnamed
#                records this argument must be the sign of the method of raw
#                data handling:
#                '-', '+' - add new records with key incrementing
#                '='      - add new unique record only
#    <value>   - "value" part of the "key=value" pair or full "raw" inputs
#  RETURN VALUE
#    Success always
#  EXAMPLE
#  SOURCE
ini.section.add() {

  [[ $2 ]] || return 0

  local s="$1"

  ini.section.select "${s:=__global__}"

  if [[ $2 =~ ^[\-\+=]$ ]]; then

    ini.section.raw "$2" "$3"

  else

    ini.section.set "$2" "$3"

  fi

}
#******
#****f* libtst/ini.read
#  SYNOPSIS
#    ini.read args
#  DESCRIPTION
#    Handling a configuration from the single INI file. Read valid "key=value"
#    pairs and "active" sections data only
#  RETURN VALUE
#    NoSuchFileOrDir - input file not exist
#    NotPermitted    - owner of the input file differ than owner of the process
#    Success for the other cases
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
        ini.section.set "__unnamed_key=${REPLY//[\'\"\\]/}" "$REPLY"

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
#    ini.group <args>
#  DESCRIPTION
#    getting indicated parameters from a group of related INI files
#  INPUTS
#    ...
#  RETURN VALUE
#    NoSuchFileOrDir - input file not exist
#    MissingArgument - parameters and sections are not selected
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

    [[ ${BASH_REMATCH[3]} ]] && hRawMode[$sSection]="${BASH_REMATCH[3]}"
    [[ ${BASH_REMATCH[4]} ]] && s="${BASH_REMATCH[4]}" || s=
    [[ $s ]] && s="${s//,/\|}" && hKeyValue[$sSection]=${fmtKeyValue/\%KEY\%/$s}

    ini.section.select "$sSection"
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

}
#******
#****f* libtst/ini.bind.cli
#  SYNOPSIS
#    ini.bind.cli args
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
#    local s="first{F} second{S}: section-single{s} no-save{N} raw{R}:="
#    _ sArg "--second test --first -s --raw abyr --raw walg -R ssass -N"
#    ini.section.init
#    ini.bind.cli $s                                                            #? true
#    declare -p _h
#    for s in "${!_h[@]}"; do                                                   #-
#      [[ $s == '__id__' ]] && continue                                         #-
#      echo "section ${s}:"
#      eval "declare -p ${_h[$s]}"
#    done                                                                       #-
#
#  SOURCE
ini.bind.cli() {

  udfOn MissingArgument "$@" || return $?

  local -a a
  local fmtCase fmHandler k sSection sShort sLong sArg s S sHandler sCases v

  fmtHandler='udfHandleGetopt() { while true; do case $1 in %s --) shift; break;; esac; done }'
  fmtCase='--%s|%s) ini.section.add "%s" "%s" "%s"; shift %s;;'

  for s in $@; do

    if [[ $s =~ (([[:alnum:]]+)(-))?(@|[[:alnum:]]+)(\{([[:alnum:]])\})?([:])?([:=\+\-])? ]]; then

      s=$( declare -p BASH_REMATCH )
      eval "${s/-ar BASH_REMATCH/-a a}"

    else

      eval $( udfOnError throw InvalidArgument "$s - format error" )

    fi

    s=;S=;v=1;sSection="${a[2]}";k="${a[4]}"

    [[ ${a[4]} ]] && sLong+="${a[4]}${a[7]},"
    [[ ${a[6]} ]] && sShort+="${a[6]}${a[7]}" && s="-${a[6]}"
    [[ ${a[7]} ]] && S="2" && v='$2'
    [[ ${a[8]} =~ ^(=|\-|\+)$ ]] && k="${a[8]}" && sSection="${a[4]}"

    sCases+="$( printf -- "$fmtCase" "${a[4]}" "$s" "${sSection}" "$k" "$v" "$S" ) "

  done

  s="$( getopt -u -o $sShort --long ${sLong%*,} -n $0 -- $(_ sArg) )"
  (( $? > 0 )) && udfOn InvalidArgument throw "$s - CLI parsing error..."

  sHandler="$( printf -- "$fmtHandler" "$sCases" )"

  eval "$sHandler" && udfHandleGetopt $s

}
#******
