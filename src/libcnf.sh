#
# $Id$
#
#****h* BASHLYK/libcnf
#  DESCRIPTION
#    Чтение/запись файлов активных конфигураций
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libcnf/Required Once
#  DESCRIPTION
#    Глобальная переменная $_BASHLYK_LIBCNF обеспечивает
#    защиту от повторного использования данного модуля.
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
[[ -n "$_BASHLYK_LIBCNF" ]] && return 0 || _BASHLYK_LIBCNF=1
#******
#****** libcnf/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s "${_bashlyk_pathLib}/libstd.sh" ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****v* libcnf/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathCnf:=$(pwd)}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}
: ${_bashlyk_aRequiredCmd_cnf:="[ awk date dirname echo mkdir printf pwd"}
: ${_bashlyk_aExport_cnf:="udfGetConfig udfSetConfig"}
#******
#****f* libcnf/udfGetConfig
#  SYNOPSIS
#    udfGetConfig <file>
#  DESCRIPTION
#    Найти и выполнить <file> и предварительно все другие файлы, от которых он
#    зависит. Такие файлы должны находится в том же каталоге. То есть, если
#    <file> это "a.b.c.conf", то вначале применяются файлы "conf" "c.conf",
#    "b.c.conf" если таковые существуют.
#    Поиск выполняется по следующим критериям:
#     1. Если имя файла -это неполный путь, то
#     в начале проверяется текущий каталог, затем каталог конфигураций по
#     умолчанию
#     2. Если имя файла - полный путь, то каталог в котором он расположен
#     3. Последняя попытка - найти файл в каталоге /etc
#    Важно: имя <file> не должно начинаться с точки и им заканчиваться!
#  INPUTS
#    file     - имя файла конфигурации
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorFileNotFound           - файл конфигурации не найден
#    0                            - успешная операция
#  EXAMPLE
#    local b conf d pid s0 s
#    # TODO "историческая" проверка в текущем каталоге временно убрана (.)
#    conf=$(mktemp --suffix=.conf || tempfile -d /tmp -s .test.conf)            #? true
#    udfSetConfig $conf "s0=$0;b=true;pid=$$;s=$(uname -a);$(date -R -r $0)"    #? true
#    udfGetConfig $conf                                                         #? true
#    test "$s0" = $0 -a "$b" = true -a "$pid" = $$ -a "$s" = "$(uname -a)"      #? true
#    rm -f $conf
#    b='' conf='' d='' pid='' s0='' sS=''
#    conf=$(mktemp --suffix=.conf || tempfile -s .test.conf)                    #? true
#    udfSetConfig $conf "s0=$0;b=true;pid=$$;s=$(uname -a);$(date -R -r $0)"    #? true
#    udfGetConfig $conf                                                         #? true
#    test "$s0" = $0 -a "$b" = true -a "$pid" = $$ -a "$s" = "$(uname -a)"      #? true
#    cat $conf
#    rm -f $conf
#  SOURCE
udfGetConfig() {
 local bashlyk_aconf_MROATHra bashlyk_conf_MROATHra bashlyk_s_MROATHra
 local bashlyk_pathCnf_MROATHra="$_bashlyk_pathCnf" IFS=$' \t\n'
 #
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 [[ "$1" == "${1##*/}" && -f "${bashlyk_pathCnf_MROATHra}/$1" ]] || bashlyk_pathCnf_MROATHra=
 [[ "$1" == "${1##*/}" && -f "$1" ]] && bashlyk_pathCnf_MROATHra=$(pwd)
 [[ "$1" != "${1##*/}" && -f "$1" ]] && bashlyk_pathCnf_MROATHra=$(dirname $1)
 #
 if [[ -z "$bashlyk_pathCnf_MROATHra" ]]; then
  [[ -f "/etc/${_bashlyk_pathPrefix}/$1" ]] \
   && bashlyk_pathCnf_MROATHra="/etc/${_bashlyk_pathPrefix}" \
   || eval $(udfOnError return iErrorFileNotFound)
 fi
 #
 bashlyk_conf_MROATHra=
 bashlyk_aconf_MROATHra=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')
 for bashlyk_s_MROATHra in $bashlyk_aconf_MROATHra; do
  [[ -n "$bashlyk_s_MROATHra" ]] || continue
  [[ -n "$bashlyk_conf_MROATHra" ]] \
   && bashlyk_conf_MROATHra="${bashlyk_s_MROATHra}.${bashlyk_conf_MROATHra}" \
   || bashlyk_conf_MROATHra="$bashlyk_s_MROATHra"
  [[ -s "${bashlyk_pathCnf_MROATHra}/${bashlyk_conf_MROATHra}" ]] \
   && . "${bashlyk_pathCnf_MROATHra}/${bashlyk_conf_MROATHra}"
 done
 return 0
}
#******
#****f* libcnf/udfSetConfig
#  SYNOPSIS
#    udfSetConfig <file> "<csv;>"
#  DESCRIPTION
#    Дополнить <file> строками вида "key=value" из аргумента <csv;>
#    Расположение файла определяется по следующим критериям:
#     Если имя файла -это неполный путь, то он сохраняется в каталоге по
#     умолчанию, иначе по полному пути.
#  INPUTS
#    <file> - имя файла конфигурации
#    <csv;> - CSV-строка, разделённая ";", поля которой содержат данные вида
#             "key=value"
#    Важно! Экранировать аргументы двойными кавычками, если есть вероятность
#    наличия в них пробелов
#  RETURN VALUE
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorNotExistNotCreated     - путь не существует и не создан
#    0                            - успешная операция
#  EXAMPLE
#    local b conf d pid s0 s
#    conf=$(mktemp --suffix=.conf || tempfile -s .test.conf)                    #? true
#    udfSetConfig $conf "s0=$0;b=true;pid=$$;s=$(uname -a);$(date -R -r $0)"    #? true
#    grep "^s0=$0$" $conf                                                       #? true
#    grep "^b=true$" $conf                                                      #? true
#    grep "^pid=${$}$" $conf                                                    #? true
#    grep "^s=\"$(uname -a)\"$" $conf                                           #? true
#    grep "^$(_ sUnnamedKeyword).*=\"$(date -R -r $0)\"$" $conf                 #? true
#    test -s $conf && . $conf                                                   #? true
#    test "$s0" = $0 -a "$b" = true -a "$pid" = $$ -a "$s" = "$(uname -a)"      #? true
#    rm -f $conf
#  SOURCE
udfSetConfig() {
 local conf IFS=$' \t\n' pathCnf="$_bashlyk_pathCnf"
 [[ -n "$1" && -n "$2" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 [[ "$1" != "${1##*/}" ]] && pathCnf="$(dirname $1)"
 mkdir -p "$pathCnf" || eval $(udfOnError return iErrorNotExistNotCreated $pathCnf)
 conf="${pathCnf}/${1##*/}"
 {
  echo "# Created $(date -R) by $USER via $0 (pid $$)"
  udfCheckCsv "$2" | tr ';' '\n'
 } >> $conf 2>/dev/null
 return 0
}
#******
