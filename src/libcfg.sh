#
# $Id: libcfg.sh 614 2016-12-07 17:16:46+04:00 toor $
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
: ${_bashlyk_cfgMethods:="section.id section.item section.select section.show section.raw section.add section.getarray get set show save read load bind.cli getopt free"}
: ${_bashlyk_aRequiredCmd_msg:="date echo getopt hostname logname md5sum mkdir mv pwd rm stat touch"}
: ${_bashlyk_aExport_msg:="get set show save read load bind.cli getopt free"}
#******
#****f* libcfg/cfg.new
#  SYNOPSIS
#    cfg.new <id>
#  DESCRIPTION
#    create new instance <id> of the INI(CFG) object
#  ARGUMENTS
#    valid variable name for created instance
#  RETURN VALUE
#    InvalidArgument - method not found
#    InvalidVariable - invalid variable name for instance
#  EXAMPLE
#    local f
#    cfg.new tnew                                                               #? true
#    declare -pf tnew.show >/dev/null 2>&1 && rc=true || rc=false               #-
#    $rc                                                                        #? true
#    declare -pf tnew.save >/dev/null 2>&1 && rc=true || rc=false               #-
#    $rc                                                                        #? true
#    declare -pf tnew.load >/dev/null 2>&1 && rc=true || rc=false               #-
#    $rc                                                                        #? true
#    declare -pf tnew.read >/dev/null 2>&1 && rc=true || rc=false               #-
#    $rc                                                                        #? true
#    tnew.free                                                                  #? true
#  SOURCE
cfg.new() {

  udfOn InvalidVariable throw "$1"

  local f s

  for s in $_bashlyk_cfgMethods; do

    f=$( declare -pf cfg.${s} )

    [[ $f =~ ^(cfg.${s}).\(\) ]] || eval $( udfOnError throw InvalidArgument "not instance $s method for $o object" )
    f=${f/${BASH_REMATCH[1]}/${1}.$s}

    eval "$f"

  done

  declare -a -g -- _a${1^^}="()"
  declare -A -g -- _h${1^^}="([__id__]=__id__)"

  return 0

}
#******
#****f* libcfg/cfg.section.id
#  SYNOPSIS
#    cfg.section.id [<section>]
#  DESCRIPTION
#    get a hash name for specified section or all hashes from instance
#  ARGUMENTS
#    section - section name, default - all hashes
#  OUTPUT
#    hash name{s}
#  EXAMPLE
#    cfg.new tu1
#    cfg.new tu2
#    tu1.section.id >| grep '__id__'                                            #? true
#    tu2.section.id >| grep '__id__'                                            #? true
#    tu1.free
#    tu2.free
#  SOURCE
cfg.section.id() {

  local o=${FUNCNAME[0]%%.*}

  eval "echo \${_h${o^^}[${1:-@}]}"

}
#******
#****f* libcfg/cfg.section.item
#  SYNOPSIS
#    cfg.section.item <index>
#  DESCRIPTION
#    get a name of the section by number of the location or sections count
#  ARGUMENTS
#    index - section index on sections order list
#  OUTPUT
#    section name or sections count
#  EXAMPLE
#    cfg.new tItem
#    tItem.section.select
#    tItem.section.select sItem1
#    tItem.section.select sItem2
#    tItem.section.item   >| grep ^3$                                           #? true
#    tItem.section.item 0 >| grep ^__global__$                                  #? true
#    tItem.section.item 1 >| grep ^sItem1$                                      #? true
#    tItem.section.item 2 >| grep ^sItem2$                                      #? true
#    tItem.free
#  SOURCE
cfg.section.item() {

  local i o=${FUNCNAME[0]%%.*} s

  udfIsNumber $1 && i=$1 || i=@

  [[ $i == @ ]] && s='#' || s=''

  eval "echo \${${s}_a${o^^}[$i]}"

}
#******
#****f* libcfg/cfg.free
#  SYNOPSIS
#    cfg.free
#  DESCRIPTION
#    remove a instance of the INI object
#  EXAMPLE
#    local i o s
#    cfg.new tFree
#    tFree.section.select
#    tFree.section.select sFree
#    o=$( tFree.section.id )
#    tFree.free                                                                 #? true
#    i=0                                                                        #-
#    for s in $o; do                                                            #-
#      declare -pA $s >/dev/null 2>&1; i=$(( i + $? ))                          #-
#    done                                                                       #-
#    (( i == 3 ))                                                               #? true
#  SOURCE
cfg.free() {

  local o s

  o=${FUNCNAME[0]%%.*}

  #
  [[ $o == cfg ]] && o=$1
  [[ $o ]] || return 1
  #

  for s in $( ${o}.section.id ); do

    [[ $s =~ ^[[:blank:]]*$|^__id__$ ]] && continue || unset -v $s

  done

  unset -v _a${o^^}
  unset -v _h${o^^}

  [[ $o == cfg ]] && return 0

  for s in section.get section.set $_bashlyk_cfgMethods; do

    unset -f ${o}.$s

  done

}
#******
#****f* libcfg/cfg.section.select
#  SYNOPSIS
#    cfg.section.select [<section>]
#  DESCRIPTION
#    select current section of the instance of INI object
#  ARGUMENTS
#    section - section name, default - unnamed global
#  EXAMPLE
#    local s
#    cfg.new tSel
#    tSel.section.select                                                        #? true
#    tSel.section.select tSect                                                  #? true
#    tSel.section.id >| md5sum - | grep ^180d2f8ad60b98865dfe06b8710b3a68.*-$   #? true
#    tSel.free
#  SOURCE
cfg.section.select() {

  local id o s=${1:-__global__}

  o=${FUNCNAME[0]%%.*}
  eval "id=\${_h${o^^}[$s]}"

  if [[ ! $id ]]; then

    ! eval "(( \${#_h${o^^}[@]} > 0 )) || declare -A -g -- _h${o^^}='([__id__]=__id__)'"
    id=$(md5sum <<< "$s")
    id="_h${o^^}_${id:0:32}"
    declare -A -g -- $id="()"

    eval "_h${o^^}[$s]=$id; _a${o^^}[\${#_a${o^^}[@]}]=\"$s\""

  fi

  eval "id=\${_h${o^^}[$s]}"
  eval "${o}.section.set() { [[ \$1 ]] && $id[\$1]="\$2"; }; ${o}.section.get() { [[ \$1 ]] && echo "\${$id[\$1]}"; };"

}
#******
#****f* libcfg/cfg.section.show
#  SYNOPSIS
#    cfg.section.show [<section>]
#  DESCRIPTION
#    show the contents of the specified section of the instance configuration
#  ARGUMENTS
#    <section> - section name, default - unnamed section
#  OUTPUT
#    the contents (must be empty) of the specified section with name as header
#  EXAMPLE
#    cfg.new tsshow
#    tsshow.section.select tSect
#    tsshow.section.set key "is value"
#    tsshow.section.show tSect >| md5sum | grep ^01db4c1804653c29952c0891593ac1f1.*-$ #? true
#    tsshow.section.select
#    tsshow.section.set key "unnamed section"
#    tsshow.section.show >| md5sum - | grep ^33098f129cdfa322a2bd326a56bb4f0b.*-$     #? true
#    tsshow.free
#  SOURCE
cfg.section.show() {

  local i iC id o s=${1:-__global__} sA sU

  o=${FUNCNAME[0]%%.*}

  ${o}.section.select $s
  id=$( ${o}.section.id $s )

  sU=$( ${o}.section.get __unnamed_mod )

  [[ $sU == '!' ]] && sA=':' || sA=
  [[ $1 ]] && printf "\n\n[ %s ]%s\n\n" "$1" "$sA" || echo ""

  if [[ $sU == "=" ]]; then

    eval "for i in "\${!$id[@]}"; do [[ \$i =~ ^__unnamed_key= ]] && printf -- '%s\n' \"\${$id[\$i]}\"; done;"

  else

    iC=$( ${o}.section.get __unnamed_cnt )

    if udfIsNumber $iC && (( iC > 0 )); then

      for (( i=0; i < $iC; i++ )); do

        ${o}.section.get "__unnamed_idx=$i"

      done

    else

      eval "for i in "\${!$id[@]}"; do [[ \$i =~ ^__unnamed_ ]] || printf -- '\t%s\t = %s\n' \"\$i\" \"\${$id[\$i]}\"; done;"

    fi

  fi

  [[ $sA ]] && printf "\n%s[ %s ]\n" "$sA" "$1"

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
#    cfg.new tRaw
#    tRaw.section.select sRaw1
#    tRaw.section.raw "=" "test 1"
#    tRaw.section.raw "=" "test 2"
#    tRaw.section.raw "=" "test 1"
#    tRaw.section.select sRaw2
#    tRaw.section.raw "+" "test 1"
#    tRaw.section.raw "+" "test 2"
#    tRaw.section.raw "+" "test 1"
#    tRaw.show >| md5sum - | grep ^7149e6d295217813c4902cd78d9fd332.*-$         #? true
#    tRaw.free
#  SOURCE
cfg.section.raw() {

  local i o s

  o=${FUNCNAME[0]%%.*}

  case "$1" in

    =)

       s="${2##*( )}"
       s="${s%%*( )}"
       ${o}.section.set "__unnamed_key=${s//[\'\"\\ ]/}" "$s"
       ${o}.section.set '__unnamed_mod' "="

    ;;

    -|+)

       i=$( ${o}.section.get __unnamed_cnt )
       udfIsNumber $i || i=0
       ${o}.section.set "__unnamed_idx=${i}" "$2"
       : $(( i++ ))
       ${o}.section.set '__unnamed_cnt' $i

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
#    add or update key-value pair or raw data to storage of the INI options
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
#    cfg.new tsadd
#    tsadd.section.add tsadd1 key1 "test 1"
#    tsadd.section.add tsadd1 key2 "test 2"
#    tsadd.section.add tsadd1 key3 "test 1"
#    tsadd.section.add tsadd2 "="  "test 1"
#    tsadd.section.add tsadd2 "="  "test 2"
#    tsadd.section.add tsadd2 "="  "test 1"
#    tsadd.section.add tsadd3 "+"  "test 1"
#    tsadd.section.add tsadd3 "+"  "test 2"
#    tsadd.section.add tsadd3 "+"  "test 1"
#    tsadd.show >| md5sum - | grep ^dd7645f79be447773dac812c67e32e7f.*-$        #? true
#    tsadd.free
#  SOURCE
cfg.section.add() {

  udfOn MissingArgument $2 || return $?

  local o
  o=${FUNCNAME[0]%%.*}

  ${o}.section.select ${1:-__global__}

  if [[ $2 =~ ^[\-\+=]$ ]]; then

    ${o}.section.raw "$2" "$3"

  else

    ${o}.section.set "$2" "$3"

  fi

}
#******
#****f* libcfg/udfIsHash
#  SYNOPSIS
#    udfIsHash <variable>
#  DESCRIPTION
#    check variable on type - success on hash
#  ARGUMENTS
#    <variable> - variable name
#  RETURN VALUE
#    InvalidVariable - argument is not valid variable name
#    InvalidHash     - argument is not hash variable
#    Success         - argument is hash variable
#  EXAMPLE
#    declare -A -g -- hh='()' s5
#    udfIsHash 5s                                                               #? $_bashlyk_iErrorInvalidVariable
#    udfIsHash s5                                                               #? $_bashlyk_iErrorInvalidHash
#    udfIsHash hh                                                               #? true
#  SOURCE
udfIsHash() {

  udfOn InvalidVariable $1 || return $?
  [[ $( declare -p $1 2>/dev/null ) =~ ^declare ]] && return 0 || return $( _ iErrorInvalidHash )

}
#******
#****f* libcfg/cfg.section.getarray
#  SYNOPSIS
#    cfg.section.getarray [<section>]
#  DESCRIPTION
#    get all value(s) from specified section of the raw data as serialized array
#  ARGUMENTS
#    <section> - correspondent section, default - unnamed
#  RETURN VALUE
#    MissingArgument - arguments not found
#    Success in other cases
#  EXAMPLE
#    cfg.new tGA
#    tGA.section.select sect1
#    tGA.section.set __unnamed_cnt 3
#    tGA.section.set __unnamed_idx=0 "is raw value No.1"
#    tGA.section.set __unnamed_idx=1 "is raw value No.2"
#    tGA.section.set __unnamed_idx=2 "is raw value No.3"
#    tGA.section.select sect2
#    tGA.section.set __unnamed_mod =
#    tGA.section.set '__unnamed_key=a1' "is raw value No.1"
#    tGA.section.set '__unnamed_key=b2' "is raw value No.2"
#    tGA.section.set '__unnamed_key=a1' "is raw value No.3"
#    tGA.section.getarray sect1 >| md5sum - | grep ^9cb6e1559552.*3d7417b.*-$ #? true
#    tGA.section.getarray sect2 >| md5sum - | grep ^9c964b5b47f6.*82a6d4e.*-$ #? true
#    tGA.free
#  SOURCE
cfg.section.getarray() {

  local -a a
  local i id iC o sU s

  o=${FUNCNAME[0]%%.*}
  ${o}.section.select ${1:-__global__}
  id=$( ${o}.section.id ${1:-__global__} )
  udfIsHash $id || eval $( udfOnError InvalidHash '$id' )

  sU=$( ${o}.section.get __unnamed_mod )

  if [[ $sU == "=" ]]; then

    eval "for i in "\${!$id[@]}"; do [[ \$i =~ ^__unnamed_key= ]] && a[\${#a[@]}]=\"\${$id[\$i]}\"; done;"

  else

    iC=$( ${o}.section.get __unnamed_cnt )
    if udfIsNumber $iC && (( iC )); then

      eval "for (( i=0; i < $iC; i++ )); do a[\${#a[@]}]=\"\${$id[__unnamed_idx=\$i]}\"; done;"

    fi

  fi

  (( ${#a[@]} > 0 )) && declare -p a

}
#******
#****f* libcfg/cfg.get
#  SYNOPSIS
#    cfg.get [\[<section>\]]<key>
#  DESCRIPTION
#    get value for a specified key of the section or all data of the "raw"
#    section
#  ARGUMENTS
#    <section> - correspondent section to the configuration, default - unnamed
#    <key>     - named key for "key=value" pair of the input data. For unnamed
#                records this argument must be supressed, this cases return
#                serialized array of the items
#  RETURN VALUE
#    MissingArgument - arguments not found
#    InvalidArgument - expected like a '[section]key', '[]key' or 'key'
#    Success in other cases
#  EXAMPLE
#    cfg.new tGet
#    tGet.section.select
#    tGet.section.set key "is unnamed section"
#    tGet.section.select section
#    tGet.section.set key "is value"
#    tGet.get [section]key
#    tGet.get [section]key >| grep '^is value$'                                 #? true
#    tGet.get   key >| grep '^is unnamed section$'                              #? true
#    tGet.get []key >| grep '^is unnamed section$'                              #? true
#    tGet.section.select section1
#    tGet.section.set __unnamed_cnt 3
#    tGet.section.set __unnamed_idx=0 "is raw value No.1"
#    tGet.section.set __unnamed_idx=1 "is raw value No.2"
#    tGet.section.set __unnamed_idx=2 "is raw value No.3"
#    tGet.section.select section2
#    tGet.section.set __unnamed_mod =
#    tGet.section.set __unnamed_key=a1 "is raw value No.1"
#    tGet.section.set __unnamed_key=b2 "is raw value No.2"
#    tGet.section.set __unnamed_key=a1 "is raw value No.3"
#    tGet.get [section2] >| md5sum -    | grep ^9c964b5b47f6dc.*82a6d4e.*-$     #? true
#    tGet.get [section1] >| md5sum -    | grep ^9cb6e155955235.*3d7417b.*-$     #? true
#    tGet.free
#  SOURCE
cfg.get() {

  udfOn MissingArgument $* || return $?

  local -a a
  local o k s v IFS

  o="$*"
  s="$IFS"
  IFS='[]' && a=( $o )
  IFS="$s"
  o=${FUNCNAME[0]%%.*}

  case "${#a[@]}" in

    3)
      s=${a[1]:-__global__}
      k="${a[2]:-__unnamed_}"
      ;;

    2)
      s=${a[1]:-__global__}
      k=__unnamed_
      ;;

    1)
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
    ${o}.section.get "$k"

  fi

}
#******
#****f* libcfg/cfg.set
#  SYNOPSIS
#    cfg.set [\[<section>\]]<key> = <value>
#  DESCRIPTION
#    set a value to the specified key of the section
#  ARGUMENTS
#    <section> - correspondent section, default - unnamed
#    <key>     - named key for "key=value" pair of the input data. For unnamed
#                records this argument must be supressed or is have '-' '+'
#                value, in this cases return serialized array of items
#  RETURN VALUE
#    MissingArgument - arguments not found
#    InvalidArgument - expected like a '[section]key = value', '[]key = value'
#                      or 'key = value'
#    Success in other cases
#  EXAMPLE
#    cfg.new tSet
#    tSet.set [section]key = is value
#    tSet.set key = is unnamed section
#    tSet.get [section]key
#    tSet.get [section]key >| grep '^is value$'                                 #? true
#    tSet.get   key >| grep '^is unnamed section$'                              #? true
#    tSet.get []key >| grep '^is unnamed section$'                              #? true
#    tSet.set [section1]+= is raw value No.1
#    tSet.set [section1]+ = is raw value No.2
#    tSet.set [section1]+  =   is raw value No.3
#    tSet.set [section2] = is raw value No.1
#    tSet.set [section2] =  is raw value No.2
#    tSet.set [section2] =   is raw value No.1
#    tSet.get [section2] >| md5sum | grep ^dae9eb0fed6d92e45ec62db6778bb0ea.*-$ #? true
#    tSet.get [section1] >| md5sum | grep ^9cb6e155955235c701959b4253d7417b.*-$ #? true
#    tSet.free
#  SOURCE
cfg.set() {

  udfOn MissingArgument $* || return $?

  local -a a
  local o k s v

  o="$*"
  s="$IFS"
  IFS='[]' && a=( $o )
  IFS="$s"
  o=${FUNCNAME[0]%%.*}

  case "${#a[@]}" in

    3)
      s=${a[1]:-__global__}
      k=${a[2]%%=*}
      v=${a[2]#*=}
      ;;

    1)
      s=__global__
      k=${a[0]%%=*}
      v=${a[0]#*=}
      ;;

    *)
      eval $( udfOnError throw InvalidArgument "$* - $(declare -p a)" )

  esac

  k="$( echo $k )"
  v="$( echo $v )"
  : ${k:==}

  ${o}.section.select $s

  if [[ $k =~ ^(=|\-|\+)$ ]]; then

    ${o}.section.raw "$k" "$v"

  else

    ${o}.section.set "$k" "$v"

  fi

}
#******
#****f* libcfg/cfg.show
#  SYNOPSIS
#    cfg.show
#  DESCRIPTION
#    Show a configuration data in the INI format
#  OUTPUT
#    configuration in the INI format
#  EXAMPLE
#    local s
#    cfg.new tShow
#    tShow.section.select "ShowTest"
#    tShow.section.set key "is value"
#    tShow.section.select
#    tShow.section.set key "unnamed section"
#    tShow.show >| md5sum - | grep ^e1f8a72e35593a7838f826ddd4590aea.*-$        #? true
#    tShow.free
#  SOURCE
cfg.show() {

  local o s

  o=${FUNCNAME[0]%%.*}

  ${o}.section.show

  for (( i=0; i < $( ${o}.section.item ); i++ )); do

    s="$( ${o}.section.item $i )"
    [[ $s =~ ^(__global__|__id__)$ ]] && continue
    ${o}.section.show "$s"

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
#    cfg.new tSave
#    tSave.section.select section
#    tSave.section.set key "is value"
#    tSave.section.select
#    tSave.section.set key "unnamed section"
#    tSave.save $fn
#    tSave.free
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
#    cfg.read <filename>
#  DESCRIPTION
#    Handling a configuration from the single INI file. Read valid "key=value"
#    pairs and as bonus "active" sections data only
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
#   cfg.new tRead
#   tRead.read $ini                                                             #? true
#   tRead.show >| md5sum - | grep ^a7d5fb1f4425f6a74154addf5801ee4b.*-$         #? true
#   tRead.free
#  SOURCE
cfg.read() {

  udfOn NoSuchFileOrDir throw $1

  local bActiveSection bIgnore csv fn i reComment reRawMode reSection reValidSections s

  reSection='^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
  reKey_Val='^[[:space:]]*([[:alnum:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
  reComment='^[[:space:]]*$|(^|[[:space:]]+)[\#\;].*$'
  reRawMode='^[=\-+]$'
  o=${FUNCNAME[0]%%.*}

  s="__global__"
  fn="$1"

  [[ $2 ]] && reValidSections="$2" || reValidSections="$reSection"
  [[ ${hKeyValue[@]}        ]] || local -A hKeyValue
  [[ ${hRawMode[@]}         ]] || local -A hRawMode
  [[ $( ${o}.section.item ) ]] || cfg.new $o

  if [[ ! $( stat -c %U $fn ) == $( _ sUser ) ]]; then

    eval $( udfOnError NotPermitted throw "$1 owned by $( stat -c %U $fn )" )

  fi

  bIgnore=

  [[ ${hKeyValue[$s]} ]] || hKeyValue[$s]="$reKey_Val"

  ${o}.section.select

  while read -t 4; do

    if [[ $REPLY =~ $reSection ]]; then

      bIgnore=1
      [[ $REPLY =~ $reValidSections ]] || continue
      bIgnore=

      s="${BASH_REMATCH[2]}"

      [[ ${BASH_REMATCH[1]} == ":" ]] && bActiveSection=close
      [[ ${BASH_REMATCH[3]} == ":" ]] && hRawMode[$s]="-"

      (( i > 0 )) && ${o}.section.set __unnamed_cnt $i

      bIgnore=1
      [[ $bActiveSection == "close" ]] && bActiveSection= && ${o}.section.set __unnamed_mod "!" && continue
      bIgnore=

      ${o}.section.select $s
      i=0
      case "${hRawMode[$s]}" in

        -) ;;

        +) i=$( ${o}.section.get __unnamed_cnt )
           udfIsNumber $i || ${o}.section.set __unnamed_cnt ${i:=0}
           ;;

        =) ${o}.section.set __unnamed_mod "=";;

        *) hKeyValue[$s]="$reKey_Val";;

      esac

      continue

    else

      [[ $REPLY =~ $reComment || $bIgnore ]] && continue

    fi

    if [[ ${hKeyValue[$s]} ]]; then

      [[ $REPLY =~ ${hKeyValue[$s]} ]] && ${o}.section.set "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"

    else

      if [[ ${hRawMode[$s]} == "=" ]]; then

        REPLY=${REPLY##*( )}
        REPLY=${REPLY%%*( )}
        ${o}.section.set "__unnamed_key=${REPLY//[\'\"\\ ]/}" "$REPLY"

      else

        ${o}.section.set "__unnamed_idx=${i:=0}" "$REPLY"
        : $(( i++ ))

      fi

    fi

  done < $fn

  [[ ${hRawMode[$s]} =~ ^(\+|\-)$ ]] && ${o}.section.set __unnamed_cnt ${i:=0}

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
#   cfg.new tLoad
#   tLoad.load $iniLoad $sRules                                                   #? true
#   tLoad.save $iniSave                                                           #? true
#   tLoad.show >| md5sum - | grep ^5a8cdc4d2dbb5cb169cc857603179217.*-$           #? true
##    tLoad.free
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

  eval "s=\${_h${o^^}[__cli__]}"
  if [[ $s ]]; then

    udfMakeTemp ini

    ${s}.save $ini
    ${o}.read $ini "$reValidSections"

    rm -f $ini

  fi

  return 0

}
#******
#****f* libcfg/cfg.bind.cli
#  SYNOPSIS
#    cfg.bind.cli [<section>-]<option long name>{<short name>}[:<extra>] ...
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
#    tLoad.save $ini                                                            #? true
#    tLoad.free
#    cfg.new tBCLI
#    tBCLI.bind.cli $rCLI                                                       #? true
#    tBCLI.load $ini $rINI                                                      #? true
#    tBCLI.show >| md5sum - | grep ^230af661227964498193dc3df7c63ece.*-$        #? true
#    tBCLI.free
#  SOURCE
cfg.bind.cli() {

  udfOn MissingArgument "$@" || return $?

  local -a a
  local c fmtCase fmHandler k o sSection sShort sLong sArg s S sHandler sCases v

  o=${FUNCNAME[0]%%.*}
  c=cli${RANDOM}

  cfg.new $c
  eval "_h${o^^}[__cli__]=$c"

  fmtHandler="${c}.getopts() { while true; do case \$1 in %s --) shift; break;; esac; done }"
  fmtCase="--%s%s) ${c}.section.add \"%s\" \"%s\" \"%s\"; shift %s;;"

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

  eval "$sHandler" && ${c}.getopts $s

}
#******
#****f* libcfg/cfg.getopt
#  SYNOPSIS
#    cfg.getopt [<section>-]<option>
#  DESCRIPTION
#    Bind command line options to the structure of the configuration INI
#  ARGUMENTS
#    <option name> - option name that used as long option of the CLI and key for
#                    array of the INI data
#    <section>     - part of the option name for binding it to a certain section
#                    of the INI data. By default, it is assumed that option is
#                    included to the global section
#  RETURN VALUE
#    MissingArgument - arguments is not specified
#  EXAMPLE
#    local rCLI
#    rCLI='file{F}: exec{E}:- main-hint{H}: main-msg{M}: unify{U}:= acc:+'      #-
#    _ sArg "-F CLI -E clear -H 'Hi!' -M test -U a.2 -U a.2 --acc=a --acc=b"    #-
#    cfg.new tGetopt
#    tGetopt.bind.cli $rCLI                                                     #? true
#    tGetopt.getopt file                                                        #? true
#    tGetopt.getopt exec--                                                      #? true
#    tGetopt.getopt main-hint                                                   #? true
#    tGetopt.getopt main-msg                                                    #? true
#    tGetopt.getopt unify--                                                     #? true
#    tGetopt.getopt acc--                                                       #? true
#    tGetopt.free
#  SOURCE
cfg.getopt() {

  udfOn MissingArgument "$@" || return $?

  local -a a
  local c o s IFS

  s="$*"
  c="$IFS"
  IFS='-' && a=( $s )
  IFS="$c"
  o=${FUNCNAME[0]%%.*}
  eval "c=\${_h${o^^}[__cli__]}"

  case "${#a[@]}" in

    2)
      s=${a[0]:-__global__}
      k=${a[1]}
      ;;

    1)
      s=__global__
      k=${a[0]}
      ;;

    *)
      eval $( udfOnError throw InvalidArgument "$*" )

  esac

  ${c}.get [${s}]${k}

}
#******
