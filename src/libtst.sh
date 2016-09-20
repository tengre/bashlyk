#
# $Id: libtst.sh 554 2016-09-20 21:37:15+04:00 toor $
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
: ${_bashlyk_aExport_msg:="udfTest"}
#******
#****f* libtst/udfMakeTemp
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
#  RETURN VALUE
#    0                  - success
#    NotExistNotCreated - temporary file system object is not created
#    InvalidVariable    - used invalid variable name
#    EmptyResult        - name for temporary object missing
#
#  EXAMPLE
#    ## TODO improve tests
#    local foTemp
#    _ onError return
#    udfMakeTemp -v foTemp path=$HOME prefix=pre. suffix=.suf1                  #? true
#    ls $foTemp >| grep -w "$HOME/pre\..*\.suf1"                                #? true
#    udfMakeTemp foTemp path=$HOME prefix=pre. suffix=.suf2                     #? true
#    ls $foTemp >| grep -w "$HOME/pre\..*\.suf2"                                #? true
#    udfMakeTemp -v foTemp type=dir mode=0751
#    ls -ld $foTemp >| grep "^drwxr-x--x.*${s}$"                                #? true
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.suf3)                             #? true
#    ls $foTemp >| grep "pre\..*\.suf3$"                                        #? true
#    rm -f $foTemp
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.suf4 keep=false)                  #? true
#    echo $foTemp
#    test -f $foTemp                                                            #? false
#    rm -f $foTemp
#    $(udfMakeTemp -v foTemp path=/tmp prefix=pre. suffix=.suf5)
#    ls -l /tmp/*.noex 2>/dev/null >| grep .*\.*suf5                            #? false
#    unset foTemp
#    foTemp=$(udfMakeTemp)                                                      #? true
#    ls -l $foTemp 2>/dev/null                                                  #? true
#    test -f $foTemp                                                            #? true
#    rm -f $foTemp
#    udfMakeTemp -v foTemp type=pipe						#? true
#    test -p $foTemp								#? true
#    ls -l $foTemp
#    udfMakeTemp -v 2t                                                          #? ${_bashlyk_iErrorInvalidVariable}
#    udfMakeTemp path=/proc                                                     #? ${_bashlyk_iErrorNotExistNotCreated}
#  SOURCE
udfMakeTemp() {

	if [[ "$1" == "-v" ]] || udfIsValidVariable $1; then

		[[ "$1" == "-v" ]] && shift

		udfIsValidVariable $1 || eval $( udfOnError2 InvalidVariable "$1" )

		eval 'export $1="$( shift; udfMakeTemp --show-only $@ )"'

		[[ -n ${!1} ]] || eval $( udfOnError2 iErrorEmptyResult "$1" )

		[[ $* =~ keep=true ]] || udfAddFObj2Clean ${!1}

		return 0

	fi

	local bKeep bPipe cmd IFS octMode optDir path s sGroup sPrefix sSuffix sUser

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
			       *)
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

	if   [[ -f "$(which mktemp)" ]]; then

		cmd=mktemp

	elif [[ -f "$(which tempfile)" ]]; then

		[[ -z "$optDir" ]] && cmd=tempfile || cmd=direct

	fi


	if [[ -z "$path" ]]; then

		if [[ -z $bPipe ]]; then

			path="/tmp"

		else

			path=$( _ pathRun )

		fi

	fi

	mkdir -p $path || eval $( udfOnError2 NotExistNotCreated "$path" )

	case "$cmd" in

	direct)

		s="${path}/${sPrefix:0:5}${RANDOM}${sSuffix}"

		[[ -n "$optDir" ]] && mkdir -p $s || touch $s

	;;

	mktemp)

		s=$(mktemp --tmpdir=${path} $optDir --suffix=${sSuffix} "${sPrefix:0:5}XXXXXXXX")

	;;

	tempfile)

		[[ -n "$sPrefix" ]] && sPrefix="-p ${sPrefix:0:5}"
		[[ -n "$sSuffix" ]] && sSuffix="-s $sSuffix"

		s=$(tempfile -d $path $sPrefix $sSuffix)

	;;

	esac

	if [[ -n $bPipe ]]; then

		rm -f  $s
		mkfifo $s

	fi >&2

	[[ -n "$octMode" ]] && chmod $octMode $s

	## TODO обработка ошибок
	if [[ $UID == 0 ]]; then

		[[ -n "$sUser"  ]] && chown $sUser  $s
		[[ -n "$sGroup" ]] && chgrp $sGroup $s

	fi >&2

	if ! [[ -f "$s" || -p "$s" || -d "$s" ]]; then

		eval $(udfOnError2 NotExistNotCreated $s)

	fi

	[[ $* =~ keep=false ]] && udfAddFObj2Clean $s

	echo $s

	[[ -n $s ]] && return 0 || return $( _ iErrorEmptyResult )

}
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
#    udfTest
#  SOURCE
udfTest() {
 return 0
}
#******
