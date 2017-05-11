#
# $Id: libstd.sh 763 2017-05-11 11:40:00+04:00 toor $
#
#****h* BASHLYK/libstd
#  DESCRIPTION
#    simple common used functions
#  USES
#    liberr libmsg
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libstd/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBSTD provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBSTD" ] && return 0 || _BASHLYK_LIBSTD=1
[ -n "$_BASHLYK" ] || . ${_bashlyk_pathLib}/bashlyk || eval '                  \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* libstd/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libpid.sh ]] && . "${_bashlyk_pathLib}/libpid.sh"
[[ -s ${_bashlyk_pathLib}/libmsg.sh ]] && . "${_bashlyk_pathLib}/libmsg.sh"
#******
#****v* libstd/Global Variables
#  DESCRIPTION
#    Global variables of the library
#    * $_bashlyk_sWSpaceAlias - substitution for whitespace
#  SOURCE
#: ${_bashlyk_envXSession:=}
: ${TMPDIR:=/tmp}
: ${HOSTNAME:=$( exec -c hostname 2>/dev/null )}
: ${_bashlyk_sWSpaceAlias:=$( printf -- "\u00a0" )}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}

declare -rg _bashlyk_iMaxOutputLines=1000

declare -rg _bashlyk_aRequiredCmd_std="                                        \
                                                                               \
    chgrp chmod chown echo expr md5sum mkdir mkfifo mktemp|tempfile rm touch   \
                                                                               \
"

declare -rg _bashlyk_aExport_std="                                             \
                                                                               \
    _  udfAlias2WSpace udfCat udfGetFreeFD udfGetMd5 udfGetPathMd5             \
    udfGetTimeInSec udfIsHash udfIsNumber udfIsValidVariable udfMakeTemp       \
    udfMakeTempV  udfPrepareByType udfQuoteIfNeeded udfShowVariable udfTrim    \
    udfWSpace2Alias udfXml                                                     \
                                                                               \
"
#******
#****f* libstd/udfIsNumber
#  SYNOPSIS
#    udfIsNumber <number> [<tag>]
#  DESCRIPTION
#    Checking the argument that it is a natural number
#    The argument is considered a number if it contains decimal digits and can
#    have a symbol at the end - a sign of order, for example, k M G T
#    (kilo-, Mega-, Giga-, Terra-)
#  INPUTS
#    <number> - input data
#    <tag>    - a set of characters, one of which is permissible after the
#    digits to indicate a characteristic of a number, for example, of order.
#    (The register does not matter)
#  RETURN VALUE
#    0               - argument is a natural number
#    NotNumber       - argument is not natural number
#    MissingArgument - no arguments
#  EXAMPLE
#    udfIsNumber 12                                                             #? true
#    udfIsNumber 34k k                                                          #? true
#    udfIsNumber 67M kMGT                                                       #? true
#    udfIsNumber 89G G                                                          #? true
#    udfIsNumber 12,34                                                          #? $_bashlyk_iErrorNotNumber
#    udfIsNumber 12T                                                            #? $_bashlyk_iErrorNotNumber
#    udfIsNumber 1O2                                                            #? $_bashlyk_iErrorNotNumber
#    udfIsNumber                                                                #? $_bashlyk_iErrorMissingArgument
#  SOURCE
udfIsNumber() {

  local s

  [[ $2 ]] && s="[$2]?"

  [[ $1 =~ ^[0-9]+${s}$ ]] && return 0

  [[ $1 ]] || return $_bashlyk_iErrorMissingArgument

  return $_bashlyk_iErrorNotNumber

}
#******
#****f* libstd/udfShowVariable
#  SYNOPSIS
#    udfShowVariable <var>[,|;| ]...
#  DESCRIPTION
#    Listing the values of the arguments if they are variable names. It is
#    possible to separate the names of variables by the signs ',' and ';',
#    however, it must be remembered that the ';' (Or entire arguments) must be
#    quoted.
#    If the argument is not a valid variable name, an appropriate message is
#    displayed. The function can be used to form the initialization lines for
#    variables, while the information lines are escaped by the ':' command when
#    parsing by the interpreter; they can also be filtered using the command
#    "grep -v '^:'".
#  INPUTS
#    <var> - list of the variables
#  OUTPUT
#    Listing the values of the arguments if they are variable names.
#    Service lines are output with the initial ':' to automatically suppress the
#    execution capability
#  EXAMPLE
#    local s='text' b='true' i=2015 a='true 2015 text'
#    udfShowVariable a,b';' i s 1w >| md5sum - | grep ^72f4ca740b23dcec5a82.*-$ #? true
#  SOURCE
udfShowVariable() {

  local bashlyk_udfShowVariable_a bashlyk_udfShowVariable_s IFS=$'\t\n ,;'

  for bashlyk_udfShowVariable_s in $*; do

    if udfIsValidVariable $bashlyk_udfShowVariable_s; then

      bashlyk_udfShowVariable_a+="\t${bashlyk_udfShowVariable_s}=${!bashlyk_udfShowVariable_s}\n"

    else

      bashlyk_udfShowVariable_a+=": Variable name \"${bashlyk_udfShowVariable_s}\" is not valid!\n"

    fi

  done

  echo -e ": Variable listing>\n${bashlyk_udfShowVariable_a}"

  return 0

}
#******
#****f* libstd/udfIsValidVariable
#  SYNOPSIS
#    udfIsValidVariable <arg>
#  DESCRIPTION
#    Validate <arg> as variable name
#  INPUTS
#    <arg> - expected valid variable name (without leader '$')
#  RETURN VALUE
#    0               - valid variable name
#    MissingArgument - no arguments
#    InvalidVariable - is not valid variable name
#  EXAMPLE
#    udfIsValidVariable                                                         #? $_bashlyk_iErrorMissingArgument
#    udfIsValidVariable "12w"                                                   #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable "a"                                                     #? true
#    udfIsValidVariable "k1"                                                    #? true
#    udfIsValidVariable "&w1"                                                   #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable "#k12s"                                                 #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable ":v1"                                                   #? $_bashlyk_iErrorInvalidVariable
#    udfIsValidVariable "a1-b"                                                  #? $_bashlyk_iErrorInvalidVariable
#  SOURCE
udfIsValidVariable() {

  [[ $* =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]] && return 0

  [[ $* ]] || return $_bashlyk_iErrorMissingArgument

  return $_bashlyk_iErrorInvalidVariable

}
#******
#****f* libstd/udfQuoteIfNeeded
#  SYNOPSIS
#    udfQuoteIfNeeded <arg>
#  DESCRIPTION
#    Argument with whitespaces is doublequoted
#  INPUTS
#    <arg> - input
#  OUTPUT
#    doublequoted input with whitespaces
#  EXAMPLE
#    udfQuoteIfNeeded                                                           #? $_bashlyk_iErrorMissingArgument
#    udfQuoteIfNeeded "word"                                 >| grep '^word$'   #? true
#    udfQuoteIfNeeded two words                              >| grep '^\".*\"$' #? true
#  SOURCE
udfQuoteIfNeeded() {

  if [[ "$*" =~ [[:space:]] && ! "$*" =~ ^\".*\"$ ]]; then

    echo "\"$*\""

  else

    [[ $* ]] && echo "$*" || return $_bashlyk_iErrorMissingArgument

  fi

}
#******
#****f* libstd/udfWSpace2Alias
#  SYNOPSIS
#    udfWSpace2Alias -|<arg>
#  DESCRIPTION
#    The whitespace in the argument is replaced by the "magic" sequence of
#    characters defined in the global variable $_bashlyk_sWSpaceAlias
#  INPUTS
#    <arg> - input data for conversion
#        - - expected data from the standard input
#  OUTPUT
#   input data with replaced (masked) whitespaces by a special sequence of
#   characters
#  EXAMPLE
#    a=($(udfWSpace2Alias single argument expected ... ))
#    echo ${#a[@]}                                                  >| grep ^1$ #? true
#    a=($(echo single argument expected ... | udfWSpace2Alias -))
#    echo ${#a[@]}                                                  >| grep ^1$ #? true
#  SOURCE
udfWSpace2Alias() {

  local s=$*

  case $* in

    -)
       ## TODO - on/off timeout
       while read s; do

         echo "${s// /$_bashlyk_sWSpaceAlias}"

       done
    ;;

    *)
       echo "${s// /$_bashlyk_sWSpaceAlias}"
    ;;

  esac

}
#******
#****f* libstd/udfAlias2WSpace
#  SYNOPSIS
#    udfAlias2WSpace -|<arg>
#  DESCRIPTION
#    If the input contains a sequence of characters defined in the global
#    variable $_bashlyk_WSpase2Alias, then they are replaced by a whitespace.
#    If, as a result of processing data from arguments (not from the standard
#    input), replacements are made for whitespace, then the output is quoted.
#  INPUTS
#    arg - argument
#  OUTPUT
#    input data with "restored" whitespaces
#  EXAMPLE
#    local text s
#    s="${_bashlyk_sWSpaceAlias}"
#    text="many${s}arguments${s}expected${s}..."
#    udfAlias2WSpace $text
#    a=($(udfAlias2WSpace $text))
#    echo ${#a[@]}                                                  >| grep ^4$ #? true
#    a=($(echo $text | udfAlias2WSpace -))
#    echo ${#a[@]}                                                  >| grep ^4$ #? true
#  SOURCE
udfAlias2WSpace() {

  local s=$*

  case "$s" in

    -)
       ## TODO - on/off timeout
       while read s; do

         echo "${s//${_bashlyk_sWSpaceAlias}/ }"

       done
    ;;

    *)
       udfQuoteIfNeeded "${s//${_bashlyk_sWSpaceAlias}/ }"
    ;;

  esac
}
#******
#****f* libstd/udfMakeTemp
#  SYNOPSIS
#    udfMakeTemp [ [-v] <valid variable> ] <named options>...
#  DESCRIPTION
#    make temporary file object - file, pipe or directory
#  INPUTS
#    [-v] <variable>    - the output assigned to the <variable> (as bash printf)
#                         option -v can be omitted, variable must be correct and
#                         this options must be first
#    path=<path>        - place the temporary filesystem objects in the <path>
#    prefix=<prefix>    - prefix (up to 5 characters for compatibility) for the
#                         generated name
#    suffix=<suffix>    - suffix for the generated name of temporary object
#    mode=<octal>       - the right of access to the temporary facility in octal
#    owner=<owner>      - owner of temporary object
#    group=<group>      - group of temporary object
#    type=file|pipe|dir - object type: file (the default), pipe or directory
#    keep=true|false    - temporary object is deleted by default at the end if
#                         its name is stored in a variable.
#                         true  - do not remove
#                         false - delete
#  OUTPUT
#    if -v option or valid variable is omitted then name of created temporary
#    filesystem object being printed to the standard output
#
#  ERRORS
#    NotExistNotCreated - temporary file system object is not created
#    InvalidVariable    - used invalid variable name
#    EmptyResult        - name for temporary object missing
#
#  EXAMPLE
#    ## TODO improve tests
#    local foTemp s=$RANDOM
#    _ onError return
#    udfMakeTemp foTemp path=/tmp prefix=pre. suffix=.${s}1                     #? true
#    ls -1 /tmp/pre.*.${s}1 2>/dev/null >| grep "/tmp/pre\..*\.${s}1"           #? true
#    rm -f $foTemp
#    udfMakeTemp foTemp path=/tmp type=dir mode=0751 suffix=.${s}2              #? true
#    ls -ld $foTemp 2>/dev/null >| grep "^drwxr-x--x.*${s}2$"                   #? true
#    rmdir $foTemp
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.${s}3)
#    ls -1 $foTemp 2>/dev/null >| grep "pre\..*\.${s}3$"                        #? true
#    rm -f $foTemp
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.${s}4 keep=false)                 #? true
#    echo $foTemp >| grep "${TMPDIR}/pre\..*\.${s}4"                            #? true
#    test -f $foTemp                                                            #? false
#    rm -f $foTemp
#    $(udfMakeTemp foTemp path=/tmp prefix=pre. suffix=.${s}5 keep=true)
#    ls -1 /tmp/pre.*.${s}5 2>/dev/null >| grep "/tmp/pre\..*\.${s}5"           #? true
#    rm -f /tmp/pre.*.${s}5
#    $(udfMakeTemp foTemp path=/tmp prefix=pre. suffix=.${s}6)
#    ls -1 /tmp/pre.*.${s}6 2>/dev/null >| grep "/tmp/pre\..*\.${s}6"           #? false
#    unset foTemp
#    foTemp=$(udfMakeTemp)                                                      #? true
#    ls -1l $foTemp 2>/dev/null                                                 #? true
#    test -f $foTemp                                                            #? true
#    rm -f $foTemp
#    udfMakeTemp foTemp type=pipe                                               #? true
#    test -p $foTemp                                                            #? true
#    rm -f $foTemp
#    udfMakeTemp invalid+variable                                               #? ${_bashlyk_iErrorInvalidVariable}
#    udfMakeTemp path=/proc                                                     #? ${_bashlyk_iErrorNotExistNotCreated}
#  SOURCE
udfMakeTemp() {

  if [[ "$1" == "-v" ]] || udfIsValidVariable $1; then

    [[ "$1" == "-v" ]] && shift

    udfIsValidVariable $1 || on error InvalidVariable $1

    eval 'export $1="$( shift; udfMakeTemp stdout-mode ${@//keep=false/} )"'

    [[ ${!1} ]] || on error EmptyResult $1

    [[ $* =~ keep=false || ! $* =~ keep=true ]] && pid::onExit::unlink ${!1}

    return 0

  fi

  local bPipe cmd IFS octMode optDir path s sGroup sPrefix sSuffix sUser

  cmd=direct
  IFS=$' \t\n'

  for s in $*; do

    case "$s" in

        path=*) path=${s#*=};;
      prefix=*) sPrefix=${s#*=};;
      suffix=*) sSuffix=${s#*=};;
        mode=*) octMode=${s#*=};;
       type=d*) optDir='-d';;
       type=f*) optDir='';;
       type=p*) bPipe=1;;
        user=*) sUser=${s#*=};;
       group=*) sGroup=${s#*=};;
        keep=*) continue;;
      stdout-*) continue;;
             *)

                if [[ $1 == $s ]]; then

      		  udfIsValidVariable $1 || on error InvalidVariable $s

                fi

      	        if udfIsNumber "$2" && [[ -z "$3" ]] ; then

      		  # compatibility with ancient version
      		  octMode="$2"
      		  sPrefix="$1"

      	        fi
      	     ;;
    esac

  done

  sPrefix=${sPrefix//\//}
  sSuffix=${sSuffix//\//}

  if   hash mktemp   2>/dev/null; then

    cmd=mktemp

  elif hash tempfile 2>/dev/null; then

    [[ $optDir ]] && cmd=direct || cmd=tempfile

  fi

  if [[ ! $path ]]; then

    [[ $bPipe ]] && path=$( _ pathRun ) || path="$TMPDIR"

  fi

  mkdir -p $path || on error NotExistNotCreated "$path"

  case "$cmd" in

    direct)

      s="${path}/${sPrefix:0:5}${RANDOM}${sSuffix}"

      [[ $optDir ]] && mkdir -p $s || touch $s

    ;;

    mktemp)

      s=$( mktemp --tmpdir=${path} $optDir --suffix=${sSuffix} "${sPrefix:0:5}XXXXXXXX" )

    ;;

    tempfile)

      [[ $sPrefix ]] && sPrefix="-p ${sPrefix:0:5}"
      [[ $sSuffix ]] && sSuffix="-s $sSuffix"

      s=$( tempfile -d $path $sPrefix $sSuffix )

    ;;

  esac

  if [[ $bPipe ]]; then

    rm -f  $s
    mkfifo $s
    : ${octMode:=0600}

  fi >&2

  [[ $octMode ]] && chmod $octMode $s

  ## TODO обработка ошибок
  if (( $UID == 0 )); then

    [[ $sUser  ]] && chown $sUser  $s
    [[ $sGroup ]] && chgrp $sGroup $s

  fi >&2

  if ! [[ -f "$s" || -p "$s" || -d "$s" ]]; then

    on error NotExistNotCreated $s

  fi

  [[ $* =~ keep=false ]] && pid::onExit::unlink $s

  [[ $s ]] || return $( _ iErrorEmptyResult )

  echo $s

}
#******
#****f* libstd/udfMakeTempV
#  SYNOPSIS
#    udfMakeTempV <var> [file|dir|keep|keepf[ile*]|keepd[ir]] [<prefix>]
#  DESCRIPTION
#    Create a temporary file or directory with automatic removal upon completion
#    of the script, the object name assigned to the variable.
#    Obsolete - replaced by a udfMakeTemp
#  INPUTS
#    <var>      - the output assigned to the <variable> (as bash printf)
#                 option -v can be omitted, variable must be correct and this
#                 options must be first
#    file       - create file
#    dir        - create directory
#    keep[file] - create file, keep after done
#    keepdir    - create directory, keep after done
#    prefix     - prefix for name (5 letters)
#  ERRORS
#    NotExistNotCreated - temporary file system object is not created
#    InvalidVariable    - used invalid variable name
#    EmptyResult        - name for temporary object missing
#  EXAMPLE
#    local foTemp
#    udfMakeTempV foTemp file prefix                                            #? true
#    ls $foTemp >| grep "prefi"                                                 #? true
#    udfMakeTempV foTemp dir                                                    #? true
#    ls -ld $foTemp >| grep "^drwx------.*${foTemp}$"                           #? true
#    echo $(pid::onExit::unlink $foTemp)
#    test -d $foTemp                                                            #? false
#  SOURCE
udfMakeTempV() {

  throw on MissingArgument $1

  local sKeep sType sPrefix IFS=$' \t\n'

  throw on InvalidVariable $1

  [[ $3 ]] && sPrefix="prefix=$3"

  case $2 in

            dir) sType="type=dir" ; sKeep="keep=false" ;;
           file) sType="type=file"; sKeep="keep=false" ;;
    keep|keepf*) sType="type=file"; sKeep="keep=true"  ;;
         keepd*) sType="type=dir" ; sKeep="keep=true"  ;;
             '') sType="type=file"; sKeep="keep=false" ;;
              *) sPrefix="prefix=$2";;

  esac

  udfMakeTemp $1 $sType $sKeep $sPrefix

}
#******
#****f* libstd/udfPrepareByType
#  SYNOPSIS
#    udfPrepareByType <arg>
#  DESCRIPTION
#    present argument 'Array[item]' as '{Array[item]}'
#  INPUTS
#    <arg> - valid name of variable or valid name item of array
#  OUTPUT
#    converted input string, if necessary
#  ERRORS
#    MissingArgument - аргумент не задан
#    InvalidVariable - не валидный идентификатор
#  EXAMPLE
#    _bashlyk_onError=return
#    udfPrepareByType                                                           #? $_bashlyk_iErrorMissingArgument
#    udfPrepareByType 12a                                                       #? $_bashlyk_iErrorInvalidVariable
#    udfPrepareByType 12a[te]                                                   #? $_bashlyk_iErrorInvalidVariable
## TODO - do not worked    udfPrepareByType a12[]                               #? $_bashlyk_iErrorInvalidVariable
#    udfPrepareByType _a >| grep '^_a$'                                         #? true
#    udfPrepareByType _a[1234] >| grep '^\{_a\[1234\]\}$'                       #? true
#  SOURCE
udfPrepareByType() {

  errorify on MissingArgument $1 || return

  [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*(\[.*\])?$ ]] || on error return InvalidVariable $1

  [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*\[.*\]$ ]] && echo "{$1}" || echo "$1"

}
#******
#****f* libstd/_
#  SYNOPSIS
#    _ [[<get>]=]<subname> [<value>]
#  DESCRIPTION
#    Special getter/setter for global variables with names like "$_bashlyk_..."
#  INPUTS
#    <get>     - (local) variable for getting value ${_bashlyk_<subname>}, may
#                be supressed if their name equal <subname>
#    <subname> - substantial part of the global variable ${_bashlyk_<subname>}
#    <value>   - new value for ${_bashlyk_<subname>}. The operation takes
#                precedence over the "get" mode
#                Important! If a variable is used as a <value>, then it must
#                be in double quotes, otherwise in the case of an empty value,
#                the meaning of the operation changes from "set" to "get" with
#                the output of the value to STDOUT
#  OUTPUT
#                Output the variable $_bashlyk_<subname> value in get mode
#  ERRORS
#    MissingArgument - no arguments
#    InvalidVariable - invalid variable for "get" mode
#    ## TODO updated needed
#  EXAMPLE
#    local sS sWSpaceAlias pid=$BASHPID k=key1 v=val1
#    _ k=sWSpaceAlias
#    echo "$k" >| grep "^${_bashlyk_sWSpaceAlias}$"                             #? true
#    _ sS=sWSpaceAlias
#    echo "$sS" >| grep "^${_bashlyk_sWSpaceAlias}$"                            #? true
#    _ =sWSpaceAlias
#    echo "$sWSpaceAlias" >| grep "^${_bashlyk_sWSpaceAlias}$"                  #? true
#    _ sWSpaceAlias >| grep "^${_bashlyk_sWSpaceAlias}$"                        #? true
#    _ sWSpaceAlias _-_
#    _ sWSpaceAlias >| grep "^_-_$"                                             #? true
#    _ sWSpaceAlias ""
#    _ sWSpaceAlias >| grep "^$"                                                #? true
#    _ sWSpaceAlias "two words"
#    _ sWSpaceAlias >| grep "^two words$"                                       #? true
#    _ sWSpaceAlias "$sWSpaceAlias"
#    _ sWSpaceAlias
#    _ sLastError[$pid] "_ sLastError settings test"                            #? true
#    _ sLastError[$pid] >| grep "^_ sLastError settings test$"                  #? true
#  SOURCE
_(){

  errorify on MissingArgument $1 || return

  if (( $# > 1 )); then

    ## TODO check for valid required
    eval "_bashlyk_${1##*=}=\"$2\""

  else

    case "$1" in

      *=*)

        if [[ -n "${1%=*}" ]]; then

          errorify on InvalidVariable ${1%=*} || return
          eval "export ${1%=*}=\$$( udfPrepareByType "_bashlyk_${1##*=}" )"

        else

          errorify on InvalidVariable $( udfPrepareByType "${1##*=}" ) || return
          eval "export $( udfPrepareByType "${1##*=}" )=\$$( udfPrepareByType "_bashlyk_${1##*=}" )"

        fi

      ;;

        *) eval "echo \$$( udfPrepareByType "_bashlyk_${1}" )";;

    esac

  fi

  return 0

}
#******
#****f* libstd/udfGetMd5
#  SYNOPSIS
#    udfGetMd5 [-]|--file <filename>|<args>
#  DESCRIPTION
#   make MD5 digest for input data
#  INPUTS
#    -                 - data expected from standart input
#    --file <filename> - data is a file
#    <args>            - data is a arguments list
#  OUTPUT
#    MD5 digest only
#  ERRORS
#    EmptyResult - no digest
#  EXAMPLE
#    local fn
#    udfMakeTemp fn
#    echo test > $fn                                                            #-
#    echo test | udfGetMd5 -      >| grep -w 'd8e8fca2dc0f896fd7cb4cb0031ba249' #? true
#    udfGetMd5 --file "$fn"       >| grep -w 'd8e8fca2dc0f896fd7cb4cb0031ba249' #? true
#    udfGetMd5 test               >| grep -w 'd8e8fca2dc0f896fd7cb4cb0031ba249' #? true
#  SOURCE
udfGetMd5() {

  local s

  case "$1" in

         -)                s="$( exec -c md5sum - < <( udfCat ) )";;
    --file) [[ -f $2 ]] && s="$( exec -c md5sum "$2" )"           ;;
         *) [[    $* ]] && s="$( exec -c md5sum - <<< "$*" )"     ;;

  esac

  [[ $s ]] && echo ${s%% *} || return $_bashlyk_iErrorEmptyResult

}
#******
#****f* libstd/udfGetPathMd5
#  SYNOPSIS
#    udfGetPathMd5 <path>
#  DESCRIPTION
#   Get recursively MD5 digest of all the non-hidden files in the directory
#   <path>
#  INPUTS
#    <path>  - source path
#  OUTPUT
#    List of MD5 digest with the names of non-hidden files in the directory
#    <path> recursively
#  ERRORS
#    MissingArgument - not arguments
#    NoSuchFileOrDir - path not found
#    NotPermitted    - not permissible
#  EXAMPLE
#    local path=$(udfMakeTemp type=dir)
#    echo "digest test 1" > ${path}/testfile1                                   #-
#    echo "digest test 2" > ${path}/testfile2                                   #-
#    echo "digest test 3" > ${path}/testfile3                                   #-
#    pid::onExit::unlink ${path}/testfile1
#    pid::onExit::unlink ${path}/testfile2
#    pid::onExit::unlink ${path}/testfile3
#    pid::onExit::unlink ${path}
#    udfGetPathMd5 $path >| grep ^[[:xdigit:]]*.*testfile.$                     #? true
#    udfGetPathMd5                                                              #? ${_bashlyk_iErrorMissingArgument}
#    udfGetPathMd5 /notexist/path                                               #? ${_bashlyk_iErrorNoSuchFileOrDir}
#  SOURCE
udfGetPathMd5() {

  local pathSrc="$( exec -c pwd )" pathDst s IFS=$' \t\n'

  errorify on MissingArgument $@ || return
  errorify on NoSuchFileOrDir "$@" || return

  cd "$@" 2>/dev/null || on error warn+return NotPermitted $@

  pathDst="$( exec -c pwd )"

  while read s; do

    [[ -d $s ]] && udfGetPathMd5 $s

    md5sum "${pathDst}/${s}" 2>/dev/null

  done< <(eval "ls -1drt * 2>/dev/null")

  cd "$pathSrc" || on error warn+return NotPermitted $@

  return 0

}
#******
#****f* libstd/udfXml
#  SYNOPSIS
#    udfXml tag [property] data
#  DESCRIPTION
#    Generate XML code to stdout
#  INPUTS
#    tag      - XML tag name (without <>)
#    property - XML tag property
#    data     - XML tag content
#  OUTPUT
#    Show compiled XML code
#  ERRORS
#    MissingArgument - аргумент не задан
#  EXAMPLE
#    local sTag='date TO="+0400" TZ="MSK"' sContent='Mon, 22 Apr 2013 15:55:50'
#    local sXml='<date TO="+0400" TZ="MSK">Mon, 22 Apr 2013 15:55:50</date>'
#    udfXml "$sTag" "$sContent" >| grep "^${sXml}$"                             #? true
#  SOURCE
udfXml() {

  errorify on MissingArgument $1 || return

  local IFS=$' \t\n' s

  s=($1)
  shift
  echo "<${s[*]}>${*}</${s[0]}>"

}
#******
#****f* libstd/udfGetTimeInSec
#  SYNOPSIS
#    udfGetTimeInSec [-v <var>] <number>[sec|min|hour|...]
#  DESCRIPTION
#    get a time value in the seconds from a string in the human-readable format
#  OPTIONS
#    -v <var>                    - set the result to valid variable <var>
#  ARGUMENTS
#    <numbers>[sec,min,hour,...] - human-readable string of date&time
#  ERRORS
#    InvalidArgument - invalid or missing arguments, number with a time suffix
#                      expected
#    EmptyResult     - no result
#  EXAMPLE
#    local v s=${RANDOM:0:2} #-
#    udfGetTimeInSec                                                            #? $_bashlyk_iErrorInvalidArgument
#    udfGetTimeInSec SeventenFourSec                                            #? $_bashlyk_iErrorInvalidArgument
#    udfGetTimeInSec 59seconds >| grep -w 59                                    #? true
#    udfGetTimeInSec -v v ${s}minutes                                           #? true
#    echo $v >| grep -w $(( s * 60 ))                                           #? true
#    udfGetTimeInSec -v 123s                                                    #? $_bashlyk_iErrorInvalidVariable
#    udfGetTimeInSec -v -v                                                      #? $_bashlyk_iErrorInvalidVariable
#    udfGetTimeInSec -v v -v v                                                  #? $_bashlyk_iErrorInvalidArgument
#    udfGetTimeInSec $RANDOM                                                    #? true
#  SOURCE
udfGetTimeInSec() {

  if [[ "$1" == "-v" ]]; then

    udfIsValidVariable "$2" || on error InvalidVariable $2

    [[ "$3" == "-v" ]] \
      && on error InvalidArgument "$3 - number with time suffix expected"

    eval 'export $2="$( udfGetTimeInSec $3 )"'

    [[ ${!2} ]] || eval 'export $2="$( udfGetTimeInSec $4 )"'
    [[ ${!2} ]] || on error EmptyResult $2

    return $?

  fi

  local i=${1%%[[:alpha:]]*}

  udfIsNumber $i || on error InvalidArgument "$i - number expected"

  case ${1##*[[:digit:]]} in

    seconds|second|sec|s|'') echo $i;;
       minutes|minute|min|m) echo $(( i*60 ));;
            hours|hour|hr|h) echo $(( i*3600 ));;
                 days|day|d) echo $(( i*3600*24 ));;
               weeks|week|w) echo $(( i*3600*24*7 ));;
           months|month|mon) echo $(( i*3600*24*30 ));;
               years|year|y) echo $(( i*3600*24*365 ));;
                          *) echo ""
                             on error InvalidArgument "$1 - number with time suffix expected"
                          ;;

  esac

  return $?

}
#******
#****f* libstd/udfGetFreeFD
#  SYNOPSIS
#    udfGetFreeFD
#  DESCRIPTION
#    get unused filedescriptor
#  OUTPUT
#    show given filedescriptor
#  TODO
#    race possible
#  EXAMPLE
#    udfGetFreeFD | grep -P "^\d+$"                                             #? true
#  SOURCE
udfGetFreeFD() {

  local i=0 iMax=$( ulimit -n )

  : ${iMax:=255}

  for (( i = 3; i < iMax; i++ )); do

    if [[ -e /proc/$$/fd/$i ]]; then

      continue

    else

      echo $i
      break

    fi

  done

}
#******
#****f* libstd/udfIsHash
#  SYNOPSIS
#    udfIsHash <variable>
#  DESCRIPTION
#    treated a variable as global associative array
#  ARGUMENTS
#    <variable> - variable name
#  RETURN VALUE
#    InvalidVariable - argument is not valid variable name
#    InvalidHash     - argument is not hash variable
#    Success         - argument is name of the associative array
#  EXAMPLE
#    declare -Ag -- hh='()' s5
#    udfIsHash 5s                                                               #? $_bashlyk_iErrorInvalidVariable
#    udfIsHash s5                                                               #? $_bashlyk_iErrorInvalidHash
#    udfIsHash hh                                                               #? true
#  SOURCE
udfIsHash() {

  errorify on InvalidVariable $1 || return

  [[ $( declare -pA $1 2>/dev/null ) =~ ^declare.*-A ]] \
    && return 0 || return $( _ iErrorInvalidHash )

}
#******
#****f* libstd/udfTrim
#  SYNOPSIS
#    udfTrim <arg>
#  DESCRIPTION
#    remove leading and trailing spaces
#  ARGUMENTS
#    <arg> - input data
#  OUTPUT
#    show input without leading and trailing spaces
#  EXAMPLE
#    local s=" a  b c  "
#    udfTrim "$s" >| grep "^a  b c$"                                            #? true
#    udfTrim  $s  >| grep "^a b c$"                                             #? true
#    udfTrim      >| grep ^$                                                    #? true
#    udfTrim '  ' >| grep ^$                                                    #? true
#  SOURCE
udfTrim() {

  local s="$*"

  [[ $s =~ ^\+$ ]] && s+=" "

  echo "$( expr "$s" : "^\ *\(.*[^ ]\)\ *$" )"

}
#******
#****f* libstd/udfCat
#  SYNOPSIS
#    udfCat
#  DESCRIPTION
#    show input by line
#  OUTPUT
#    show input by line
#  EXAMPLE
#    local s fn
#    udfMakeTemp -v fn
#    for s in $( seq 0 12 ); do printf -- '\t%s\n' "$RANDOM"; done > $fn        #-
#    udfCat < $fn | grep -E '^[[:space:]][0-9]{1,5}$'                           #? true
#  SOURCE
udfCat() { while IFS= read -t 32 || [[ $REPLY ]]; do echo "$REPLY"; done; }
#******
#****f* libstd/udfDateR
#  SYNOPSIS
#    udfDateR
#  DESCRIPTION
#    show 'date -R' like output
#  EXAMPLE
#    udfDateR >| grep -P "^\S{3}, \d{2} \S{3} \d{4} \d{2}:\d{2}:\d{2} .\d{4}$"  #? true
#  SOURCE
if (( _bashlyk_ShellVersion > 4002000 )); then

  udfDateR() { LC_ALL=C printf -- '%(%a, %d %b %Y %T %z)T\n' '-1'; }

else

  udfDateR() { exec -c date -R; }

fi
#******
#****f* libstd/udfUptime
#  SYNOPSIS
#    udfUptime
#  DESCRIPTION
#    show uptime value in the seconds
#  EXAMPLE
#    udfUptime >| grep "^[[:digit:]]*$"                                         #? true
#  SOURCE
if (( _bashlyk_ShellVersion > 4002000 )); then

  udfUptime() { echo $(( $(printf '%(%s)T' '-1') - $(printf '%(%s)T' '-2') )); }

else

  readonly _bashlyk_iStartTimeStamp=$( exec -c date "+%s" )

  udfUptime() { echo $(( $(exec -c date "+%s") - _bashlyk_iStartTimeStamp )); }

fi
#******
#****f* libstd/udfFinally
#  SYNOPSIS
#    udfFinally <text>
#  DESCRIPTION
#    show uptime with input text
#  INPUTS
#    <text> - prefix text before " uptime <number> sec"
#  EXAMPLE
#    udfFinally $RANDOM >| grep "^[[:digit:]]* uptime [[:digit:]]* sec$"        #? true
#  SOURCE
udfFinally() { echo "$@ uptime $( udfUptime ) sec"; }
#******
