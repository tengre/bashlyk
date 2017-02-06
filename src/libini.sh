#
# $Id: libini.sh 678 2017-02-06 14:47:38+04:00 toor $
#
#****h* BASHLYK/libini
#  DESCRIPTION
#    Management of the configuration files in the INI-style. Implemented
#    capabilities and features:
#     - associative arrays are used to store the INI configuration data
#     - OOP style used for a treatment of the INI configuration data:
#       * functions (eg, get/set) bind with the configuration data, as "methods"
#         of the corresponding instance of the base class "INI"
#       * used the constructor and destructor to manage the life cycle of the
#         resources allocated for processing configuration data
#     - INI configuration source may be not only single file but also a group of
#       related files
#     - supported the filtration ability  - retrieving only the specified
#       sections and parameters
#     - The possibility of simultaneous and independent work with different
#       sources of INI data
#     - Get/Set certain configuration data by using parameter as key
#     - Record the configuration data to a file or output to the standard device
#       in INI format.
#     - Support for Command Line Interface (CLI) - simultaneous determination of
#       long and short options of configuration parameters.
#     - parsing the command line arguments and their binding to configuration
#       data that allows you to override selected parameters of the INI-file.
#  USES
#    libstd liberr
#  EXAMPLE
#    INI ini
#    ini.bind.cli config{c}: source{s}:-- help{h} mode{m}: dry-run
#    conf=$( ini.getopt config )
#    ini.load $conf :mode,help dry:run source:=
#    if [[ $( ini.get [dry]run ) ]]; then
#      echo "dry run, view current config:"
#      ini.show
#      exit 0
#    fi
#
#    ini.set mode = demo
#    ini.set [source] = $HOME
#    ini.set [source] = /var/mail/$USER
#
#    ini.save $conf
#    ini.free
#
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* liberr/BASH Compability
#  DESCRIPTION
#    BASH version 4.xx or more required for this script
#  SOURCE
[ -n "$BASH_VERSION" ] && (( ${BASH_VERSINFO[0]} >= 4 )) || eval '             \
                                                                               \
    echo "[!] BASH shell version 4.xx required for ${0}, abort.."; exit 255    \
                                                                               \
'
#******
#  $_BASHLYK_LIBINI provides protection against re-using of this module
[[ $_BASHLYK_LIBINI ]] && return 0 || _BASHLYK_LIBINI=1
#******
#****L* libini/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****G* libini/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
: ${_bashlyk_sArg:="$@"}
: ${_bashlyk_pathIni:=$(pwd)}

declare -rg _bashlyk_methods_ini="                                             \
                                                                               \
    __section.id __section.byindex __section.select __section.show             \
    __section.setRawData __section.getArray get set show save read             \
    keys load bind.cli getopt free                                             \
                                                                               \
"
declare -rg _bashlyk_externals_ini="                                           \
                                                                               \
    date echo getopt sha1sum mkdir mv pwd rm stat touch                        \
                                                                               \
"
declare -rg _bashlyk_exports_ini="                                             \
                                                                               \
    INI get set keys show save read load bind.cli getopt free                  \
                                                                               \
"
#******
#****e* libini/INI
#  SYNOPSIS
#    INI [<id>]
#  DESCRIPTION
#    constructor for new instance <id> of the INI "class" (object)
#  NOTES
#    public method
#  ARGUMENTS
#    valid variable name for created instance, default - used class name INI as
#    instance
#  ERRORS
#    InvalidArgument - method not found
#    InvalidVariable - invalid variable name for instance
#  EXAMPLE
#    INI tnew                                                                   #? true
#    declare -pf tnew.show >/dev/null 2>&1                                      #= true
#    declare -pf tnew.save >/dev/null 2>&1                                      #= true
#    declare -pf tnew.load >/dev/null 2>&1                                      #= true
#    tnew.__section.id @ >| grep _hTNEW_settings                                #? true
#    tnew.free
#  SOURCE
INI() {

  local f s=${1:-INI}

  udfOn InvalidVariable throw $s

  declare -ag -- _a${s^^}="()"
  declare -Ag -- _h${s^^}_settings="()"
  declare -Ag -- _h${s^^}="([__settings__]=_h${s^^}_settings)"

  for s in $_bashlyk_methods_ini; do

    f=$( declare -pf INI::${s} )

    [[ $f =~ ^(INI::${s}).\(\) ]] || eval $( udfOnError throw InvalidArgument "not instance $s method for $o object" )

    eval "${f/${BASH_REMATCH[1]}/${1}.$s}"

  done


  return 0

}
#******
#****p* libini/INI::__section.id
#  SYNOPSIS
#    INI::__section.id [<section>]
#  DESCRIPTION
#    get a link of the storage for specified section or links for all storages.
#  NOTES
#    INI private method
#  ARGUMENTS
#    <section> - section name, '@' - all sections, default - unnamed 'global'
#  OUTPUT
#    associative array(s), in which are stored data of the section(s)
#  EXAMPLE
#    INI tSectionId1
#    INI tSectionId2
#    tSectionId1.__section.select
#    tSectionId1.__section.id   >| grep ^_hTSECTIONID1_[[:xdigit:]]*$           #? true
#    tSectionId2.__section.id @ >| grep ^_hTSECTIONID2_settings$                #? true
#    tSectionId1.free
#    tSectionId2.free
#  SOURCE
INI::__section.id() {

  local o=${FUNCNAME[0]%%.*}

  eval "echo \${_h${o^^}[${*:-__global__}]}"

}
#******
#****p* libini/INI::__section.byindex
#  SYNOPSIS
#    INI::__section.byindex [<index>]
#  DESCRIPTION
#    get the name of the section at the specified index, or number of then
#    registered sections.
#  NOTES
#    INI private method
#  ARGUMENTS
#    <index> - index of the section in the common list in order of registration,
#              default - total number of the registered sections
#  OUTPUT
#    section name or total number of the registered sections
#  EXAMPLE
#    INI tSectionIndex
#    tSectionIndex.__section.select
#    tSectionIndex.__section.select sItem1
#    tSectionIndex.__section.select sItem2
#    tSectionIndex.__section.byindex   >| grep ^3$                              #? true
#    tSectionIndex.__section.byindex 0 >| grep ^__global__$                     #? true
#    tSectionIndex.__section.byindex 1 >| grep ^sItem1$                         #? true
#    tSectionIndex.__section.byindex 2 >| grep ^sItem2$                         #? true
#    tSectionIndex.free
#  SOURCE
INI::__section.byindex() {

  local i o=${FUNCNAME[0]%%.*} s

  udfIsNumber $1 && i=$1 || i=@

  [[ $i == @ ]] && s='#' || s=''

  eval "echo \${${s}_a${o^^}[$i]}"

}
#******
#****e* libini/INI::free
#  SYNOPSIS
#    INI::free
#  DESCRIPTION
#    destructor of the instance
#  NOTES
#    public method
#  EXAMPLE
#    local i o s
#    INI tFree
#    tFree.__section.select
#    tFree.__section.select sFree
#    o=$( tFree.__section.id @ )
#    tFree.free                                                                 #? true
#    i=0                                                                        #-
#    for s in $o; do                                                            #-
#      declare -pA $s >/dev/null 2>&1; i=$(( i + $? ))                          #-
#    done                                                                       #-
#    (( i == 3 ))                                                               #? true
#  SOURCE
INI::free() {

  local o s

  o=${FUNCNAME[0]%%.*}

  for s in $( ${o}.__section.id @ ); do

    [[ $s =~ ^[[:blank:]]*$ ]] && continue || unset -v $s

  done

  unset -v _a${o^^}
  unset -v _h${o^^}
  unset -v _h${o^^}_settings

  for s in __section.get __section.set $_bashlyk_methods_ini; do

    unset -f ${o}.$s

  done

}
#******
#****p* libini/INI::__section.select
#  SYNOPSIS
#    INI::__section.select [<section>]
#  DESCRIPTION
#    select current section of the instance, prepare INI private getter and setter
#    for the storage of the selected section
#  NOTES
#    INI private method
#  ARGUMENTS
#    <section> - section name, default - unnamed global
#  EXAMPLE
#    local s
#    INI tSel
#    tSel.__section.select                                                      #? true
#    tSel.__section.set key "is value from unnamed section"
#    tSel.__section.get key >| grep '^is value from unnamed section$'           #? true
#    tSel.__section.select tSect                                                #? true
#    tSel.__section.set key "is value"
#    tSel.__section.get key >| grep '^is value$'                                #? true
#    tSel.__section.select section with spaces                                  #? true
#    tSel.__section.set "key with spaces" "is value"
#    tSel.__section.get "key with spaces" >| grep '^is value$'                  #? true
#    tSel.__section.id @ >| grep -P "^_hTSEL.*(settings|[[:xdigit:]]*)$"        #? true
#    tSel.free
#  SOURCE
INI::__section.select() {

  local id o s=${*:-__global__}

  o=${FUNCNAME[0]%%.*}
  eval "id=\${_h${o^^}[$s]}"

  if [[ ! $id ]]; then

    id=$(sha1sum <<< "$s")
    id="_h${o^^}_${id:0:40}"

    declare -Ag -- $id="()"

    eval "_h${o^^}[$s]=$id; _a${o^^}[\${#_a${o^^}[@]}]=\"$s\""

  fi

  eval "                                                                       \
                                                                               \
    id=\${_h${o^^}[$s]};                                                       \
    ${o}.__section.set() { [[ \$1 ]] && $id[\$1]=\"\$2\"; };                   \
    ${o}.__section.get() { [[ \$1 ]] && echo \"\${$id[\$1]}\"; };              \
                                                                               \
  "

}
#******
#****p* libini/INI::__section.show
#  SYNOPSIS
#    INI::__section.show [<section>]
#  DESCRIPTION
#    show a content of the specified section
#  ARGUMENTS
#    <section> - section name, default - unnamed section
#  OUTPUT
#    the contents (must be empty) of the specified section with name as header
#  EXAMPLE
#    INI tSShow
#    tSShow.__section.select tSect
#    tSShow.__section.set key "is value"
#    tSShow.__section.show tSect >| md5sum | grep ^99c8669469e47642b9b540db.*-$ #? true
#    tSShow.__section.select
#    tSShow.__section.set key "unnamed section"
#    tSShow.__section.show >| md5sum | grep ^67d9d58badfb9e5e568e72adcc5c95.*-$ #? true
#    tSShow.free
#    INI tSShow2
#    tSShow2.set [ __settings__ ] bConfMode = true
#    tSShow2.set [ tSect2 ] keyFirst   = is first value
#    tSShow2.set [ tSect2 ] keySecond  = is second value
#    tSShow2.set [ tSect2 ] keyOneWord = is_one_world_value
#    tSShow2.__section.show tSect2 >| md5sum - | grep ^f4bea0366a1f110343bf.*-$ #? true
#    tSShow2.free
#  SOURCE
INI::__section.show() {

  local iC id k o sA sU

  o=${FUNCNAME[0]%%.*}

  ${o}.__section.select $*
  id=$( ${o}.__section.id $* )

  sU=$( ${o}.__section.get _bashlyk_raw_mode )

  [[ $sU == '!' ]] && sA=':' || sA=
  [[ $1 ]] && printf "\n\n[ %s ]%s\n\n" "$1" "$sA" || echo ""

  if [[ $sU == "=" ]]; then

    eval "                                                                     \
                                                                               \
      for k in \"\${!$id[@]}\"; do                                             \
                                                                               \
        [[ \$k =~ ^_bashlyk_raw_uniq= ]] && printf -- '%s\n' \"\${$id[\$k]}\"; \
                                                                               \
      done;                                                                    \
                                                                               \
    "

  else

    iC=$( ${o}.__section.get _bashlyk_raw_num )

    if udfIsNumber $iC && (( iC > 0 )); then

      for (( k=0; k < $iC; k++ )); do

        ${o}.__section.get "_bashlyk_raw_incr=$k"

      done

    else

      local bQuote iKeyWidth iPadding v

      iKeyWidth=$( ${o}.__section.get _bashlyk_key_width )
      udfIsNumber $iKeyWidth || iKeyWidth=''

      iPadding=$( ${o}.get [__settings__]iPadding )
      udfIsNumber $iPadding || iPadding=4

      if [[ $( ${o}.get [__settings__]bConfMode ) =~ ^(true|yes|1)$ ]]; then

        bQuote=true
        iPadding=0

      else

        bQuote=''

      fi

      eval "                                                                   \
                                                                               \
        for k in \"\${!$id[@]}\"; do                                           \
          if [[ ! \$k =~ ^_bashlyk_ ]]; then                                   \
            v=\${$id[\$k]};                                                    \
            [[ \$bQuote ]] && v=\$( udfQuoteIfNeeded \$v );                    \
            printf -- '\t%${iKeyWidth}s%${iPadding}s=%${iPadding}s%s\n'        \
              \"\$k\" \"\" \"\"  \"\$v\";                                      \
          fi                                                                   \
        done;                                                                  \
                                                                               \
      "

    fi

  fi

  [[ $sA ]] && printf "\n%s[ %s ]\n" "$sA" "$1"

}
#******
#****p* libini/INI::__section.setRawData
#  SYNOPSIS
#    INI::__section.setRawData -|=|+ <data>
#  DESCRIPTION
#    set "raw" data record to the current section with special key prefix
#    '_bashlyk_raw_...'
#  NOTES
#    INI private method
#  ARGUMENTS
#    '-', '+' - add "raw" record with incremented key like "_bashlyk_raw_incr=<No>"
#    '='      - add or update "raw" unique record with key like
#               "_bashlyk_raw_uniq=<input data without spaces and quotes>"
#    <data>   - input data, interpreted as "raw" record
#  ERRORS
#    InvalidArgument - unexpected "raw" mode
#  EXAMPLE
#    INI tSRawData
#    tSRawData.__section.select "unique_values"
#    tSRawData.__section.setRawData "=" "save only unique 1"
#    tSRawData.__section.setRawData "=" "save only unique 2"
#    tSRawData.__section.setRawData "=" "save only unique 1"
#    tSRawData.__section.select "accumulated_values"
#    tSRawData.__section.setRawData "+" "save all 1"
#    tSRawData.__section.setRawData "+" "save all 2"
#    tSRawData.__section.setRawData "+" "save all 1"
#    tSRawData.show >| md5sum - | grep ^1ec72eb6334d7eb29d45ffd7b01fccd2.*-$    #? true
#    tSRawData.free
#  SOURCE
INI::__section.setRawData() {

  local c=$1 i o s

  o=${FUNCNAME[0]%%.*}

  shift && s="$( udfTrim "$*" )"

  case "$c" in

    =)

       ${o}.__section.set "_bashlyk_raw_uniq=${s//[\'\"\\ ]/}" "$s"

    ;;

    -|+)

       i=$( ${o}.__section.get _bashlyk_raw_num )
       udfIsNumber $i || i=0
       ${o}.__section.set "_bashlyk_raw_incr=${i}" "$s"
       : $(( i++ ))
       ${o}.__section.set '_bashlyk_raw_num' $i

    ;;

    *)

      return $( _ iErrorInvalidArgument )

  esac

  ${o}.__section.set '_bashlyk_raw_mode' "$c"

  return 0

}
#******
#****p* libini/INI::__section.getArray
#  SYNOPSIS
#    INI::__section.getArray [<section>]
#  DESCRIPTION
#    get unnamed records from specified section as serialized array. Try to get
#    a unique "raw" records (with the prefix "_bashlyk_raw_uniq=...") or incremented
#    records (with prefix "_bashlyk_raw_incr=...")
#  NOTES
#    INI private method
#  ARGUMENTS
#    <section> - specified section, default - unnamed global
#  ERRORS
#    MissingArgument - arguments not found
#  EXAMPLE
#    INI tGA
#    tGA.__section.select sect1
#    tGA.__section.set _bashlyk_raw_num 3
#    tGA.__section.set _bashlyk_raw_incr=0 "is raw value No.1"
#    tGA.__section.set _bashlyk_raw_incr=1 "is raw value No.2"
#    tGA.__section.set _bashlyk_raw_incr=2 "is raw value No.3"
#    tGA.__section.select sect2
#    tGA.__section.set _bashlyk_raw_mode =
#    tGA.__section.set '_bashlyk_raw_uniq=a1' "is raw value No.1"
#    tGA.__section.set '_bashlyk_raw_uniq=b2' "is raw value No.2"
#    tGA.__section.set '_bashlyk_raw_uniq=a1' "is raw value No.3"
#    tGA.__section.getArray sect1 >| md5sum - | grep ^9cb6e1559552.*3d7417b.*-$ #? true
#    tGA.__section.getArray sect2 >| md5sum - | grep ^9c964b5b47f6.*82a6d4e.*-$ #? true
#    tGA.free
#  SOURCE
INI::__section.getArray() {

  local -a a
  local i id iC o s sU

  o=${FUNCNAME[0]%%.*}
  ${o}.__section.select $*
  id=$( ${o}.__section.id $* )
  udfIsHash $id || eval $( udfOnError InvalidHash '$id' )

  sU=$( ${o}.__section.get _bashlyk_raw_mode )

  if [[ $sU == "=" ]]; then

    eval "for i in "\${!$id[@]}"; do [[ \$i =~ ^_bashlyk_raw_uniq= ]] && a[\${#a[@]}]=\"\${$id[\$i]}\"; done;"

  else

    iC=$( ${o}.__section.get _bashlyk_raw_num )
    if udfIsNumber $iC && (( iC )); then

      eval "for (( i=0; i < $iC; i++ )); do a[\${#a[@]}]=\"\${$id[_bashlyk_raw_incr=\$i]}\"; done;"

    fi

  fi

  (( ${#a[@]} > 0 )) && declare -p a || return $( _ iErrorEmptyResult )

}
#******
#****e* libini/INI::get
#  SYNOPSIS
#    INI::get [\[<section>\]]<key>
#  DESCRIPTION
#    get single value for a key or serialized array of the "raw" records for
#    specified section
#  SEE ALSO
#    INI::__section.getArray
#  NOTES
#    public method
#  ARGUMENTS
#    <section> - specified section, default - unnamed global
#    <key>     - named key for "key=value" pair of the input data. For unnamed
#                records this argument must be supressed, this cases return
#                serialized array of the records (see INI::__section.getArray)
#  ERRORS
#    MissingArgument - arguments not found
#    InvalidArgument - expected like a '[section]key', '[]key' or 'key'
#  EXAMPLE
#    INI tGet
#    tGet.__section.select
#    tGet.__section.set key "is unnamed section"
#    tGet.__section.select section
#    tGet.__section.set key "is value"
#    tGet.get [section]key
#    tGet.get [section]key >| grep '^is value$'                                 #? true
#    tGet.get   key >| grep '^is unnamed section$'                              #? true
#    tGet.get []key >| grep '^is unnamed section$'                              #? true
#    tGet.__section.select accumu
#    tGet.__section.set _bashlyk_raw_num 3
#    tGet.__section.set _bashlyk_raw_incr=0 "is raw value No.1"
#    tGet.__section.set _bashlyk_raw_incr=1 "is raw value No.2"
#    tGet.__section.set _bashlyk_raw_incr=2 "is raw value No.3"
#    tGet.__section.select unique
#    tGet.__section.set _bashlyk_raw_mode =
#    tGet.__section.set _bashlyk_raw_uniq=a1 "is raw value No.1"
#    tGet.__section.set _bashlyk_raw_uniq=b2 "is raw value No.2"
#    tGet.__section.set _bashlyk_raw_uniq=a1 "is raw value No.3"
#    tGet.get [accumu] >| md5sum | grep ^9cb6e155955235c701959b4253d7417b.*-$   #? true
#    tGet.get [unique] >| md5sum | grep ^9c964b5b47f6dcc62be09c5de82a6d4e.*-$   #? true
#    tGet.free
#  SOURCE
INI::get() {

  udfOn MissingArgument $* || return $?

  local -a a
  local IFS o k s="$*" v

  IFS='[]' a=( $s ) && IFS=$' \t\n'

  o=${FUNCNAME[0]%%.*}

  case "${#a[@]}" in

    3)
      s=${a[1]:-__global__}
      k="${a[2]:-_bashlyk_raw}"
      ;;

    2)
      s=${a[1]:-__global__}
      k=_bashlyk_raw
      ;;

    1)
      s=__global__
      k="${a[0]:-_bashlyk_raw}"
      ;;

    *)
      eval $( udfOnError retwarn InvalidArgument "$*" )
      ;;

  esac

  if [[ $k =~ _bashlyk_raw ]]; then

    ${o}.__section.getArray $s

  else

    ${o}.__section.select $s
    ${o}.__section.get "$k"

  fi

}
#******
#****e* libini/INI::keys
#  SYNOPSIS
#    INI::keys [\[<section>\]]
#  DESCRIPTION
#    Show all the keys of the selected section in a row, separated by commas.
#    For the section of the "raw data" (without keys) will be shown the storage
#    mode.
#  NOTES
#    public method
#  ARGUMENTS
#    <section> - specified section, default - unnamed global
#  ERRORS
#    InvalidArgument - expected like a '[section]key', '[]key' or 'key'
#  EXAMPLE
#    INI tKeys
#    tKeys.set  [section1] key1 = is value 1
#    tKeys.set  [section1] key2 = is value 2
#    tKeys.set  [section1] key with spaces = is value 3
#    tKeys.set  keyA = is value A
#    tKeys.set  []keyB = is value B
#    tKeys.set  key with spaces = is value C
#    tKeys.set  [section2] += save value
#    tKeys.set  [section2] += save value
#    tKeys.set  [section3] -= save value No.2
#    tKeys.set  [section3] -= save value No.1
#    tKeys.set  [section4] = save unique value No.2
#    tKeys.set  [section4] = save unique value No.1
#    tKeys.keys >| md5sum - | grep ^bcfcd2f2d13115c731e46c1bebfd21bf.*$         #? true
#    tKeys.keys [section1] >| md5sum - | grep ^22e3ec00d3439034aea5476664d52.*$ #? true
#    tKeys.keys [section2] >| grep ^+$                                          #? true
#    tKeys.keys [section3] >| grep ^-$                                          #? true
#    tKeys.keys [section4] >| grep ^=$                                          #? true
#    tKeys.free
#  SOURCE
INI::keys() {

  local -a a
  local csv IFS o k s="$*"

  IFS='[]' a=( $s ) && IFS=$' \t\n'

  o=${FUNCNAME[0]%%.*}

  case "${#a[@]}" in

    2)
      s=${a[1]:-__global__}
    ;;

    0)
      s=__global__
    ;;

    *)
      eval $( udfOnError retwarn InvalidArgument "$*" )
    ;;

  esac

  ${o}.__section.select $s
  id=$( ${o}.__section.id $s )
  sU=$( ${o}.__section.get _bashlyk_raw_mode )

  if [[ $sU ]]; then

    echo $sU

  else

    eval "                                                                     \
                                                                               \
      for k in \"\${!$id[@]}\"; do                                             \
        if [[ ! \$k =~ ^_bashlyk_ ]]; then                                     \
          csv+=\"\$k,\";                                                       \
        fi                                                                     \
      done;                                                                    \
                                                                               \
    "
    echo "$csv"

  fi

}
#******
#****e* libini/INI::set
#  SYNOPSIS
#    INI::set [\[<section>\]]<key> = <value>
#  DESCRIPTION
#    set a value to the specified key of the section
#  NOTES
#    public method
#  ARGUMENTS
#    <section> - specified section, default - unnamed global
#    <key>     - named key for "key=value" pair of the input data. For unnamed
#                records this argument must be supressed or must have '-' '+'
#                value, in this cases return serialized array of items
#  ERRORS
#    MissingArgument - arguments not found
#    InvalidArgument - expected like a '[section]key = value', '[]key = value'
#                      or 'key = value'
#  EXAMPLE
#    INI tSet
#    tSet.set [section]key = is value
#    tSet.set key = is unnamed section
#    tSet.set key with spaces = is unnamed section
#    tSet.show
#    tSet.get [section]key >| grep '^is value$'                                 #? true
#    tSet.get   key >| grep '^is unnamed section$'                              #? true
#    tSet.get []key >| grep '^is unnamed section$'                              #? true
#    tSet.get key with spaces >| grep '^is unnamed section$'                    #? true
#    tSet.set [section1]+= is raw value No.1
#    tSet.set [section1]+ = is raw value No.2
#    tSet.set [section1]+  =   is raw value No.3
#    tSet.set [section2]=save unique value No.1
#    tSet.set [section2] =  save unique value No.2
#    tSet.set [section2] =   save unique value No.1
#    tSet.get [section2] >| md5sum | grep ^8c6e9c4833a07c3d451eacbef0813534.*-$ #? true
#    tSet.get [section1] >| md5sum | grep ^9cb6e155955235c701959b4253d7417b.*-$ #? true
#    tSet.free
#    _ onError return
#    INI InvalidInput
#    InvalidInput.set Thu, 30 Jun 2016 08:55:36 +0400                           #? $_bashlyk_iErrorInvalidArgument
#    InvalidInput.set [section] Thu, 30 Jun 2016 08:55:36 +0400                 #? $_bashlyk_iErrorInvalidArgument
#    InvalidInput.free
#  SOURCE
INI::set() {
  ## TODO ignore bad arguments or raw mode ?
  udfOn MissingArgument $* || return $?

  local -a a
  local iKeyWidth IFS o k s="$*" v

  IFS='[]' && a=( $s ) && IFS=$' \t\n'

  o=${FUNCNAME[0]%%.*}

  case "${#a[@]}" in

    3)
      s=${a[1]:-__global__}
      k=${a[2]%%=*}
      v=${a[2]#*=}
      [[ $k == ${a[2]} && $v == ${a[2]} ]] \
        && eval $( udfOnError InvalidArgument "${a[2]}" )
      ;;

    1)
      s=__global__
      k=${a[0]%%=*}
      v=${a[0]#*=}
      [[ $k == ${a[0]} && $v == ${a[0]} ]] \
        && eval $( udfOnError InvalidArgument "${a[0]}" )
      ;;

    *)
      eval $( udfOnError InvalidArgument "$* - $(declare -p a)" )
      ;;

  esac

  k="$( echo $k )"
  v="$( echo $v )"
  : ${k:==}

  ${o}.__section.select $s

  if [[ $k =~ ^(=|\-|\+)$ ]]; then

    ${o}.__section.setRawData "$k" "$v"

  else

    iKeyWidth=$( ${o}.__section.get _bashlyk_key_width )
    udfIsNumber $iKeyWidth || iKeyWidth=0

    (( ${#k} > iKeyWidth )) && ${o}.__section.set _bashlyk_key_width ${#k}
    ${o}.__section.set "$k" "$v"

  fi

}
#******
#****e* libini/INI::show
#  SYNOPSIS
#    INI::show
#  DESCRIPTION
#    Show a instance data in the INI format
#  NOTES
#    public method
#  OUTPUT
#    instance data in the INI format
#  EXAMPLE
#    INI tShow
#    tShow.__section.select "tShow"
#    tShow.__section.set key "is value"
#    tShow.__section.select
#    tShow.__section.set key "unnamed section"
#    tShow.set [section with spaces] key with spaces = value with spaces
#    tShow.show >| md5sum - | grep ^b6ebbda48d1710b2c253669365786a25.*-$        #? true
#    tShow.free
#  SOURCE
INI::show() {

  local i o s

  o=${FUNCNAME[0]%%.*}

  ${o}.__section.show

  for (( i=0; i < $( ${o}.__section.byindex ); i++ )); do

    s="$( ${o}.__section.byindex $i )"
    [[ $s =~ ^(__global__|__settings__)$ ]] && continue
    ${o}.__section.show "$s"

  done

  printf -- "\n"

}
#******
#****e* libini/INI::save
#  SYNOPSIS
#    INI::save <file>
#  DESCRIPTION
#    Save the configuration to the specified file in the INI format
#  NOTES
#    public method
#  ARGUMENTS
#    <file>  - target file for saving, full path required
#  ERRORS
#    MissingArgument    - the file name is not specified
#    NotExistNotCreated - the target file is not created
#  EXAMPLE
#    local fn
#    udfMakeTemp fn
#    INI tSave
#    tSave.__section.select section
#    tSave.__section.set key "is value"
#    tSave.__section.select
#    tSave.__section.set key "unnamed section"
#    tSave.save $fn
#    tSave.free
#    tail -n +4 $fn >| md5sum - | grep ^014d76fac8f057af36d119aaddeb30ee.*-$    #? true
#  SOURCE
INI::save() {

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
#****e* libini/INI::read
#  SYNOPSIS
#    INI::read <filename>
#  DESCRIPTION
#    Handling a configuration from the single INI file. Read valid "key=value"
#    pairs and as bonus "active" sections data only
#  ERRORS
#    NoSuchFileOrDir - input file not exist
#    NotPermitted    - owner of the input file differ than owner of the process
#  EXAMPLE
#   local ini s S                                                               #-
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
#   _ onError retwarn
#   INI tRead
#   tRead.read                                                                  #? $_bashlyk_iErrorMissingArgument
#   tRead.read /not/exist/file.$$.ini                                           #? $_bashlyk_iErrorNoSuchFileOrDir
#   tRead.read $ini                                                             #? true
#   tRead.show >| md5sum - | grep ^65d9ae6b9e7ac8ec24cb069c89fdebd4.*-$         #? true
#   tRead.free
#  SOURCE
INI::read() {

  udfOn NoSuchFileOrDir $1 || return

  local bActiveSection bIgnore csv fn i iKeyWidth reComment reSection reValidSections s

  reSection='^[[:space:]]*(:?)\[[[:space:]]*([[:print:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
  reKey_Val='^[[:space:]]*\b([^=]+)\b[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
  reComment='^[[:space:]]*$|(^|[[:space:]]+)[\#\;].*$'
  o=${FUNCNAME[0]%%.*}

  s="__global__"
  fn="$1"

  [[ $2 ]] && reValidSections="$2" || reValidSections="$reSection"
  [[ ${hKeyValue[@]} ]] || local -A hKeyValue
  [[ ${hRawMode[@]}  ]] || local -A hRawMode

  ## TODO permit hi uid ?
  if [[ ! $( stat -c %u $fn ) =~ ^($UID|0)$ ]]; then

    eval $( udfOnError NotPermitted "$1 owned by $( stat -c %U $fn )" )

  fi

  bIgnore=

  [[ ${hKeyValue[$s]} ]] || hKeyValue[$s]="$reKey_Val"

  ${o}.__section.select
  iKeyWidth=$( ${o}.__section.get _bashlyk_key_width )
  udfIsNumber $iKeyWidth || iKeyWidth=0

  while read -t 4; do

    if [[ $REPLY =~ $reSection ]]; then

      ## TODO section =~ ([[:print:]] && ![\[\]])
      bIgnore=1
      [[ $REPLY =~ $reValidSections ]] || continue
      bIgnore=

      (( i > 0   )) && ${o}.__section.set _bashlyk_raw_num $i
      (( iKeyWidth > 0 )) && ${o}.__section.set _bashlyk_key_width $iKeyWidth

      s="${BASH_REMATCH[2]}"

      [[ ${BASH_REMATCH[1]} == ":" ]] && bActiveSection=close
      ## TODO other modes for active section ?
      [[ ${BASH_REMATCH[3]} == ":" ]] && hRawMode[$s]="-"

      bIgnore=1
      [[ $bActiveSection == "close" ]] && bActiveSection= && ${o}.__section.set _bashlyk_raw_mode "!" && continue
      bIgnore=

      ${o}.__section.select $s
      i=0
      iKeyWidth=$( ${o}.__section.get _bashlyk_key_width )
      udfIsNumber $iKeyWidth || iKeyWidth=0

      case "${hRawMode[$s]}" in

        -) ;;

        +) i=$( ${o}.__section.get _bashlyk_raw_num )
           udfIsNumber $i || ${o}.__section.set _bashlyk_raw_num ${i:=0}
           ;;

        =) ${o}.__section.set _bashlyk_raw_mode "=";;

        *) hKeyValue[$s]="$reKey_Val";;

      esac

      continue

    else

      [[ $REPLY =~ $reComment || $bIgnore ]] && continue

    fi

    if [[ ${hKeyValue[$s]} ]]; then

      if [[ $REPLY =~ ${hKeyValue[$s]} ]]; then

        ## TODO __settings__ options for key mode - with{out} spaces & etc
        ## TODO check key for current mode
        ${o}.__section.set "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        (( ${#BASH_REMATCH[1]} > $iKeyWidth )) && iKeyWidth=${#BASH_REMATCH[1]}

      fi

    else

      if [[ ${hRawMode[$s]} == "=" ]]; then

        REPLY="$( echo $REPLY )"
        ${o}.__section.set "_bashlyk_raw_uniq=${REPLY//[\'\"\\ ]/}" "$REPLY"

      else

        ${o}.__section.set "_bashlyk_raw_incr=${i:=0}" "$REPLY"
        : $(( i++ ))

      fi

    fi

  done < $fn

  [[ ${hRawMode[$s]} =~ ^(\+|\-)$ ]] && ${o}.__section.set _bashlyk_raw_num ${i:=0}
  [[ ${hKeyValue[$s]} ]] && ${o}.__section.set _bashlyk_key_width $iKeyWidth

  return 0

}
#******
#****e* libini/INI::load
#  SYNOPSIS
#    INI::load <file> <section>:(<options>|<raw mode>) ...
#    INI::load <file> {[\[<section>\]](<options>|<raw mode>)} ...
#  DESCRIPTION
#    load the specified configuration data from a group of related INI files
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
#  NOTES
#    The file name must not begin with a point or end with a point.
#    configuration sources are ignored if they do not owned by the owner of the
#    process or root.
#  ERRORS
#    NoSuchFileOrDir - input file not exist
#    MissingArgument - parameters and sections are not selected
#  EXAMPLE
#   local iniMain iniLoad iniSave                                               #-
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
#    udfAddFile2Clean $iniSave                                                  #-
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
#   INI tLoad
#   tLoad.load $iniLoad ::[]file,main,child :: [exec]- :: [main]hint, msg , cnt :: [replace]- :: [unify]= :: [acc]+ :: #? true
#   tLoad.save $iniSave                                                         #? true
#   tLoad.show >| md5sum - | grep ^a37cbb57c7bb753968ae93db79260b44.*-$         #? true
##    tLoad.free
#  SOURCE
INI::load() {

  [[ ${1##*/} =~ ^\.|\.$ ]] && eval $( udfOnError InvalidArgument "$1" )

  local -a a
  local -A h hKeyValue hRawMode
  local csv i IFS ini fmtKeyValue fmtSections o path reSection reValidSections s sSection

  o=${FUNCNAME[0]%%.*}
  fmtSections='^[[:space:]]*(:?)\[[[:space:]]*(%SECTION%)[[:space:]]*\](:?)[[:space:]]*$'
  fmtKeyValue='^[[:space:]]*(%KEY%)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'

  [[ "$1" == "${1##*/}" && -f "$(_ pathIni)/$1" ]] && path=$(_ pathIni)
  [[ "$1" == "${1##*/}" && -f "$1"              ]] && path=$(pwd)
  [[ "$1" != "${1##*/}" && -f "$1"              ]] && path=${1%/*}
  #
  if [[ ! $path && -f "/etc/$(_ pathPrefix)/$1" ]]; then

    path="/etc/$( _ pathPrefix )"

  else

    udfOn NoSuchFileOrDir $1 || return $?

  fi

  [[ $path ]] && ini=${1##*/}

  shift

  s="$*" && IFS=':' && a=( $s )

  for s in ${a[@]}; do

    s="${s//, /,}"
    s="$( udfTrim "${s//,,/,}" )"

    if [[ $s =~ ^(\[(.*)\])?(([=+\-]?)|([^=+\-].*))$ ]]; then

      [[ ${BASH_REMATCH[1]} ]] || continue

      [[ ${BASH_REMATCH[2]} ]] && sSection="${BASH_REMATCH[2]}" || sSection=__global__

      if   [[ ${BASH_REMATCH[3]} == ${BASH_REMATCH[5]} ]]; then

        s="${BASH_REMATCH[3]}"
        s="${s//,/\|}"
        hKeyValue[$sSection]=${fmtKeyValue/\%KEY\%/$s}

      elif [[ ${BASH_REMATCH[3]} == ${BASH_REMATCH[4]} ]]; then

        hRawMode[$sSection]="${BASH_REMATCH[3]}"

      else

        continue

      fi

      ${o}.__section.select $sSection

      csv+="${sSection}|"

    fi

  done

  IFS=$' \t\n' && a=( ${ini//./ } )

  csv=${csv%*|}

  [[ $csv ]] && reValidSections=${fmtSections/\%SECTION\%/$csv}

  unset ini s

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
#****e* libini/INI::bind.cli
#  SYNOPSIS
#    INI::bind.cli [<section>-]<option long name>{<short name>}[:[:=+]] ...
#  DESCRIPTION
#    Parse command line options and bind to the INI instance
#  ARGUMENTS
#    <option name> - option name that used as long option of the CLI and key for
#                    array of the INI data
#    <section>     - part of the option name for binding it to a certain section
#                    of the INI data. By default, it is assumed that option is
#                    included to the global section
#    <short name>  - short alias as single letter for option name
#    first  :      - option is expected to have a required argument
#    second :      - argument is a optional
#           =      - option is expected to have list of unique arguments
#           +      - option is expected to have list of accumulated arguments
#                    by default, option is included in the global section of the
#                    INI instance data
#  ERRORS
#    MissingArgument - arguments is not specified
#    InvalidArgument - invalid format of the arguments
#  EXAMPLE
#    local ini
#    _ sArg "-F CLI -E clear -H 'Hi!' -M test -U a.2 -U a.2 --acc a --acc b "   #-
#    udfMakeTemp ini
#    tLoad.save $ini                                                            #? true
#    tLoad.free
#    _ onError retwarn
#    INI tCLI
#    tCLI.bind.cli                                                              #? $_bashlyk_iErrorInvalidOption
#    tCLI.bind.cli file{F}: exec{E}:- main-hint{H}: main-msg{M}: unify{U}:=     #? $_bashlyk_iErrorInvalidOption
#    tCLI.bind.cli file{F}: exec{E}:- main-hint{H}: main-msg{M}: unify{U}:= acc:+                      #? true
#    tCLI.load $ini []file,main,child : [exec]- : [main]hint,msg,cnt : [replace]- : [unify]= : [acc]+  #? true
#    tCLI.show >| md5sum - | grep ^50878d828696bb09394b2b90ea10dd84.*-$         #? true
#    tCLI.free
#  SOURCE
INI::bind.cli() {

  local -a a
  local c fnErr fmtCase fmtHandler k o sSection sShort sLong s S evalGetopts sCases v

  o=${FUNCNAME[0]%%.*}
  c=cli${RANDOM}

  INI $c
  eval "_h${o^^}[__cli__]=$c"

  fmtHandler="${c}.getopts() { while true; do case \$1 in %s --) shift; break;; esac; done }"
  fmtCase="--%s%s) ${c}.set [%s]%s = %s; shift %s;;"

  for s in $@; do

    if [[ $s =~ (([[:alnum:]]+)(-))?(@|[[:alnum:]]+)(\{([[:alnum:]])\})?([:])?([:=\+\-])? ]]; then

      s=$( declare -p BASH_REMATCH )
      eval "${s/-ar BASH_REMATCH/-a a}"

    else

      eval $( udfOnError InvalidArgument "$s - format error" )

    fi

    s=;S=;v=1;sSection="${a[2]}";k="${a[4]}"

    [[ ${a[4]} ]] && sLong+="${a[4]}${a[7]},"
    [[ ${a[6]} ]] && sShort+="${a[6]}${a[7]}" && s="|-${a[6]}"
    [[ ${a[7]} ]] && S="2" && v='$2'
    [[ ${a[8]} =~ ^(=|\-|\+)$ ]] && k="${a[8]}" && sSection="${a[4]}"

    sCases+="$( printf -- "$fmtCase" "${a[4]}" "$s" "${sSection}" "${k/=/}" "$v" "$S" ) "

  done

  udfMakeTemp fnErr
  s="$( LC_ALL=C getopt -u -o $sShort --long ${sLong%*,} -n $0 -- $(_ sArg) 2>$fnErr )"

  case $? in

    0)
      evalGetopts="$( printf -- "$fmtHandler" "$sCases" )"
      eval "$evalGetopts" && ${c}.getopts $s
      unset -f evalGetopts
    ;;

    1)
      local -A h
      while read -t 4 s; do

        s=${s//$0: /}
        s=${s// option/}
        s=${s// --/}
        h[${s% *}]+="${s##* },"

      done < $fnErr

      [[ ${h[invalid]}      ]] && s+="${h[invalid]%*,},"
      [[ ${h[unrecognized]} ]] && s+="${h[unrecognized]%*,}"

      unset h
      eval $( udfOnError InvalidOption "${s%*,} (command line:  $(_ sArg))" )

    ;;

    *)
      eval $( udfOnError InvalidOption "internal fail - $(< $fnErr)" )
    ;;

  esac

}
#******
#****e* libini/INI::getopt
#  SYNOPSIS
#    INI::getopt <option>[--]
#  DESCRIPTION
#    get option value after binding command line arguments to the INI instance
#    ( after <o>.bind.cli call )
#  ARGUMENTS
#    <option> - option name that used as long option of the CLI and key for
#               array of the INI data
#          -- - expected list of the values - serialized array
#  ERRORS
#    MissingArgument - arguments is not specified
#    InvalidArgument - invalid format of the arguments
#    EmptyResult     - option not found
#    NotAvailable    - CLI object not exist ( <o>.bind.cli not runned )
#  OUTPUT
#    option value
#  EXAMPLE
#    _ sArg "-F CLI -E clear -H 'Hi!' -M test -U a.2 -U a.2"                    #-
#    INI tOpt
#    tOpt.getopt                                                                #? $_bashlyk_iErrorMissingArgument
#    tOpt.getopt not-exist                                                      #? $_bashlyk_iErrorNotAvailable
#    tOpt.getopt invalid - argument - list                                      #? $_bashlyk_iErrorInvalidArgument
#    tOpt.bind.cli file{F}: exec{E}:- main-hint{H}: main-msg{M}: unify{U}:=     #? true
#    tOpt.getopt file                                                           #? true
#    tOpt.getopt exec--                                                         #? true
#    tOpt.getopt main-hint                                                      #? true
#    tOpt.getopt main-msg                                                       #? true
#    tOpt.getopt unify--                                                        #? true
#    tOpt.getopt acc--                                                          #? $_bashlyk_iErrorEmptyResult
#    tOpt.free
#  SOURCE
INI::getopt() {

  local -a a
  local IFS o s="$*"

  IFS='-' a=( $s )

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
      udfOn MissingArgument "$*" || return $?
      return $( _ iErrorInvalidArgument )
    ;;

  esac

  o=${FUNCNAME[0]%%.*}
  eval "o=\${_h${o^^}[__cli__]}"

  udfOn EmptyVariable o || return $( _ iErrorNotAvailable )

  ${o}.get [${s}]${k}

}
#******
