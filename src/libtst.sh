#
# $Id: libtst.sh 557 2016-09-22 17:22:40+04:00 toor $
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
#    udfMakeTemp foTemp path=$HOME prefix=pre. suffix=.suf1                  #? true
#    ls $foTemp >| grep -w "$HOME/pre\..*\.suf1"                                #? true
#    udfMakeTemp foTemp path=$HOME prefix=pre. suffix=.suf2                     #? true
#    ls $foTemp >| grep -w "$HOME/pre\..*\.suf2"                                #? true
#    udfMakeTemp foTemp type=dir mode=0751
#    ls -ld $foTemp >| grep "^drwxr-x--x.*${s}$"                                #? true
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.suf3)                             #? true
#    ls $foTemp >| grep "pre\..*\.suf3$"                                        #? true
#    rm -f $foTemp
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.suf4 keep=false)                  #? true
#    echo $foTemp
#    test -f $foTemp                                                            #? false
#    rm -f $foTemp
#    $(udfMakeTemp foTemp path=/tmp prefix=pre. suffix=.suf5)
#    ls -l /tmp/*.noex 2>/dev/null >| grep .*\.*suf5                            #? false
#    unset foTemp
#    foTemp=$(udfMakeTemp)                                                      #? true
#    ls -l $foTemp 2>/dev/null                                                  #? true
#    test -f $foTemp                                                            #? true
#    rm -f $foTemp
#    udfMakeTemp foTemp type=pipe						#? true
#    test -p $foTemp								#? true
#    ls -l $foTemp
#    udfMakeTemp 2t                                                             #? ${_bashlyk_iErrorInvalidVariable}
#    udfMakeTemp path=/proc                                                     #? ${_bashlyk_iErrorNotExistNotCreated}
#  SOURCE
udfMakeTemp() {

	if [[ "$1" == "-v" ]] || udfIsValidVariable $1; then

		[[ "$1" == "-v" ]] && shift

		udfIsValidVariable $1 || eval $( udfOnError2 InvalidVariable "$1" )

		eval 'export $1="$( shift; udfMakeTemp stdout-mode $@ )"'

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
			  keep=*) bKeep=${s#*=};;
	             stdout-mode) continue;;
			       *)

			        if [[ $1 == $s ]]; then

					udfIsValidVariable $1 || eval $( udfOnError2 InvalidVariable "$s" )

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
		: ${octMode:=0600}

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
#****f* libtst/udfCheckCsv
#  SYNOPSIS
#    udfCheckCsv "<csv;>" [[-v] <varname>]
#  DESCRIPTION
#    Нормализация CSV-строки <csv;>. Приведение к виду "ключ=значение" полей.
#    В случае если поле не содержит ключа или ключ содержит пробел, то к полю
#    добавляется ключ вида _bashlyk_unnamed_key_<инкремент>, всё содержимое поля
#    становится значением.
#    Результат выводится в стандартный вывод или в переменную, если имеется
#    второй аргумент функции <varname>
#  INPUTS
#    csv;    - CSV-строка, разделённая ";"
#    varname - идентификатор переменной (без "$ "). При его наличии результат
#              будет помещен в соответствующую переменную. При отсутствии такого
#              идентификатора результат будет выдан на стандартный вывод
#    Важно! Экранировать аргументы двойными кавычками, если есть вероятность
#    наличия в них пробелов
#  OUTPUT
#              разделенный символом ";" строка, в полях которого содержатся
#              данные в формате "<key>=<value>;..."
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNonValidVariable       - не валидный идентификатор
#    0                            - успешная операция
#  EXAMPLE
#    local s="a=b;a=c;s=a b c d e f;test value" r
#    local csv='^a=b;a=c;s="a b c d e f";_bashlyk_unnamed_key_0="test value";$'
#    udfCheckCsv "$s" >| grep "$csv"                                            #? true
#    udfCheckCsv "$s" r                                                         #? true
#    echo $r >| grep "$csv"                                                     #? true
#    udfCheckCsv "$s" 2r                                                        #? ${_bashlyk_iErrorNonValidVariable}
#    udfCheckCsv                                                                #? ${_bashlyk_iErrorEmptyOrMissingArgument}
#  SOURCE
udfCheckCsv() {

	if [[ -n "$2" ]]; then

		[[ "$2" == "-v" ]] && shift

		udfIsValidVariable $2 || eval $( udfOnError return InvalidVariable "$2" )

		eval 'export $2="$( udfCheckCsv "$1" )"'

		[[ -n ${!2} ]] || eval $( udfOnError return iErrorEmptyResult "$2" )

		return 0

	fi

	local IFS=$' \t\n'

	udfOn MissingArgument $1 || return $?

	local s k v i csvResult

	IFS=';'
	i=0
	csvResult=''
 #
	for s in $1; do

		s=${s/\[*\][,;]/}
		s=${s//[\'\"]/}

		k="$(echo ${s%%=*}|xargs)"
		v="$(echo ${s#*=}|xargs)"

		[[ -n "$k" ]] || continue
		if [[ "$k" == "$v" || -n "$(echo "$k" | grep '.*[[:space:]+].*')" ]]; then

			k=${_bashlyk_sUnnamedKeyword}${i}
			i=$((i+1))

		fi

		IFS=' ' csvResult+="$k=$(udfQuoteIfNeeded $v);"

	done

	IFS=$' \t\n'

	echo "$csvResult"

	[[ -n $csvResult ]] && return 0 || return $( _ iErrorEmptyResult )

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
