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
#    защиту от повторного использования данного модуля
#  SOURCE
[ -n "$_BASHLYK_LIBCNF" ] && return 0 || _BASHLYK_LIBCNF=1
#******
#****** bashlyk/libpid/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
[ -s "${_bashlyk_pathLib}/liblog.sh" ] && . "${_bashlyk_pathLib}/liblog.sh"
#******
#****v*  bashlyk/libcnf/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathCnf:=$(pwd)}
: ${_bashlyk_aRequiredCmd_cnf:="basename cat date dirname echo grep pwd rm sleep ["}
#******
#****f* bashlyk/libcnf/udfGetConfig
#  SYNOPSIS
#    udfGetConfig <file>
#  DESCRIPTION
#    Найти и выполнить <file> и предварительно все другие файлы, от которых он зависит.
#    Такие файлы должны находится в том же каталоге. То есть, если <file> это
#    "a.b.c.conf", то вначале применяются файлы "conf" "c.conf", "b.c.conf"
#    если таковые существуют.
#    Поиск выполняется по следующим критериям:
#     1. Если имя файла -это неполный путь, то
#     в начале проверяется текущий каталог, затем каталог конфигураций по умолчанию
#     2. Если имя файла - полный путь, то каталог в кототром он расположен
#     3. Последняя попытка - найти файл в каталоге /etc
#  INPUTS
#    file     - имя файла конфигурации
#  RETURN VALUE
#    -1 - Ошибка: аргумент отсутствует
#     0 - Выполнено успешно
#     1 - Ошибка: файл конфигурации не найден
#  SOURCE
udfGetConfig() {
 [ -n "$1" ] || return -1
 #
 local aconf chIFS conf fn i pathCnf=$_bashlyk_pathCnf
 #
 [ "$1"  = "$(basename $1)" -a -f ${pathCnf}/$1 ] || pathCnf=
 [ "$1"  = "$(basename $1)" -a -f $1 ] && pathCnf=$(pwd)
 [ "$1" != "$(basename $1)" -a -f $1 ] && pathCnf=$(dirname $1)
 #
 if [ -z "$pathCnf" ]; then
  [ -f "/etc${_bashlyk_pathPrefix}/$1" ] \
   && pathCnf="/etc${_bashlyk_pathPrefix}" || return 1
 fi
 #
 chIFS=$IFS
 IFS='.'
 i=0
 for fn in $(basename "$1"); do
  aconf[++i]=$fn
 done
 IFS=$chIFS
 conf=
 for ((i=$((${#aconf[*]})); $i; i--)); do
  [ -n "${aconf[i]}" ] || continue
  [ -n "$conf" ] && conf="${aconf[$i]}.${conf}" || conf=${aconf[i]}
  [ -s "${pathCnf}/${conf}" ] && . "${pathCnf}/${conf}"
 done
 return 0
}
#******
#****f* bashlyk/libcnf/udfSetConfig
#  SYNOPSIS
#    udfSetConfig <file> <csv;>
#  DESCRIPTION
#    Дополнить <file> строками вида "key=value" из аргумента <csv;>
#    Расположение файла определяется по следующим критериям:
#     Если имя файла -это неполный путь, то он сохраняется в каталоге по умолчанию,
#     иначе по полному пути.
#  INPUTS
#    <file> - имя файла конфигурации
#    <csv;> - CSV-строка, разделённая ";", поля которой содержат данные вида "key=value"
#  RETURN VALUE
#    -1 - Ошибка: аргумент отсутствует
#     0 - Выполнено успешно
#     1 - Ошибка: файл конфигурации не найден
#  SOURCE
udfSetConfig() {
 [ -n "$1" -a -n "$2" ] || return -1
 #
 local conf sKeyValue chIFS=$IFS pathCnf=$_bashlyk_pathCnf
 #
 [ "$1" != "$(basename $1)" ] && pathCnf=$(dirname $1)
 [ -d "$pathCnf" ] || mkdir -p $pathCnf
 conf="${pathCnf}/$(basename $1)"
 IFS=';'
 {
  LANG=C date "+#Created %c by $USER $0 ($$)"
  for sKeyValue in $2; do
   [ -n "${sKeyValue}" ] && echo "${sKeyValue}"
  done
 } >> $conf 2>/dev/null
 IFS=$chIFS
 return 0
}
#******
#****u* bashlyk/libcnf/udfLibCnf
#  SYNOPSIS
#    udfLibCnf
# DESCRIPTION
#   bashlyk CNF library test unit
#   Запуск проверочных операций модуля выполняется если только аргументы командной строки
#   cодержат ключевые слова "--bashlyk-test" и "cnf"
#  SOURCE
udfLibCnf() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -e "--bashlyk-test=*cnf")" ] && return 0
 local s conf="$$.testlib.conf" a b
 echo "--- libcnf.sh tests --- start"
 printf "#\n# Relative path to config config file (${_bashlyk_pathCnf}/${conf})\n#\n"
 udfAddFile2Clean "${_bashlyk_pathCnf}/${conf}"
 for s in udfSetConfig udfGetConfig; do
  echo "check $s:"
  $s $conf "a=b;b=\"$(date -R)\""
  sleep 0.1
 done
 echo "file ${_bashlyk_pathCnf}/${conf} contains:"
 cat "${_bashlyk_pathCnf}/${conf}"
 echo "Variable contains:"
 echo "a=$a"
 echo "b=$b"
 #
 a=
 b=
 conf=$(mktemp -t "XXXXXXXX.${conf}")\
 || udfThrow "Error: temporary file $conf do not created..."
 udfAddFile2Clean $conf
 printf "#\n# Absolute path to config file ($conf))\n#\n"
 for s in udfSetConfig udfGetConfig; do
  sleep 1
  echo "check $s:"
  $s $conf "a=b;b=\"$(date -R)\""
 done
 echo "file ${conf} contains:"
 cat "${conf}"
 echo "Variable contains:"
 echo "a=$a"
 echo "b=$b"
 echo "--- libcnf.sh tests ---  done"
 return 0
}
#******
#****** bashlyk/libcnf/Main section
# DESCRIPTION
#   Running CNF library test unit if $_bashlyk_sArg ($*) contain
#   substring "--bashlyk-test=" and "cnf" - command for test using
#  SOURCE
udfLibCnf
#******
