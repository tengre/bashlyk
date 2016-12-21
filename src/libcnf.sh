#
# $Id: libcnf.sh 634 2016-12-21 17:13:02+04:00 toor $
#
#****h* BASHLYK/libcnf
#  DESCRIPTION
#    management of the active configuration files
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libcnf/ Compatibility сheck
#  DESCRIPTION
#    - $BASH_VERSION    - no value is incompatible with the current shell
#    - $BASH_VERSION    - required Bash major version 4 or more for this script
#    - $_BASHLYK_LIBCNF - global variable provides protection against re-use of
#                         this module
#  SOURCE
[ -n "$BASH_VERSION" ] || eval 'echo "BASH interpreter for this script ($0) required ..."; exit 255'
(( ${BASH_VERSINFO[0]} >= 4 )) || eval 'echo "required BASH version 4 or more for this script ($0) ..."; exit 255'
[[ $_BASHLYK_LIBCNF ]] && return 0 || _BASHLYK_LIBCNF=1
#******
#****** libcnf/ Loading external modules
# DESCRIPTION
#   read and execute required external modules
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
#******
#****v* libcnf/ Global Variables - init section
#  DESCRIPTION
#    init of the required global variables
#  SOURCE
: ${_bashlyk_sArg:="$@"}
: ${_bashlyk_pathCnf:=$(pwd)}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}
: ${_bashlyk_aRequiredCmd_cnf:="awk date mkdir pwd tr"}
: ${_bashlyk_aExport_cnf:="udfGetConfig udfSetConfig"}
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
#    b='' conf='' d='' pid='' s0='' sS=''
#    cat <<'EOFchild' > $confChild                                              #-
#                                                                               #-
#    s0=bash                                                                    #-
#    b=false                                                                    #-
#    pid=$$                                                                     #-
#    s="$(uname -a)"                                                            #-
#                                                                               #-
#    EOFchild                                                                   #-
#    cat $confChild
#    udfGetConfig $confChild                                                    #? true
#    test "$s0" = bash -a "$b" = false -a "$pid" = $$ -a "$s" = "$(uname -a)"   #? true
#    echo "$s0 = bash :: $b = false :: $pid = $$ :: $s = $(uname -a)"
#    rm -f $confChild
#    udfGetConfig $confChild                                                    #? $_bashlyk_iErrorNoSuchFileOrDir
#    udfGetConfig                                                               #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
udfGetConfig() {

  [[ $1 ]] || eval $( udfOnError return MissingArgument )
  [[ $1 =~ ^\.|\.$ ]] && eval $( udfOnError return InvalidArgument "$1" )

  local _conf_8q2FJGFO _s_nXLLvxAX _path_EmDVDmik _IFS_SkJ0cw9Y

  _path_EmDVDmik="$_bashlyk_pathCnf"
  _IFS_SkJ0cw9Y="$IFS"
  IFS=$' \t\n'

  [[ "$1" == "${1##*/}" && -f "${_path_EmDVDmik}/$1" ]] || _path_EmDVDmik=
  [[ "$1" == "${1##*/}" && -f "$1" ]] && _path_EmDVDmik=$(pwd)
  [[ "$1" != "${1##*/}" && -f "$1" ]] && _path_EmDVDmik=${1%/*}
 #
  if [[ -z "$_path_EmDVDmik" ]]; then

    if [[ -f "/etc/${_bashlyk_pathPrefix}/$1" ]]; then

      _path_EmDVDmik="/etc/${_bashlyk_pathPrefix}"

    else

      IFS="$_IFS_SkJ0cw9Y"
      eval $(udfOnError return iErrorNoSuchFileOrDir)

    fi

  fi

  _conf_8q2FJGFO=
  _s_nXLLvxAX=$( echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}' )

  eval set -- "$_s_nXLLvxAX"

  for _s_nXLLvxAX in "$@"; do

    [[ -n "$_s_nXLLvxAX" ]] || continue

    if [[ -n "$_conf_8q2FJGFO" ]]; then

      _conf_8q2FJGFO="${_s_nXLLvxAX}.${_conf_8q2FJGFO}"

    else

      _conf_8q2FJGFO="$_s_nXLLvxAX"

    fi

    [[ -s "${_path_EmDVDmik}/${_conf_8q2FJGFO}" ]] || continue

    if [[ ! $( stat -c %u "${_path_EmDVDmik}/${_conf_8q2FJGFO}" ) =~ ^($UID|0)$ ]]; then

      eval $( udfOnError NotPermitted warn "${_conf_8q2FJGFO} owned by $( stat -c %U "${_path_EmDVDmik}/${_conf_8q2FJGFO}" ) - skipped" )

    else

      source "${_path_EmDVDmik}/${_conf_8q2FJGFO}"

    fi

  done

  IFS="$_IFS_SkJ0cw9Y"
  return 0

}
#******
#****f* libcnf/udfSetConfig
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
