#
# $Id: libini.sh 779 2017-06-15 01:04:54+04:00 toor $
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
#    # create ini object from INI class
#    INI ini
#
#    # bind to ini object CLI options
#    ## TODO detailed description required
#    ini.bind.cli config{c}: source{s}:-- help{h} mode{m}: dry-run
#
#    # get value of the --config (-c) option
#    conf=$( ini.getopt config )
#
#    # load selected only options from ini configuration file and combine with
#    # CLI options.
#    # [!] CLI options with the same name have higher priority
#    ini.load $conf                                                            \
#                  []mode,help                                                 \
#               [dry]run                                                       \
#            [source]=
#
#    # check value of the option 'run' from section 'dry'
#    if [[ $( ini.get [dry]run ) =~ ^(true|yes|1)$ ]]; then
#      echo "dry run, view current config:"
#
#      # show configuration in the ini format
#      ini.show
#      exit 0
#    fi
#
#    # set new value for 'mode' options from global section
#    ini.set mode = demo
#
#    # add new items to list of unique values
#    ini.set [source] = $HOME
#    ini.set [source] = /var/mail/$USER
#
#    # save updated configuration to file
#    ini.save $conf
#
#    # destroy ini object, free resources
#    ini.free
#
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libini/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBINI provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBINI" ] && return 0 || _BASHLYK_LIBINI=1
[ -n "$_BASHLYK" ] || . ${_bashlyk_pathLib}/bashlyk || eval '                  \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* libini/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****G* libini/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
declare -rg _bashlyk_cnf_reKey='^\b([_a-zA-Z][_a-zA-Z0-9]*)\b$'
declare -rg _bashlyk_ini_reKey='^\b([^=]+)\b$'
declare -rg _bashlyk_cnf_reKeyVal='^[[:space:]]*\b([_a-zA-Z][_a-zA-Z0-9]*)\b=(.*)[[:space:]]*$'
declare -rg _bashlyk_ini_reKeyVal='^[[:space:]]*\b([^=]+)\b[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
declare -rg _bashlyk_cnf_fmtPairs='^[[:space:]]*\b(%KEY%)\b=(.*)[[:space:]]*$'
declare -rg _bashlyk_ini_fmtPairs='^[[:space:]]*\b(%KEY%)\b[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'

declare -rg _bashlyk_methods_ini="                                             \
                                                                               \
    __section.id __section.byindex __section.select __section.show             \
    __section.setRawData __section.getArray get set show save read             \
    settings settings.section.padding settings.shellmode                       \
    keys load bind.cli getopt free                                             \
"

declare -rg _bashlyk_externals_ini="                                           \
                                                                               \
    getopt sha1sum mkdir mv pwd rm stat touch                                  \
                                                                               \
"

declare -rg _bashlyk_exports_ini="                                             \
                                                                               \
    INI INI::{get,set,keys,show,save,read,load,bind.cli,getopt,settings,       \
              settings.section.padding,settings.shellmode,free}                \
                                                                               \
"
_bashlyk_iErrorIniMissingMethod=111
_bashlyk_iErrorIniBadMethod=110
_bashlyk_iErrorIniExtraCharInKey=109
_bashlyk_hError[$_bashlyk_iErrorIniMissingMethod]="instance failed - missing method"
_bashlyk_hError[$_bashlyk_iErrorIniBadMethod]="instance failed - bad method"
_bashlyk_hError[$_bashlyk_iErrorIniExtraCharInKey]="extra character(s) in the key"
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
#    InvalidVariable  - invalid variable name for instance
#    IniMissingMethod - method not found
#    IniBadMethod     - bad method
#  EXAMPLE
#    INI tnew                                                                   #? true
#    ## TODO check errors
#    declare -pf tnew.show >/dev/null 2>&1                                      #= true
#    declare -pf tnew.save >/dev/null 2>&1                                      #= true
#    declare -pf tnew.load >/dev/null 2>&1                                      #= true
#    tnew.__section.id @ >| grep _hTNEW_settings                                #? true
#    tnew.free
#  SOURCE
INI() {

  local f fn s o=${1:-INI}

  throw on InvalidVariable $o

  declare -Ag -- _h${o^^}_settings='(                                          \
                                                                               \
    [chComment]="#"                                                            \
    [bSectionPadding]="true"                                                   \
    [bShellMode]="false"                                                       \
    [reKey]="$_bashlyk_ini_reKey"                                              \
    [reKeyVal]="$_bashlyk_ini_reKeyVal"                                        \
    [fmtPairs]="$_bashlyk_ini_fmtPairs"                                        \
    [fmtSection0]="\n\n[ %s ]%s\n\n"                                           \
    [fmtSection1]="\n%s[ %s ]\n"                                               \
                                                                               \
  )'

  declare -Ag -- _h${o^^}="([__settings__]=_h${o^^}_settings)"
  declare -ag -- _a${o^^}="()"

  std::temp fn path="${TMPDIR}/${USER}/bashlyk" prefix='ini.' suffix=".${o}"

  for s in $_bashlyk_methods_ini; do

    f=$( declare -pf INI::${s} 2>/dev/null ) || on error throw IniMissingMethod "INI::${s} for $o"

    echo "${f/INI::$s/${o}.$s}" >> $fn || on error throw IniBadMethod "INI::$s for $o"

  done

  source $fn || on error throw InvalidArgument "$fn"
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
#    tSectionIndex.__section.select test "with double" quotes
#    tSectionIndex.__section.byindex   >| grep ^4$                              #? true
#    tSectionIndex.__section.byindex 0 >| grep ^__global__$                     #? true
#    tSectionIndex.__section.byindex 1 >| grep ^sItem1$                         #? true
#    tSectionIndex.__section.byindex 2 >| grep ^sItem2$                         #? true
#    tSectionIndex.__section.byindex 3
#    tSectionIndex.free
#  SOURCE
INI::__section.byindex() {

  local i o=${FUNCNAME[0]%%.*} s

  std::isNumber $1 && i=$1 || i=@

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
#    select current section of the instance, prepare INI getter/setter for the
#    private storage of the selected section
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

  local id o s="${@:-__global__}"

  s="${s//\"/\'\'}"

  o=${FUNCNAME[0]%%.*}
  eval "id=\${_h${o^^}[$s]}"

  if [[ ! $id ]]; then

    id=$( exec -c sha1sum <<< "$s" )
    id="_h${o^^}_${id:0:40}"

    declare -Ag -- $id="()"

    eval "_h${o^^}[$s]=$id; _a${o^^}[\${#_a${o^^}[@]}]=\"$s\""

  fi

  eval "                                                                       \
                                                                               \
    id=\${_h${o^^}[$s]};                                                       \
    ${o}.__section.set() { [[ \$1 ]] && $id[\$1]=\"\$2\"; };                   \
    ${o}.__section.get() { [[ \$* ]] && echo \"\${$id[\$*]}\"; };              \
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
#    tSShow.__section.show tSect >| md5sum | grep ^39277799012588d417f0ef8e.*-$ #? true
#    tSShow.__section.select
#    tSShow.__section.set key "unnamed section"
#    tSShow.__section.show >| md5sum | grep ^12790719e0b9d1f73db7a950368df8.*-$ #? true
#    tSShow.free
#    INI tSShow2
#    tSShow2.settings.shellmode true
#    tSShow2.set [ tSect2 ] keyFirst   = is first value
#    tSShow2.set [ tSect2 ] keySecond  = is second value
#    tSShow2.set [ tSect2 ] keyOneWord = is_one_world_value
#    tSShow2.__section.show tSect2 >| md5sum | grep ^648e93c0ed92724db16782.*-$ #? true
#    tSShow2.free
#    INI tCheckSpaces
#    ## TODO tests checking
#    tCheckSpaces.set [ section ] key = value
#    tCheckSpaces.settings.section.padding = false
#    tCheckSpaces.show                                >| grep '^\[section\]$'   #? true
#    tCheckSpaces.settings.section.padding = true
#    tCheckSpaces.show                                >| grep '^\[ section \]$' #? true
#    tCheckSpaces.free
#  SOURCE
INI::__section.show() {

  local iC id k o sA sU s

  o=${FUNCNAME[0]%%.*}

  ${o}.__section.select $*
  id=$( ${o}.__section.id $* )

  sU=$( ${o}.__section.get _bashlyk_raw_mode )

  [[ $sU == '!' ]] && sA=':' || sA=

  if [[ $1 ]]; then

    printf -- "$( ${o}.settings fmtSection0 )" "${@//\'\'/\"}" "$sA"

  else

    echo ""

  fi

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

    if std::isNumber $iC && (( iC > 0 )); then

      for (( k=0; k < $iC; k++ )); do

        ${o}.__section.get "_bashlyk_raw_incr=$k"

      done

    else

      local bQuote iKeyWidth iPad v

      iKeyWidth=$( ${o}.__section.get _bashlyk_key_width )
      std::isNumber $iKeyWidth || iKeyWidth=''

      iPad=$( ${o}.settings iPadding )

      std::isNumber $iPad || iPad=4

      if [[ $( ${o}.settings.shellmode ) =~ ^(true|yes|1)$ ]]; then

        bQuote=true
        iPad=0

      else

        bQuote=''

      fi

      eval "                                                                   \
                                                                               \
        for k in \"\${!$id[@]}\"; do                                           \
          if [[ ! \$k =~ ^_bashlyk_ ]]; then                                   \
            v=\${$id[\$k]};                                                    \
            [[ \$bQuote ]] && v=\$( std::lazyquote \$v );                      \
            printf -- '%${iPad}s%${iKeyWidth}s%${iPad}s=%${iPad}s%s\n'         \
              \"\" \"\$k\" \"\" \"\"  \"\$v\";                                 \
          fi                                                                   \
        done;                                                                  \
                                                                               \
      "

    fi

  fi

  ## TODO unnamed section behavior ?
  [[ $sA ]] && printf "$( ${o}.settings fmtSection1 )" "$sA" "${@//\'\'/\"}"

  return 0

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
#    -+   - add "raw" record with incremented key like "_bashlyk_raw_incr=<No>"
#    =    - add or update "raw" unique record with key like
#           "_bashlyk_raw_uniq=<input data without spaces and quotes>"
#    data - input data, interpreted as "raw" record
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

  shift && s="$( std::trim "$*" )"

  case "$c" in

    =)

       ${o}.__section.set "_bashlyk_raw_uniq=${s//[\'\"\\ ]/}" "$s"

    ;;

    -|+)

       i=$( ${o}.__section.get _bashlyk_raw_num )
       std::isNumber $i || i=0
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
#    a unique "raw" records (with the prefix "_bashlyk_raw_uniq=...") or
#    incremented records (with prefix "_bashlyk_raw_incr=...")
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
  std::isHash $id || on error $(_ onError) InvalidHash $id

  sU=$( ${o}.__section.get _bashlyk_raw_mode )

  if [[ $sU == "=" ]]; then

    eval "                                                                     \
                                                                               \
      for i in \"\${!$id[@]}\"; do                                             \
                                                                               \
        [[ \$i =~ ^_bashlyk_raw_uniq= ]] && a[\${#a[@]}]=\"\${$id[\$i]}\";     \
                                                                               \
      done;                                                                    \
                                                                               \
    "

  else

    iC=$( ${o}.__section.get _bashlyk_raw_num )
    if std::isNumber $iC && (( iC )); then

      eval "                                                                   \
                                                                               \
        for (( i=0; i < $iC; i++ )); do                                        \
                                                                               \
          a[\${#a[@]}]=\"\${$id[_bashlyk_raw_incr=\$i]}\";                     \
                                                                               \
        done;                                                                  \
                                                                               \
      "

    fi

  fi

  declare -pa a 2>/dev/null || return $( _ iErrorEmptyResult )

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
#    tGet.__section.set "key with spaces" "is value"
#    tGet.get [section] key with spaces >| grep '^is value$'                    #? true
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
#    tGet.get [a][b]                                                            #? $_bashlyk_iErrorInvalidArgument
#    tGet.get [accumu] >| md5sum | grep ^9cb6e155955235c701959b4253d7417b.*-$   #? true
#    tGet.get [unique] >| md5sum | grep ^9c964b5b47f6dcc62be09c5de82a6d4e.*-$   #? true
#    tGet.free
#  SOURCE
INI::get() {

  errorify on MissingArgument $* || return

  local -a a
  local IFS o k s="$*" v

  IFS='[]' && a=( $s ) && IFS=$' \t\n'

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
      on error warn+return InvalidArgument $*
      ;;

  esac

  if [[ $k =~ _bashlyk_raw ]]; then

    ${o}.__section.getArray $s

  else

    ${o}.__section.select $s
    ${o}.__section.get $( std::trim "$k" )

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
      on error warn+return InvalidArgument "${a[@]}"
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
#    tSet.set                                                                   #? $_bashlyk_iErrorMissingArgument
#    tSet.set [section]key = is value
#    tSet.set key = is unnamed section
#    tSet.set key with spaces = is unnamed section
#    tSet.show
#    tSet.get [section]key >| grep '^is value$'                                 #? true
#    tSet.get   key >| grep '^is unnamed section$'                              #? true
#    tSet.get []key >| grep '^is unnamed section$'                              #? true
#    tSet.get key with spaces >| grep '^is unnamed section$'                    #? true
#    tSet.set [section1]+= is raw value No.1
#    tSet.set [section1] += is raw value No.2
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
#    err::status
#    InvalidInput.set [section] Thu, 30 Jun 2016 08:55:36 +0400                 #? $_bashlyk_iErrorInvalidArgument
#    err::status
#    InvalidInput.free
#  SOURCE
INI::set() {

  errorify on MissingArgument $* || return

  local iKeyWidth o k s v

  if [[ $* =~ [[:space:]]*([^=]*)[[:space:]]*=[[:space:]]*(.*)[[:space:]]* ]];
  then

    s=${BASH_REMATCH[1]}
    v=${BASH_REMATCH[2]}

  else

  on error InvalidArgument $*

  fi

  k="$( std::trim "${s##*]}" )"
  s="$( std::trim "${s%]*}"  )"

  [[ $s == $k ]] && s=__global__
  [[ ${s/[/}  ]] && s=$( std::trim "${s/[/}" ) || s=__global__

  o=${FUNCNAME[0]%%.*}

  : ${k:==}

  ${o}.__section.select $s

  if [[ $k =~ ^(=|\-|\+)$ ]]; then

    ${o}.__section.setRawData "$k" "$v"

  else

    [[ $k =~ $( ${o}.settings reKey ) ]] || on error IniExtraCharInKey "$k"

    iKeyWidth=$( ${o}.__section.get _bashlyk_key_width )
    std::isNumber $iKeyWidth || iKeyWidth=0

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
#    tShow.show        >| md5sum - | grep ^ea41a8a4d178df401850fbc701fbba58.*-$ #? true
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
#    std::temp fn
#    pid::onExit.unlink ${fn}.bak
#    INI tSave
#    tSave.__section.select section
#    tSave.__section.set key "is value"
#    tSave.__section.select
#    tSave.__section.set key "unnamed section"
#    tSave.save $fn
#    tSave.free
#    tail -n +4 $fn    >| md5sum - | grep ^ec11a98eb5eff761999bb604cae70d70.*-$ #? true
#    INI tComments
#    ## TODO globs
#    tComments.settings chComment = \# this is comment';'
#    tComments.save $fn
#    cat $fn             >| grep -Po "^# this is comment; created .* by $USER"  #? true
#    tComments.settings chComment =
#    tComments.save $fn
#    cat $fn             >| grep -Po "^# created .* by $USER"                   #? true
#    tComments.free
#  SOURCE
INI::save() {

  throw on MissingArgument $1

  local c fmtComment fn o

  fmtComment='%COMMENT%\n%COMMENT% created %s by %s\n%COMMENT%\n'
  fn="$1"
  o=${FUNCNAME[0]%%.*}

  c=$( ${o}.settings chComment )
  : ${c:=#}

  [[ -s $fn ]] && mv -f $fn ${fn}.bak

  mkdir -p ${fn%/*} && touch $fn || on error throw NotExistNotCreated ${fn%/*}

  {

    printf -- "${fmtComment//%COMMENT%/$c}" "$( std::dateR )" "$( _ sUser )"
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
#   std::temp ini suffix=".ini"                                               #-
#    cat <<'EOFini' > ${ini}                                                    #-
#    key              = on the global unnamed section                           #-
#    key.with.dot     = with dot                                                #-
#    key::with::colon = with colon                                              #-
#[section with  punct (!#%^&*+=|?$) and spaces: "Foo Bar" <user@host.domain>]   #-
#                key = $(date -R)                                               #-
#                   b=false                                                     #-
#    key with spaces =  value with spaces                                       #-
#                 iX =80                                                        #-
#                  iY= 25                                                       #-
#                  iZ=                                                          #-
#        multi equal = value with equal ( = ), more = stop.                     #-
#    simple line without "key value" pairs                                      #-
#                                                                               #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#         export HOSTNAME=$(hostname)                                           #-
#    fi                                                                         #-
#:[exec]                                                                        #-
#[replace]                                                                      #-
#    this is a line of the raw data                                             #-
#    key = in the base mode                                                     #-
#    key in = the base mode                                                     #-
#    key in the = base mode                                                     #-
#[ section with raw data ]                                                      #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#[unify]                                                                        #-
#    # this is a comment                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    key = in the base mode                                                     #-
#    key in = the base mode                                                     #-
#    key in the = base mode                                                     #-
#    EOFini                                                                     #-
#   _ onError retwarn
#   INI tRead
#   tRead.read                                                                  #? $_bashlyk_iErrorMissingArgument
#   tRead.read /not/exist/file.$$.ini                                           #? $_bashlyk_iErrorNoSuchFileOrDir
#   tRead.read $ini                                                             #? true
#   tRead.show         >| md5sum - | grep ^f01c7775fb8969d7ee07ea39015356c4.*-$ #? true
#   tRead.free
#  SOURCE
INI::read() {

  errorify on MissingArgument $1 || return
  errorify on NoSuchFileOrDir $1 || return

  local bActiveSection bIgnore csv fn i iKeyWidth reComment reKeyVal reSection
  local reValidSections s

  o=${FUNCNAME[0]%%.*}

  reSection='^[[:space:]]*(:?)\[[[:space:]]*([[:print:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
  reComment='^[[:space:]]*$|(^|[[:space:]]+)[\#\;].*$'

  reKeyVal=$( ${o}.settings reKeyVal )

  s="__global__"
  fn="$1"

  [[ $2 ]] && reValidSections="$2" || reValidSections="$reSection"
  [[ ${hKeyValue[@]} ]] || local -A hKeyValue
  [[ ${hRawMode[@]}  ]] || local -A hRawMode

  ## TODO permit hi uid ?
  if [[ ! $( exec -c stat -c %u $fn ) =~ ^($UID|0)$ ]]; then

    on error NotPermitted $1 owned by $( stat -c %U $fn )

  fi

  bIgnore=

  [[ ${hKeyValue[$s]} ]] || hKeyValue[$s]="$reKeyVal"

  ${o}.__section.select
  iKeyWidth=$( ${o}.__section.get _bashlyk_key_width )
  std::isNumber $iKeyWidth || iKeyWidth=0

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
      if [[ $bActiveSection == "close" ]]; then

        bActiveSection=
        ${o}.__section.set _bashlyk_raw_mode "!"
        continue

      fi
      bIgnore=

      ${o}.__section.select $s
      i=0
      iKeyWidth=$( ${o}.__section.get _bashlyk_key_width )
      std::isNumber $iKeyWidth || iKeyWidth=0

      case "${hRawMode[$s]}" in

        -) ;;

        +) i=$( ${o}.__section.get _bashlyk_raw_num )
           std::isNumber $i || ${o}.__section.set _bashlyk_raw_num ${i:=0}
           ;;

        =) ${o}.__section.set _bashlyk_raw_mode "=";;

        *) hKeyValue[$s]="$reKeyVal";;

      esac

      continue

    else

      [[ $REPLY =~ $reComment || $bIgnore ]] && continue

    fi

    if [[ ${hKeyValue[$s]} ]]; then

      if [[ $REPLY =~ ${hKeyValue[$s]} ]]; then

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
## TODO well known places of the configuration don't worked..
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
#   std::temp -v iniMain suffix=.ini                                            #-
#   GLOBIGNORE="*:?"                                                            #-
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
#    pid::onExit.unlink $iniLoad                                                #-
#    pid::onExit.unlink $iniSave                                                #-
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
#   ## TODO add more tests
#   tLoad.load $iniLoad []file,main,child [exec]- [main]hint, msg, cnt [replace]- [unify]= [acc]+ #? true
#   tLoad.save $iniSave                                                         #? true
#   tLoad.show         >| md5sum -| grep ^9d20121502695508ff37c79f94b6ca16.*-$  #? true
##    tLoad.free
#  SOURCE
INI::load() {

  [[ ${1##*/} =~ ^\.|\.$ ]] && on error InvalidArgument "${BASH_REMATCH[0]}"

  local -a a
  local -A h hKeyValue hRawMode
  local csv i IFS ini fmtPairs fmtSections o path reSection reValidSections s
  local sSection

  o=${FUNCNAME[0]%%.*}
  fmtSections='^[[:space:]]*(:?)\[[[:space:]]*(%SECTION%)[[:space:]]*\](:?)[[:space:]]*$'

  fmtPairs=$( ${o}.settings fmtPairs )

  #
  # Internal temporary function into INI::load namespace
  #
  INI::load::parse() {

    local s sSection

    sSection=$( std::trim ${1:-__global__} )
    s="$( std::trim "${2//,[, ]/,}" )"

    if [[ $s =~ ^[=+\-]$ ]]; then

      hRawMode[$sSection]="${s//,/\|}"

    else

      hKeyValue[$sSection]=${fmtPairs/\%KEY\%/${s//,/\|}}

    fi

    ${o}.__section.select $sSection
    csv+="${sSection}|"

  }
  #
  # end INI::load::parse
  #

  [[ "$1" == "${1##*/}" && -f "$(_ pathIni)/$1" ]] && path=$(_ pathIni)
  [[ "$1" == "${1##*/}" && -f "$1"              ]] && path=$( exec -c pwd )
  [[ "$1" != "${1##*/}" && -f "$1"              ]] && path=${1%/*}

  if [[ ! $path && -f "/etc/$(_ pathPrefix)/$1" ]]; then

    path="/etc/$( _ pathPrefix )"

  else

    errorify on NoSuchFileOrDir $1 || return

  fi

  [[ $path ]] && ini=${1##*/}

  shift

  s=$* && IFS='][' && a=( $s ) && IFS=$' \t\n'

  [[ ${a[0]} ]] && INI::load::parse "" "${a[0]}"

  for (( i=1; i < ${#a[@]}; i++ )); do

    INI::load::parse "${a[$i]}" "${a[$i+1]}"

    i=$(( i+1 ))

  done

  unset -f INI::load::parse

  a=( ${ini//./ } )

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

    std::temp ini

    ${s}.save $ini
    ${o}.read $ini "$reValidSections"

    rm -f $ini

  fi

  return 0

}
#******
## TODO raw section description required
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
#    std::temp ini
#    tLoad.save $ini                                                            #? true
#    tLoad.free
#    _ onError retwarn
#    INI tCLI
#    tCLI.bind.cli                                                              #? $_bashlyk_iErrorInvalidOption
#    tCLI.bind.cli file{F}: exec{E}:- main-hint{H}: main-msg{M}: unify{U}:=     #? $_bashlyk_iErrorInvalidOption
#    tCLI.bind.cli file{F}: exec{E}:- main-hint{H}: main-msg{M}: unify{U}:= acc:+                      #? true
#    tCLI.load $ini []file,main,child [exec]- [main]hint,msg,cnt [replace]- [unify]= [acc]+  #? true
#    tCLI.show         >| md5sum - | grep ^264dd527123fc976df435cda9785dd3c.*-$ #? true
#    tCLI.free
#  SOURCE
INI::bind.cli() {

  local -a a
  local c fnErr fmtCase fmtHandler k o sSection sShort sLong s S evalGetopts sCases v

  o=${FUNCNAME[0]%%.*}
  c=cli${RANDOM}

  INI $c
  eval "_h${o^^}[__cli__]=$c"

  fmtHandler="                                                                 \
                                                                               \
    ${c}.getopts() {                                                           \
      while true; do                                                           \
        case \$1 in                                                            \
          %s --) shift; break;;                                                \
        esac;                                                                  \
      done                                                                     \
    }                                                                          \
  "

  fmtCase="--%s%s) ${c}.set [%s]%s = %s; shift %s;;"

  for s in $@; do

    if [[ $s =~ (([[:alnum:]]+)(-))?(@|[[:alnum:]]+)(\{([[:alnum:]])\})?([:])?([:=\+\-])? ]]; then

      s=$( declare -p BASH_REMATCH )
      eval "${s/-ar BASH_REMATCH/-a a}"

    else

      on error InvalidArgument $s - format error

    fi

    s=;S=;v=1;sSection="${a[2]}";k="${a[4]}"

    [[ ${a[4]} ]] && sLong+="${a[4]}${a[7]},"
    [[ ${a[6]} ]] && sShort+="${a[6]}${a[7]}" && s="|-${a[6]}"
    [[ ${a[7]} ]] && S="2" && v='$2'
    [[ ${a[8]} =~ ^(=|\-|\+)$ ]] && k="${a[8]}" && sSection="${a[4]}"

    sCases+="$(                                                                \
                                                                               \
      printf -- "$fmtCase" "${a[4]}" "$s" "${sSection}" "${k/=/}" "$v" "$S"    \
                                                                               \
    ) "

  done

  std::temp fnErr
  s="$(                                                                        \
                                                                               \
    LC_ALL=C getopt -u -o $sShort --long ${sLong%*,} -n $0 -- $(_ sArg)        \
    2>$fnErr                                                                   \
                                                                               \
  )"

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
      on error warn+return InvalidOption "${s%*,} (command line:  $( _ sArg ))"

    ;;

    *)
      on error InvalidOption "internal fail - $( < $fnErr )"
    ;;

  esac

}
#******
#****e* libini/INI::getopt
#  SYNOPSIS
#    INI::getopt <option>[--]
#  DESCRIPTION
#    get option value after binding command line options to the INI instance
#    ( it makes sense only after the execution of the method "INI::bind.cli" )
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
      errorify on MissingArgument "$*" || return
      return $( _ iErrorInvalidArgument )
    ;;

  esac

  o=${FUNCNAME[0]%%.*}
  eval "o=\${_h${o^^}[__cli__]}"

  errorify on EmptyVariable o || return $( _ iErrorNotAvailable )

  ${o}.get [${s}]${k}

}
#******
#****p* libini/INI::settings
#  SYNOPSIS
#    INI::settings [ <key> [ = <value> ] ]
#  DESCRIPTION
#    set or get propertie(s) of the INI instance
#  ARGUMENTS
#    <key>   - select propertie for action - get (show) or set
#    <value> - set new value for selected properties
#              default, show all properties with section header
#  NOTES
#    public method
#  ERRORS
#    iErrorInvalidArgument - invalid key name ( char class :alnum: expected )
#  EXAMPLE
#    INI tSettings
#    tSettings.set key = value
#    tSettings.settings bBooleanOption     =   true
#    tSettings.settings sSimpleFakeOption  =   simple fake option
#    tSettings.settings sSimpleFakeOption        >| grep '^simple fake option$' #? true
#    tSettings.settings bBooleanOption           >| grep ^true$                 #? true
#    tSettings.settings >| wc -w                  | grep ^39$                   #? true
#    tSettings.settings bSection With Spaces                                    #? $_bashlyk_iErrorInvalidArgument
#    tSettings.free
#  SOURCE
INI::settings() {

  local o=${FUNCNAME[0]%%.*} k s v

  if [[ $* =~ ^[[:space:]]*([[:alnum:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$ ]]; then

    ${o}.set [ __settings__ ] $*

  elif [[ $* =~ ^[[:space:]]*([[:alnum:]]+)[[:space:]]*$ ]]; then

    ${o}.get [ __settings__ ] $*

  elif [[ $* =~ ^[[:space:]]*$ ]]; then

    ${o}.__section.show '__settings__'

  else

    return $( _ iErrorInvalidArgument )

  fi

  return $?

}
#******
#****p* libini/INI::settings.shellmode
#  SYNOPSIS
#    INI::settings.shellmode [ [=] true|false ]
#  DESCRIPTION
#    enable/disable "active configuration" for instance INI. For example, save
#    the configuration with "shellmode = true" looks like:
#
#          var="value with whitespaces doublequoted"
#      varmore=example
#
#  ARGUMENTS
#    true  - enable
#    false - disable
#    without argument show current state of the shellmode
#  NOTES
#    public method
#  ERRORS
#    InvalidArgument - expected true or false
#  EXAMPLE
#    INI tShellmode
#    tShellmode.settings.shellmode                              >| grep ^false$ #? true
#    tShellmode.settings.shellmode = YEs                                        #? true
#    tShellmode.settings.shellmode                              >| grep ^true$  #? true
#    tShellmode.settings.shellmode = error                                      #? $_bashlyk_iErrorInvalidArgument
#    tShellmode.free
#  SOURCE
INI::settings.shellmode() {

  local o=${FUNCNAME[0]%%.*}

  [[ $1 =~ ^[[:space:]]*=[[:space:]]*$ ]] && shift

  ${o}.__section.select __settings__

  case ${*,,} in

    true|yes|1)

      ${o}.__section.set reKey $_bashlyk_cnf_reKey
      ${o}.__section.set reKeyVal $_bashlyk_cnf_reKeyVal
      ${o}.__section.set fmtPairs $_bashlyk_cnf_fmtPairs
      ${o}.__section.set bShellMode true

    ;;

    false|no|0)

      ${o}.__section.set reKey $_bashlyk_ini_reKey
      ${o}.__section.set reKeyVal $_bashlyk_ini_reKeyVal
      ${o}.__section.set fmtPairs $_bashlyk_ini_fmtPairs
      ${o}.__section.set bShellMode false

    ;;

            '')

      ${o}.__section.get bShellMode

    ;;

             *)

      return $( _ iErrorInvalidArgument )

    ;;

  esac

}
#******
#****p* libini/INI::settings.section.padding
#  SYNOPSIS
#    INI::settings.section.padding [ [=] true|false ]
#  DESCRIPTION
#    enable/disable padding with one whitespace around section name.
#    default is enabled
#  ARGUMENTS
#    true  - enable
#    false - disable
#    without argument show current state of the section padding
#  NOTES
#    public method
#  ERRORS
#    InvalidArgument - expected true or false
#  EXAMPLE
#    INI tShellmode
#    tShellmode.settings.section.padding                        >| grep ^true$  #? true
#    tShellmode.settings.section.padding = FALSE                                #? true
#    tShellmode.settings.section.padding                        >| grep ^false$ #? true
#    tShellmode.settings.section.padding = error                                #? $_bashlyk_iErrorInvalidArgument
#    tShellmode.free
#  SOURCE
INI::settings.section.padding() {

  local o=${FUNCNAME[0]%%.*}

  [[ $1 =~ ^[[:space:]]*=[[:space:]]*$ ]] && shift

  ${o}.__section.select __settings__

  case ${*,,} in

    true|yes|1)

      ${o}.__section.set fmtSection0 "\n\n[ %s ]%s\n\n"
      ${o}.__section.set fmtSection1 "\n%s[ %s ]\n"
      ${o}.__section.set bSectionPadding true

    ;;

    false|no|0)

      ${o}.__section.set fmtSection0 "\n\n[%s]%s\n\n"
      ${o}.__section.set fmtSection1 "\n%s[%s]\n"
      ${o}.__section.set bSectionPadding false

    ;;

            '')

      ${o}.__section.get bSectionPadding

    ;;

             *)

      return $( _ iErrorInvalidArgument )

    ;;

  esac

}
#******
