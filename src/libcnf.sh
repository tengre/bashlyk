#
# $Id: libcnf.sh 761 2017-05-10 10:31:26+04:00 toor $
#
#****h* BASHLYK/libcnf
#  DESCRIPTION
#    Safe management of the active configuration files by using INI library
#    Deprecated, for backward compatibility
#  USES
#    libstd libini
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libcnf/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBCNF provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBCNF" ] && return 0 || _BASHLYK_LIBCNF=1
[ -n "$_BASHLYK" ] || . bashlyk || eval '                                      \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* libcnf/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/libini.sh ]] && . "${_bashlyk_pathLib}/libini.sh"
#******
#****G* libcnf/Global Variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}

declare -rg _bashlyk_externals_cnf="mkdir"
declare -rg _bashlyk_exports_cnf="udfGetConfig udfSetConfig"
#******
#****p* libcnf/__getconfig
#  SYNOPSIS
#    __getconfig <file> [<comma separated variable list>]
#  DESCRIPTION
#    Safely reading of the active configuration by using the INI library.
#    configuration source can be a single file or a group of related files. For
#    example, if <file> - is "a.b.c.conf" and it exists, sequentially read
#    "conf", "c.conf", "b.c.conf", "a.b.c.conf" files, if they exist, too.
#    Search  source of the configuration is done on the following criteria (in
#    the absence of the full path):
#      1. in the default directory,
#      2. in the current directory
#      3. in the system directory "/etc"
#  NOTES
#    The file name must not begin with a dot or end with a dot.
#    configuration sources are ignored if they do not owned by the owner of the
#    process or root.
#  ARGUMENTS
#    <file>                          - filename of the configuration
#    <comma separated variable list> - list of selected variables, default - all
#                                      variables from configuration
#  OUTPUT
#    a serialized CSV-string or an error code and message.
#  EXAMPLE
#    local b confChild confMain pid s s0
#    udfMakeTemp confMain suffix=.conf
#    confChild="${confMain%/*}/child.${confMain##*/}"                           #-
#    pid::onExit::unlink $confChild                                             #-
#    cat <<'EOFconf' > $confMain                                                #-
#                                                                               #-
#    s0=$0                                                                      #-
#    b=true                                                                     #-
#    pid=$$                                                                     #-
#    s="$(uname -a)"                                                            #-
#    invalid line                                                               #-
#    invalid key=true                                                           #-
#    invalid.key=$$                                                             #-
#    1nvalid_key = "$(uname -a)"                                                #-
#                                                                               #-
#    EOFconf                                                                    #-
#    cat $confMain
#    __getconfig $confMain >| grep 'pid=$$\|b=true\|s="$(uname -a)"\|s0=$0\|;$' #? true
#    unset b pid s s0                                                           #-
#    cat <<'EOFchild' > $confChild                                              #-
#                                                                               #-
#    s0=bash                                                                    #-
#    b=false                                                                    #-
#    pid=$$                                                                     #-
#    s="$(uname -a)"                                                            #-
#    test=test                                                                  #-
#                                                                               #-
#    EOFchild                                                                   #-
#    echo "cat start --"
#    cat $confChild
#    echo "cat stop  --"
#    _ onError echo+return
#    __getconfig $confChild b,pid >| grep 'pid=$$\|b=false\|;$'                 #? true
#    rm -f $confChild
#    __getconfig $confChild  >| grep "err::status $( _ iErrorNoSuchFileOrDir )" #? true
#    __getconfig             >| grep "err::status $( _ iErrorMissingArgument )" #? true
#  SOURCE
__getconfig() {

  local fn id k o s

  o="${FUNCNAME[0]%%.*}_${RANDOM}${RANDOM}"

  if [[ ! $1 ]]; then

    err::eval MissingArgument '1'
    return $(_ MissingArgument )

  fi

  ## TODO temporary object source file do not removed!!!
  INI $o
  ${o}.settings.shellmode true

  if ! ${o}.load "$@"; then

    e="${_bashlyk_iLastError[$BASHPID]} $@"
    err::eval $e
    return ${_bashlyk_iLastError[$BASHPID]}

  fi

  ${o}.__section.select
  id=$( ${o}.__section.id )

  eval "                                                                       \
                                                                               \
    for k in \${!$id[@]}; do                                                   \
      [[ \$k =~ ^_bashlyk_ ]] && continue;                                     \
      udfIsValidVariable \$k && s+=\$k=\"\${$id[\$k]}\"\;;                     \
    done;                                                                      \
                                                                               \
  "

  ${o}.free

  echo "$s"

}
#******
#****e* libcnf/udfGetConfig
#  SYNOPSIS
#    udfGetConfig <file>
#  DESCRIPTION
#    Safely reading of the active configuration by using the INI library.
#    configuration source can be a single file or a group of related files. For
#    example, if <file> - is "a.b.c.conf" and it exists, sequentially read
#    "conf", "c.conf", "b.c.conf", "a.b.c.conf" files, if they exist, too.
#    Search  source of the configuration is done on the following criteria (in
#    the absence of the full path):
#      1. in the default directory,
#      2. in the current directory
#      3. in the system directory "/etc"
#  NOTES
#    The file name must not begin with a point or end with a point.
#    configuration sources are ignored if they do not owned by the owner of the
#    process or root.
#  ARGUMENTS
#    <file>     - source of the configuration
#    <variable> - set only this list of the variables from the configuration
#  ERRORS
#    MissingArgument - no arguments
#    NoSuchFileOrDir - configuration file is not found
#    InvalidArgument - name contains the point at the beginning or at the end of
#                      the name
#  EXAMPLE
#    local b confChild confMain pid s s0
#    udfMakeTemp confMain suffix=.conf
#    confChild="${confMain%/*}/child.${confMain##*/}"                           #-
#    pid::onExit::unlink $confChild                                             #-
#    cat <<'EOFconf' > $confMain                                                #-
#                                                                               #-
#    s0=$0                                                                      #-
#    b=true                                                                     #-
#    pid=$$                                                                     #-
#    s="$(uname -a)"                                                            #-
#                                                                               #-
#    EOFconf                                                                    #-
#    cat $confMain
#    udfGetConfig $confMain                                                     #? true
#    echo "$s0 $b $pid $s" >| grep "$0 true $$ $(uname -a)"                     #? true
#    unset b pid s0 s
#    cat <<'EOFchild' > $confChild                                              #-
#                                                                               #-
#    s0=bash                                                                    #-
#    b=false                                                                    #-
#    pid=$$                                                                     #-
#    s="$(uname)"                                                               #-
#    test=test                                                                  #-
#                                                                               #-
#    EOFchild                                                                   #-
#    cat $confChild
#    udfGetConfig $confChild pid,b,test                                         #? true
#    echo "$b $pid $test" >| grep "false $$ test"                               #? true
#    rm -f $confChild
#    _ onError echo+return
#    udfGetConfig $confChild s                                                  #? $_bashlyk_iErrorNoSuchFileOrDir
#    udfGetConfig                                                               #? $_bashlyk_iErrorMissingArgument
#  SOURCE
udfGetConfig() {

  eval "$( __getconfig $@ )"

}
#******
#****e* libcnf/udfSetConfig
#  SYNOPSIS
#    udfSetConfig <file> "<comma separated key=value pairs>;"
#  DESCRIPTION
#    Write to <file> string in the format "key = value" from a fields of the
#    second argument "<CSV>;"
#    In the case where the filename does not contain the path, it is saved in a
#    default directory, or is saved using a full path.
#  ARGUMENTS
#    <file> - file name of the active configuration
#    "<comma separated key=value pairs>;" - CSV-string, divided by ";", fields
#             that contain the data of the form "key = value"
#  NOTES
#    It is important to take the arguments in double quotes, if they contain a
#    whitespace or ';'
#  ERRORS
#    MissingArgument    - no arguments
#    NotExistNotCreated - target file not created or updated
#    InvalidArgument    - name contains the point at the beginning or at the end of
#                         the name
#  EXAMPLE
#    udfMakeTemp conf suffix=.conf
#    udfSetConfig $conf "s0=$0;b=true;pid=$$;s=$(uname -a);1nvalid.key=invalid" #? true
#    cat $conf >| grep "s0=$0\|b=true\|pid=$$\|s=\"$(uname -a)\""               #? true
#    rm -f $conf
#  SOURCE
udfSetConfig() {

  throw on MissingArgument $@

  local conf path o s

  [[ "$1" != "${1##*/}" ]] && path="${1%/*}" || path="$( _ pathCnf )"
  conf="${path}/${1##*/}"

  mkdir -p $path && touch $conf || on error throw NotExistNotCreated $conf

  o="${FUNCNAME[0]%%.*}_${RANDOM}${RANDOM}"
  INI $o
  ${o}.settings.shellmode true

  while read -t 4; do

    ${o}.set $REPLY

  done< <( printf -- "${2//[;,]/\\\n}" )

  ${o}.save $conf
  s=$?

  ${o}.free

  return $s

}
#******
