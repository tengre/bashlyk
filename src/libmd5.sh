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
: ${_bashlyk_aRequiredCmd_md5:="cut echo md5sum sleep true"}
#******
#****f* bashlyk/libmd5/udfGetMd5
#  SYNOPSIS
#    udfGetMd5 [-]|--file <filename>|<args>
#  DESCRIPTION
#   Получить дайджест MD5 указанных данных
#  INPUTS
#    "-"  - использовать поток данных STDIN
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
          local s
          while read s; do echo "$s"; done | md5sum
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
#   Получить дайджест MD5 всех файлов в каталоге <path>
#  INPUTS
#    <path>  - начальный каталог для формирования списка хэша md5 файлов
#  OUTPUT
#    Дайджест MD5
#  EXAMPLE
#    udfGetMd5 $(date)
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
udfLibMd5() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -e "--bashlyk-test" | grep -w "md5")" ] && return 0
 echo "--- libmd5.sh tests --- start"
 echo "Check udfGetMd5 with string $(uname -a):"
 echo -n "from argument: " && udfGetMd5 $(uname -a)
 sleep 1
 echo -n "from stdin   : " && echo $(uname -a) | udfGetMd5 -
 sleep 1
 echo $(uname -a) > /tmp/$1.$$.tmp
 echo -n "from file    : " && udfGetMd5 --file /tmp/$1.$$.tmp
 rm -f /tmp/$1.$$.tmp
 sleep 1
 echo "Check udfGetPathMd5 with path .:"
 udfGetPathMd5 .
 echo "--- libmd5.sh tests ---  done"
 return 0
}
#
# main section
#
udfLibMd5
