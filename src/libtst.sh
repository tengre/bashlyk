#
# $Id: libtst.sh 687 2017-02-15 16:47:23+04:00 toor $
#
#****h* BASHLYK/libtst
#  DESCRIPTION
#    template for testing
#  USES
#    libstd
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
#  $_BASHLYK_LIBTST provides protection against re-using of this module
[[ $_BASHLYK_LIBTST ]] && return 0 || _BASHLYK_LIBTST=1
#****L* libtst/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libini.sh ]] && . "${_bashlyk_pathLib}/libini.sh"
#******
#****v* libtst/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}

## TODO check __global.vars for exists
#__global.vars cli.arguments cli.shortname error.action msg.email.subject

declare -rg _bashlyk_externals_tst=""
declare -rg _bashlyk_exports_tst="udfTest"
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
#    udfTest                                                                    #? $_bashlyk_iErrorMissingArgument
#    udfTest test                                                               #? true
#  SOURCE
udfTest() {

  udfOn MissingArgument $1 || return $?

  return 0

}
#******
#****f* libtst/cnf::get
#  SYNOPSIS
#    cnf::get args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
###    cnf::get                                                                   #? $_bashlyk_iErrorMissingArgument
#    cnf::get                                                                   #? true
#  SOURCE
cnf::get() {

  #udfOn MissingArgument $1 || return $?

  INI ini

  ini.read bashlyk.test.conf                                                #? true

  ini.show                                                                  #? true

  return 0

}
#******
#****f* libtst/__interface
#  SYNOPSIS
#    __interface [_,+=] [args]
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    __interface = input                                                        #? true
#    __interface + more input data                                              #? true
#    __interface ,  comma separate input data                                    #? true
#    __interface                                                                #? true
#    __interface _                                                              #? true
#    __interface                                                                #? true
#  SOURCE
__interface() {

  local o s

  case $1 in
    =) s='="${*/=/}"';;
    +) s='+=" ${*/+/}"';;
    ,) s='+=",${*/+/}"';;
    _) s='=""';;
  esac

  o="_${FUNCNAME[0]//./_}${s}"
  [[ $s ]] && eval "shift; declare -g ${o}" || echo "${!o}"

}
#******
#****f* libtst/__private
#  SYNOPSIS
#    __private
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#  __private cli.arguments cli.shortname error.action msg.email.subject         #? true
#  bashlyk.cli.arguments = test                                                 #? true
#  _bashlyk_cli_shortname=shortname                                             #? true
#  bashlyk.cli.shortname                                                        #? true
#  bashlyk.error.action = action                                                #? true
#  bashlyk.msg.email.subject = subject                                          #? true
#  bashlyk.cli.arguments                                                        #? true
#  bashlyk.error.action                                                         #? true
#  bashlyk.msg.email.subject                                                    #? true
#  SOURCE
__private() {

  __() {

    local o=_${FUNCNAME[0]//./_}

    case $1 in

      =) eval 'shift; declare -g $o="${*/=/}"';;
      +) eval 'shift; declare -g $o+=" ${*/+/}"';;
      ,) eval 'shift; declare -g $o+=",${*/+/}"';;
      _) eval 'shift; declare -g $o=""';;
     '') echo "${!o}";;

    esac

  }

  local f=$(declare -pf __) s

  for s in $*; do

    eval "${f/__/bashlyk.$s}"

  done

}
#******
shopt -s expand_aliases
alias try="try()"
alias catch='; eval "$( ERR::__convert_try_to_func )" ||'

#****f* libtst/ERR::__add_throw_to_command
#  SYNOPSIS
#    ERR::__add_throw_to_command <command line>
#  DESCRIPTION
#    add controlled trap for errors of the <commandline>
#  INPUTS
#    <commandline> - source command line
#  OUTPUT
#    changed command line
#  NOTES
#    private method, used for 'try ..catch' emulation
#  EXAMPLE
#    local s='command --with -a -- arguments' cmd='ERR::__add_throw_to_command'
#    $cmd $s             >| md5sum | grep ^856f03be5778a30bb61dcd1e2e3fdcde.*-$ #? true
#  SOURCE
ERR::__add_throw_to_command() {

  local s

   s='_bashlyk_sLastError[$BASHPID]="command: $( udfTrim '${*/;/}' )\n output: '
  s+='{\n$('${*/;/}' 2>&1)\n}" && echo -n . || return $?;'

  echo $s

}
#****f* libtst/ERR::__convert_try_to_func
#  SYNOPSIS
#    ERR::__convert_try_to_func
#  DESCRIPTION
#    convert "try" block to the function with controlled traps of the errors
#  OUTPUT
#    function definition for evaluate
#  NOTES
#    private method, used for 'try ..catch' emulation
#  TODO
#    error handling for input 'try' function checking not worked
#  EXAMPLE
#    ERR::__convert_try_to_func >| grep '^/tmp/.*ok.*fail.*; false; }$'         #? true
#  SOURCE
ERR::__convert_try_to_func() {

  local s
  udfMakeTemp -v s

  while read -t 4; do

    if [[ ! $REPLY =~ ^[[:space:]]*(try \(\)|\{|\})[[:space:]]*$ ]]; then

      ERR::__add_throw_to_command $REPLY

    else

      #echo "${REPLY/try/try${s//\//.}}"
      echo "${REPLY/try/$s}"

    fi

  done< <( declare -pf try 2>/dev/null)

  echo $s' && echo " ok." || { udfSetLastError $?; echo " fail..($?)"; false; }'
  rm -f $s

}
#******
#****f* libtst/ERR::exception.message
#  SYNOPSIS
#    ERR::exception.message
#  DESCRIPTION
#    show last error status
#  INPUTS
#    used global variables $_bashlyk_{i,s}LastError
#  OUTPUT
#    try show commandline, status(error code) and output
#  ERRORS
#    MissingArgument - _bashlyk_iLastError[$BASHPID] empty
#    NotNumber       - _bashlyk_iLastError[$BASHPID] is not number
#  EXAMPLE
#   _bashlyk_iLastError[$BASHPID]=''
#   ERR::exception.message                                                      #? $_bashlyk_iErrorMissingArgument
#   _bashlyk_iLastError[$BASHPID]='not number'
#   ERR::exception.message                                                      #? $_bashlyk_iErrorNotNumber
#   local s fn                                                                  #-
#   error4test() { echo "$0: special error for testing"; return 210; };         #-
#   udfMakeTemp fn                                                              #-
#   cat <<-'EOFtry' > $fn                                                       #-
#   try {                                                                       #-
#     uname -a                                                                  #-
#     date -R                                                                   #-
#     uname                                                                     #-
#     error4test                                                                #-
#     true                                                                      #-
#   } catch {                                                                   #-
#                                                                               #-
#     ERR::exception.message                                                    #-
#                                                                               #-
#   }                                                                           #-
#   EOFtry                                                                      #-
#  . $fn               >| md5sum - | grep ^015d8fd97d8fecef29d5c7f068881e47.*-$ #? true
#  SOURCE
ERR::exception.message() {

  local msg=${_bashlyk_sLastError[$BASHPID]} rc=${_bashlyk_iLastError[$BASHPID]}
  udfIsNumber $rc || return $?

  echo -e "try box exception:\n~~~~~~~~~~~~~~~~~~"
  echo " status: $rc"

  if [[ $msg ]]; then

    echo -e $msg

  fi

  return $rc

}
#******
