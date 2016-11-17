#
# $Id: libtst.sh 590 2016-11-18 00:46:55+04:00 toor $
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
: ${_bashlyk_aRequiredCmd_msg:="[ "}
: ${_bashlyk_aExport_msg:="udfTest udfRead"}
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
#****f* libtst/udfEncode
#  SYNOPSIS
#    udfEncode args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    local s='if [[ re  =~  (a|b b|\") ]]; then ok; fi'
#    udfEncode "$s" #? true
#  SOURCE
udfEncode() {

  local s="$@"
  s=${s// /_&#20_}
  s=${s//\*/_&#2A_}
  s=${s//\"/_&#34_}
  s=${s//\(/_&#40_}
  s=${s//\)/_&#41_}
  s=${s//\;/_&#59_}
  s=${s//\=/_&#61_}
  s=${s//\|/_&#7C_}
  s=${s//\[/_&#91_}
  s=${s//\\/_&#92_}
  s=${s//\]/_&#93_}
  #s=${s//\$\(/-S-(}
  #s=${s//\`/^_}

  echo "$s"
}
#******
#****f* libtst/udfDecode
#  SYNOPSIS
#    udfDecode args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#    local s='if _&#91__&#91_ re  _&#61_~  _&#40_a_&#7C_b b_&#7C__&#92__&#34__&#41_ _&#93__&#93__&#59_ then ok_&#59_ fi'
#    udfDecode "$s" #? true
#  SOURCE
udfDecode() {

  local s="$@"
  s=${s//_&#20_/ }
  s=${s//_&#2A_/\*}
  s=${s//_&#34_/\"}
  s=${s//_&#40_/\(}
  s=${s//_&#41_/\)}
  s=${s//_&#59_/\;}
  s=${s//_&#61_/\=}
  s=${s//_&#7C_/\|}
  s=${s//_&#91_/\[}
  s=${s//_&#92_/\\}
  s=${s//_&#93_/\]}
  #s=${s//\$\(/-S-(}
  #s=${s//\`/^_}

  echo "$s"
}
#******
#****f* libtst/ini.read
#  SYNOPSIS
#    ini.read args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#   local c ini s S                                                             #-
#   local -A hT
#   c='([__global__]="" [exec]="-" [main]="" [replace]="-" [unify]="=" [acc to ass]="+")' #-
#   udfMakeTemp ini suffix=".ini"                                               #-
#    cat <<'EOFini' > ${ini}                                                    #-
#    void  =  1                                                                 #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#    _____export HOSTNAME=$(hostname)                                           #-
#    fi                                                                         #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt   =  $(date-R)                                                        #-
#    b      =  false                                                            #-
#    iXo Xo =  19                                                               #-
#    iYo    =  80                                                               #-
#    `simple line`                                                              #-
#[replace]                                                                      #-
#    before replacing                                                           #-
#[unify]                                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#[acc to ass]                                                                   #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#                                                                               #-
#    EOFini                                                                     #-
#   sed -i -e "s/_____/     /" $ini                                             #-
#   cat $ini
#   s=$( ini.read $ini "" "$c" )                                                #? true
#   echo ${s/h=/hT=}
#   eval "${s/h=/hT=}"                                                            #-
##   for S in ${hT[__sections__]}; do                                            #-
#     for s in "${!hT[@]}"; do                                                  #-
##       [[ "$s" =~ __$S$ ]] || continue
#       echo "$s = ${hT["$s"]}"
#     done                                                                      #-
##   done                                                                        #-
#  SOURCE
ini.read() {

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $3
  #typeset -A $2 || eval $( udfOnError throw InvalidArgument "$2 must be hash" )
  #typeset -A $3 || eval $( udfOnError throw InvalidArgument "$3 must be hash" )

  local -A h hRC
  local bActiveSection fn i k reComment reKeyVal reRawClass reSection s v
  #
  if [[ $2 ]]; then

    [[ $2 =~ ^declare.-A.[[:alnum:]]+= ]] && s="${2#*=}" || s="$2"
    eval "local -A h=$s"

  fi

  if [[ $3 ]]; then

   [[ $3 =~ ^declare.-A.[[:alnum:]]+= ]] && s="${3#*=}" || s="$3"
   eval "local -A hRC=$s"

  fi

  #
  i=0
  s="__global__"
  #
  fn=$1
  h[__sections__]="$s"

   reSection='^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
    reKeyVal='^[[:space:]]*([[:alnum:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
   reComment='(^|[[:space:]]+)[\#\;].*$'
  reRawClass='^[=\-\+]$'

  while read -t 4; do

    if [[ $REPLY =~ $reSection ]]; then

      (( i > 0 )) && h["__unnamed_cnt__${s}"]=$i
      i=0

      #s=$( udfEncode ${BASH_REMATCH[2]} )
      s="${BASH_REMATCH[2]}"

      [[ ${BASH_REMATCH[1]} == ":" ]] && bActiveSection=close
      [[ ${BASH_REMATCH[3]} == ":" ]] && bActiveSection=open

      if [[ $bActiveSection == "close" ]]; then

        bActiveSection=
        continue

      fi

      if udfIsNumber ${h["__unnamed_cnt__${s}"]}; then

        case ${hRC[$s]} in

          '-') i=0;;
          '+') i=${h["__unnamed_cnt__${s}"]};;
          '=') i=${h["__unnamed_cnt__${s}"]};;
            *) i=0;;

        esac

        echo "dbg : $s : ${hRC[$s]} : $i" >> /tmp/class.log
      fi

      h["__sections__"]+=" $s"

    else

      [[ $REPLY =~ $reComment ]] && continue

      if [[ ! $bActiveSection && ! ${hRC[$s]} =~ $reRawClass && $REPLY =~ $reKeyVal ]]; then

        k="${BASH_REMATCH[1]}"
        v="${BASH_REMATCH[2]}"

        h["${k}__${s}"]="$v"

      else

        if   [[ ${hRC[$s]} =~ ^=$ ]]; then

          REPLY=${REPLY##*( )}
          REPLY=${REPLY%%*( )}
          h["__unnamed_key=${REPLY}__${s}"]="$REPLY"

        else

          h["__unnamed_idx=${i}__${s}"]="$REPLY"

        fi

        : $(( i++ ))

      fi

    fi

  done < $fn

  (( i > 0 )) && h["__unnamed_cnt__${s}"]=$i

  declare -p h

}
#******
#****f* libtst/ini.get
#  SYNOPSIS
#    ini.get args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#   local c ini s S                                                             #-
#   local -A hT
#   c='([__global__]="" [exec]="-" [main]="" [replace]="-" [unify]="=" [acc to ass]="+")' #-
#   udfMakeTemp ini suffix=".ini"                                               #-
#    cat <<'EOFini' > ${ini}                                                    #-
#    void  =  1                                                                 #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#    _____export HOSTNAME=$(hostname)                                           #-
#    fi                                                                         #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt   =  $(date-R)                                                        #-
#    b      =  false                                                            #-
#    iXo Xo =  19                                                               #-
#    iYo    =  80                                                               #-
#    `simple line`                                                              #-
#[replace]                                                                      #-
#    before replacing                                                           #-
#[unify]                                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#[acc to ass]                                                                   #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#                                                                               #-
#    EOFini                                                                     #-
#   sed -i -e "s/_____/     /" $ini                                             #-
#   cat $ini
#   s=$( ini.get $ini "" "$c" )                                                 #? true
#   echo ${s/h=/hT=}
#   eval "${s/h=/hT=}"                                                          #-
#   for S in ${hT[__sections__]}; do                                            #-
#     unset hS
#     echo "section $S"
#     eval "${hT[$S]}"
#     for s in "${!hS[@]}"; do                                                  #-
#       echo "$s = ${hS["$s"]}"
#     done                                                                      #-
#   done                                                                        #-
#  SOURCE
ini.get() {

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $3
  #typeset -A $2 || eval $( udfOnError throw InvalidArgument "$2 must be hash" )
  #typeset -A $3 || eval $( udfOnError throw InvalidArgument "$3 must be hash" )

  local -A h hRC hS
  local bActiveSection fn i k reComment reKeyVal reRawClass reSection s v
  #
  if [[ $2 ]]; then

    [[ $2 =~ ^declare.-A.[[:alnum:]]+= ]] && s="${2#*=}" || s="$2"
    eval "local -A h=$s"

  fi

  if [[ $3 ]]; then

   [[ $3 =~ ^declare.-A.[[:alnum:]]+= ]] && s="${3#*=}" || s="$3"
   eval "local -A hRC=$s"

  fi

  #
  i=0
  s="__global__"
  #
  fn=$1
  h[__sections__]="$s"

   reSection='^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$'
    reKeyVal='^[[:space:]]*([[:alnum:]]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$'
   reComment='(^|[[:space:]]+)[\#\;].*$'
  reRawClass='^[=\-+]$'

  while read -t 4; do

    if [[ $REPLY =~ $reSection ]]; then

      (( i > 0 )) && hS["__unnamed_cnt"]=$i
      i=0

      if (( ${#hS[@]} > 0 )); then

        h[$s]="$(declare -p hS)"

      fi

      unset hS

      #s=$( udfEncode ${BASH_REMATCH[2]} )
      s="${BASH_REMATCH[2]}"

      [[ ${BASH_REMATCH[1]} == ":" ]] && bActiveSection=close
      [[ ${BASH_REMATCH[3]} == ":" ]] && bActiveSection=open

      if [[ $bActiveSection == "close" ]]; then

        bActiveSection=
        continue

      fi

      local sS=${h[$s]}

      [[ $sS =~ ^declare.-A.[[:alnum:]]+= ]] && sS="${sS#*=}" || sS="()"
      eval "local -A hS=$sS"

      if udfIsNumber ${hS["__unnamed_cnt"]}; then

        case ${hRC[$s]} in

          '-') i=0;;
          '+') i=${hS["__unnamed_cnt"]};;
          '=') i=${hS["__unnamed_cnt"]};;
            *) i=${hS["__unnamed_cnt"]};;

        esac

      else

        hS["__unnamed_cnt"]=0

      fi
      echo "dbg : $s : ${hRC[$s]} : $i" >> /tmp/classg.log
      h["__sections__"]+=" $s"

    else

      [[ $REPLY =~ $reComment ]] && continue

      if [[ ! $bActiveSection && ! ${hRC[$s]} =~ $reRawClass && $REPLY =~ $reKeyVal ]]; then

        k=${BASH_REMATCH[1]}
        v=${BASH_REMATCH[2]}

        hS["${k}"]="$v"

      else

        if   [[ ${hRC[$s]} =~ ^=$ ]]; then

          REPLY=${REPLY##*( )}
          REPLY=${REPLY%%*( )}
          hS["__unnamed_key=${REPLY}"]="$REPLY"

        else

          hS["__unnamed_idx=${i}"]="$REPLY"

        fi

        : $(( i++ ))

      fi

    fi

  done < $fn

  if (( ${#hS[@]} > 0 )); then

    hS["__unnamed_cnt"]=$i
    h[$s]=$(declare -p hS)
    unset hS

  fi

  declare -p h

}
#******
#****f* libtst/ini.group
#  SYNOPSIS
#    ini.group args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#   local c ini s S                                                             #-
#   local -A hT                                                                 #-
#   c='([__global__]="" [exec]="-" [main]="" [replace]="-" [unify]="=" [acc to ass]="+")'
#   udfMakeTemp ini suffix=.ini                                                 #-
#    cat <<'EOFini' > ${ini}                                                    #-
#    void  =  1                                                                 #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#    _____export HOSTNAME=$(hostname)                                           #-
#    fi                                                                         #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt   =  $(date-R)                                                        #-
#    b      =  false                                                            #-
#    iXo Xo =  19                                                               #-
#    iYo    =  80                                                               #-
#    `simple line`                                                              #-
#[replace]                                                                      #-
#    before replacing                                                           #-
#[unify]                                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#[acc to ass]                                                                   #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#                                                                               #-
#    EOFini                                                                     #-
#    cat <<'EOFiniChild' > "${ini%/*}/child.${ini##*/}"                         #-
#    void  =  2                                                                 #-
#    main  =  main                                                              #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345679'                                          #-
#    sUname="$(uname)"                                                          #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#    _____export HOSTNAME=$(hostname -f)                                        #-
#    fi                                                                         #-
#    echo $sUname                                                               #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt   =  $(date "+%s") =test = a =                                        #-
#    b      =  true                                                             #-
#    iXo Xo =  19                                                               #-
#    iYo    =  81                                                               #-
#    simple line                                                                #-
#[replace]                                                                      #-
#    after replacing                                                            #-
#[unify]                                                                        #-
#    *.xxx                                                                      #-
#    *.tmp                                                                      #-
#[acc to ass]                                                                   #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    *.com                                                                      #-
#    *.exe                                                                      #-
#    *.jpg                                                                      #-
#    *.png                                                                      #-
#    *.mp3                                                                      #-
#    *.dll                                                                      #-
#    *.asp                                                                      #-
#    EOFiniChild                                                                #-
#   sed -i -e "s/_____/     /g" "${ini%/*}/child.${ini##*/}"                    #-
#   cat $ini
#   s=$( ini.group "${ini%/*}/child.${ini##*/}" "$c" )                          #? true
#   echo ${s/h/hT}
#   eval "${s/h/hT}"                                                            #-
##   for S in ${hT[__sections__]}; do                                           #-
#     for s in "${!hT[@]}"; do                                                  #-
##     unset hS
##     echo "section $S"
##     eval "${hT[$S]}"
##     for s in ${!hS[@]}; do                                                   #-
#       echo "$s = ${hT["$s"]}"
#     done                                                                      #-
##   done                                                                       #-
#  SOURCE
ini.group() {

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $2

  local -a a
  local i ini path s sIni sRawClass

  [[ $2 ]] && sRawClass="$2"

  [[ "$1" == "${1##*/}" && -f "$(_ pathIni)/$1" ]] && path=$(_ pathIni)
  [[ "$1" == "${1##*/}" && -f "$1"              ]] && path=$(pwd)
  [[ "$1" != "${1##*/}" && -f "$1"              ]] && path=${1%/*}

  if [[ ! $( stat -c %U ${path}/${1##*/} ) == $( _ sUser ) ]]; then

	eval $( udfOnError NotPermitted throw "$1 owned by $( stat -c %U ${path}/${1##*/} )" )

  fi
  #
  if [[ ! $path && -f "/etc/$(_ pathPrefix)/$1" ]]; then

    path="/etc/$(_ pathPrefix)"

  fi

  if [[ $path ]]; then

    s=${1##*/}
    a=( ${s//./ } )

    for (( i = ${#a[@]}-1; i >= 0; i-- )); do

      [[ ${a[i]} ]] || continue
      [[ $ini    ]] && ini="${a[i]}.${ini}" || ini="${a[i]}"
      [[ -s "${path}/${ini}" ]] && sIni="$( ini.read "${path}/${ini}" "$sIni" "$sRawClass" )"

    done

 fi

 echo "$sIni"

#	if ( scalar keys %_hCLI ) {
#
#		( $fh, $fn ) = tempfile();
#		writeTarget( $fh, \%_hCLI );
#		seek( $fh, 0, 0 ) or die "${fn}: seek error $!\n";
#		$ph = readSource( $fh, $ph, $phClass );
#		close( $fh );
#		unlink( $fn );
#
#	}
#
#	return $ph;
#
}
#******
#****f* libtst/ini.group2
#  SYNOPSIS
#    ini.group2 args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#   local c ini s S                                                             #-
#   local -A hT hS                                                                #-
#   c='([__global__]="" [exec]="-" [main]="" [replace]="-" [unify]="=" [acc to ass]="+")'
#   udfMakeTemp ini suffix=.ini                                                 #-
#    cat <<'EOFini' > ${ini}                                                    #-
#    void  =  1                                                                 #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#    _____export HOSTNAME=$(hostname)                                           #-
#    fi                                                                         #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt   =  $(date-R)                                                        #-
#    b      =  false                                                            #-
#    iXo Xo =  19                                                               #-
#    iYo    =  80                                                               #-
#    `simple line`                                                              #-
#[replace]                                                                      #-
#    before replacing                                                           #-
#[unify]                                                                        #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#[acc to ass]                                                                   #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#                                                                               #-
#    EOFini                                                                     #-
#    cat <<'EOFiniChild' > "${ini%/*}/child.${ini##*/}"                         #-
#    void  =  2                                                                 #-
#    main  =  main                                                              #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345679'                                          #-
#    sUname="$(uname)"                                                          #-
#    if [[ $HOSTNAME ]]; then                                                   #-
#    _____export HOSTNAME=$(hostname -f)                                        #-
#    fi                                                                         #-
#    echo $sUname                                                               #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt   =  $(date "+%s") =test = a =                                        #-
#    b      =  true                                                             #-
#    iXo Xo =  19                                                               #-
#    iYo    =  81                                                               #-
#    simple line                                                                #-
#[replace]                                                                      #-
#    after replacing                                                            #-
#[unify]                                                                        #-
#    *.xxx                                                                      #-
#    *.tmp                                                                      #-
#[acc to ass]                                                                   #-
#    *.bak                                                                      #-
#    *.tmp                                                                      #-
#    *.com                                                                      #-
#    *.exe                                                                      #-
#    *.jpg                                                                      #-
#    *.png                                                                      #-
#    *.mp3                                                                      #-
#    *.dll                                                                      #-
#    *.asp                                                                      #-
#    EOFiniChild                                                                #-
#   sed -i -e "s/_____/     /g" "${ini%/*}/child.${ini##*/}"                    #-
#   cat $ini
#   s=$( ini.group2 "${ini%/*}/child.${ini##*/}" "$c" )                          #? true
#   echo ${s/h=/hT=}
#   eval "${s/h=/hT=}"                                                            #-
##   for S in ${hT[__sections__]}; do                                           #-
#     for S in "${!hT[@]}"; do                                                  #-
#     unset hS
#     eval "${hT[$S]}"
#     echo "section $S"
#     for s in "${!hS[@]}"; do                                                  #-
#       echo "$s = ${hS[$s]}"
#     done                                                                      #-
#   done                                                                       #-
#  SOURCE
ini.group2() {

  udfOn NoSuchFileOrDir throw $1
  udfOn MissingArgument throw $2

  local -a a
  local i ini path s sIni sRawClass

  [[ $2 ]] && sRawClass="$2"

  [[ "$1" == "${1##*/}" && -f "$(_ pathIni)/$1" ]] && path=$(_ pathIni)
  [[ "$1" == "${1##*/}" && -f "$1"              ]] && path=$(pwd)
  [[ "$1" != "${1##*/}" && -f "$1"              ]] && path=${1%/*}

  if [[ ! $( stat -c %U ${path}/${1##*/} ) == $( _ sUser ) ]]; then

	eval $( udfOnError NotPermitted throw "$1 owned by $( stat -c %U ${path}/${1##*/} )" )

  fi
  #
  if [[ ! $path && -f "/etc/$(_ pathPrefix)/$1" ]]; then

    path="/etc/$(_ pathPrefix)"

  fi

  if [[ $path ]]; then

    s=${1##*/}
    a=( ${s//./ } )

    for (( i = ${#a[@]}-1; i >= 0; i-- )); do

      [[ ${a[i]} ]] || continue
      [[ $ini    ]] && ini="${a[i]}.${ini}" || ini="${a[i]}"
      [[ -s "${path}/${ini}" ]] && sIni="$( ini.get "${path}/${ini}" "$sIni" "$sRawClass" )"

    done

 fi

 echo "$sIni"

#	if ( scalar keys %_hCLI ) {
#
#		( $fh, $fn ) = tempfile();
#		writeTarget( $fh, \%_hCLI );
#		seek( $fh, 0, 0 ) or die "${fn}: seek error $!\n";
#		$ph = readSource( $fh, $ph, $phClass );
#		close( $fh );
#		unlink( $fn );
#
#	}
#
#	return $ph;
#
}
#******
#****f* libtst/ini.getsafe
#  SYNOPSIS
#    ini.getsafe args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#
#  SOURCE
#sub prepare {
#ini.getsafe() {
#
#	return undef unless @_ == 2
#						&& defined( $_[0] )
#						&&     ref( $_[0] )
#						&& defined( $_[1] );
#
#	my ( $ph, $s ) = @_;
#	my $p = undef;
#	my %h = ();
#	my @a = ();
#
#  local -a a
#  local -A hI hO
#  local s
  #
#  if [[ $1 ]]; then
#
#    [[ $1 =~ ^declare.-A.[[:alnum:]]+= ]] && s="${1#*=}" || s="$1"
#    eval "local -A hI=$s"
#
#  fi
#
#  s=$2
#
##	if ( $s !~ /^[\-\+=!]/ ) {
#  if [[ ! $s =~ ^[\!\-\+=] ]]; then
##
##		my @aValidOptions = ( $s =~ m/^(.*)$/ ) ? split( ',', $1 ) : ();
#                ## TODO keys without spaces!
#    for s in ${s//,/ }; do
#
#      hO[$s]=${hI[$s]}
#
#    done
#
#    declare -p hO
##		$h{$_} = $ph->{$_} foreach ( @aValidOptions );
##		$p = \%h;
##
##	} else {
#  else
#
##		push( @a, $ph->{$_} ) foreach sort { substr( $a, 14 ) <=> substr( $b, 14 ) } ( grep { /__unnamed_idx_/ } keys %{$ph} );
#    for s in $( echo "${!h[@]}" | tr ' ' '\n' | grep "__unnamed_idx=${S}$" | sort -t= -k2n); do   #-
#
#		@a = grep { ! $h{$_}++ } @a if "$s" =~ /=/;
#		$p = \@a;
#
#	}
#
#	return $p;
#
#}
##******
#****f* libtst/ini.getOnlyWhatYouNeed
#  SYNOPSIS
#    ini.getOnlyWhatYouNeed args
#  DESCRIPTION
#    ...
#  INPUTS
#    ...
#  OUTPUT
#    ...
#  RETURN VALUE
#    ...
#  EXAMPLE
#
#  SOURCE
#sub parse {
#ini.getOnlyWhatYouNeed() {
#
#	return () unless @_ > 1;
#  udfOn MissingArgument $@ || return $?
#  udfOn NoSuchFileOrDir $1 || return $?
#
##
##	my ( $fn, $ph, %h ) = ( "$_[0]", undef, () );
#  local -a a
#  local -A hI hO
#  local csv fn s
##
#  fn=$1
##
##	shift;
#  shift
##
#	foreach (@_) {
#		my $s  = ( m/^(.*?):.*$/           ) ? $1 : "";
#		$h{$s} = ( m/^.*?:([=\-\+\!]|.*)$/ ) ? $1 : "";
#	}
#
#	$ph = readRelated( $fn, $ph, \%h );
#	if ( defined $ph && scalar keys %{$ph} ) {
#		$ph->{$_} = prepare( $ph->{$_}, $h{$_} ) foreach keys %{$ph};
#	}
#
#  for s in "$@"; do
#
#    if [[ $s =~ ^(.*)?:([=+\-]?)([^=+\-].*)$ ]]; then
#
#     sSection=${BASH_REMATCH[1]}
#     : ${sSection:=__global__}
#     sRawClass=${BASH_REMATCH[2]}
#     csvOptions=${BASH_REMATCH[3]}
#
#    else
#
#      udfOn InvalidArgument throw $s
#
#    fi
#
#    hRawClass[$sSection]="$sRawClass"
#    hOptions[$sSection]="$csvOptions"
#
#  done
#
#  $sIni=$(ini.group $ini $sIni "$(declare -A hRawClass)" )
#
#  for sSection in ${!hOptions[@]}; do
#
#    for s in
#
#  done
#
#	return $ph;
#
#}
#
