#
# $Id$
#
#****h* bashlyk/libmd5
#  DESCRIPTION
#    bashlyk MD5 library
#    Использование md5sum
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/libmd5/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает
#    защиту от повторного использования данного модуля
#  SOURCE
[ -n "$_BASHLYK_LIBMD5" ] && return 0 || _BASHLYK_LIBMD5=1
#******
#****v*  bashlyk/libmd5/Init section
#  DESCRIPTION
#    Блок инициализации глобальных переменных
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
: ${_bashlyk_aRequiredCmd_md5:="cut echo md5sum sleep true ["}
#******
#****f* bashlyk/libmd5/udfGetMd5
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
#    udfGetMd5 $(date)
#  SOURCE
udfGetMd5() {
 {
  case "$1" in
       "-")
          cat | md5sum
         ;;
  "--file")
          [ -f "$2" ] && md5sum $2
         ;;
         *)
          [ -n "$1" ] && echo "$*" | md5sum
         ;;
  esac
 } | cut -f 1 -d ' '
 return 0
}
#******
#****f* bashlyk/libmd5/udfGetPathMd5
#  SYNOPSIS
#    udfGetPathMd5 <path>
#  DESCRIPTION
#   Получить дайджест MD5 всех нескрытых файлов в каталоге <path>
#  INPUTS
#    <path>  - начальный каталог
#  OUTPUT
#    Список MD5-сумм и имён нескрытых файлов в каталоге <path> рекурсивно
#  RETURN VALUE
#    -1 - аргумент не указан или это не каталог
#     0 - выполнено
#  EXAMPLE
#    udfGetPathMd5 ~
#  SOURCE
udfGetPathMd5() {
 [ -n "$1" -a -d "$1" ] || return -1
 local pathSrc=$(pwd)
 cd $1 2>/dev/null
 local pathDst=$(pwd)
 local       a=$(ls)
 for s in $a
 do
  [ -d "$s" ] && udfGetPathMd5 $s
 done
 md5sum $pathDst/* 2>/dev/null
 cd $pathSrc
 return 0
}
#******
#****u* bashlyk/libmd5/udfLibMd5
#  SYNOPSIS
#    udfLibMd5
# DESCRIPTION
#   bashlyk MD5 library test unit
#   Запуск проверочных операций модуля выполняется если только аргументы 
#   командной строки cодержат строку вида "--bashlyk-test=[.*,]md5[,.*]",
#   где * - ярлыки на другие тестируемые библиотеки
#  SOURCE
udfLibMd5() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -E -e "--bashlyk-test=.*md5")" ] \
  && return 0
 local fn s b=1
 printf "\n- libmd5.sh tests:\n\n"
 echo -n "Check MD5 functions: "
 s=$(udfGetMd5 $(uname -a) 2>/dev/null) 
 echo -n '.'
 [ "$s" = "$(echo $(uname -a) | udfGetMd5 - 2>/dev/null)" ] \
  && echo -n '.' || { echo -n '?'; b=0; } 
 fn=$(mktemp -t "XXXXXXXX.${conf}" 2>/dev/null) || fn=/tmp/$$.tmp.md5
 echo -n '.'
 echo $(uname -a) > $fn
 [ "$s" = "$(udfGetMd5 --file $fn 2>/dev/null)" ] \
  && echo -n '.' || { echo -n '?'; b=0; } 
 rm -f $fn
 udfGetPathMd5 . >/dev/null 2>&1 && echo -n '.' || { echo -n '?'; b=0; } 
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 printf "\n--\n\n"
 return 0
}
#******
#****** bashlyk/libmd5/Main section
# DESCRIPTION
#   Running MD5 library test unit if $_bashlyk_sArg ($*) contains
#   substrings "--bashlyk-test=" and "md5" - command for test using
#  SOURCE
udfLibMd5
#******
