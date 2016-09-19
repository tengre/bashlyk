#
# $Id: libtst.sh 552 2016-09-19 21:35:49+04:00 toor $
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
#    udfMakeTemp [varname] options...
#  DESCRIPTION
#    Создание временного файла или каталога
#  INPUTS
#    varname=[<varid>] - идентификатор переменной для возврата результата, если
#                        аргумент не именной, то должен быть всегда первый
#    path=<path>       - каталог, в котором будут создаваться временные объекты
#    prefix=<prefix>   - префикс имени временного объекта
#    suffix=<suffix>   - суффикс имени временного объекта
#    mode=<mode>       - права на временный объект
#    owner=<owner>     - владелец временного объекта
#    group=<group>     - группа временного объекта
#    type=file|dir     - тип объекта: файл (по умолчанию) или каталог
#    keep=true|false   - удалять/не удалять временные объекты после завершения
#                        сценария. По умолчанию, удаляется, если имя временного
#                        объекта передается аргументу-переменной, если оно
#                        выдается на stdout, то не удаляется
#  OUTPUT
#    вывод происходит если нет аргументов или отсутствует именной аргумент
#    varname, если временный объект не создан, то ничего не выдается
#
#  RETURN VALUE
#    0                        - выполнено успешно
#    iErrorNotExistNotCreated - временный объект файловой системы не создан
#    iErrorNonValidVariable   - аргумент <varname> не является валидным
#                               идентификатором переменной
#
#  EXAMPLE
#    local foTemp
#    udfMakeTemp -v foTemp path=$HOME prefix=pre. suffix=.suf
#    ls $foTemp >| grep -w "$HOME/pre\.........\.suf"                           #? true
#    udfMakeTemp -v foTemp type=dir mode=0751
#    ls -ld $foTemp >| grep "^drwxr-x--x.*${foTemp}$"                           #? true
#    foTemp=$(udfMakeTemp prefix=pre. suffix=.suf)
#    ls $foTemp >| grep "pre\.........\.suf$"                                   #? true
#    rm -f $foTemp
#    $(udfMakeTemp -v foTemp prefix=pre. suffix=.suf)
#    test -f $foTemp                                                            #? false
#    unset foTemp
#    foTemp=$(udfMakeTemp)                                                      #? true
#    test -f $foTemp                                                            #? true
#    rm -f $foTemp
#    udfMakeTemp 2t                                                             #? ${_bashlyk_iErrorNonValidVariable}
#    udfMakeTemp path=/proc                                                     #? ${_bashlyk_iErrorNotExistNotCreated}
#  SOURCE
udfMakeTemp() {

	if [[ "$1" == "-v" ]]; then

		shift

		udfIsValidVariable "$1" || eval $( udfOnError2 InvalidArgument "$2" )

		eval 'export $1="$( udfMakeTemp $* )"'

		[[ -n ${!1} ]] || eval $( udfOnError2 iErrorEmptyResult "$2" )

		if [[ $* =~ keep=false ]]; then

			case $* in

				*type=d*) udfAddPath2Clean ${!1};;
				*type=f*) udfAddFile2Clean ${!1};;
				*type=p*) udfAddFile2Clean ${!1};;

			esac

		fi

		return $?

	fi

	local foResult optDir s bPipe sVar sGroup sCreateMode path sUser sPrefix sSuffix rc octMode IFS=$' \t\n'
 #
 sCreateMode=direct
 #
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
    keep=t*) bNoKeep=false;;
    keep=f*) bNoKeep=true;;
  varname=*) sVar=${s#*=};;
          *)
            sVar="$1"
            udfIsNumber "$2"
            rc=$?
            if [[ -z "$3" && -n "$2" && $rc -eq 0 ]]; then
             # oldstyle
             octMode="$2"
             sVar=''
             sPrefix="$1"
            fi
          ;;
  esac
 done

	if   [[ -f "$(which mktemp)" ]]; then

		sCreateMode=mktemp

	elif [[ -f "$(which tempfile)" ]]; then

		[[ -z "$optDir" ]] && sCreateMode=tempfile || sCreateMode=direct

	fi

	case "$sCreateMode" in

	direct)

		if [[ -n "$path" ]]; then

			s="${path}/"

		else

			if [[ -z $bPipe ]]; then

				s="/tmp/"
			else

				mkdir -p $( _ pathRun )
				s=$( _ pathRun )

			fi

		fi

		s+="${sPrefix}${$}${sSuffix}"

		[[ -n "$optDir" ]] && mkdir -p $s || touch $s

	;;

	mktemp)

		if [[ -n "$path" ]]; then

			mkdir -p ${path}
			path="--tmpdir=${path}"

		else

			if [[ -z $bPipe ]]; then

				path="--tmpdir=/tmp"

			else

				mkdir -p $( _ pathRun )
				path="--tmpdir=$( _ pathRun )"

			fi

		fi

		if [[ -n "$sPrefix" ]]; then

			sPrefix=$(echo $sPrefix | tr -d '/')

		fi

		if [[ -n "${sSuffix}" ]]; then

			sSuffix="--suffix=$(echo ${sSuffix} | tr -d '/')"

		fi

		s=$(mktemp $path $optDir ${sSuffix} "${sPrefix}XXXXXXXX")

	;;

	tempfile)

		[[ -n "$sPrefix" ]] && sPrefix="-p $sPrefix"
		[[ -n "$sSuffix" ]] && sSuffix="-s $sSuffix"
		s=$(tempfile $optDir $sPrefix $sSuffix)

	;;

	*)
		## не достижимое состояние
		eval $(udfOnError return iErrorUnexpected $sCreateMode)
	;;

	esac

	if [[ -n $bPipe ]]; then

		rm -f  $s
		mkfifo $s

	fi

	[[ -n "$octMode" ]] && chmod $octMode $s

 ## TODO обработка ошибок
 [[ -n "$sUser"  ]] && chown $sUser  $s
 [[ -n "$sGroup" ]] && chgrp $sGroup $s

 if ! [[ -f "$s" || -p "$s" || -d "$s" ]]; then
  eval $(udfOnError return iErrorNotExistNotCreated $s)
 fi

 echo $s

 return 0
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
#    ...
#  SOURCE
udfTest() {
 return 0
}
#******
