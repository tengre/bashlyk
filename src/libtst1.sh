#
# $Id: libtst1.sh 601 2016-11-25 16:18:39+04:00 toor $
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

[[ -n "$_BASHLYK_LIBTST" ]] && return 0 || _BASHLYK_LIBTST=1
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
declare -A ini_h
declare -A ini_hClass
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
#   local ini s=""                                                              #-
#   udfMakeTemp ini                                                             #-
#    cat <<'EOFini' > ${ini}                                                    #-
#    void  =  1                                                       #-
#[exec]:                                                                        #-
#    TZ=UTC date -R --date='@12345678'                                          #-
#    sUname="$(uname -a)"                                                       #-
#:[exec]                                                                        #-
#[main]                                                                         #-
#    sTxt  =  $(date -R)                                              #-
#    b    =  false                                                   #-
#    iXo Xo  =  19                                                      #-
#    iYo  =  80                                                      #-
#    `simple line`                                                              #-
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
#   ini_hClass["__void__"]=""
#   ini_hClass["exec"]="!"
#   ini_hClass["main"]=""
#   ini_hClass["replace"]="-"
#   ini_hClass["unify"]="="
#   ini_hClass["acc"]="+"
#   cat $ini
#   ini.read $ini ini_h ini_hClass                                               #? true
#  SOURCE
#udfRead() {
ini.read() {

#  return undef unless @_ == 3
#            && defined( $_[0] )
#            && udfIsFD( $_[0] )
#            #&& defined( $_[1] )
#            #&&     ref( $_[1] ) eq 'HASH'
#            && defined( $_[2] )
#            &&     ref( $_[2] ) eq 'HASH';
#
  udfOn NoSuchFileOrDir throw $1
  typeset -A $2 || eval $( udfOnError throw InvalidArgument "$2 must be hash" )
  typeset -A $3 || eval $( udfOnError throw InvalidArgument "$3 must be hash" )

  local -a a
  local -A h
  local bA chClass fn i k p ph s sKeyLast sNewSection v
  #
  i=0
  ## TODO - check unnamed section
  s="__void__"
  #
  fn=$1

  a[0]=$s

  while read -t 4; do

    if [[ $REPLY =~ ^[[:space:]]*(:?)\[[[:space:]]*([^[:punct:]]+?)[[:space:]]*\](:?)[[:space:]]*$ ]]; then

      sNewSection=${BASH_REMATCH[2]}

      s=$sNewSection;
      i=0

      [[ ${BASH_REMATCH[1]} == ":" ]] && h[${s}".__class_active"]=2
      [[ ${BASH_REMATCH[3]} == ":" ]] && h[${s}".__class_active"]=1

      a[${#a[@]}]="$s"
      sKeyLast=""

    else

      [[ $REPLY =~ (^|[[:space:]]+)[\#\;].*$ && ! ${ini_hClass[$s]} =~ ^\!$ ]] && continue

      #+ TODO line with multi '='
      #+ TODO key with spaces...
      #+ TODO active sections...
      if [[    ! ${h[${s}".__class_active"]} =~ ^(1|2)$     \
            && ! ${ini_hClass[$s]}           =~ ^[=\!\-\+]$ \
            && $REPLY =~ ^[[:space:]]*([[:alnum:]]+)[[:space:]]*=\[[:space:]]*(.*)[[:space:]]*$ \
         ]]

      then

        k=${BASH_REMATCH[1]}
        v=${BASH_REMATCH[2]}
        if [[ $k =~ "=" ]]; then

          k=${REPLY%%=*}
          k=${k%% *}
          v=${REPLY#*=}
          v=${v#* }
          h[${s}.${k}]=$v
          sKeyLast=$k

        else

          sKeyLast="$k"
          h[${s}.${sKeyLast}]="$v"

        fi

      else

#        if [[ -n "$sKeyLast" && ! ${h[${s}".__class_active"]} =~ ^(1|2)$ && ! ${ini_hClass[$s]} =~ ^[=!\-\+]$ ]]; then
#
#          h[${s}.${sKeyLast}]+="\n${REPLY}"
#
#        fi
#
        if [[ ! $chClass =~ ^=$ ]]; then

          REPLY=${REPLY##*( )}
          REPLY=${REPLY%%*( )}
        fi

        : $(( i++ ))
        h[${s}".__unnamed_idx_"${i}]="$REPLY"

      fi
    fi
  done < $fn

  for s in ${!h[@]}; do

    echo "pair: $s = ${h[$s]}"

  done
}
#******
