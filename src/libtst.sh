#
# $Id: libtst.sh 604 2016-11-28 17:19:22+04:00 toor $
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
  ini.read ini.load ini.save ini.bind.cli"}
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

  unset -v _a
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
  declare -a -g -- _a="()"

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

  local s s1=$1

  : ${s1:=__global__}

  if [[ ! ${_h[$s1]} ]]; then

    s=$(md5sum <<< "$s1")
    s="_ini${s:0:32}"
    _h[$s1]="$s"
    _a[${#_a[@]}]="$s1"

    eval "declare -A -g -- $s=()"

  else

    s=${_h[$s1]}

  fi

  ## TODO '$1' checking required
  eval "ini.section.set() { $s[\$1]="\$2"; }; ini.section.get() { echo "\${$s[\$1]}"; };"

}
#******
#****f* libtst/ini.section.show
#  SYNOPSIS
#    ini.section.show <section>
#  DESCRIPTION
#    show the contents of the specified section
#  ARGUMENTS
#    <section> - section name, default - unnamed section
#  OUTPUT
#    the contents (must be empty) of the specified section with name
#  EXAMPLE
#  SOURCE
ini.section.show() {

  local i iC s=$1 sA sU

  : ${s:=__global__}

  ini.section.select $s

  s=${_h[$s]}
  sU=$( ini.section.get __unnamed_mod )
  [[ $sU == '!' ]] && sA=':' || sA=

  eval "ini.section.show.pairs()   { local i; for i in "\${!$s[@]}"; do [[ \$i =~ ^__unnamed_     ]] || printf -- '\t%s\t = %s\n' \"\$i\" \"\${$s[\$i]}\"; done; };"
  eval "ini.section.show.unnamed() { local i; for i in "\${!$s[@]}"; do [[ \$i =~ ^__unnamed_key= ]] && printf -- '%s\n' \"\${$s[\$i]}\"; done; };"

  [[ $1 ]] && printf "\n\n[ %s ]%s\n\n" "$1" "$sA" || echo ""

  if   [[ $sU == "@" ]]; then

    ini.section.show.unnamed

  else

    iC=$( ini.section.get __unnamed_cnt )
    if udfIsNumber $iC && (( iC > 0 )); then

      for (( i=0; i < $iC; i++ )); do

        ini.section.get "__unnamed_idx=$i"

      done

    else

      ini.section.show.pairs

    fi

  fi

  [[ $sA ]] && printf "\n%s[ %s ]\n" "$sA" "$1"

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
#   ini.read $ini                                                               #? true
#   ini.show
#   declare -p _h
##    for s in "${!_h[@]}"; do                                                  #-
##      [[ $s == '__id__' ]] && continue                                        #-
##      echo "section ${s}:"
##      eval "declare -p ${_h[$s]}"
##    done                                                                      #-
#  SOURCE
ini.read() {

  udfOn NoSuchFileOrDir throw $1

  local bActiveSection bIgnore csv fn i reComment reRawMode reSection reValidSections s

  reSection='^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
  reKey_Val='^[[:space:]]*([[:alnum:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
  reComment='^[[:space:]]*$|(^|[[:space:]]+)[\#\;].*$'
  reRawMode='^[=\-+]$'

  s="__global__"
  fn="$1"

  [[ $2 ]] && reValidSections="$2" || reValidSections="$reSection"
  [[ ${hKeyValue[@]} ]] || local -A hKeyValue
  [[ ${hRawMode[@]}  ]] || local -A hRawMode
  [[ ${_h[@]}        ]] || ini.section.init

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
      [[ $bActiveSection == "close" ]] && bActiveSection= && ini.section.set __unnamed_mod "!" && continue
      bIgnore=

      ini.section.select "$s"

      if [[ ${hRawMode[$s]} ]]; then

       i=$( ini.section.get __unnamed_cnt )

       if ! udfIsNumber $i; then

         i=0
         ini.section.set __unnamed_cnt $i

       fi

       [[ ${hRawMode[$s]} =~ ^(\+|=)$ ]] || i=0
       [[ ${hRawMode[$s]} =~ ^=$ ]] && ini.section.set __unnamed_mod "@"

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
#****f* libtst/ini.load
#  SYNOPSIS
#    ini.load <file> <section>:(<options>)|<raw mode>) ...
#  DESCRIPTION
#    load the specified parameters from a group of related INI files
#  ARGUMENTS
#    <file>     - the final configuration file. Based on of his name may be
#                 pre-loaded the parent files of the configuration
#    <section>  - section name, by default is empty for global section
#    <options>  - comma separated list of the options for loading. Required or
#                 replaced by <raw mode specs>
#    <raw mode> - specifiers '-=+' define the section of the store as a list of
#                 the "raw" data:
#                 - - replace early load data of the section
#                 + - add data to the early loaded data of the section
#                 = - add only unique data of the early loaded data
#  RETURN VALUE
#    NoSuchFileOrDir - input file not exist
#    MissingArgument - parameters and sections are not selected
#  EXAMPLE
#   local iniMain iniLoad iniSave s S sRules                                    #-
#   sRules=':file,main,child exec:- main:hint,msg,cnt replace:- unify:= acc:+'  #-
#   udfMakeTemp -v iniMain suffix=.ini                                          #-
#    cat <<-'EOFini' > $iniMain                                                 #-
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
#[acc]                                                                          #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#                                                                               #-
#    EOFini                                                                     #-
#    iniLoad="${iniMain%/*}/child.${iniMain##*/}"                               #-
#    iniSave="${iniMain%/*}/write.${iniMain##*/}"                               #-
#    udfAddFile2Clean $iniLoad                                                  #-
#    cat <<-'EOFiniChild' > $iniLoad                                            #-
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
#[acc]                                                                          #-
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
#   ini.load $iniLoad $sRules                                                   #? true
#   ini.save $iniSave                                                           #? true
#   declare -p _a
#   declare -p _h
#   ini.show
##    for s in "${!_h[@]}"; do                                                   #-
##      [[ $s == '__id__' ]] && continue                                         #-
##      echo "section ${s}:"
##      eval "declare -p ${_h[$s]}"
##    done                                                                       #-
#  SOURCE
ini.load() {

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

#  {
#   declare -p hRawMode
#   declare -p hKeyValue
#   echo $reValidSections
#  } > /tmp/hashes.log

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
#    ini.bind.cli [<section>-]<option long name>{<short name>}[:<extra>] ...
#  DESCRIPTION
#    Bind command line options to the structure of the configuration INI
#  ARGUMENTS
#    <option name> - option name that used as long option of the CLI and key for
#                    array of the INI data
#    <section>     - part of the option name for binding it to a certain section
#                    of the INI data. By default, it is assumed that option is
#                    included to the global section
#    <short name>  - short alias as single letter for option name
#    <extra>       - Additional configuration options for specifying arguments:
#                    :     - an optional argument
#                    [=-+] - option is to store the data list, binded to the
#                            eponymous section of the INI data
#                    by default, the option is expected to have a required
#                    argument and is included in the global section of the INI
#                    data
#  RETURN VALUE
#    MissingArgument - arguments is not specified
#  EXAMPLE
#    local sRules
#    sRules='file{F}: exec{E}:- main-hint{H}: main-msg{M}: unify{U}:= acc:+'    #-
#    _ sArg "-F CLI -E clear -H 'Hi!' -M test -U a.2 -U a.2 --acc=a --acc=b"    #-
#    ini.bind.cli $sRules                                                       #? true
#    declare -p _h
#    ini.show
##    for s in "${!_h[@]}"; do                                                  #-
##      [[ $s == '__id__' ]] && continue                                        #-
##      echo "section ${s}:"
##      eval "declare -p ${_h[$s]}"
##    done                                                                      #-
#
#  SOURCE
ini.bind.cli() {

  udfOn MissingArgument "$@" || return $?

  local -a a
  local fmtCase fmHandler k sSection sShort sLong sArg s S sHandler sCases v

  [[ ${_h[@]} ]] || ini.section.init

  fmtHandler='udfHandleGetopt() { while true; do case $1 in %s --) shift; break;; esac; done }'
  fmtCase='--%s%s) ini.section.add "%s" "%s" "%s"; shift %s;;'

  for s in $@; do

    if [[ $s =~ (([[:alnum:]]+)(-))?(@|[[:alnum:]]+)(\{([[:alnum:]])\})?([:])?([:=\+\-])? ]]; then

      s=$( declare -p BASH_REMATCH )
      eval "${s/-ar BASH_REMATCH/-a a}"

    else

      eval $( udfOnError throw InvalidArgument "$s - format error" )

    fi

    s=;S=;v=1;sSection="${a[2]}";k="${a[4]}"

    [[ ${a[4]} ]] && sLong+="${a[4]}${a[7]},"
    [[ ${a[6]} ]] && sShort+="${a[6]}${a[7]}" && s="|-${a[6]}"
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
#****f* libtst/ini.show
#  SYNOPSIS
#    ini.show
#  DESCRIPTION
#    Show the current state of the configuration data
#  EXAMPLE
#  SOURCE
ini.show() {

  ini.section.show

  for s in ${_a[@]}; do

    [[ $s =~ ^(__global__|__id__)$ ]] && continue
    ini.section.show "$s"

  done

  printf -- "\n"

}
#******
#****f* libtst/ini.save
#  SYNOPSIS
#    ini.save <file>
#  DESCRIPTION
#    Save the current state of the configuration data to the specified file
#  ARGUMENTS
#    <file> - target file for saving, full path required
#  RETURN VALUE
#    MissingArgument    - the file name is not specified
#    NotExistNotCreated - the target file is not created
#  EXAMPLE
#  SOURCE
ini.save() {

  udfOn MissingArgument throw $1

  local fn
  fn=$1

  ## TODO backup previous version if exist
  mkdir -p ${fn%/*} && touch $fn || eval $( udfOnError throw NotExistNotCreated "${fn%/*}" )

  {

    printf ';\n; created %s by %s\n;\n' "$(date -R)" "$( _ sUser)"
    ini.show

  } > $fn

  return 0

}
#******
