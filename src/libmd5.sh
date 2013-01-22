#!/bin/bash
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
: ${_bashlyk_aRequiredCmd_md5:="[ cat cut echo file ls md5sum pwd"}
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
#    255 - аргумент не указан или это не каталог
#     0  - выполнено
#  EXAMPLE
#    udfGetPathMd5 ~
#  SOURCE
udfGetPathMd5() {
 [ -n "$1" -a -d "$1" ] || return 255
 local pathSrc="$(pwd)"
 cd $1 2>/dev/null
 local pathDst="$(pwd)"
 local a=$(ls)
 for s in $a
 do
  [ -d "$s" ] && udfGetPathMd5 $s
 done
 md5sum $pathDst/* 2>/dev/null
 cd $pathSrc
 return 0
}
#******
