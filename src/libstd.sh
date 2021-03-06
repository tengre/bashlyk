#
# $Id: libstd.sh 909 2019-03-12 23:30:22+04:00 yds $
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

declare -rg _bashlyk_aRequiredCmd_std="

    [ chgrp chmod chown date echo expr hostname md5sum mkdir mkfifo mktemp pwd
    rm tempfile touch

"

declare -rg _bashlyk_aExport_std="

    _ std::{acceptArrayItem,cat,date,dateR,finally,getFreeFD,getMD5,getMD5.list,
    getTimeInSec,inline,isDecimal,isHash,isNumber,isVariable,lazyquote,temp,
    trim,showVariable,whitespace.decode,whitespace.encode,xml}

"

#******
#****f* libstd/std::isNumber
#  SYNOPSIS
#    std::isNumber <number> [<tag>]
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
#  ERRORS
#    NotNumber       - argument is not natural number
#    MissingArgument - no arguments
#  EXAMPLE
#    std::isNumber 12                                                           #? true
#    std::isNumber 34k k                                                        #? true
#    std::isNumber 67M kMGT                                                     #? true
#    std::isNumber 89G G                                                        #? true
#    std::isNumber 12,34                                                        #? $_bashlyk_iErrorNotNumber
#    std::isNumber 12T                                                          #? $_bashlyk_iErrorNotNumber
#    std::isNumber 1O2                                                          #? $_bashlyk_iErrorNotNumber
#    std::isNumber                                                              #? $_bashlyk_iErrorMissingArgument
#  SOURCE
std::isNumber() {

  local s

  [[ $2 ]] && s="[$2]?"

  [[ $1 =~ ^[0-9]+${s}$ ]] && return 0

  [[ $1 ]] || return $_bashlyk_iErrorMissingArgument

  return $_bashlyk_iErrorNotNumber

}
#******
#****f* libstd/std::isDecimal
#  SYNOPSIS
#    std::isDecimal <decimal number>
#  DESCRIPTION
#    Checking the argument that it is a decimal number
#    The argument is considered a number if it contains decimal digits and can
#    have a dot
#  INPUTS
#    <decimal number> - input data
#  ERRORS
#    NotDecimal      - argument is not decimal number
#    MissingArgument - no arguments
#  EXAMPLE
#    std::isDecimal 12                                                          #? true
#    std::isDecimal +34.0                                                       #? true
#    std::isDecimal -67.0                                                       #? true
#    std::isDecimal .89                                                         #? $_bashlyk_iErrorNotDecimal
#    std::isDecimal 12.34                                                       #? true
#    std::isDecimal 12,34                                                       #? $_bashlyk_iErrorNotDecimal
#    std::isDecimal 12T                                                         #? $_bashlyk_iErrorNotDecimal
#    std::isDecimal 1O02.0O                                                     #? $_bashlyk_iErrorNotDecimal
#    std::isDecimal                                                             #? $_bashlyk_iErrorMissingArgument
#  SOURCE
std::isDecimal() {

  [[ $1 =~ ^[+-]?[0-9]+(\.[0-9]+)?$ ]] && return 0

  [[ $1 ]] && return $_bashlyk_iErrorNotDecimal || return $_bashlyk_iErrorMissingArgument

}
#******
#****f* libstd/std::showVariable
#  SYNOPSIS
#    std::showVariable <var>[,|;| ]...
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
#    std::showVariable a,b';' i s 1w                                            | {{{
#    : Variable listing>
#            a=true 2015 text
#            b=true
#            i=2015
#            s=text
#    : Variable name "1w" is not valid!
#
# }}}
#  SOURCE
std::showVariable() {

  local bashlyk_std_showVariable_a bashlyk_std_showVariable_s IFS=$'\t\n ,;'

  for bashlyk_std_showVariable_s in $*; do

    if std::isVariable $bashlyk_std_showVariable_s; then

      bashlyk_std_showVariable_a+="\t${bashlyk_std_showVariable_s}=${!bashlyk_std_showVariable_s}\n"

    else

      bashlyk_std_showVariable_a+=": Variable name \"${bashlyk_std_showVariable_s}\" is not valid!\n"

    fi

  done

  echo -e ": Variable listing>\n${bashlyk_std_showVariable_a}"

  return 0

}
#******
#****f* libstd/std::isVariable
#  SYNOPSIS
#    std::isVariable <arg>
#  DESCRIPTION
#    Validate <arg> as variable name
#  INPUTS
#    <arg> - expected valid variable name (without leader '$')
#  RETURN VALUE
#    0               - valid variable name
#    MissingArgument - no arguments
#    InvalidVariable - is not valid variable name
#  EXAMPLE
#    std::isVariable                                                            #? $_bashlyk_iErrorMissingArgument
#    std::isVariable "12w"                                                      #? $_bashlyk_iErrorInvalidVariable
#    std::isVariable "a"                                                        #? true
#    std::isVariable "k1"                                                       #? true
#    std::isVariable "&w1"                                                      #? $_bashlyk_iErrorInvalidVariable
#    std::isVariable "#k12s"                                                    #? $_bashlyk_iErrorInvalidVariable
#    std::isVariable ":v1"                                                      #? $_bashlyk_iErrorInvalidVariable
#    std::isVariable "a1-b"                                                     #? $_bashlyk_iErrorInvalidVariable
#  SOURCE
std::isVariable() {

  [[ $* =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]] && return 0

  [[ $* ]] || return $_bashlyk_iErrorMissingArgument

  return $_bashlyk_iErrorInvalidVariable

}
#******
#****f* libstd/std::lazyquote
#  SYNOPSIS
#    std::lazyquote <arg>
#  DESCRIPTION
#    Argument with whitespaces is doublequoted
#  INPUTS
#    <arg> - input
#  OUTPUT
#    doublequoted input with whitespaces
#  EXAMPLE
#    std::lazyquote                                                             #? $_bashlyk_iErrorMissingArgument
#    std::lazyquote "word"                                                      | {{ '^word$'   }}
#    std::lazyquote two words                                                   | {{ '^\".*\"$' }}
#    std::lazyquote "two words"                                                 | {{ '^\".*\"$' }}
#  SOURCE
std::lazyquote() {

  if [[ "$*" =~ [[:space:]] && ! "$*" =~ ^\".*\"$ ]]; then

    printf -- '"%s"\n' "$*"

  else

    [[ $* ]] && printf -- '%s\n' "$*" || return $_bashlyk_iErrorMissingArgument

  fi

}
#******
#****f* libstd/std::whitespace.encode
#  SYNOPSIS
#    std::whitespace.encode -|<arg>
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
#    a=($(std::whitespace.encode single argument expected ... ))
#    echo ${#a[@]}                                                              | {{ ^1$ }}
#    a=($(echo single argument expected ... | std::whitespace.encode -))
#    echo ${#a[@]}                                                              | {{ ^1$ }}
#  SOURCE
std::whitespace.encode() {

  local s=$*

  case $* in

    -)
       ## TODO - on/off timeout
       while read s; do

         printf -- '%s\n' "${s// /$_bashlyk_sWSpaceAlias}"

       done
    ;;

    *)
       printf -- '%s\n' "${s// /$_bashlyk_sWSpaceAlias}"
    ;;

  esac

}
#******
#****f* libstd/std::whitespace.decode
#  SYNOPSIS
#    std::whitespace.decode -|<arg>
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
#    std::whitespace.decode $text                                               | {{ '"' }}
#    std::whitespace.decode - <<< $text                                         | {{ '"' }}1
#    a=( $( std::whitespace.decode $text ) )
#    echo ${#a[@]}                                                              | {{ ^4$ }}
#    a=( $( std::whitespace.decode - <<< $text ) )
#    echo ${#a[@]}                                                              | {{ ^4$ }}
#  SOURCE
std::whitespace.decode() {

  local s=$*

  case "$s" in

    -)
       ## TODO - on/off timeout
       while read s; do

         printf -- '%s\n' "${s//${_bashlyk_sWSpaceAlias}/ }"

       done
    ;;

    *)
       std::lazyquote "${s//${_bashlyk_sWSpaceAlias}/ }"
    ;;

  esac
}
#******
#****f* libstd/std::temp
#  SYNOPSIS
#    std::temp [ [-v] <valid variable> ] <named options>...
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
#    local foTemp s=$RANDOM
#    _ onError return
#    std::temp foTemp path=/tmp prefix=pre. suffix=.${s}1                       #? true
#    ls -1 /tmp/pre.*.${s}1 2>/dev/null                                         | {{ "/tmp/pre\..*\.${s}1" }}
#    rm -f $foTemp
#    std::temp foTemp path=/tmp type=dir mode=0751 suffix=.${s}2                #? true
#    ls -ld $foTemp 2>/dev/null                                                 | {{ "^drwxr-x--x.*${s}2$" }}
#    rmdir $foTemp
#    foTemp=$(std::temp prefix=pre. suffix=.${s}3)
#    ls -1 $foTemp 2>/dev/null                                                  | {{ "pre\..*\.${s}3$"     }}
#    rm -f $foTemp
#    foTemp=$(std::temp prefix=pre. suffix=.${s}4 keep=false)                   #? true
#    echo $foTemp                                                               | {{ "pre\..*\.${s}4"      }}
#    test -f $foTemp                                                            #? false
#    rm -f $foTemp
#    : $(std::temp foTemp path=/tmp prefix=pre. suffix=.${s}5 keep=true)
#    ls -1 /tmp/pre.*.${s}5 2>/dev/null                                         | {{ "/tmp/pre\..*\.${s}5" }}
#    rm -f /tmp/pre.*.${s}5
#    $(std::temp foTemp path=/tmp prefix=pre. suffix=.${s}6)
#    ls -1 /tmp/pre.*.${s}6 2>/dev/null                                         | {{ "/tmp/pre\..*\.${s}6" }}!
#    unset foTemp
#    foTemp=$(std::temp)                                                        #? true
#    ls -1 $foTemp 2>/dev/null                                                  #? true
#    test -f $foTemp                                                            #? true
#    rm -f $foTemp
#    std::temp foTemp type=pipe                                                 #? true
#    test -p $foTemp                                                            #? true
#    rm -f $foTemp
#    std::temp foTemp prefix="pref." suffix=".suffix with spaces.tmp"
#    ls -1 "$foTemp"                                                            | {{ "ix with spaces.tmp$" }}
#    rm -f "$foTemp"
#    std::temp invalid+variable                                                 #? ${_bashlyk_iErrorInvalidVariable}
#    err::status                                                                | {{ -P '^invalid variable - invalid\+variable \(\d+\)$' }}
#    std::temp path=/proc                                                       #? ${_bashlyk_iErrorNotExistNotCreated}
#    err::status
#  SOURCE
std::temp() {

  if [[ "$1" == "-v" ]] || std::isVariable $1; then

    [[ "$1" == "-v" ]] && shift

    std::isVariable $1 || error InvalidVariable -- $1

    #eval 'export $1="$( shift; std::temp stdout-mode "${@//keep=false/}" )"'
    eval 'printf -v $1 "%s" "$(shift; std::temp stdout-mode "${@//keep=false/}")"'

    [[ ${!1} ]] || error EmptyResult -- $1

    [[ $* =~ keep=false || ! $* =~ keep=true ]] && pid::onExit.unlink ${!1}

    return 0

  fi

  local bPipe cmd fnErr IFS octMode optDir path s sGroup sPrefix sSuffix sUser

  cmd=direct
  fnErr=${TMPDIR:-/tmp}/${RANDOM}${RANDOM}${RANDOM}${USER}${$}
  IFS=$' \t\n'

  for s in "$@"; do

    case "$s" in

        path=*) path="${s#*=}";;
      prefix=*) sPrefix="${s#*=}";;
      suffix=*) sSuffix="${s#*=}";;
        mode=*) octMode="${s#*=}";;
       type=d*) optDir='-d';;
       type=f*) optDir='';;
       type=p*) bPipe=1;;
        user=*) sUser=${s#*=};;
       group=*) sGroup=${s#*=};;
        keep=*) continue;;
      stdout-*) continue;;
             *)

                if [[ $1 == $s ]]; then

                  std::isVariable $1 || error InvalidVariable $1

                fi

                if std::isNumber "$2" && [[ ! $3 ]] ; then

                  # compatibility with ancient version
                  octMode="$2"
                  sPrefix="$1"

                fi
             ;;
    esac

  done

  sPrefix="${sPrefix//\//}"
  sSuffix="${sSuffix//\//}"

  if   hash mktemp   2>/dev/null; then

    cmd=mktemp

  elif hash tempfile 2>/dev/null; then

    [[ $optDir ]] && cmd=direct || cmd=tempfile

  fi

  if [[ ! $path ]]; then

    [[ $bPipe ]] && path="$( _ pathRun )" || path="$TMPDIR"

  fi

  mkdir -p "$path" || error NotExistNotCreated -- $path

  pid::onExit.unlink $fnErr

  case "$cmd" in

    direct)

      s="${path}/${sPrefix:0:5}${RANDOM}${sSuffix}"

      [[ $optDir ]] && mkdir -p "$s" || touch "$s"

    ;;

    mktemp)

      s="$( LC_ALL=C mktemp --tmpdir="$path" $optDir --suffix="$sSuffix" "${sPrefix:0:5}XXXXXXXX" )"

    ;;

    tempfile)

      [[ $sPrefix ]] && sPrefix="-p ${sPrefix:0:5}"
      [[ $sSuffix ]] && sSuffix="-s $sSuffix"

      s="$( LC_ALL=C tempfile -d "$path" "$sPrefix" "$sSuffix" )"

    ;;

  esac >$fnErr 2>&1

  if [[ $bPipe ]]; then

    rm -f  "$s"
    mkfifo "$s"
    : ${octMode:=0600}

  fi >>$fnErr 2>&1

  [[ $octMode ]] && chmod $octMode $s

  ## TODO error handling
  if (( $UID == 0 )); then

    [[ $sUser  ]] && chown $sUser  $s
    [[ $sGroup ]] && chgrp $sGroup $s

  fi >>$fnErr 2>&1

  if ! [[ -f "$s" || -p "$s" || -d "$s" ]]; then

    error NotExistNotCreated -- $s $(< $fnErr)

  fi

  [[ $* =~ keep=false ]] && pid::onExit.unlink "$s"

  [[ $s ]] && printf -- '%s\n' "$s" || return $( _ iErrorEmptyResult )

}
#******
#****f* libstd/std::acceptArrayItem
#  SYNOPSIS
#    std::acceptArrayItem <arg>
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
#    std::acceptArrayItem                                                       #? $_bashlyk_iErrorMissingArgument
#    std::acceptArrayItem 12a                                                   #? $_bashlyk_iErrorInvalidVariable
#    err::status
#    std::acceptArrayItem 12a[te]                                               #? $_bashlyk_iErrorInvalidVariable
## TODO - do not worked    std::acceptArrayItem a12[]                           #? $_bashlyk_iErrorInvalidVariable
#    std::acceptArrayItem _a                                                    | {{ '^_a$'             }}
#    std::acceptArrayItem _a[1234]                                              | {{ '^\{_a\[1234\]\}$' }}
#  SOURCE
std::acceptArrayItem() {

  errorify on MissingArgument $1 || return

  [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*(\[.*\])?$ ]] || error InvalidVariable return -- $1

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
#    echo "$k"                                                                  | {{ "^${_bashlyk_sWSpaceAlias}$" }}
#    _ sS=sWSpaceAlias
#    echo "$sS"                                                                 | {{ "^${_bashlyk_sWSpaceAlias}$" }}
#    _ =sWSpaceAlias
#    echo "$sWSpaceAlias"                                                       | {{ "^${_bashlyk_sWSpaceAlias}$" }}
#    _ sWSpaceAlias                                                             | {{ "^${_bashlyk_sWSpaceAlias}$" }}
#    _ sWSpaceAlias _-_
#    _ sWSpaceAlias                                                             | {{ "^_-_$"                      }}
#    _ sWSpaceAlias ""
#    _ sWSpaceAlias                                                             | {{ "^$"                         }}
#    _ sWSpaceAlias "two words"
#    _ sWSpaceAlias                                                             | {{ "^two words$"                }}
#    _ sWSpaceAlias "$sWSpaceAlias"
#    _ sWSpaceAlias
#    _ sLastError[$pid] "_ sLastError settings test"                            #? true
#    _ sLastError[$pid]                                                         | {{"^_ sLastError settings test$"}}
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
          eval "export ${1%=*}=\$$( std::acceptArrayItem "_bashlyk_${1##*=}" )"

        else

          errorify on InvalidVariable $( std::acceptArrayItem "${1##*=}" ) || return
          eval "export $( std::acceptArrayItem "${1##*=}" )=\$$( std::acceptArrayItem "_bashlyk_${1##*=}" )"

        fi

      ;;

        *) eval "echo \$$( std::acceptArrayItem "_bashlyk_${1}" )";;

    esac

  fi

  return 0

}
#******
#****f* libstd/std::getMD5
#  SYNOPSIS
#    std::getMD5 [-]|--file <filename>|<args>
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
#    std::temp fn
#    echo test > $fn                                                            #-
#    echo test | std::getMD5 -                                                  | {{ -w 'd8e8fca2dc0f896fd7cb4cb0031ba249' }}
#    std::getMD5 --file "$fn"                                                   | {{ -w 'd8e8fca2dc0f896fd7cb4cb0031ba249' }}
#    std::getMD5 test                                                           | {{ -w 'd8e8fca2dc0f896fd7cb4cb0031ba249' }}
#  SOURCE
std::getMD5() {

  local s

  case "$1" in

         -)                s="$( exec -c md5sum - < <( std::cat ) )";;
    --file) [[ -f $2 ]] && s="$( exec -c md5sum "$2" )"           ;;
         *) [[    $* ]] && s="$( exec -c md5sum - <<< "$*" )"     ;;

  esac

  [[ $s ]] && printf -- '%s\n' "${s%% *}" || return $_bashlyk_iErrorEmptyResult

}
#******
#****f* libstd/std::getMD5.list
#  SYNOPSIS
#    std::getMD5.list <path>
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
#    local path=$(std::temp type=dir)
#    echo "digest test 1" > ${path}/testfile1                                   #-
#    echo "digest test 2" > ${path}/testfile2                                   #-
#    echo "digest test 3" > ${path}/testfile3                                   #-
#    pid::onExit.unlink ${path}/testfile1
#    pid::onExit.unlink ${path}/testfile2
#    pid::onExit.unlink ${path}/testfile3
#    pid::onExit.unlink ${path}
#    std::getMD5.list $path                                                     | {{ ^[[:xdigit:]]*.*testfile.$ }}
#    std::getMD5.list                                                           #? ${_bashlyk_iErrorMissingArgument}
#    err::status
#    std::getMD5.list /notexist/path                                            #? ${_bashlyk_iErrorNoSuchFileOrDir}
#    err::status
#  SOURCE
std::getMD5.list() {

  local pathSrc="$( exec -c pwd )" pathDst s IFS=$' \t\n'

  errorify on MissingArgument $@ || return
  errorify on NoSuchFileOrDir "$@" || return

  cd "$@" 2>/dev/null || error NotPermitted warn+return -- $@

  pathDst="$( exec -c pwd )"

  while read s; do

    [[ -d $s ]] && std::getMD5.list $s

    md5sum "${pathDst}/${s}" 2>/dev/null

  done< <(eval "ls -1drt * 2>/dev/null")

  cd "$pathSrc" || error NotPermitted warn+return -- $pathSrc

  return 0

}
#******
#****f* libstd/std::xml
#  SYNOPSIS
#    std::xml tag [property] data
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
#    std::xml "$sTag" "$sContent"                                               | {{ "^${sXml}$" }}
#  SOURCE
std::xml() {

  errorify on MissingArgument $1 || return

  local IFS=$' \t\n'
  local -a a=( $1 )

  shift

  printf -- '%s\n' "<${a[*]}>${*}</${a[0]}>"

}
#******
#****f* libstd/std::getTimeInSec
#  SYNOPSIS
#    std::getTimeInSec [-v <var>] <number>[sec|min|hour|...]
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
#    std::getTimeInSec                                                          #? $_bashlyk_iErrorInvalidArgument
#    err::status
#    std::getTimeInSec SeventenFourSec                                          #? $_bashlyk_iErrorInvalidArgument
#    err::status
#    std::getTimeInSec 59seconds                                                | {{ -w 59            }}
#    std::getTimeInSec -v v ${s}minutes                                         #? true
#    echo $v                                                                    | {{ -w $(( s * 60 )) }}
#    std::getTimeInSec -v 123s                                                  #? $_bashlyk_iErrorInvalidVariable
#    err::status
#    std::getTimeInSec -v -v                                                    #? $_bashlyk_iErrorInvalidVariable
#    err::status
#    std::getTimeInSec -v v -v v                                                #? $_bashlyk_iErrorInvalidArgument
#    err::status
#    std::getTimeInSec $RANDOM                                                  #? true
#  SOURCE
std::getTimeInSec() {

  if [[ "$1" == "-v" ]]; then

    std::isVariable "$2" || error InvalidVariable $2

    [[ "$3" == "-v" ]] \
      && error InvalidArgument -- $3 - number with time suffix expected

    eval 'export $2="$( std::getTimeInSec $3 )"'

    [[ ${!2} ]] || eval 'export $2="$( std::getTimeInSec $4 )"'
    [[ ${!2} ]] || error EmptyResult $2

    return $?

  fi

  local i=${1%%[[:alpha:]]*}

  std::isNumber $i || error InvalidArgument ${1%%[[:alpha:]]*}

  case ${1##*[[:digit:]]} in

    seconds|second|sec|s|'') echo $i;;
       minutes|minute|min|m) echo $(( i*60 ));;
            hours|hour|hr|h) echo $(( i*3600 ));;
                 days|day|d) echo $(( i*3600*24 ));;
               weeks|week|w) echo $(( i*3600*24*7 ));;
           months|month|mon) echo $(( i*3600*24*30 ));;
               years|year|y) echo $(( i*3600*24*365 ));;
                          *) echo ""
                             error InvalidArgument -- $1 - number with time suffix expected
                          ;;

  esac

  return $?

}
#******
#****f* libstd/std::getFreeFD
#  SYNOPSIS
#    std::getFreeFD
#  DESCRIPTION
#    get unused filedescriptor
#  OUTPUT
#    show given filedescriptor
#  TODO
#    race possible
#  EXAMPLE
#    std::getFreeFD                                                             | {{ -P "^\d+$" }}
#  SOURCE
std::getFreeFD() {

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
#****f* libstd/std::isHash
#  SYNOPSIS
#    std::isHash <variable>
#  DESCRIPTION
#    treated a variable as global associative array
#  ARGUMENTS
#    <variable> - variable name
#  RETURN VALUE
#    InvalidVariable - argument is not valid variable name
#    InvalidHash     - argument is not hash variable (or declared only - empty)
#    Success         - argument is name of the associative array
#  EXAMPLE
#    declare -Ag -- hh='()' s5
#    declare -ig -- i1
#    declare -ag -- aa='()'
#    std::isHash 5s                                                             #? $_bashlyk_iErrorInvalidVariable
#    err::status
#    std::isHash i1                                                             #? $_bashlyk_iErrorInvalidHash
#    err::status
#    std::isHash aa                                                             #? $_bashlyk_iErrorInvalidHash
#    err::status
#    std::isHash hh                                                             #? true
#    err::status
#  SOURCE
std::isHash() {

  errorify on InvalidVariable $1 || return

  if [[ $( declare -p $1 2>/dev/null ) =~ ^declare.-A.${1}= ]]; then

    return 0

  else

    return $( _ iErrorInvalidHash )

  fi

}
#******
#****f* libstd/std::trim
#  SYNOPSIS
#    std::trim <arg>
#  DESCRIPTION
#    remove leading and trailing spaces
#  ARGUMENTS
#    <arg> - input data
#  OUTPUT
#    show input without leading and trailing spaces
#  EXAMPLE
#    local s=" a  b c  "
#    std::trim "$s"                                                             | {{ "^a  b c$" }}
#    std::trim  $s                                                              | {{ "^a b c$"  }}
#    std::trim                                                                  | {{ ^$         }}
#    std::trim '+'                                                              | {{ ^\+$       }}
#    std::trim '  '                                                             | {{ ^$         }}
#  SOURCE
std::trim() {

  printf -- '%s\n' "$( expr "$* " : "^\ *\(.*[^ ]\)\ *$" )"

}
#******
#****f* libstd/std::cat
#  SYNOPSIS
#    std::cat
#  DESCRIPTION
#    show input by line
#  OUTPUT
#    show input by line
#  EXAMPLE
#    local s fn
#    std::temp -v fn
#    for s in $( seq 0 12 ); do printf -- '\t%s\n' "$RANDOM"; done > $fn        #-
#    std::cat < $fn                                                             | {{ -E '^[[:space:]][0-9]{1,5}$' }}
#  SOURCE
std::cat() {

  [[ $* ]] && printf -- '%s\n' "$*"

  while IFS= read -t 32 || [[ $REPLY ]]; do

    printf -- '%s\n' "$REPLY"

  done

}
#******
#****f* libstd/std::inline
#  SYNOPSIS
#    std::1nline [\[<mark linefeed>\]]
#  DESCRIPTION
#    show input as single line, mark every linefeed with mark (if this setted)
#  OUTPUT
#    show input as single line
#  EXAMPLE
#    local s fn
#    std::temp -v fn
#    for s in $( seq 0 1 ); do printf -- '%s\n' "$RANDOM"; done > $fn           #-
#    std::inline lf < $fn                                                       | {{ -E '^[0-9]{1,5} \[lf\] [0-9]{1,5} \[lf\] $' }}
#    std::inline    < $fn                                                       | {{ -E '^[0-9]{1,5} [0-9]{1,5} $' }}
#  SOURCE
std::inline() {

  local tag=''
  [[ $* ]] && tag=" [$*]"

  while IFS= read -t 32 || [[ $REPLY ]]; do

    printf -- '%s%s ' "$REPLY" "$tag"

  done

    printf -- "\n"

}
#******
#****f* libstd/std::date
#  SYNOPSIS
#    std::date <string with format controls>
#  DESCRIPTION
#    show formatted datetime output
#  EXAMPLE
#    std::date %s                                                               | {{ -P "^\d+$" }}
#  SOURCE
if (( _bashlyk_ShellVersion > 4002000 )); then

  std::date() { printf -- "%($@)T\n" '-1'; }

else

  std::date() { exec -c date +"$@"; }

fi
#******
#****f* libstd/std::dateR
#  SYNOPSIS
#    std::dateR
#  DESCRIPTION
#    show 'date -R' like output
#  EXAMPLE
#    std::dateR                                                                 | {{ -P "^\S{3}, \d{2} \S{3} \d{4} \d{2}:\d{2}:\d{2} .\d{4}$" }}
#  SOURCE
std::dateR() {

  LC_ALL=C std::date '%a, %d %b %Y %T %z'

}
#******
#****f* libstd/std::uptime
#  SYNOPSIS
#    std::uptime
#  DESCRIPTION
#    show uptime value in the seconds
#  EXAMPLE
#    std::uptime                                                                | {{ "^[[:digit:]]*$" }}
#  SOURCE
if (( _bashlyk_ShellVersion > 4002000 )); then

  std::uptime() {

    echo $(( $(printf -- '%(%s)T' '-1') - $(printf -- '%(%s)T' '-2') ))

  }

else

  readonly _bashlyk_iStartTimeStamp=$( exec -c date "+%s" )

  std::uptime() { echo $(($(exec -c date "+%s") - _bashlyk_iStartTimeStamp )); }

fi
#******
#****f* libstd/std::finally
#  SYNOPSIS
#    std::finally <text>
#  DESCRIPTION
#    show uptime with input text
#  INPUTS
#    <text> - prefix text before " uptime <number> sec"
#  EXAMPLE
#    std::finally $RANDOM                                                       | {{ "^[[:digit:]]* uptime [[:digit:]]* sec$" }}
#  SOURCE
std::finally() { echo "$@ uptime $( std::uptime ) sec"; }
#******
