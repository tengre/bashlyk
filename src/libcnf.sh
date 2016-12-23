#
# $Id: libcnf.sh 639 2016-12-23 16:09:41+04:00 toor $
#
#****h* BASHLYK/libcnf
#  DESCRIPTION
#    safe management of the active configuration files
#  USES
#    libstd liberr libini
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****V* libcnf/BASH compability
#  DESCRIPTION
#    required BASH version 4.xx or more for this script
#  SOURCE
[ -n "$BASH_VERSION" ] || eval 'echo "BASH interpreter for this script ($0) required ..."; exit 255'
(( ${BASH_VERSINFO[0]} >= 4 )) || eval 'echo "required BASH version 4 or more for this script ($0) ..."; exit 255'
#******
#****L* libcnf/library initialization
# DESCRIPTION
#   * $_BASHLYK_LIBCNF provides protection against re-using of this module
#   * loading external libraries
# SOURCE
[[ $_BASHLYK_LIBCNF ]] && return 0 || _BASHLYK_LIBCNF=1
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libini.sh ]] && . "${_bashlyk_pathLib}/libini.sh"
#******
#****G* libcnf/Global Variables
#  DESCRIPTION
#    global variables
#  SOURCE
: ${_bashlyk_sArg:="$@"}
: ${_bashlyk_pathCnf:=$(pwd)}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}

declare -r _bashlyk_externals_cnf="date mkdir pwd tr"
declare -r _bashlyk_exports_cnf="CNF load save free udfGetConfig udfSetConfig"
declare -r _bashlyk_methods_cnf="__show load save free"
#******
#****e* libcnf/CNF
#  SYNOPSIS
#    CNF [<object>]
#  DESCRIPTION
#    constructor for new instance <object> of the CNF "class"
#  ARGUMENTS
#    valid name for created instance, default - used class name "CNF" as
#    instance name
#  ERRORS
#    InvalidArgument - listed in the $_bashlyk_methods_cnf method not found
#    InvalidVariable - invalid name for instance
#  EXAMPLE
#    CNF tnew                                                                   #? true
#    declare -pf tnew.load >/dev/null 2>&1                                      #= true
#    declare -pf tnew.save >/dev/null 2>&1                                      #= true
#    tnew.free
#  SOURCE
CNF() {

  local f s=${1:-CNF}

  udfOn InvalidVariable throw $s

  [[ $s == CNF ]] && return 0

  for s in $_bashlyk_methods_cnf; do

    f=$( declare -pf CNF.${s} )

    [[ $f =~ ^(CNF.${s}).\(\) ]] || eval $( udfOnError throw InvalidArgument "not instance $s method for $o object" )

    eval "${f/${BASH_REMATCH[1]}/${1}.$s}"

  done

  return 0

}
#******
#****e* libcnf/CNF.free
#  SYNOPSIS
#    <object>.free
#  DESCRIPTION
#    destructor for new instance <object> of the CNF "class"
#  NOTES
#    public method
#  EXAMPLE
#    CNF tFree
#    declare -pf tFree.load >/dev/null 2>&1                                     #= true
#    declare -pf tFree.save >/dev/null 2>&1                                     #= true
#    tFree.free                                                                 #? true
#    declare -pf tFree.load >/dev/null 2>&1                                     #= false
#    declare -pf tFree.save >/dev/null 2>&1                                     #= false
#  SOURCE
CNF.free() {

  local o s

  o=${FUNCNAME[0]%%.*}

  [[ $o == CNF ]] && return 0

  for s in $_bashlyk_methods_cnf; do

    unset -f ${o}.$s

  done

}
#******
#****p* libcnf/CNF.__show
#  SYNOPSIS
#    CNF.__show <file> [variable name s]
#  DESCRIPTION
#    Safely reading of the active configuration by using the INI library.
#    configuration source can be a single file or a group of related files. For
#    example, if <file> - is "a.b.c.conf" and it exists, sequentially read
#    "conf", "c.conf", "b.c.conf", "a.b.c.conf" files, if they exist, too.
#    Search  source of the configuration is done on the following criteria (in
#    the absence of the full path):
#      1 in the default directory,
#      2. in the current directory
#      3. in the system directory "/ etc"
#  NOTES
#    The file name must not begin with a dot or end with a dot.
#    configuration sources are ignored if they do not owned by the owner of the
#    process or root.
#  ARGUMENTS
#    <file> - filename of the configuration
#  OUTPUT
#    a serialized CSV-string or an error code and message.
#  EXAMPLE
#    local b conf d pid s0 s
#    udfMakeTemp confMain suffix=.conf
#    confChild="${confMain%/*}/child.${confMain##*/}"                           #-
#    udfAddFile2Clean $confChild                                                #-
#    cat <<'EOFconf' > $confMain                                                #-
#                                                                               #-
#    s0=$0                                                                      #-
#    b=true                                                                     #-
#    pid=$$                                                                     #-
#    s="$(uname -a)"                                                            #-
#                                                                               #-
#    EOFconf                                                                    #-
#    cat $confMain
#    CNF conf
#    conf.__show $confMain >| grep 'pid=$$\|b=true\|s="$(uname -a)"\|s0=$0\|;$' #? true
#    rm -f $conf
#    unset b conf pid s0 s
#    cat <<'EOFchild' > $confChild                                              #-
#                                                                               #-
#    s0=bash                                                                    #-
#    b=false                                                                    #-
#    pid=$$                                                                     #-
#    s="$(uname -a)"                                                            #-
#                                                                               #-
#    EOFchild                                                                   #-
#    cat $confChild
#    conf.__show $confChild b,pid >| grep 'pid=$$\|b=false\|;$'                 #? true
#    conf.free
#    rm -f $confChild
#    _ onError return
#    eval "$( CNF.__show $confChild )"                                          #? $_bashlyk_iErrorNoSuchFileOrDir
#    eval "$( CNF.__show )"                                                     #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
CNF.__show() {

  local fn id k o s

  o="_cnf_${FUNCNAME[0]%%.*}_${RANDOM}"

  if [[ ! $1 ]]; then

    udfOnError MissingArgument '1'
    return $(_ MissingArgument )

  fi

  fn=$1
  shift
  k="$@"

  INI $o

  if ! ${o}.load $fn ":${k// /,}"; then

    udfOnError ${_bashlyk_iLastError[$BASHPID]} "$fn"
    return $?

  fi

  ${o}.__section.select
  id=$( ${o}.__section.id )

  eval "for k in \${!$id[@]}; do [[ \$k =~ ^_bashlyk_ ]] && continue; udfIsValidVariable \$k && s+=\$k=\"\${$id[\$k]}\"\;; done;"

  ${o}.free

  echo "$s"

}
#******
#****e* libcnf/CNF.load
#  SYNOPSIS
#    CNF.load <file> [<variable>[, ]..]
#  DESCRIPTION
#    Safely reading of the active configuration by using the INI library.
#    configuration source can be a single file or a group of related files. For
#    example, if <file> - is "a.b.c.conf" and it exists, sequentially read
#    "conf", "c.conf", "b.c.conf", "a.b.c.conf" files, if they exist, too.
#    Search  source of the configuration is done on the following criteria (in
#    the absence of the full path):
#      1 in the default directory,
#      2. in the current directory
#      3. in the system directory "/etc"
#  NOTES
#    The file name must not begin with a point or end with a point.
#    configuration sources are ignored if they do not owned by the owner of the
#    process or root.
#  ARGUMENTS
#    <file>     - source of the configuration
#    <variable> - set only this list of the variables from the configuration
#  RETURN VALUE
#    MissingArgument - no arguments
#    NoSuchFileOrDir - configuration file is not found
#    InvalidArgument - name contains the point at the beginning or at the end of
#                      the name
#    Success on other cases
#  EXAMPLE
#    local b conf pid s0 s
#    udfMakeTemp confMain suffix=.conf
#    confChild="${confMain%/*}/child.${confMain##*/}"                           #-
#    udfAddFile2Clean $confChild                                                #-
#    cat <<'EOFconf' > $confMain                                                #-
#                                                                               #-
#    s0=$0                                                                      #-
#    b=true                                                                     #-
#    pid=$$                                                                     #-
#    s="$(uname -a)"                                                            #-
#                                                                               #-
#    EOFconf                                                                    #-
#    cat $confMain
#    CNF conf
#    conf.load $confMain                                                        #? true
#    echo "$s0 $b $pid $s" >| grep "$0\|true\|$$\|$(uname -a)"                  #? true
#    rm -f $conf
#    unset b conf pid s0 s
#    cat <<'EOFchild' > $confChild                                              #-
#                                                                               #-
#    s0=bash                                                                    #-
#    b=false                                                                    #-
#    pid=$$                                                                     #-
#    s="$(uname -a)"                                                            #-
#                                                                               #-
#    EOFchild                                                                   #-
#    cat $confChild
#    conf.load $confChild b pid                                                 #? true
#    echo "$b $pid" >| grep "false\|$$"                                         #? true
#    conf.free
#    rm -f $confChild
#    CNF.load $confChild                                                        #? $_bashlyk_iErrorNoSuchFileOrDir
#    CNF.load                                                                   #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
CNF.load() {

  eval "$( CNF.__show $@ )"

}
#******
#****e* libcnf/CNF.save
#  SYNOPSIS
#    CNF.save <file> "<comma separated key=value pairs>;"
#  DESCRIPTION
#    Write to the <file> string in the format "key=value" from a fields of the
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
#  RETURN VALUE
#    MissingArgument    - no arguments
#    NotExistNotCreated - target file not created or updated
#    InvalidArgument    - name contains the point at the beginning or at the end
#                         of the name
#    Success on other cases
#  EXAMPLE
#    udfMakeTemp conf suffix=.conf
#    CNF cnf
#    cnf.save $conf "s0=$0;b=true;pid=$$;s=$(uname -a);$(date -R -r $0);"       #? true
#    cat $conf >| grep "s0=$0\|b=true\|pid=$$\|s=\"$(uname -a)\""               #? true
#    cnf.free
#    rm -f $conf
#  SOURCE
CNF.save() {

  local conf IFS=$' \t\n' pathCnf="$_bashlyk_pathCnf"

  [[ $1 && $2 ]] || eval $( udfOnError return MissingArgument )

  [[ "$1" != "${1##*/}" ]] && pathCnf="${1%/*}"

  mkdir -p "$pathCnf" || eval $( udfOnError return NotExistNotCreated "$pathCnf" )

  conf="${pathCnf}/${1##*/}"

  {

    printf -- '#\n# created %s by %s\n#\n' "$( date -R )" "$( _ sUser )"
    udfCheckCsv "$2" | tr ';' '\n'

  } >> $conf 2>/dev/null

  return 0

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
#      1 in the default directory,
#      2. in the current directory
#      3. in the system directory "/etc"
#  NOTES
#    The file name must not begin with a point or end with a point.
#    configuration sources are ignored if they do not owned by the owner of the
#    process or root.
#  ARGUMENTS
#    <file>     - source of the configuration
#    <variable> - set only this list of the variables from the configuration
#  RETURN VALUE
#    MissingArgument - no arguments
#    NoSuchFileOrDir - configuration file is not found
#    InvalidArgument - name contains the point at the beginning or at the end of
#                      the name
#    Success on other cases
#  EXAMPLE
#    local b confChild confMain pid s0 s
#    udfMakeTemp confMain suffix=.conf
#    confChild="${confMain%/*}/child.${confMain##*/}"                           #-
#    udfAddFile2Clean $confChild                                                #-
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
#    unset b conf pid s0 s
#    cat <<'EOFchild' > $confChild                                              #-
#                                                                               #-
#    s0=bash                                                                    #-
#    b=false                                                                    #-
#    pid=$$                                                                     #-
#    s="$(uname -a)"                                                            #-
#                                                                               #-
#    EOFchild                                                                   #-
#    cat $confChild
#    udfGetConfig $confChild pid b                                              #? true
#    echo "$b $pid" >| grep "false $$"                                          #? true
#    rm -f $confChild
#    udfGetConfig $confChild s                                                  #? $_bashlyk_iErrorNoSuchFileOrDir
#    udfGetConfig                                                               #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
udfGetConfig() {

  eval "$( CNF.__show $@ )"

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
#  RETURN VALUE
#    MissingArgument    - no arguments
#    NotExistNotCreated - target file not created or updated
#    InvalidArgument    - name contains the point at the beginning or at the end of
#                         the name
#    Success on other cases
#  EXAMPLE
#    udfMakeTemp conf suffix=.conf
#    CNF cnf
#    cnf.save $conf "s0=$0;b=true;pid=$$;s=$(uname -a);$(date -R -r $0);"       #? true
#    cnf.free
#    cat $conf >| grep "s0=$0\|b=true\|pid=$$\|s=\"$(uname -a)\""               #? true
#    rm -f $conf
#  SOURCE
udfSetConfig() {

  CNF.save "$@"

}
#******
