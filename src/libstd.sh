#
# $Id: libstd.sh 628 2016-12-19 00:27:21+04:00 toor $
#
#****h* BASHLYK/libstd
#  DESCRIPTION
#    стандартный набор функций, включает автоматически управляемые функции
#    вывода сообщений, контроля корректности входных данных, создания временных
#    объектов и автоматического их удаления после завершения сценария или
#    фонового процесса, обработки ошибок
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libstd/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
[[ $_BASHLYK_LIBSTD ]] && return 0 || _BASHLYK_LIBSTD=1
#******
#****** libstd/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libmsg.sh ]] && . "${_bashlyk_pathLib}/libmsg.sh"
#******
#****v* libstd/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#    * $_bashlyk_sArg - аргументы командной строки вызова сценария
#    * $_bashlyk_sWSpaceAlias - заменяющая пробел последовательность символов
#    * $_bashlyk_aRequiredCmd_opt - список используемых в данном модуле внешних
#    утилит
#  SOURCE
_bashlyk_iMaxOutputLines=1000
#
: ${_bashlyk_onError:=throw}
: ${_bashlyk_sArg:="$@"}
: ${_bashlyk_pathDat:=/tmp}
: ${_bashlyk_sWSpaceAlias:=___}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}
: ${_bashlyk_s0:=${0##*/}}
: ${_bashlyk_sId:=${_bashlyk_s0%.sh}}
: ${_bashlyk_afoClean:=}
: ${_bashlyk_afdClean:=}
: ${_bashlyk_ajobClean:=}
: ${_bashlyk_apidClean:=}
: ${_bashlyk_pidLogSock:=}
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_reMetaRules:='34=":40=(:41=):59=;:91=[:92=\\:93=]:61=='}
: ${_bashlyk_envXSession:=}
: ${_bashlyk_aRequiredCmd_std:="cat chgrp chmod chown cut date echo grep hostname kill \
  logname md5sum mkdir mkfifo mktemp pgrep ps pwd rm rmdir sed sleep tempfile touch tr \
  which xargs"}
: ${_bashlyk_aExport_std:="_ _ARGUMENTS _gete _getv _pathDat _s0 _set udfAddFile2Clean    \
  udfAddFD2Clean udfAddFO2Clean udfAddFObj2Clean udfAddJob2Clean udfAddPath2Clean         \
  udfAddPid2Clean udfAlias2WSpace udfBaseId udfBashlykUnquote udfCheckCsv udfCleanQueue   \
  udfDate udfGetFreeFD udfGetMd5 udfGetPathMd5 udfIsNumber udfIsValidVariable             \
  udfLocalVarFromCSV udfMakeTemp udfMakeTempV udfOnTrap udfPrepare2Exec udfPrepareByType  \
  udfQuoteIfNeeded udfSerialize udfShellExec udfShowVariable udfTimeStamp udfWSpace2Alias \
  udfXml"}
#******
#****f* libstd/udfIsNumber
#  SYNOPSIS
#    udfIsNumber <number> [<tag>]
#  DESCRIPTION
#    Проверка аргумента на то, что он является натуральным числом
#    Аргумент считается числом, если он содержит цифры и может иметь в конце
#    символ - признак порядка, например, k M G T (kilo-, Mega-, Giga-, Terra-)
#  INPUTS
#    number - проверяемое значение
#    tag    - набор символов, один из которых можно применить
#             после цифр для указания признака числа, например,
#             порядка. (регистр не имеет значения)
#  RETURN VALUE
#    0                            - аргумент является натуральным числом
#    iErrorNonValidArgument       - аргумент не является натуральным числом
#    iErrorEmptyOrMissingArgument - аргумент не задан
#  EXAMPLE
#    udfIsNumber 12                                                             #? true
#    udfIsNumber 34k k                                                          #? true
#    udfIsNumber 67M kMGT                                                       #? true
#    udfIsNumber 89G G                                                          #? true
#    udfIsNumber 12,34                                                          #? $_bashlyk_iErrorNonValidArgument
#    udfIsNumber 12T                                                            #? $_bashlyk_iErrorNonValidArgument
#    udfIsNumber 1O2                                                            #? $_bashlyk_iErrorNonValidArgument
#    udfIsNumber                                                                #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
udfIsNumber() {
 [[ -n "$1" ]] || return $_bashlyk_iErrorEmptyOrMissingArgument
 local s
 [[ -n "$2" ]] && s="[$2]?"
 [[ "$1" =~ ^[0-9]+${s}$ ]] && return 0 || return $_bashlyk_iErrorNonValidArgument
}
#******
#****f* libstd/udfBaseId
#  SYNOPSIS
#    udfBaseId
#  DESCRIPTION
#    получить имя сценария без расширения .sh
#    устаревшая - заменяется "_ sId"
#  OUTPUT
#    Короткое имя запущенного сценария без расширения ".sh"
#  EXAMPLE
#    udfBaseId >| grep -w "^$(basename $0 .sh)$"                                #? true
#  SOURCE
udfBaseId() {
 _ sId
}
#******
#****f* libstd/udfTimeStamp
#  SYNOPSIS
#    udfTimeStamp <args>
#  DESCRIPTION
#    сформировать строку c заголовком в виде текущего времени в формате
#    'Jun 25 14:52:56' (LANG=C LC_TIME=C)
#  INPUTS
#    <args> - суффикс к заголовку
#  OUTPUT
#    строка с заголовком в виде "штампа времени"
#  EXAMPLE
#    local re="[a-zA-Z]+ [0-9]+ [0-9]+:[0-9]+:[[:digit:]]+ foo bar"
#    udfTimeStamp foo bar >| grep -E "$re"                                      #? true
#  SOURCE
udfTimeStamp() {
 LANG=C LC_TIME=C LC_ALL=C date "+%b %d %H:%M:%S $*"
}
#******
#****f* libstd/udfDate
#  SYNOPSIS
#    udfDate <args>
#  DESCRIPTION
#    сформировать строку c заголовком в виде текущего времени
#  INPUTS
#    <args> - суффикс к заголовку
#  OUTPUT
#    строка с заголовком в виде "штампа времени"
#  EXAMPLE
#    local re="[[:graph:]]+ [0-9]+ [0-9]+:[0-9]+:[[:digit:]]+ foo bar"
#    udfDate foo bar >| grep -E "$re"                                           #? true
#  SOURCE
udfDate() {
 date "+%b %d %H:%M:%S $*"
}
#******
#****f* libstd/udfShowVariable
#  SYNOPSIS
#    udfShowVariable args
#  DESCRIPTION
#    Вывод листинга значений аргументов, если они являются именами переменными. Допускается
#    разделять имена переменных знаками ',' и ';', однако, необходимо помнить, что знак ';'
#    (или аргументы целиком) необходимо экранировать кавычками, иначе интерпретатор воспримет
#    аргумент как следующую команду!
#    Если аргумент не является валидным именем переменной, то выводится соответствующее сообщение.
#    Функцию можно использовать для формирования строк инициализации переменных, при этом
#    информационные строки за счет экранирования командой ':' не выполняют никаких действий
#    при разборе интерпретатором, их также можно отфильтровать командой "grep -v '^:'"
#  INPUTS
#    args - ожидаются имена переменных
#  OUTPUT
#    служебные строки выводятся с начальным ':' для автоматической подавления возможности выполнения
#    Валидное имя переменной и значение в виде <Имя>=<Значение>
#  EXAMPLE
#    local s='text' b='true' i=2015 a='true 2015 text'
#    udfShowVariable "a,b; i" s  >| grep -w "a=true 2015 text\|b=true\|i=2015\|s=text"                                    #? true
#    udfShowVariable a b i s 12w >| grep '^:.*12w.* not valid'                                                            #? true                                                                             #? true
#  SOURCE
udfShowVariable() {
 local bashlyk_udfShowVariable_a bashlyk_udfShowVariable_s IFS=$'\t\n ,;'
 for bashlyk_udfShowVariable_s in $*; do
  if udfIsValidVariable $bashlyk_udfShowVariable_s; then
   bashlyk_udfShowVariable_a+="\t${bashlyk_udfShowVariable_s}=${!bashlyk_udfShowVariable_s}\n"
  else
   bashlyk_udfShowVariable_a+=": Variable name \"${bashlyk_udfShowVariable_s}\" is not valid!\n"
  fi
 done
 echo -e ": Variable listing>\n${bashlyk_udfShowVariable_a}"
 return 0
}
#******
#****f* libstd/udfIsValidVariable
#  SYNOPSIS
#    udfIsValidVariable <arg>
#  DESCRIPTION
#    Проверка аргумента на то, что он может быть валидным идентификатором
#    переменной
#  INPUTS
#    arg - проверяемое значение
#  RETURN VALUE
#    0                            - аргумент валидный идентификатор
#    iErrorNonValidVariable       - аргумент невалидный идентификатор (или не задан)
#  EXAMPLE
#    udfIsValidVariable                                                         #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable "12w"                                                   #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable "a"                                                     #? true
#    udfIsValidVariable "k1"                                                    #? true
#    udfIsValidVariable "&w1"                                                   #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable "#k12s"                                                 #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable ":v1"                                                   #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable ";q1"                                                   #? $_bashlyk_iErrorNonValidVariable
#    udfIsValidVariable ",g99"                                                  #? $_bashlyk_iErrorNonValidVariable
#  SOURCE
udfIsValidVariable() {
 local IFS=$' \t\n'
 [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]] && return 0 || eval $(udfOnError return iErrorNonValidVariable '${1}')
}
#******
#****f* libstd/udfQuoteIfNeeded
#  SYNOPSIS
#    udfQuoteIfNeeded <arg>
#  DESCRIPTION
#   Аргумент, содержащий пробел(ы) отмечается кавычками
#  INPUTS
#    arg - argument
#  OUTPUT
#    аргумент с кавычками, если есть пробелы
#  EXAMPLE
#    udfQuoteIfNeeded "word" >| grep '^word$'                                   #? true
#    udfQuoteIfNeeded two words >| grep '^".*"$'                                #? true
#  SOURCE
udfQuoteIfNeeded() {
 [[ "$*" =~ [[:space:]] ]] &&  echo "\"$*\"" || echo "$*"
}
#******
#****f* libstd/udfWSpace2Alias
#  SYNOPSIS
#    udfWSpace2Alias -|<arg>
#  DESCRIPTION
#   Пробел в аргументе заменяется "магической" последовательностью символов,
#   определённых в глобальной переменной $_bashlyk_sWSpaceAlias
#  INPUTS
#    arg - argument
#    "-" - ожидается ввод в конвейере
#  OUTPUT
#   Аргумент с заменой пробелов на специальную последовательность символов
#  EXAMPLE
#    udfWSpace2Alias 'a b  cd' >| grep  '^a___b______cd$'                       #? true
#    echo 'a b  cd' | udfWSpace2Alias - >| grep '^a___b______cd$'               #? true
#  SOURCE
udfWSpace2Alias() {
 case "$1" in
 -) sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
 *) echo "$*" | sed -e "s/ /$_bashlyk_sWSpaceAlias/g";;
 esac
}
#******
#****f* libstd/udfAlias2WSpace
#  SYNOPSIS
#    udfAlias2WSpace -|<arg>
#  DESCRIPTION
#    Последовательность символов, определённых в глобальной переменной
#    $_bashlyk_sWSpaceAlias заменяется на пробел в заданном аргументе.
#    Причём, если появляются пробелы, то вывод обрамляется кавычками.
#    В случае ввода в конвейере вывод не обрамляется кавычками
#  INPUTS
#    arg - argument
#  OUTPUT
#    Аргумент с заменой специальной последовательности символов на пробел
#  EXAMPLE
#    udfAlias2WSpace a___b______cd >| grep '^"a b  cd"$'                        #? true
#    echo a___b______cd | udfAlias2WSpace - >| grep '^a b  cd$'                 #? true
#  SOURCE
udfAlias2WSpace() {
 case "$1" in
 -) sed -e "s/$_bashlyk_sWSpaceAlias/ /g";;
 *) udfQuoteIfNeeded "$(echo "$*" | sed -e "s/$_bashlyk_sWSpaceAlias/ /g")";;
 esac
}
#******
#****f* libstd/udfMakeTemp
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
#    local foTemp s=$RANDOM
#    _ onError return
#    udfMakeTemp foTemp path=/tmp prefix=pre. suffix=.${s}1                     #? true
#    ls -1 /tmp/pre.*.${s}1 2>/dev/null >| grep "/tmp/pre\..*\.${s}1"           #? true
#    rm -f $foTemp
#    udfMakeTemp foTemp path=/tmp type=dir mode=0751 suffix=.${s}2              #? true
#    ls -ld $foTemp 2>/dev/null >| grep "^drwxr-x--x.*${s}2$"                   #? true
#    rmdir $foTemp
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.${s}3)
#    ls -1 $foTemp 2>/dev/null >| grep "pre\..*\.${s}3$"                        #? true
#    rm -f $foTemp
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.${s}4 keep=false)                 #? true
#    echo $foTemp | grep "/tmp/pre\..*\.${s}4"                                  #? true
#    test -f $foTemp                                                            #? false
#    rm -f $foTemp
#    $(udfMakeTemp foTemp path=/tmp prefix=pre. suffix=.${s}5 keep=true)
#    ls -1 /tmp/pre.*.${s}5 2>/dev/null >| grep "/tmp/pre\..*\.${s}5"           #? true
#    rm -f /tmp/pre.*.${s}5
#    $(udfMakeTemp foTemp path=/tmp prefix=pre. suffix=.${s}6)
#    ls -1 /tmp/pre.*.${s}6 2>/dev/null >| grep "/tmp/pre\..*\.${s}6"           #? false
#    unset foTemp
#    foTemp=$(udfMakeTemp)                                                      #? true
#    ls -1l $foTemp 2>/dev/null                                                 #? true
#    test -f $foTemp                                                            #? true
#    rm -f $foTemp
#    udfMakeTemp foTemp type=pipe						#? true
#    test -p $foTemp								#? true
#    rm -f $foTemp
#    udfMakeTemp invalid+variable                                               #? ${_bashlyk_iErrorInvalidVariable}
#    udfMakeTemp path=/proc                                                     #? ${_bashlyk_iErrorNotExistNotCreated}
#  SOURCE
udfMakeTemp() {

	if [[ "$1" == "-v" ]] || udfIsValidVariable $1; then

		[[ "$1" == "-v" ]] && shift

		udfIsValidVariable $1 || eval $( udfOnError2 InvalidVariable "$1" )

		eval 'export $1="$( shift; udfMakeTemp stdout-mode ${@//keep=false/} )"'

		[[ -n ${!1} ]] || eval $( udfOnError2 iErrorEmptyResult "$1" )

		[[ $* =~ keep=false ]] && udfAddFO2Clean ${!1}
		[[ $* =~ keep=true  ]] || udfAddFO2Clean ${!1}

		return 0

	fi

	local bPipe cmd IFS octMode optDir path s sGroup sPrefix sSuffix sUser

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
			  keep=*) continue;;
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

		[[ -z $bPipe ]] && path="/tmp" || path=$( _ pathRun )

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

	[[ $* =~ keep=false ]] && udfAddFO2Clean $s

	echo $s

	[[ -n $s ]] && return 0 || return $( _ iErrorEmptyResult )

}
#******
#****f* libstd/udfMakeTempV
#  SYNOPSIS
#    udfMakeTempV <var> [file|dir|keep|keepf[ile*]|keepd[ir]] [<prefix>]
#  DESCRIPTION
#    Create a temporary file or directory with automatic removal upon completion
#    of the script, the object name assigned to the variable.
#    Obsolete - replaced by a udfMakeTemp
#  INPUTS
#    <var>      - the output assigned to the <variable> (as bash printf)
#                 option -v can be omitted, variable must be correct and this
#                 options must be first
#    file       - create file
#    dir        - create directory
#    keep[file] - create file, keep after done
#    keepdir    - create directory, keep after done
#    prefix     - prefix for name (5 letters)
#  RETURN VALUE
#    0                  - success
#    NotExistNotCreated - temporary file system object is not created
#    InvalidVariable    - used invalid variable name
#    EmptyResult        - name for temporary object missing
#  EXAMPLE
#    local foTemp
#    udfMakeTempV foTemp file prefix                                            #? true
#    ls $foTemp >| grep "prefi"                                                 #? true
#    udfMakeTempV foTemp dir                                                    #? true
#    ls -ld $foTemp >| grep "^drwx------.*${foTemp}$"                           #? true
#    echo $(udfAddPath2Clean $foTemp)
#    test -d $foTemp                                                            #? false
#  SOURCE
udfMakeTempV() {

	local sKeep sType sPrefix IFS=$' \t\n'

	[[ -n "$1" ]] || eval $(udfOnError throw iErrorEmptyOrMissingArgument "$1")

	udfIsValidVariable "$1" || eval $(udfOnError throw iErrorNonValidVariable "$1")

	[[ -n "$3" ]] && sPrefix="prefix=$3"

	case "$2" in

		 dir) sType="type=dir" ; sKeep="keep=false" ;;
		file) sType="type=file"; sKeep="keep=false" ;;
	 keep|keepf*) sType="type=file"; sKeep="keep=true"  ;;
	      keepd*) sType="type=dir" ; sKeep="keep=true"  ;;
		  '') sType="type=file"; sKeep="keep=false" ;;
		   *) sPrefix="prefix=$2"                   ;;
	esac

	udfMakeTemp $1 $sType $sKeep $sPrefix
}
#******
#****f* libstd/udfPrepare2Exec
#  SYNOPSIS
#    udfPrepare2Exec - args
#  DESCRIPTION
#    Преобразование метапоследовательностей _bashlyk_&#XX_ в символы '[]()=;\'
#    со стандартного входа или строки аргументов. В последнем случае,
#    дополнительно происходит разделение полей "CSV;"-строки в отдельные
#    строки
#  INPUTS
#    args - командная строка
#       - - данные поступают со стандартного входа
#  OUTPUT
#    поток строк, пригодных для выполнения командным интерпретатором
#  EXAMPLE
#    local s1 s2
#    s1="_bashlyk_&#91__bashlyk_&#93__bashlyk_&#59__bashlyk_&#40__bashlyk_&#41__bashlyk_&#61_"
#    s2="while _bashlyk_&#91_ true _bashlyk_&#93_; do read;done"
#    echo $s1 | udfPrepare2Exec -                                                              #? true
#    udfPrepare2Exec $s1 >| grep -e '\[\];()='                                                 #? true
#    udfPrepare2Exec $s2 >| grep -e "^while \[ true \]$\|^ do read$\|^done$"                   #? true
#  SOURCE
udfPrepare2Exec() {
 local s IFS=$' \t\n'
 if [[ "$1" == "-" ]]; then
  udfBashlykUnquote
 else
  echo -e "${*//;/\\n}" | udfBashlykUnquote
 fi
 return 0
}
#******
#****f* libstd/udfShellExec
#  SYNOPSIS
#    udfShellExec args
#  DESCRIPTION
#    Выполнение командной строки во внешнем временном файле
#    в текущей среде интерпретатора оболочки
#  INPUTS
#    args - командная строка
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    в остальных случаях код возврата командной строки с учетом доступа к временному файлу
#  EXAMPLE
#    udfShellExec 'true; false'                                                 #? false
#    udfShellExec 'false; true'                                                 #? true
#  SOURCE
udfShellExec() {
 local rc fn IFS=$' \t\n'
 [[ -n "$*" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 udfMakeTemp fn
 udfPrepare2Exec $* > $fn
 . $fn
 rc=$?
 rm -f $fn
 return $rc
}
#******
#****f* libstd/udfAddFile2Clean
#  SYNOPSIS
#    udfAddFile2Clean args
#  DESCRIPTION
#    Добавляет имена файлов к списку удаляемых при завершении сценария
#    Предназначен для удаления временных файлов.
#  INPUTS
#    args - имена файлов
#  EXAMPLE
#    local a fnTemp1 fnTemp2 s=$RANDOM
#    udfMakeTemp fnTemp1 keep=true suffix=.${s}1
#    test -f $fnTemp1                                                           #? true
#    echo $(udfAddFile2Clean $fnTemp1 )
#    ls -l /tmp/*.${s}1 2>/dev/null >| grep ".*\.${s}1"                         #? false
#    echo $(udfMakeTemp fnTemp2 suffix=.${s}2)
#    ls -l /tmp/*.${s}2 2>/dev/null >| grep ".*\.${s}2"                         #? false
#    echo $(udfMakeTemp fnTemp2 suffix=.${s}3 keep=true)
#    ls -l /tmp/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                         #? true
#    a=$(ls -1 /tmp/*.${s}3)
#    echo $(udfAddFile2Clean $a )
#    ls -l /tmp/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                         #? false
#  SOURCE
udfAddFile2Clean() { udfAddFO2Clean $@; }
#******
#****f* libstd/udfAddPath2Clean
#  SYNOPSIS
#    udfAddPath2Clean args
#  DESCRIPTION
#    Добавляет имена каталогов к списку удаляемых при завершении сценария.
#    Предназначен для удаления временных каталогов (если они пустые).
#  INPUTS
#    args - имена каталогов
#  EXAMPLE
#    local a pathTemp1 pathTemp2 s=$RANDOM
#    udfMakeTemp pathTemp1 keep=true suffix=.${s}1 type=dir
#    test -d $pathTemp1                                                         #? true
#    echo $(udfAddPath2Clean $pathTemp1 )
#    ls -1ld /tmp/*.${s}1 2>/dev/null >| grep ".*\.${s}1"                       #? false
#    echo $(udfMakeTemp pathTemp2 suffix=.${s}2 type=dir)
#    ls -1ld /tmp/*.${s}2 2>/dev/null >| grep ".*\.${s}2"                       #? false
#    echo $(udfMakeTemp pathTemp2 suffix=.${s}3 keep=true type=dir)
#    ls -1ld /tmp/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                       #? true
#    a=$(ls -1ld /tmp/*.${s}3)
#    echo $(udfAddPath2Clean $a )
#    ls -1ld /tmp/*.${s}3 2>/dev/null >| grep ".*\.${s}3"                       #? false
#  SOURCE
udfAddPath2Clean() { udfAddFO2Clean $@; }
#******
#****f* libstd/udfAddJob2Clean
#  SYNOPSIS
#    udfAddJob2Clean args
#  NOTES
#    deprecated
#  DESCRIPTION
#    функция удалена, осталась только заглушка
#  SOURCE
udfAddJob2Clean() { return 0; }
#******
#****f* libstd/udfAddPid2Clean
#  SYNOPSIS
#    udfAddPid2Clean args
#  DESCRIPTION
#    Добавляет идентификаторы запущенных процессов к списку очистки при
#    завершении текущего процесса.
#  INPUTS
#    args - идентификаторы процессов
#  EXAMPLE
#    sleep 99 &
#    udfAddPid2Clean $!
#    test "${_bashlyk_apidClean[$BASHPID]}" -eq "$!"                                    #? true
#    ps -p $! -o pid= >| grep -w $!                                                     #? true
#    echo $(udfAddPid2Clean $!; echo "$BASHPID : $! : ${_bashlyk_apidClean[$BASHPID]}")
#    ps -p $! -o pid= >| grep -w $!                                                     #? false
#
#  SOURCE
udfAddPid2Clean() {
 [[ -n "$1" ]] || return 0
 _bashlyk_apidClean[$BASHPID]+=" $*"
 trap "udfOnTrap" 1 2 5 9 15 EXIT
}
#******
#****f* libstd/udfCleanQueue
#  SYNOPSIS
#    udfCleanQueue args
#  DESCRIPTION
#    Псевдоним для udfAddFile2Clean. (Устаревшее)
#  INPUTS
#    args - имена файлов
#  SOURCE
udfCleanQueue()    { udfAddFile2Clean $@; }
udfAddFObj2Clean() { udfAddFO2Clean   $@; }
#******
#****f* libstd/udfAddFO2Clean
#  SYNOPSIS
#    udfAddFO2Clean <args>
#  DESCRIPTION
#    add list of filesystem objects for cleaning on exit
#  INPUTS
#    args - files or directories for cleaning on exit
#  SOURCE
udfAddFO2Clean() {

	udfOn MissingArgument return $*

	_bashlyk_afoClean[$BASHPID]+=" $*"

	 trap "udfOnTrap" 1 2 5 9 15 EXIT

}
#******
#****f* libstd/udfAddFD2Clean
#  SYNOPSIS
#    udfAddFD2Clean <args>
#  DESCRIPTION
#    add list of filedescriptors for cleaning on exit
#  ARGUMENTS
#    <args> - file descriptors
#  SOURCE
udfAddFD2Clean() {

	udfOn MissingArgument return $*

	_bashlyk_afdClean[$BASHPID]+=" $*"

	 trap "udfOnTrap" 1 2 5 9 15 EXIT

}
#******
#****f* libstd/udfOnTrap
#  SYNOPSIS
#    udfOnTrap
#  DESCRIPTION
#    The cleaning procedure at the end of the calling script.
#    Suitable for trap command call.
#    Produced deletion of files and empty directories; stop child processes,
#    closure of open file descriptors listed in the corresponding global
#    variables. All processes must be related and descended from the working
#    script process. Closes the socket script log if it was used.
#  EXAMPLE
#    local fd fn1 fn2 path pid pipe
#    udfMakeTemp fn1
#    udfMakeTemp fn2
#    udfMakeTemp path type=dir
#    udfMakeTemp pipe type=pipe
#    fd=$( udfGetFreeFD )
#    eval "exec ${fd}>$fn2"
#    (sleep 1024)&
#    pid=$!
#    test -f $fn1
#    test -d $path
#    ps -p $pid -o pid= >| grep -w $pid
#    ls /proc/$$/fd >| grep -w $fd
#    udfAddFD2Clean $fd
#    udfAddPid2Clean $pid
#    udfAddFile2Clean $fn1
#    udfAddPath2Clean $path
#    udfAddFile2Clean $pipe
#    udfOnTrap
#    test -f $fn1                                                               #? false
#    test -d $path                                                              #? false
#    ps -p $pid -o pid= >| grep -w $pid                                         #? false
#    ls /proc/$$/fd >| grep -w $fd                                              #? false
#  SOURCE
udfOnTrap() {

	local i IFS=$' \t\n' re s
	local -a a

	a=( ${_bashlyk_apidClean[$BASHPID]} )

	for (( i=${#a[@]}-1; i>=0 ; i-- )) ; do

		re="\\b${a[i]}\\b"

		for s in 15 9; do

			if [[  "$(pgrep -d' ' -P $$)" =~ $re ]]; then

				if ! kill -${s} ${a[i]}; then

					udfSetLastError NotPermitted "${a[i]}"
					sleep 0.1

				fi

			fi

		done

	done

	for s in ${_bashlyk_afdClean[$BASHPID]}; do

		udfIsNumber $s && eval "exec ${s}>&-"

	done

	for s in ${_bashlyk_afoClean[$BASHPID]}; do

		[[ -f $s ]] && rm -f $s && continue
		[[ -p $s ]] && rm -f $s && continue
		[[ -d $s ]] && rmdir --ignore-fail-on-non-empty $s 2>/dev/null && continue

	done

	if [[ -n "${_bashlyk_pidLogSock}" ]]; then

		exec >/dev/null 2>&1
		wait ${_bashlyk_pidLogSock}

	fi

}
#******
#****f* libstd/_ARGUMENTS
#  SYNOPSIS
#    _ARGUMENTS [args]
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_sArg -
#    командная строка сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  INPUTS
#    args - новая командная строка
#  OUTPUT
#    Вывод значения переменной $_bashlyk_sArg
#  EXAMPLE
#    local ARGUMENTS=$(_ARGUMENTS)
#    _ARGUMENTS >| grep "^${_bashlyk_sArg}$"                                    #? true
#    _ARGUMENTS "test"
#    _ARGUMENTS >| grep -w "^test$"                                             #? true
#    _ARGUMENTS $ARGUMENTS
#  SOURCE
_ARGUMENTS() {
 [[ -n "$1" ]] && _bashlyk_sArg="$*" || echo ${_bashlyk_sArg}
}
#******
#****f* libstd/_s0
#  SYNOPSIS
#    _s0
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_s0 -
#    короткое имя сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  OUTPUT
#    Вывод значения переменной $_bashlyk_s0
#  EXAMPLE
#    local s0=$(_s0)
#    _s0 >| grep -w "^${_bashlyk_s0}$"                                          #? true
#    _s0 "test"
#    _s0 >| grep -w "^test$"                                                    #? true
#    _s0 $s0
#  SOURCE
_s0() {
 [[ -n "$1" ]] && _bashlyk_s0="$*" || echo ${_bashlyk_s0}
}
#******
#****f* libstd/_pathDat
#  SYNOPSIS
#    _pathDat
#  DESCRIPTION
#    Получить или установить значение переменной $_bashlyk_pathDat -
#    полное имя каталога данных сценария
#    устаревшая функция, заменяется _, _get{e,v}, _set
#  OUTPUT
#    Вывод значения переменной $_bashlyk_pathDat
#  EXAMPLE
#    local pathDat=$(_pathDat)
#    _pathDat >| grep -w "^${_bashlyk_pathDat}$"                                #? true
#    _pathDat "/tmp/testdat.$$"
#    _pathDat >| grep -w "^/tmp/testdat.${$}$"                                  #? true
#    rmdir $(_pathDat)                                                          #? true
#    _pathDat $pathDat
#  SOURCE
_pathDat() {
 if [[ -n "$1" ]]; then
  _bashlyk_pathDat="$*"
  mkdir -p $_bashlyk_pathDat
 else
  echo ${_bashlyk_pathDat}
 fi
}
#******
#****f* libstd/udfPrepareByType
#  SYNOPSIS
#    udfPrepareByType <arg>
#  DESCRIPTION
#    present argument 'Array[item]' as '{Array[item]}'
#  INPUTS
#    <arg> - valid name of variable or valid name item of array
#  OUTPUT
#    converted input string, if necessary
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNonValidVariable       - не валидный идентификатор
#    0                            - успешная операция
#  EXAMPLE
#    _bashlyk_onError=return
#    udfPrepareByType                                                           #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfPrepareByType 12a                                                       #? $_bashlyk_iErrorNonValidVariable
#    udfPrepareByType 12a[te]                                                   #? $_bashlyk_iErrorNonValidVariable
## TODO - do not worked    udfPrepareByType a12[]                               #? $_bashlyk_iErrorNonValidVariable
#    udfPrepareByType _a >| grep '^_a$'                                         #? true
#    udfPrepareByType _a[1234] >| grep '^\{_a\[1234\]\}$'                       #? true
#  SOURCE
udfPrepareByType() {

	[[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)

	[[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*(\[.*\])?$ ]] || eval $( udfOnError return iErrorNonValidVariable '$1' )

	[[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*\[.*\]$ ]] && echo "{$1}" || echo "$1"

}
#******
#****f* libstd/_
#  SYNOPSIS
#    _ [[<get>]=]<subname> [<value>]
#  DESCRIPTION
#    Получить или установить (get/set) значение глобальной переменной
#    $_bashlyk_<subname>
#  INPUTS
#    <get>     - переменная для приема значения (get) ${_bashlyk_<subname>},
#                может быть опущена (знак "=" не опускается), в этом случае
#                предполагается, что она имеет имя <subname>
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#    <value>   - новое значение (set) для ${_bashlyk_<subname>}. Имеет приоритет
#                перед режимом "get"
#    Важно! Если используется переменная в качестве <value>, то она обязательно
#    должна быть в двойных кавычках, иначе в случае принятия пустого значения
#    смысл операции поменяется с "set" на "get" c выводом значения на STDOUT
#  OUTPUT
#    Вывод значения переменной $_bashlyk_<subname> в режиме get, если не указана
#    приемная переменная и нет знака "="
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNonValidVariable       - не валидный идентификатор
#    0                            - успешная операция
#  EXAMPLE
#    local sS sWSpaceAlias pid=$BASHPID k=key1 v=val1
#    _ k=sWSpaceAlias
#    echo "$k" >| grep "^${_bashlyk_sWSpaceAlias}$"                             #? true
#    _ sS=sWSpaceAlias
#    echo "$sS" >| grep "^${_bashlyk_sWSpaceAlias}$"                            #? true
#    _ =sWSpaceAlias
#    echo "$sWSpaceAlias" >| grep "^${_bashlyk_sWSpaceAlias}$"                  #? true
#    _ sWSpaceAlias >| grep "^${_bashlyk_sWSpaceAlias}$"                        #? true
#    _ sWSpaceAlias _-_
#    _ sWSpaceAlias >| grep "^_-_$"                                             #? true
#    _ sWSpaceAlias ""
#    _ sWSpaceAlias >| grep "^$"                                                #? true
#    _ sWSpaceAlias "two words"
#    _ sWSpaceAlias >| grep "^two words$"                                       #? true
#    _ sWSpaceAlias "$sWSpaceAlias"
#    _ sWSpaceAlias
#    _ sLastError[$pid] "_ sLastError settings test"                            #? true
#    _ sLastError[$pid] >| grep "^_ sLastError settings test$"                  #? true
#  SOURCE
_(){

	udfOn MissingArgument $1 || return $?

	if (( $# > 1 )); then

		## TODO check for valid required
		eval "_bashlyk_${1##*=}=\"$2\""

	else

		case "$1" in

		*=*)

			if [[ -n "${1%=*}" ]]; then

				udfOn InvalidVariable ${1%=*} || return $?
				eval "export ${1%=*}=\$$( udfPrepareByType "_bashlyk_${1##*=}" )"

			else

				udfOn InvalidVariable $( udfPrepareByType "${1##*=}" ) || return $?
				eval "export $( udfPrepareByType "${1##*=}" )=\$$( udfPrepareByType "_bashlyk_${1##*=}" )"

			fi

        ;;

		*)
			eval "echo \$$( udfPrepareByType "_bashlyk_${1}" )"
		;;
  esac
 fi
 return 0
}
#******
#****f* libstd/_getv
#  SYNOPSIS
#    _getv <subname> [<get>]
#  DESCRIPTION
#    Получить (get) значение глобальной переменной $_bashlyk_<subname> в
#    (локальную) переменную
#  INPUTS
#    <get>     - переменная для приема значения (get) ${_bashlyk_<subname>},
#                может быть опущена, в этом случае приемником становится
#                переменная <subname>
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNonValidVariable       - не валидный идентификатор
#    0                            - успешная операция
#  EXAMPLE
#    local sS sWSpaceAlias
#    _getv sWSpaceAlias sS
#    echo "$sS" >| grep "^${_bashlyk_sWSpaceAlias}$"                            #? true
#    _getv sWSpaceAlias
#    echo "$sWSpaceAlias" >| grep "^${_bashlyk_sWSpaceAlias}$"                  #? true
#  SOURCE
_getv() {
 local IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 if [[ -n "$2" ]]; then
  udfIsValidVariable $2 || return $?
  eval "export $2="'$_bashlyk_'"${1}"
 else
  udfIsValidVariable "$1" || return $?
  eval "export $1="'$_bashlyk_'"${1}"
 fi
 return 0
}
#******
#****f* libstd/_gete
#  SYNOPSIS
#    _gete <subname>
#  DESCRIPTION
#    Вывести значение глобальной переменной $_bashlyk_<subname>
#  INPUTS
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    _gete sWSpaceAlias >| grep "^${_bashlyk_sWSpaceAlias}$"                    #? true
#  SOURCE
_gete() {
 local IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 eval "echo "'$_bashlyk_'"${1}"
}
#******
#****f* libstd/_set
#  SYNOPSIS
#    _set <subname> [<value>]
#  DESCRIPTION
#    установить (set) значение глобальной переменной $_bashlyk_<subname>
#  INPUTS
#    <subname> - содержательная часть глобальной имени ${_bashlyk_<subname>}
#    <value>   - новое значение, в случае отсутствия - пустая строка
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    local sWSpaceAlias=$(_ sWSpaceAlias)
#    _set sWSpaceAlias _-_
#    _ sWSpaceAlias >| grep "^_-_$"                                             #? true
#    _set sWSpaceAlias $sWSpaceAlias
#  SOURCE
_set() {
 local IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 eval "_bashlyk_$1=$2"
}
#******
#****f* libstd/udfCheckCsv
#  SYNOPSIS
#    udfCheckCsv [[-v] <varname>] "<csv>;"
#  DESCRIPTION
#    Bringing the format "key = value" fields of the CSV-line. If the field does
#    not contain a key or key contains a space, then the field receives key
#    species _bashlyk_unnamed_key_<increment>, and all the contents of the field
#    becomes the value. The result is printed to stdout or assigned to the <var>
#    variable if the first argument is listed as -v <var> ( -v can be skipped )
#  INPUTS
#    csv;    - CSV-string, separated by ';'
#    Important! Enclose the string in double quotes if it can contain spaces
#    Important! The string must contain the field sign ";"
#    varname - variable identifier (without the "$"). If present the result will
#    be assigned to this variable, otherwise result will be printed to stdout
#  OUTPUT
#    separated by a ";" CSV-string in fields that contain data in the format
#    "<key> = <value>; ..."
#  RETURN VALUE
#    EmptyResult     - empty result
#    MissingArgument - no arguments
#    InvalidArgument - invalid argument
#    InvalidVariable - invalid variable for output assign
#    0               - success
#  EXAMPLE
#    local cmd=udfCheckCsv csv="a=b;a=c;s=a b c d e f;test value" v1 v2
#    local re='^a=b;a=c;s="a b c d e f";_bashlyk_unnamed_key_0="test value";$'
#    $cmd "$csv" >| grep "$re"                                                  #? true
#    $cmd -v v1 "$csv"                                                          #? true
#    echo $v1 >| grep "$re"                                                     #? true
#    $cmd  v2 "$csv"                                                            #? true
#    echo $v2 >| grep "$re"                                                     #? true
#    $cmd  v2 ""                                                                #? ${_bashlyk_iErrorEmptyResult}
#    echo $v2 >| grep "$re"                                                     #? false
#    $cmd -v invalid+variable "$csv"                                            #? ${_bashlyk_iErrorInvalidVariable}
#    $cmd    invalid+variable "$csv"                                            #? ${_bashlyk_iErrorInvalidVariable}
#    $cmd invalid+variable                                                      #? ${_bashlyk_iErrorInvalidArgument}
#    $cmd _valid_variable_                                                      #? ${_bashlyk_iErrorInvalidArgument}
#    $cmd 'csv data;' | grep '^_bashlyk_unnamed_key_0="csv data";$'             #? true
#    $cmd                                                                       #? ${_bashlyk_iErrorMissingArgument}
#  SOURCE
udfCheckCsv() {

	if (( $# > 1 )); then

		[[ "$1" == "-v" ]] && shift

		udfIsValidVariable $1 || eval $( udfOnError return InvalidVariable "$1" )

		eval 'export $1="$( shift; udfCheckCsv "$1" )"'

		[[ -n ${!1} ]] || eval $( udfOnError return EmptyResult "$1" )

		return 0

	fi

	udfOn MissingArgument $1 || return $?

	[[ $1 =~ \; ]] || return $( _ iErrorInvalidArgument )

	local csv i IFS k s v

	IFS=';'
	i=0
	csv=''

	for s in $1; do

		s=${s/\[*\][;]/}
		s=${s//[\'\"]/}

		k="$(echo ${s%%=*}|xargs)"
		v="$(echo ${s#*=}|xargs)"

		[[ -n "$k" ]] || continue
		if [[ "$k" == "$v" || -n "$(echo "$k" | grep '.*[[:space:]+].*')" ]]; then

			k=${_bashlyk_sUnnamedKeyword}${i}
			i=$((i+1))

		fi

		IFS=' ' csv+="$k=$(udfQuoteIfNeeded $v);"

	done

	IFS=$' \t\n'

	echo "$csv"

	[[ -n $csv ]] && return 0 || return $( _ iErrorEmptyResult )

}
#******
#****f* libstd/udfGetMd5
#  SYNOPSIS
#    udfGetMd5 [-]|--file <filename>|<args>
#  DESCRIPTION
#   Получить дайджест MD5 указанных данных
#  INPUTS
#    "-"  - использовать поток данных "input"
#    --file <filename> - использовать в качестве данных указанный файл
#    <args> - использовать строку аргументов
#  OUTPUT
#    Дайджест MD5
#  EXAMPLE
#    udfGetMd5 "test" >| grep -w 'd8e8fca2dc0f896fd7cb4cb0031ba249'             #? true
#  SOURCE
udfGetMd5() {
 {
  case "$1" in
       "-")
          cat | md5sum
         ;;
  "--file")
          [[ -f "$2" ]] && md5sum "$2"
         ;;
         *)
          [[ -n "$1" ]] && echo "$*" | md5sum
         ;;
  esac
 } | cut -f 1 -d ' '
 return 0
}
#******
#****f* libstd/udfGetPathMd5
#  SYNOPSIS
#    udfGetPathMd5 <path>
#  DESCRIPTION
#   Получить дайджест MD5 всех нескрытых файлов в каталоге <path>
#  INPUTS
#    <path>  - начальный каталог
#  OUTPUT
#    Список MD5-сумм и имён нескрытых файлов в каталоге <path> рекурсивно
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNoSuchFileOrDir        - путь не доступен
#    iErrorNotPermitted           - нет прав
#    0                            - успешная операция
#  EXAMPLE
#    local path=$(udfMakeTemp type=dir)
#    touch ${path}/testfile
#    udfAddFile2Clean ${path}/testfile
#    udfAddPath2Clean ${path}
#    udfGetPathMd5 $path >| grep '^d41.*27e.*testfile'                   #? true
#    udfGetPathMd5                                                       #? ${_bashlyk_iErrorNoSuchFileOrDir}
#    ## TODO udfGetPathMd5 /root                                          #? ${_bashlyk_iErrorNotPermitted}
#  SOURCE
udfGetPathMd5() {
 local pathSrc="$(pwd)" pathDst s IFS=$' \t\n'
 [[ -n "$1" && -d "$1" ]] || eval $(udfOnError return iErrorNoSuchFileOrDir)
 cd "$1" 2>/dev/null || eval $(udfOnError return iErrorNotPermitted '$1')
 pathDst="$(pwd)"
 for s in *; do
  [[ -d "$s" ]] && udfGetPathMd5 $s
 done
 md5sum $pathDst/* 2>/dev/null
 cd $pathSrc
 return 0
}
#******
#****f* libstd/udfXml
#  SYNOPSIS
#    udfXml tag [property] data
#  DESCRIPTION
#    Generate XML code to stdout
#  INPUTS
#    tag      - XML tag name (without <>)
#    property - XML tag property
#    data     - XML tag content
#  OUTPUT
#    Show compiled XML code
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    local sTag='date TO="+0400" TZ="MSK"' sContent='Mon, 22 Apr 2013 15:55:50'
#    local sXml='<date TO="+0400" TZ="MSK">Mon, 22 Apr 2013 15:55:50</date>'
#    udfXml "$sTag" "$sContent" >| grep "^${sXml}$"                             #? true
#  SOURCE
udfXml() {
 local IFS=$' \t\n' s
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 s=($1)
 shift
 echo "<${s[*]}>${*}</${s[0]}>"
}
#******
#****f* libstd/udfSerialize
#  SYNOPSIS
#    udfSerialize variables
#  DESCRIPTION
#    Generate csv string from variable list
#  INPUTS
#    variables - list of variables
#  OUTPUT
#    Show csv string
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    local sUname="$(uname -a)" sDate="" s=100
#    udfSerialize sUname sDate s >| grep "^sUname=.*s=100;$"                                                                 #? true
#  SOURCE
udfSerialize() {
 local bashlyk_s_Serialize csv IFS=$' \t\n'
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 for bashlyk_s_Serialize in $*; do
  udfIsValidVariable "$bashlyk_s_Serialize" \
   && csv+="${bashlyk_s_Serialize}=${!bashlyk_s_Serialize};" \
   || udfSetLastError iErrorNonValidVariable "$bashlyk_s_Serialize"
 done
 echo "$csv"
}
#******
#****f* libstd/udfBashlykUnquote
#  SYNOPSIS
#    udfBashlykUnquote
#  DESCRIPTION
#    Преобразование метапоследовательностей _bashlyk_&#XX_ из потока со стандартного входа в символы '"[]()=;\'
#  EXAMPLE
#    local s="_bashlyk_&#34__bashlyk_&#91__bashlyk_&#93__bashlyk_&#59__bashlyk_&#40__bashlyk_&#41__bashlyk_&#61_"
#    echo $s | udfBashlykUnquote >| grep -e '\"\[\];()='                                                          #? true
#  SOURCE
udfBashlykUnquote() {
 local a cmd="sed" i IFS=$' \t\n'
 declare -A a=( [34]='\"' [40]='\(' [41]='\)' [59]='\;' [61]='\=' [91]='\[' [92]='\\\' [93]='\]' )
 for i in "${!a[@]}"; do
  cmd+=" -e \"s/_bashlyk_\&#${i}_/${a[$i]}/g\""
 done
 ## TODO продумать команды для удаления "_bashlyk_csv_record=" и автоматических ключей
 #cmd+=" -e \"s/\t\?_bashlyk_ini_.*_autoKey_[0-9]\+\t\?=\t\?//g\""
 cmd+=' -e "s/^\"\(.*\)\"$/\1/"'
 eval "$cmd"
}
#******
#****f* libstd/udfLocalVarFromCSV
#  SYNOPSIS
#    udfLocalVarFromCSV CSV1 CSV2 ...
#  DESCRIPTION
#    Prepare string from comma separated lists (ex. INI options) for definition
#    of the local variables by using eval
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    0                            - успешная операция
#  EXAMPLE
#    udfLocalVarFromCSV a1,b2,c3                                                #? true
#    udfLocalVarFromCSV a1 b2,c3                                                #? true
#    udfLocalVarFromCSV a1,b2 c3                                                #? true
#    echo $( udfLocalVarFromCSV a1,b2 c3,4d 2>/dev/null ) >| grep '^local'      #? false
#  SOURCE
udfLocalVarFromCSV() {

	udfOn EmptyOrMissingArgument throw "$@"

	local s
	local -A h

	for s in ${*//[;,]/ }; do

		udfIsValidVariable $s || eval $( udfOnError2 throw iErrorNonValidVariable "$s" )
		h[$s]="$s"

	done

	udfOn EmptyResult throw "${h[@]}"
	echo "local ${h[@]}"

}
#******
#****f* libstd/udfGetTimeInSec
#  SYNOPSIS
#    udfGetTimeInSec [-v <var>] <number>[sec|min|hour|...]
#  DESCRIPTION
#    get a time value in the seconds from a string in the human-readable format
#  OPTIONS
#    -v <var>                    - set the result to valid variable <var>
#  ARGUMENTS
#    <numbers>[sec,min,hour,...] - human-readable string of date&time
#  RETURN VALUE
#    InvalidArgument              - invalid or missing arguments, number with
#                                   a time suffix expected
#    EmptyResult                  - no result
#    0                            - success
#  EXAMPLE
#    local v s=${RANDOM:0:2} #-
#    udfGetTimeInSec                                                            #? $_bashlyk_iErrorInvalidArgument
#    udfGetTimeInSec SeventenFourSec                                            #? $_bashlyk_iErrorInvalidArgument
#    udfGetTimeInSec 59seconds >| grep -w 59                                    #? true
#    udfGetTimeInSec -v v ${s}minutes                                           #? true
#    echo $v >| grep -w $(( s * 60 ))                                           #? true
#    udfGetTimeInSec -v 123s                                                    #? $_bashlyk_iErrorInvalidVariable
#    udfGetTimeInSec -v -v                                                      #? $_bashlyk_iErrorInvalidVariable
#    udfGetTimeInSec -v v -v v                                                  #? $_bashlyk_iErrorInvalidArgument
#    udfGetTimeInSec $RANDOM                                                    #? true
#  SOURCE
udfGetTimeInSec() {

	if [[ "$1" == "-v" ]]; then

		udfIsValidVariable "$2" || eval $( udfOnError InvalidVariable "$2" )

		[[ "$3" == "-v" ]] && eval $( udfOnError InvalidArgument "$3 - number with time suffix expected" )

		eval 'export $2="$( udfGetTimeInSec $3 )"'

		[[ -n ${!2} ]] || eval 'export $2="$( udfGetTimeInSec $4 )"'
		[[ -n ${!2} ]] || eval $( udfOnError EmptyResult "$2" )

		return $?

	fi

	local i=${1%%[[:alpha:]]*}

	udfIsNumber $i || eval $( udfOnError InvalidArgument "$i - number expected" )

	case ${1##*[[:digit:]]} in

		seconds|second|sec|s|'') echo $i;;
		   minutes|minute|min|m) echo $(( i*60 ));;
		        hours|hour|hr|h) echo $(( i*3600 ));;
		             days|day|d) echo $(( i*3600*24 ));;
		           weeks|week|w) echo $(( i*3600*24*7 ));;
		       months|month|mon) echo $(( i*3600*24*30 ));;
		           years|year|y) echo $(( i*3600*24*365 ));;
	                              *) echo ""
                                       eval $( udfOnError InvalidArgument "$1 - number with time suffix expected" )

	esac

    return $?

}
#******
#****f* libpid/udfGetFreeFD
#  SYNOPSIS
#    udfGetFreeFD
#  DESCRIPTION
#    get unused filedescriptor
#  OUTPUT
#    show given filedescriptor
#  EXAMPLE
#    udfGetFreeFD | grep -P "^\d+$"                                             #? true
#  SOURCE
udfGetFreeFD() {

	local i=0 iMax=$(ulimit -n)
	#
	: ${iMax:=255}
	#
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
