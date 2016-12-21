#
# $Id: libtst.sh 634 2016-12-21 17:13:02+04:00 toor $
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
#****** libtst/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libini.sh ]] && . "${_bashlyk_pathLib}/libini.sh"
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
: ${_bashlyk_aRequiredCmd_tst:=""}
: ${_bashlyk_aExport_tst:="udfTest"}
: ${_bashlyk_methods_cnf:="load save free"}
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
#****f* public/CNF
#  SYNOPSIS
#    CNF [<id>]
#  DESCRIPTION
#    constructor for new instance <id> of the CNF "class" (object)
#  NOTES
#    public method
#  ARGUMENTS
#    valid variable name for created instance, default - used class name CNF as
#    instance
#  RETURN VALUE
#    InvalidArgument - method not found
#    InvalidVariable - invalid variable name for instance
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
#****f* public/CNF.free
#  SYNOPSIS
#    CNF.free
#  DESCRIPTION
#    destructor of the instance
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
#****f* libtst/CNF.load
#  SYNOPSIS
#    CNF.load <file> [variable name s]
#  DESCRIPTION
#    Reading active configuration by executing the source - a single file or a
#    group of related files. For example, if <file> - is "a.b.c.conf" and it
#    exists, are executed "conf", "c.conf", "b.c.conf", "a.b.c.conf" files if
#    they exist, too.
#    Configuration source search is performed on the following criteria:
#      1. The name of the file does not contain the path - check the current
#         directory, after the default directory configurations
#      2. The file name contains the full path - the directory is used in which
#         it is located
#      3. The last attempt - to find the file in the "/etc" directory
#  NOTES
#    The file name must not begin with a point or end with a point.
#    configuration sources are ignored if they do not owned by the owner of the
#    process or root.
#  ARGUMENTS
#    <file> - filename of the configuration
#  RETURN VALUE
#    MissingArgument - no arguments
#    NoSuchFileOrDir - configuration file is not found
#    InvalidArgument - name contains the point at the beginning or at the end of
#                      the name
#    Success on other cases
#  OUTPUT
#    Comma Separated Value string with "key=value" fields where key it is valid
#    variable name
#  EXAMPLE
#    local b conf d pid s0 s
#    CNF conf
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
#    conf.load $confMain                                                        #? true
#    eval "$( CNF.load $confMain )"                                             #? true
#    test "$s0" = $0 -a "$b" = true -a "$pid" = $$ -a "$s" = "$(uname -a)"      #? true
#    echo "$s0 = $0 :: $b = true :: $pid = $$ :: $s = $(uname -a)"
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
#    eval "$( conf.load $confChild b pid )"                                     #? true
#    conf.free
#    test ""$b" = false -a "$pid" = $$"                                         #? true
#    echo "$s0 = bash :: $b = false :: $pid = $$ :: $s = $(uname -a)"
#    rm -f $confChild
#    s=$( CNF.load $confChild )                                                 #? $_bashlyk_iErrorNoSuchFileOrDir
#    s=$( CNF.load )                                                            #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
CNF.load() {

  local fn id k o s

  o=${FUNCNAME[0]%%.*}${RANDOM}

  udfOn MissingArgument $1 || return $?
  udfOn NoSuchFileOrDir $1 || return $?

  fn=$1
  shift
  k="$@"

  INI $o
  ${o}.load $fn ":${k// /,}"

  ${o}.__section.select
  id=$( ${o}.__section.id )

  eval "for k in \${!$id[@]}; do [[ \$k =~ ^_bashlyk_ ]] && continue; udfIsValidVariable \$k && s+=\$k=\"\${$id[\$k]}\"\;; done;"

  ${o}.free

  echo "$s"

}
#******
#****f* libtst/CNF.save
#  SYNOPSIS
#    CNF.save <file> "<comma separated key=value pairs>;"
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
#    local b conf d pid s0 s
#    udfMakeTemp conf suffix=.conf
#    CNF cnf
#    cnf.save $conf "s0=$0;b=true;pid=$$;s=$(uname -a);$(date -R -r $0)"        #? true
#    cnf.free                                                                   #? true
#    grep "^s0=$0$" $conf                                                       #? true
#    grep "^b=true$" $conf                                                      #? true
#    grep "^pid=${$}$" $conf                                                    #? true
#    grep "^s=\"$(uname -a)\"$" $conf                                           #? true
#    grep "^$(_ sUnnamedKeyword).*=\"$(date -R -r $0)\"$" $conf                 #? true
#    cat $conf
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
#****f* libcnf/udfGetConfig
#  SYNOPSIS
#    udfGetConfig <file>
#  DESCRIPTION
#    Reading active configuration by executing the source - a single file or a
#    group of related files. For example, if <file> - is "a.b.c.conf" and it
#    exists, are executed "conf", "c.conf", "b.c.conf", "a.b.c.conf" files if
#    they exist, too.
#    Configuration source search is performed on the following criteria:
#      1. The name of the file does not contain the path - check the current
#         directory, after the default directory configurations
#      2. The file name contains the full path - the directory is used in which
#         it is located
#      3. The last attempt - to find the file in the "/etc" directory
#  NOTES
#    The file name must not begin with a point or end with a point.
#    configuration sources are ignored if they do not owned by the owner of the
#    process or root.
#  ARGUMENTS
#    <file> - filename of the configuration
#  RETURN VALUE
#    MissingArgument - no arguments
#    NoSuchFileOrDir - configuration file is not found
#    InvalidArgument - name contains the point at the beginning or at the end of
#                      the name
#    Success on other cases
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
#    udfGetConfig $confMain                                                     #? true
#    test "$s0" = $0 -a "$b" = true -a "$pid" = $$ -a "$s" = "$(uname -a)"      #? true
#    echo "$s0 = $0 :: $b = true :: $pid = $$ :: $s = $(uname -a)"
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
#    udfGetConfig $confChild pid b                                              #? true
#    test "$b" = false -a "$pid" = $$                                           #? true
#    echo "$b = false :: $pid = $$"
#    rm -f $confChild
#    udfGetConfig                                                               #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
udfGetConfig() {

  udfOn MissingArgument $1 || return $?

  eval "$( CNF.load $@ )"

}
#******
#****f* libtst/udfSetConfig
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
#    local b conf d pid s0 s
#    udfMakeTemp conf suffix=.conf
#    udfSetConfig $conf "s0=$0;b=true;pid=$$;s=$(uname -a);$(date -R -r $0)"    #? true
#    grep "^s0=$0$" $conf                                                       #? true
#    grep "^b=true$" $conf                                                      #? true
#    grep "^pid=${$}$" $conf                                                    #? true
#    grep "^s=\"$(uname -a)\"$" $conf                                           #? true
#    grep "^$(_ sUnnamedKeyword).*=\"$(date -R -r $0)\"$" $conf                 #? true
#    cat $conf
#    rm -f $conf
#  SOURCE
udfSetConfig() {

  CNF.save "$@"

}
#******
