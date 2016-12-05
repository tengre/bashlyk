#
# $Id: libcfg.sh 612 2016-12-06 00:28:26+04:00 toor $
#
#****h* BASHLYK/libcfg
#  DESCRIPTION
#    template for testing
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libcfg/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'

[[ $_BASHLYK_libcfg ]] && return 0 || _BASHLYK_libcfg=1
#******
#declare -g -A _h
#****** libcfg/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
#******
#****v* libcfg/Init section
#  DESCRIPTION
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_envXSession:=}
: ${_bashlyk_aRequiredCmd_msg:="getopt stat"}
: ${_bashlyk_aExport_msg:="ini.cli.bind ini.load ini.read ini.save ini.show"}
#******
#****f* libcfg/cfg.new
#  SYNOPSIS
#    cfg.new <id>
#  DESCRIPTION
#    instance new INI object
#  ARGUMENTS
#    valid variable name
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    cfg.new test #? true
#  SOURCE
cfg.new() {

  udfOn InvalidVariable throw "$1"

  local a o s f

  o=$1
  a="section.id section.select section.show section.raw section.add get show save read load cli.bind"

  for s in $a; do

    f=$( declare -pf cfg.${s} )

    [[ $f =~ ^(cfg.${s}).\(\) ]] || eval $( udfOnError throw InvalidArgument "not instance $s method for $o object" )
    f=${f/${BASH_REMATCH[1]}/${o}.$s}

    eval "$f"

  done

  declare -a -g -- _a${o^^}="()"
  declare -A -g -- _h${o^^}="([__id__]=__id__)"

  return 0

}
#******
#****f* libcfg/cfg.section.id
#  SYNOPSIS
#    cfg.section.id [<section>]
#  DESCRIPTION
#    get a hash name for specified section or all hashes from INI or CLI storage
#  ARGUMENTS
#    section - section name, default - all hashes
#  OUTPUT
#    hash name{s}
#  EXAMPLE
#    cfg.new ini
#    cfg.new cli
#    ini.section.id >| grep '__id__'                                            #? true
#    cli.section.id >| grep '__id__'                                            #? true
#    cfg.free ini
#    cfg.free cli
#  SOURCE
cfg.section.id() {

  local o=${FUNCNAME[0]%%.*}

  eval "echo \${_h${o^^}[${1:-@}]}"

}
#******
#****f* libcfg/cfg.free
#  SYNOPSIS
#    cfg.free <db>
#  DESCRIPTION
#    remove the storage associated with the configuration
#  ARGUMENTS
#    <db> - storage for INI options
#  EXAMPLE
#    local -A _hINI='([__id__]="__id__" [i]="_hINI_i")' _hINI_i='([__id__]="__id__")'
#    local -A _hCLI='([__id__]="__id__" [c]="_hCLI_c")' _hCLI_c='([__id__]="__id__")'
#    [[ ${_hINI[@]} && ${_hINI_i[@]} && ${_hCLI[@]} && ${_hCLI_c[@]} ]]         #? true
#    cfg.free ini                                                               #? true
#    cfg.free cli                                                               #? true
#    [[ ${_hINI[@]} || ${_hINI_i[@]} || ${_hCLI[@]} || ${_hCLI_c[@]} ]]         #? false
#  SOURCE
cfg.free() {

  local o=${1:-CFG} s

  for s in "$( ${o}.section.id )"; do

    [[ $s == '__id__' ]] && continue || unset -v $s

  done

  unset -v _a${o^^}
  unset -v _h${o^^}

}
#******
#****f* libcfg/cfg.section.select
#  SYNOPSIS
#    cfg.section.select [<section>]
#  DESCRIPTION
#    select a section of the storage  for the processing
#  ARGUMENTS
#    section - section name, default - unnamed global
#  RETURN VALUE
#    InvalidArgument - not valid first argument, expected CLI or INI
#  EXAMPLE
#    local s
#    cfg.new CNF
#    CNF.section.select                                                         #? true
#    s=$(CNF.section.id __global__)
#    echo "hash $s"
#    declare -pf CNF.$s.set
#    declare -pf CNF.$s.get
#    declare -p _hCNF
#    CNF.section.select test                                                    #? true
#    s=$( CNF.section.id test  )
#    eval "declare -p $s" >| grep "declare.*2dc0f896fd7cb4cb0031ba249="         #? true
#    cfg.free CNF
#  SOURCE
cfg.section.select() {

  local id o s=${1:-__global__}

  o=${FUNCNAME[0]%%.*}
  eval "id=\${_h${o^^}[$s]}"

  echo "dbg0 -- $id" >> /tmp/o.log
  if [[ ! $id ]]; then

    ! eval "(( \${#_h${o^^}[@]} > 0 )) || declare -A -g -- _h${o^^}='([__id__]=__id__)'"
    id=$(md5sum <<< "$s")
    id="_h${o^^}_${id:0:32}"
    declare -A -g -- $id="()"

    eval "_h${o^^}[$s]=$id; _a${o^^}[\${#_a${o^^}[@]}]=\"$s\""
    eval "${o}.${id}.set() { [[ \$1 ]] && $id[\$1]="\$2"; }; ${o}.${id}.get() { [[ \$1 ]] && echo "\${$id[\$1]}"; };"
    eval "${o}.${id}.show.pairs()   { local i; for i in "\${!$id[@]}"; do [[ \$i =~ ^__unnamed_     ]] || printf -- '\t%s\t = %s\n' \"\$i\" \"\${$id[\$i]}\"; done; };"
    eval "${o}.${id}.show.unnamed() { local i; for i in "\${!$id[@]}"; do [[ \$i =~ ^__unnamed_key= ]] && printf -- '%s\n' \"\${$id[\$i]}\"; done; };"

    echo "dbg1 -- $id" >> /tmp/o.log
  fi

  echo "dbg ${FUNCNAME[1]} :: $*" >> /tmp/o.log
  declare -pf ${o}.${id}.set >> /tmp/o.log
  declare -p _h${o^^} >> /tmp/o.log
  declare -p $id >> /tmp/o.log
  #echo $id

}
#******
#****f* libcfg/cfg.section.show
#  SYNOPSIS
#    cfg.section.show [<section>]
#  DESCRIPTION
#    show the contents of the specified section of the configuration
#  ARGUMENTS
#    <section> - section name, default - unnamed section
#  OUTPUT
#    the contents (must be empty) of the specified section with name
#  EXAMPLE
#    local id
#    cfg.new conf
#    conf.section.select section
#    conf.$(conf.section.id section).set key "is value"
#    conf.section.show section >| md5sum - | grep ^9134a91b84725c7357c6f0aa12d5ef71.*-$ #? true
#    conf.section.select
#    conf.$(conf.section.id __global__).set key "unnamed section"
#    conf.section.show >| md5sum - | grep ^33098f129cdfa322a2bd326a56bb4f0b.*-$ #? true
#    cfg.free conf
#  SOURCE
cfg.section.show() {

  local i iC id o s=${1:-__global__} sA sU

  o=${FUNCNAME[0]%%.*}

  ${o}.section.select $s
  id=$( ${o}.section.id $s )

  sU=$( ${o}.${id}.get __unnamed_mod )

  [[ $sU == '!' ]] && sA=':' || sA=
  [[ $1 ]] && printf "\n\n[ %s ]%s\n\n" "$1" "$sA" || echo ""

  if [[ $sU == "=" ]]; then

    ${o}.${id}.show.unnamed

  else

    iC=$( ${o}.${id}.get __unnamed_cnt )

    if udfIsNumber $iC && (( iC > 0 )); then

      for (( i=0; i < $iC; i++ )); do

        ${o}.${id}.get "__unnamed_idx=$i"

      done

    else

      ${o}.${id}.show.pairs

    fi

  fi

  [[ $sA ]] && printf "\n%s[ %s ]\n" "$sA" "$2"

}
#******
#****f* libcfg/cfg.section.raw
#  SYNOPSIS
#    cfg.section.raw <raw mode> <data>
#  DESCRIPTION
#    add or update unnamed record of the "raw" data for early selected section
#  ARGUMENTS
#    <raw mode> - the signs of the method of raw data handling:
#                 '-', '+' - add new records with key incrementing
#                 '='      - add new unique record only
#    <data>     - "raw" data, no as "key=value" pairs
#  RETURN VALUE
#    InvalidArgument - unexpected "raw" mode
#    Success for other cases
#  EXAMPLE
#  SOURCE
cfg.section.raw() {

  local a i s

  a=( ${FUNCNAME[0]//./ } )

  case "$1" in

    =)

       s="${2##*( )}"
       s="${s%%*( )}"
       ${a[0]}.${a[1]}.set "__unnamed_key=${s//[\'\"\\ ]/}" "$s"
       ${a[0]}.${a[1]}.set '__unnamed_mod' "="

    ;;

    -|+)

       i=$( ${a[0]}.${a[1]}.get __unnamed_cnt )
       udfIsNumber $i || i=0
       ${a[0]}.${a[1]}.set "__unnamed_idx=${i}" "$2"
       : $(( i++ ))
       ${a[0]}.${a[1]}.set '__unnamed_cnt' $i

    ;;

    *)

      return $( _ iErrorInvalidArgument )

  esac

  return 0

}
#******
#****f* libcfg/cfg.section.add
#  SYNOPSIS
#    cfg.section.add <section> <key> <value>
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
cfg.section.add() {

  udfOn MissingArgument $2 || return $?

  local a id o
  o=${FUNCNAME[0]%%.*}

  ${o}.section.select ${1:-__global__}
  id=$( ${o}.section.id ${1:-__global__} )

  if [[ $2 =~ ^[\-\+=]$ ]]; then

    ${o}.${id}.raw "$2" "$3"

  else

    ${o}.${id}.set "$2" "$3"

  fi

}
#******
udfIsHash() {

  udfOn InvalidVariable $1 || return $?
  [[ $( declare -p $1 2>/dev/null ) =~ ^declare ]] && return 0 || return $( _ iErrorInvalidHash )

}
#****f* libcfg/cfg.section.getarray
#  SYNOPSIS
#    cfg.section.getarray [<section>]
#  DESCRIPTION
#    get value(s) for specified key of the section of the configuration
#  ARGUMENTS
#    <section> - correspondent section to the configuration, default - unnamed
#  RETURN VALUE
#    MissingArgument - arguments not found
#    Success in other cases
#  EXAMPLE
#    local id
#    cfg.new ini
#    ini.section.select sect1
#    id=$(ini.section.id sect1)
#    ini.${id}.set __unnamed_cnt 3
#    ini.${id}.set __unnamed_idx=0 "is raw value No.1"
#    ini.${id}.set __unnamed_idx=1 "is raw value No.2"
#    ini.${id}.set __unnamed_idx=2 "is raw value No.3"
#    ini.section.select sect2
#    id=$(ini.section.id sect2)
#    ini.${id}.set __unnamed_mod =
#    ini.${id}.set '__unnamed_key=a1' "is raw value No.1"
#    ini.${id}.set '__unnamed_key=b2' "is raw value No.2"
#    ini.${id}.set '__unnamed_key=a1' "is raw value No.3"
#    ini.section.getarray sect1 >| md5sum - | grep ^9cb6e1559552.*3d7417b.*-$ #? true
#    ini.section.getarray sect2 >| md5sum - | grep ^9c964b5b47f6.*82a6d4e.*-$ #? true
#    cfg.free ini
#  SOURCE
ini.section.getarray() {

  local -a a
  local id iC o sU s

  o=${FUNCNAME[0]%%.*}
  ${o}.section.select ${1:-__global__}
  id=$( ${o}.section.id ${1:-__global__} )

  udfIsHash $id || eval $( udfOnError InvalidHash '$id' )

  sU=$( ${o}.${id}.get __unnamed_mod )

  if [[ $sU == "=" ]]; then

    eval "${o}.${id}.getarray.unnamed.keys() { local i; for i in "\${!$id[@]}"; do [[ \$i =~ ^__unnamed_key= ]] && a[\${#a[@]}]=\"\${$id[\$i]}\"; done; };"
    ${o}.${id}.getarray.unnamed.keys

  else

    iC=$( ${o}.${id}.get __unnamed_cnt )
    if udfIsNumber $iC && (( iC )); then

      eval "${o}.${id}.getarray.unnamed.idxs() { local i; for (( i=0; i < $iC; i++ )); do a[\${#a[@]}]=\"\${$id[__unnamed_idx=\$i]}\"; done; };"
      ${o}.${id}.getarray.unnamed.idxs

    fi

  fi

  (( ${#a[@]} > 0 )) && declare -p a

}
#******
#****f* libcfg/cfg.get
#  SYNOPSIS
#    cfg.get [<section>]<key>
#  DESCRIPTION
#    get value(s) for specified key of the section of the configuration
#  ARGUMENTS
#    <section> - correspondent section to the configuration, default - unnamed
#    <key>     - named key for "key=value" pair of the input data. For unnamed
#                records this argument must be supressed, this cases return
#                serialized array of items
#  RETURN VALUE
#    MissingArgument - arguments not found
#    InvalidArgument - expected like a 'cli[section]key', 'cli[]key', 'key'
#    Success in other cases
#  EXAMPLE
#    local id
#    cfg.new ini
#    ini.section.select
#    ini.$(ini.section.id __global__).set key "is unnamed section"
#    ini.section.select section
#    ini.$(ini.section.id section).set key "is value"
##    ini.section.select section
#    ini.get [section]key >| grep '^is value$'                                  #? true
#    ini.section.select section
#    ini.get      key >| grep '^is unnamed section$'                            #? true
#    ini.get    []key >| grep '^is unnamed section$'                            #? true
#    ini.section.select section1
#    id=$(ini.section.id section1)
#    ini.${id}.set __unnamed_cnt 3
#    ini.${id}.set __unnamed_idx=0 "is raw value No.1"
#    ini.${id}.set __unnamed_idx=1 "is raw value No.2"
#    ini.${id}.set __unnamed_idx=2 "is raw value No.3"
#    ini.section.select section2
#    id=$(ini.section.id section2)
#    ini.${id}.set __unnamed_mod =
#    ini.${id}.set __unnamed_key=a1 "is raw value No.1"
#    ini.${id}.set __unnamed_key=b2 "is raw value No.2"
#    ini.${id}.set __unnamed_key=a1 "is raw value No.3"
#    ini.get [section2] >| md5sum -    | grep ^9c964b5b47f6dc.*82a6d4e.*-$      #? true
#    ini.get [section1] >| md5sum -    | grep ^9cb6e155955235.*3d7417b.*-$      #? true
#    cfg.free ini
#  SOURCE
cfg.get() {

  udfOn MissingArgument $* || return $?

  local -a a
  local o k s v IFS

  o=${FUNCNAME[0]%%.*}

  IFS='[]' && a=( $* ) && IFS=$' \t\n'

  case "${#a[@]}" in

    2|3)
      s=${a[0]:-__global__}
      k="${a[1]:-__unnamed_}"
      ;;

    0|1)
      s=__global__
      k="${a[0]:-__unnamed_}"
      ;;

    *)
      eval $( udfOnError throw InvalidArgument "$*" )

  esac

  if [[ $k =~ __unnamed_ ]]; then

    ${o}.section.getarray $s

  else

    ${o}.section.select $s
    $o.$(${o}.section.id $s).get "$k"

  fi

}
#******
#****f* libcfg/cfg.show
#  SYNOPSIS
#    cfg.show
#  DESCRIPTION
#    Show a configuration in the INI format
#  OUTPUT
#    configuration in the INI format
#  EXAMPLE
#    local s
#    cfg.new ini
#    ini.section.select section
#    ini.$(ini.section.id section).set key "is value"
#    ini.section.select
#    ini.$(ini.section.id __global__).set key "unnamed section"
#    ini.show >| md5sum - | grep ^5a67839daaa52b9c5dbd135daaad313e.*-$          #? true
#    cfg.free ini
#  SOURCE
cfg.show() {

  local o s

  o=${FUNCNAME[0]%%.*}

  ${o}.section.show

  for s in $( ${o}.section.id ); do

    [[ $s =~ ^(__global__|__id__)$ ]] && continue
    ${o}.section.show $s

  done

  printf -- "\n"

}
#******
#****f* libcfg/cfg.save
#  SYNOPSIS
#    cfg.save <file>
#  DESCRIPTION
#    Save the configuration to the specified file in the INI format
#  ARGUMENTS
#    <file>  - target file for saving, full path required
#  RETURN VALUE
#    MissingArgument    - the file name is not specified
#    NotExistNotCreated - the target file is not created
#  EXAMPLE
#    local fn
#    udfMakeTemp fn
#    cfg.new ini
#    ini.$(ini.section.select section).set key "is value"
#    ini.$(ini.section.select).set key "unnamed section"
#    cfg.save $fn
#    cfg.free ini
#    tail -n +4 $fn >| md5sum - | grep ^5a67839daaa52b9c5dbd135daaad313e.*-$    #? true
#  SOURCE
cfg.save() {

  udfOn MissingArgument throw "$1"

  local fn o

  fn="$1"
  o=${FUNCNAME[0]%%.*}

  [[ -s $fn ]] && mv $fn ${fn}.bak
  mkdir -p ${fn%/*} && touch $fn || eval $( udfOnError throw NotExistNotCreated "${fn%/*}" )

  {

    printf ';\n; created %s by %s\n;\n' "$(date -R)" "$( _ sUser )"
    ${o}.show

  } > $fn

  return 0

}
#******
#****f* libcfg/cfg.read
#  SYNOPSIS
#    cfg.read args
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
#   cfg.new ini
#   ini.read $ini                                                               #? true
#   ini.show >| md5sum - | grep ^a7d5fb1f4425f6a74154addf5801ee4b.*-$           #? true
#   declare -p _hINI >| md5sum - | grep ^c5d33e3b1b3cccf9b32ae2d41ee3b8c3.*-$   #? true
#    for s in "${!_hINI[@]}"; do                                                #-
#      [[ $s == '__id__' ]] && continue                                         #-
#      echo "section ${s}:"
#      eval "declare -p ${_hINI[$s]}"
#    done                                                                       #-
#   cfg.free ini
#  SOURCE
cfg.read() {

  udfOn NoSuchFileOrDir throw $1

  local bActiveSection bIgnore csv fn i reComment reRawMode reSection reValidSections s

  reSection='^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
  reKey_Val='^[[:space:]]*([[:alnum:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
  reComment='^[[:space:]]*$|(^|[[:space:]]+)[\#\;].*$'
  reRawMode='^[=\-+]$'

  s="__global__"
  fn="$1"

  [[ $2 ]] && reValidSections="$2" || reValidSections="$reSection"
  [[ ${hKeyValue[@]}      ]] || local -A hKeyValue
  [[ ${hRawMode[@]}       ]] || local -A hRawMode
  [[ $( ${o}.section.id ) ]] || cfg.new $o

  if [[ ! $( stat -c %U $fn ) == $( _ sUser ) ]]; then

    eval $( udfOnError NotPermitted throw "$1 owned by $( stat -c %U $fn )" )

  fi

  bIgnore=

  [[ ${hKeyValue[$s]} ]] || hKeyValue[$s]="$reKey_Val"

  ${o}.section.select
  id=$( ${o}.section.id __global__ )

  while read -t 4; do

    if [[ $REPLY =~ $reSection ]]; then

      bIgnore=1
      [[ $REPLY =~ $reValidSections ]] || continue
      bIgnore=

      s="${BASH_REMATCH[2]}"

      [[ ${BASH_REMATCH[1]} == ":" ]] && bActiveSection=close
      [[ ${BASH_REMATCH[3]} == ":" ]] && hRawMode[$s]="-"

      (( i > 0 )) && ${o}.${id}.set __unnamed_cnt $i

      bIgnore=1
      [[ $bActiveSection == "close" ]] && bActiveSection= && ${o}.${id}.set __unnamed_mod "!" && continue
      bIgnore=

      ${o}.section.select $s
      id=$( ${o}.section.id $s )
      i=0
      case "${hRawMode[$s]}" in

        -) ;;

        +) i=$( ${o}.${id}.get __unnamed_cnt )
           udfIsNumber $i || ${o}.${id}.set __unnamed_cnt ${i:=0}
           ;;

        =) ${o}.${id}.set __unnamed_mod "=";;

        *) hKeyValue[$s]="$reKey_Val";;

      esac

      continue

    else

      [[ $REPLY =~ $reComment || $bIgnore ]] && continue

    fi

    if [[ ${hKeyValue[$s]} ]]; then

      [[ $REPLY =~ ${hKeyValue[$s]} ]] && ${o}.${id}.set "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"

    else

      if [[ ${hRawMode[$s]} == "=" ]]; then

        REPLY=${REPLY##*( )}
        REPLY=${REPLY%%*( )}
        ${o}.${id}.set "__unnamed_key=${REPLY//[\'\"\\ ]/}" "$REPLY"

      else

        ${o}.${id}.set "__unnamed_idx=${i:=0}" "$REPLY"
        : $(( i++ ))

      fi

    fi

  done < $fn

  [[ ${hRawMode[$s]} =~ ^(\+|\-)$ ]] && ${o}.${id}.set __unnamed_cnt ${i:=0}

  return 0

}
#******
#****f* libcfg/cfg.load
#  SYNOPSIS
#    cfg.load <file> <section>:(<options>)|<raw mode>) ...
#  DESCRIPTION
#    load the specified parameters from a group of related INI files
#  ARGUMENTS
#    <file>     - the final configuration file. Based on of his name may be
#                 pre-loaded the parent files of the configuration
#    <section>  - section name, by default is empty for global section
#    <options>  - comma separated list of the options for loading. Required or
#                 replaced by <raw mode> argument
#    <raw mode> - specifiers '-=+' define the section of the store as a list of
#                 the "raw" data (without keys):
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
#   cfg.new ini
#   ini.load $iniLoad $sRules                                                   #? true
#   ini.save $iniSave                                                           #? true
#   declare -p _aINI
#   declare -p _hINI
#   ini.show >| md5sum - | grep ^5a8cdc4d2dbb5cb169cc857603179217.*-$           #? true
#    for s in "${!_hINI[@]}"; do                                                #-
#      [[ $s == '__id__' ]] && continue                                         #-
#      echo "section ${s}:"
#      eval "declare -p ${_hINI[$s]}"
#    done                                                                       #-
#    cfg.free ini
#  SOURCE
cfg.load() {

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $2

  local -a a
  local -A h hKeyValue hRawMode
  local csv i ini fmtKeyValue fmtSections o path reSection reValidSections s sSection

  o=${FUNCNAME[0]%%.*}
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

    ${o}.section.select $sSection
    csv+="${sSection}|"

  done

  csv=${csv%*|}

  [[ $csv ]] && reValidSections=${fmtSections/\%SECTION\%/$csv}

  for (( i = ${#a[@]}-1; i >= 0; i-- )); do

    [[ ${a[i]} ]] || continue
    [[ $ini    ]] && ini="${a[i]}.${ini}" || ini="${a[i]}"
    [[ -s "${path}/${ini}" ]] && ${o}.read "${path}/${ini}" "$reValidSections"

  done

  if [[ $( cli.section.id ) ]]; then

    udfMakeTemp ini

    cli.save $ini
    ${o}.read $ini "$reValidSections"

    rm -f $ini

  fi

  return 0

}
#******
#****f* libcfg/cfg.cli.bind
#  SYNOPSIS
#    cfg.cli.bind [<section>-]<option long name>{<short name>}[:<extra>] ...
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
#    cfg.new ini
#    ini.save $ini                                                              #? true
#    ini.cli.bind $rCLI                                                         #? true
#    ini.load $ini $rINI                                                        #? true
#    declare -p _hCLI
#    cli.show >| md5sum - | grep ^033a19e25672b2c703023b4da23e2efd.*-$          #? true
#    ini.show >| md5sum - | grep ^230af661227964498193dc3df7c63ece.*-$          #? true
#    for s in "${!_hCLI[@]}"; do                                                #-
#      [[ $s == '__id__' ]] && continue                                         #-
#      echo "section ${s}:"
#      eval "declare -p ${_hCLI[$s]}"
#    done                                                                       #-
#    cfg.free cli
#    cfg.free ini
#  SOURCE
cfg.cli.bind() {

  udfOn MissingArgument "$@" || return $?

  local -a a
  local fmtCase fmHandler k o sSection sShort sLong sArg s S sHandler sCases v

  o=${FUNCNAME[0]%%.*}

  cfg.new cli

  fmtHandler="${o}.cli.getopt() { while true; do case \$1 in %s --) shift; break;; esac; done }"
  fmtCase="--%s%s) ${o}.section.add "%s" "%s" "%s"; shift %s;;"

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

  eval "$sHandler" && ${o}.cli.getopt $s

  echo $sHandler

}
#******
