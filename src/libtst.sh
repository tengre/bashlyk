#
# $Id: libtst.sh 605 2016-11-29 17:24:53+04:00 toor $
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
__config.section.storage.show() {

  [[ ${1^^} =~ ^(CLI|INI)$ ]] && eval "echo \${_h${1^^}[${2:-@}]}" || return $( _ iErrorInvalidArgument )

}
#****f* libtst/__config.section.storage.free
#  SYNOPSIS
#    __config.section.storage.free cli|ini
#  DESCRIPTION
#    removing the resources associated with processing of the data configurations
#  RETURN VALUE
#    last unset status
#  EXAMPLE
#    local -A _hINI='( [__id__]="__id__" [test]="hI" )' hI='( [__id__]="__id__" )'
#    __config.section.storage.free ini                                          #? true
#    [[ ${_hINI[@]} ]]                                                          #? false
#    [[ ${hI[@]} ]]                                                             #? false
#  SOURCE
__config.section.storage.free() {

  local s

  for s in "$( __config.section.storage.show $1 )"; do

    [[ $s == '__id__' ]] && continue || unset -v $s

  done

  unset -v _a${1^^}
  unset -v _h${1^^}

}
#******
#****f* libtst/__config.section.storage.renew
#  SYNOPSIS
#    __config.section.storage.renew cli|ini
#  DESCRIPTION
#    preparing resources to handle the INI configurations
#  RETURN VALUE
#    declare status
#  EXAMPLE
#    local -A _hINI='( [__id__]="__id__" [test]="hI" )' hI='( [__id__]="__id__" )'
#    __config.section.storage.renew ini                                         #? true
#    [[ ${_hINI[@]} ]]                                                          #? true
#    [[ ${hI[@]} ]]                                                             #? false
#    __config.section.storage.free ini                                          #? true
#    [[ ${_hINI[@]} ]]                                                          #? false
#  SOURCE
__config.section.storage.renew() {

  [[ ${1^^} =~ ^(CLI|INI)$ ]] || eval $( udfOnError InvalidArgument '$1' )

  __config.section.storage.free $1

  declare -a -g -- _a${1^^}="()"
  declare -A -g -- _h${1^^}="( [__id__]=__id__ )"

}
#******
#****f* libtst/__config.section.storage.select
#  SYNOPSIS
#    __config.section.storage.select cli|ini <section>
#  DESCRIPTION
#    preparing resources to handle the selected section of the INI-file(s)
#  ARGUMENTS
#    section name
#  RETURN VALUE
#    last eval status
#  EXAMPLE
#    local s
#    __config.section.storage.renew ini                                         #? true
#    __config.section.storage.select ini test                                                     #? true
#    s=${_hINI[test]}
#    eval "declare -p $s" >| grep "declare.*2dc0f896fd7cb4cb0031ba249="         #? true
#    [[ ${hI[@]} ]]                                                             #? false
#    __config.section.storage.free ini                                          #? true
#    [[ ${_hINI[@]} ]]                                                          #? false
## TODO add tests for section.{get,set}
#  SOURCE
__config.section.storage.select() {

  [[ ${1^^} =~ ^(CLI|INI)$ ]] || eval $( udfOnError InvalidArgument '$1' )

  local s sS="${2:-__global__}"

  if [[ ! $( __config.section.storage.show $1 $2 ) ]]; then

    s=$(md5sum <<< "$sS")
    s="_h${1^^}_${s:0:32}"
    declare -A -g -- $s="()"

    eval "_h${1^^}[$sS]=$s; _a${1^^}[\${#_a${1^^}[@]}]=\"$sS\""

  else

    eval "s=\${_h${1^^}[$sS]}"

  fi

  ## TODO '$1' checking required
  eval "${1}.section.set() { $s[\$1]="\$2"; }; ${1}.section.get() { echo "\${$s[\$1]}"; };"

}
#******
#****f* libtst/config.section.show
#  SYNOPSIS
#    config.section.show cli|ini <section>
#  DESCRIPTION
#    show the contents of the specified section
#  ARGUMENTS
#    <section> - section name, default - unnamed section
#  OUTPUT
#    the contents (must be empty) of the specified section with name
#  EXAMPLE
#  SOURCE
config.section.show() {

  [[ $1 =~ ^(cli|ini)$ ]] || eval $( udfOnError InvalidArgument '$1' )

  local i iC s="${2:-__global__}" sA sU

  __config.section.storage.select $1 $s

  s=$( __config.section.storage.show $1 "$s" )

  sU=$( ${1}.section.get __unnamed_mod )
  [[ $sU == '!' ]] && sA=':' || sA=

  eval "${1}.section.show.pairs()   { local i; for i in "\${!$s[@]}"; do [[ \$i =~ ^__unnamed_     ]] || printf -- '\t%s\t = %s\n' \"\$i\" \"\${$s[\$i]}\"; done; };"
  eval "${1}.section.show.unnamed() { local i; for i in "\${!$s[@]}"; do [[ \$i =~ ^__unnamed_key= ]] && printf -- '%s\n' \"\${$s[\$i]}\"; done; };"

  [[ $2 ]] && printf "\n\n[ %s ]%s\n\n" "$2" "$sA" || echo ""

  if   [[ $sU == "@" ]]; then

    ${1}.section.show.unnamed

  else

    iC=$( ${1}.section.get __unnamed_cnt )
    if udfIsNumber $iC && (( iC > 0 )); then

      for (( i=0; i < $iC; i++ )); do

        ${1}.section.get "__unnamed_idx=$i"

      done

    else

      ${1}.section.show.pairs

    fi

  fi

  [[ $sA ]] && printf "\n%s[ %s ]\n" "$sA" "$2"

}
#******
#****f* libtst/config.show
#  SYNOPSIS
#    config.show cli|ini
#  DESCRIPTION
#    Show the current state of the configuration data
#  EXAMPLE
#  SOURCE
config.show() {

  [[ $1 =~ ^(cli|ini)$ ]] || eval $( udfOnError InvalidArgument '$1' )

  local sS

  eval "sS=\"\${_a${1^^}[@]}\""

  config.section.show $1

  for s in $sS; do

    [[ $s =~ ^(__global__|__id__)$ ]] && continue
    config.section.show $1 "$s"

  done

  printf -- "\n"

}
#******
#****f* libtst/config.save
#  SYNOPSIS
#    config.save cli|ini <file>
#  DESCRIPTION
#    Save the current state of the configuration data to the specified file
#  ARGUMENTS
#    <file> - target file for saving, full path required
#  RETURN VALUE
#    MissingArgument    - the file name is not specified
#    NotExistNotCreated - the target file is not created
#  EXAMPLE
#  SOURCE
config.save() {

  [[ $1 =~ ^(cli|ini)$ ]] || eval $( udfOnError InvalidArgument '$1' )
  udfOn MissingArgument throw "$2"

  local fn
  fn="$2"

  ## TODO backup previous version if exist
  mkdir -p ${fn%/*} && touch $fn || eval $( udfOnError throw NotExistNotCreated "${fn%/*}" )

  {

    printf ';\n; created %s by %s\n;\n' "$(date -R)" "$( _ sUser )"
    config.show $1

  } > $fn

  return 0

}
#******
#****f* libtst/cli.section.raw
#  SYNOPSIS
#    cli.section.raw <raw mode> <data>
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
cli.section.raw() {

  local i s

  i=$( cli.section.get __unnamed_cnt )
  udfIsNumber $i || i=0

  case "$1" in

    =)

       s="${2##*( )}"
       s="${s%%*( )}"
       cli.section.set "__unnamed_key=${s//[\'\"\\]/}" "$s"
       cli.section.set "__unnamed_mod" "@"

    ;;

    -|+)

       cli.section.set "__unnamed_idx=${i}" "$2"
       : $(( i++ ))

    ;;

    *)

      return $( _ iErrorInvalidArgument )

  esac

  [[ $1 == = ]] && cli.section.set __unnamed_mod '@' || cli.section.set __unnamed_cnt $i

  return 0

}
#******
#  SYNOPSIS
#    cli.section.add <section> <key> <value>
#  DESCRIPTION
#    add or update key-value pair to storage of the CLI options
#  ARGUMENTS
#    <section> - correspondent section to the INI-configuration
#    <key>     - named key for "key=value" pair of the input data. For unnamed
#                records this argument must be the sign of the method of raw
#                data handling:
#                '-', '+' - add new records with key incrementing
#                '='      - add new unique record only
#    <value>   - "value" part of the "key=value" pair or full "raw" inputs
#  RETURN VALUE
#    Success always
#  EXAMPLE
#  SOURCE
cli.section.add() {

  [[ $2 ]] || return 0

  local s="$1"

  #cli.section.select "${s:=__global__}"
  __config.section.storage.select cli "${s:=__global__}"

  if [[ $2 =~ ^[\-\+=]$ ]]; then

    cli.section.raw "$2" "$3"

  else

    cli.section.set "$2" "$3"

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
#   config.show ini
#   declare -p _hINI
#    for s in "${!_hINI[@]}"; do                                                #-
#      [[ $s == '__id__' ]] && continue                                         #-
#      echo "section ${s}:"
#      eval "declare -p ${_hINI[$s]}"
#    done                                                                       #-
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
  [[ ${_hINI[@]}     ]] || __config.section.storage.renew ini

  if [[ ! $( stat -c %U $fn ) == $( _ sUser ) ]]; then

    eval $( udfOnError NotPermitted throw "$1 owned by $( stat -c %U $fn )" )

  fi

  i=0
  bIgnore=

  [[ ${hKeyValue[$s]} ]] || hKeyValue[$s]="$reKey_Val"

  __config.section.storage.select ini "$s"

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

      __config.section.storage.select ini "$s"

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
#   GLOBIGNORE="*:?"
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
#   declare -p _aINI
#   declare -p _hINI
#   config.show ini
#    for s in "${!_hINI[@]}"; do                                                #-
#      [[ $s == '__id__' ]] && continue                                         #-
#      echo "section ${s}:"
#      eval "declare -p ${_hINI[$s]}"
#    done                                                                       #-
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

    __config.section.storage.select ini "$sSection"
    csv+="${sSection}|"

  done

  csv=${csv%*|}

  [[ $csv ]] && reValidSections=${fmtSections/\%SECTION\%/$csv}

  {
   declare -p hRawMode
   declare -p hKeyValue
   echo $reValidSections
  } >> /tmp/hashes.log

  ## TODO init hash per section here
  __config.section.storage.renew ini

  for (( i = ${#a[@]}-1; i >= 0; i-- )); do

    [[ ${a[i]} ]] || continue
    [[ $ini    ]] && ini="${a[i]}.${ini}" || ini="${a[i]}"
    [[ -s "${path}/${ini}" ]] && ini.read "${path}/${ini}" "$reValidSections"

  done

  if [[ ${_hCLI[@]} ]]; then

    udfMakeTemp ini

    config.save cli $ini
    ini.read $ini "$reValidSections"

    rm -f $ini

  fi

  return 0

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
#    local rINI rCLI ini
#    rINI=':file,main,child exec:- main:hint,msg,cnt replace:- unify:= acc:+'   #-
#    rCLI='file{F}: exec{E}:- main-hint{H}: main-msg{M}: unify{U}:= acc:+'      #-
#    _ sArg "-F CLI -E clear -H 'Hi!' -M test -U a.2 -U a.2 --acc=a --acc=b"    #-
#    udfMakeTemp ini
#    ini.save $ini                                                              #? true
#    ini.bind.cli $rCLI                                                         #? true
#    ini.load $ini $rINI                                                        #? true
#    declare -p _hCLI
#    config.show cli
#    config.show ini
#    for s in "${!_hCLI[@]}"; do                                                #-
#      [[ $s == '__id__' ]] && continue                                         #-
#      echo "section ${s}:"
#      eval "declare -p ${_hCLI[$s]}"
#    done                                                                       #-
#
#  SOURCE
ini.bind.cli() {

  udfOn MissingArgument "$@" || return $?

  local -a a
  local fmtCase fmHandler k sSection sShort sLong sArg s S sHandler sCases v

  __config.section.storage.renew cli

  fmtHandler='udfHandleGetopt() { while true; do case $1 in %s --) shift; break;; esac; done }'
  fmtCase='--%s%s) cli.section.add "%s" "%s" "%s"; shift %s;;'

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

  echo $sHandler
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

  config.save ini $1

}
#******
