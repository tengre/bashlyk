#
# $Id$
#
#****h* bashlyk/libcnf
#  DESCRIPTION
#    bashlyk CNF library
#    Чтение/запись файлов конфигураций
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/libcnf/Required Once
#  DESCRIPTION
#    Глобальная переменная $_BASHLYK_LIBCNF обеспечивает
#    защиту от повторного использования данного модуля.
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$_BASHLYK_LIBCNF" ] && return 0 || _BASHLYK_LIBCNF=1
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
#******
#****** bashlyk/libcnf/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/libstd.sh" ] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****v*  bashlyk/libcnf/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathCnf:=$(pwd)}
: ${_bashlyk_sUnnamedKeyword:=_bashlyk_unnamed_key_}
: ${_bashlyk_aRequiredCmd_cnf:="[ awk date dirname echo mkdir printf pwd"}
: ${_bashlyk_aExport_cnf:="udfGetConfig udfSetConfig"}
#******
#****f* bashlyk/libcnf/udfGetConfig
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
#     0  - Выполнено успешно
#     1  - Ошибка: файл конфигурации не найден
#    255 - Ошибка: аргумент отсутствует
#  EXAMPLE
#    local b conf d pid s0 s                                                    
#    # TODO тестовые блоки обертывать в отдельные функции
#    # TODO "историческая" проверка в текущем каталоге временно убрана (.)
#    conf=$(mktemp --suffix=.conf || tempfile -d /tmp -s .test.conf)    ## ? true
#    udfSetConfig $conf "s0=$0;b=true;pid=$$;s=$(uname -a);$(date -R -r $0)"    ## ? true
#    udfGetConfig $conf                                                         ## ? true
#    test "$s0" = $0 -a "$b" = true -a "$pid" = $$ -a "$s" = "$(uname -a)"      ## ? true
#    rm -f $conf                                                                
#    b='' conf='' d='' pid='' s0='' sS=''                                       
#    conf=$(mktemp --suffix=.conf || tempfile -s .test.conf)                    ## ? true
#    udfSetConfig $conf "s0=$0;b=true;pid=$$;s=$(uname -a);$(date -R -r $0)"    ## ? true
#    udfGetConfig $conf                                                         ## ? true
#    test "$s0" = $0 -a "$b" = true -a "$pid" = $$ -a "$s" = "$(uname -a)"      ## ? true
#    cat $conf                                                                  
#    rm -f $conf                                                                
#  SOURCE
udfGetConfig() {
 [ -n "$1" ] || return 255
 #
 local bashlyk_aconf_MROATHra bashlyk_conf_MROATHra bashlyk_s_MROATHra
 local bashlyk_pathCnf_MROATHra="$_bashlyk_pathCnf"
 #
 [ "$1"  = "${1##*/}" -a -f ${bashlyk_pathCnf_MROATHra}/$1 ] || bashlyk_pathCnf_MROATHra=
 [ "$1"  = "${1##*/}" -a -f $1 ] && bashlyk_pathCnf_MROATHra=$(pwd)
 [ "$1" != "${1##*/}" -a -f $1 ] && bashlyk_pathCnf_MROATHra=$(dirname $1)
 #
 if [ -z "$bashlyk_pathCnf_MROATHra" ]; then
  [ -f "/etc/${_bashlyk_pathPrefix}/$1" ] \
   && bashlyk_pathCnf_MROATHra="/etc/${_bashlyk_pathPrefix}" || return 1
 fi
 #
 bashlyk_conf_MROATHra=
 bashlyk_aconf_MROATHra=$(echo "${1##*/}" | awk 'BEGIN{FS="."} {for (i=NF;i>=1;i--) printf $i" "}')
 for bashlyk_s_MROATHra in $bashlyk_aconf_MROATHra; do
  [ -n "$bashlyk_s_MROATHra" ] || continue
  [ -n "$bashlyk_conf_MROATHra" ] \
   && bashlyk_conf_MROATHra="${bashlyk_s_MROATHra}.${bashlyk_conf_MROATHra}" \
   || bashlyk_conf_MROATHra="$bashlyk_s_MROATHra"
  [ -s "${bashlyk_pathCnf_MROATHra}/${bashlyk_conf_MROATHra}" ] \
   && . "${bashlyk_pathCnf_MROATHra}/${bashlyk_conf_MROATHra}"
 done
 return 0
}
#******
#****f* bashlyk/libcnf/udfSetConfig
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
#    255 - Ошибка: аргументы отсутствует
#    254 - Ошибка: нет каталога для файла конфигурации и его невозможно создать
#     0  - Выполнено успешно
#  EXAMPLE
#    local b conf d pid s0 s                                                    
#    conf=$(mktemp --suffix=.conf || tempfile -s .test.conf)                    ## ? true
#    udfSetConfig $conf "s0=$0;b=true;pid=$$;s=$(uname -a);$(date -R -r $0)"    ## ? true
#    grep "^s0=$0$" $conf                                                       ## ? true
#    grep "^b=true$" $conf                                                      ## ? true
#    grep "^pid=${$}$" $conf                                                    ## ? true
#    grep "^s=\"$(uname -a)\"$" $conf                                           ## ? true
#    grep "^$(_ sUnnamedKeyword).*=\"$(date -R -r $0)\"$" $conf                 ## ? true
#    test -s $conf && . $conf                                                   ## ? true
#    test "$s0" = $0 -a "$b" = true -a "$pid" = $$ -a "$s" = "$(uname -a)"      ## ? true
#    rm -f $conf                                                                
#  SOURCE
udfSetConfig() {
 [ -n "$1" -a -n "$2" ] || return 255
 #
 local bashlyk_conf_kpHeLmpy bashlyk_chIFS_kpHeLmpy="$IFS"
 local bashlyk_pathCnf_kpHeLmpy="$_bashlyk_pathCnf" bashlyk_sPair_kpHeLmpy
 #
 [ "$1" != "${1##*/}" ] && bashlyk_pathCnf_kpHeLmpy="$(dirname $1)"
 mkdir -p "$bashlyk_pathCnf_kpHeLmpy" || return 254
 bashlyk_conf_kpHeLmpy="${bashlyk_pathCnf_kpHeLmpy}/${1##*/}"
 IFS=';'
 {
  echo "# Created $(date -R) by $USER via $0 (pid $$)"
  for bashlyk_sPair_kpHeLmpy in $(udfCheckCsv "$2"); do
   [ -n "${bashlyk_sPair_kpHeLmpy}" ] && echo "${bashlyk_sPair_kpHeLmpy}"
  done
 } >> $bashlyk_conf_kpHeLmpy 2>/dev/null
 IFS="$bashlyk_chIFS_kpHeLmpy"
 return 0
}
#******

