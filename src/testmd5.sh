#
# $Id$
#
#****h* bashlyk/testmd5
#  DESCRIPTION
#    bashlyk md5 test unit
#    Тестовый модуль библиотеки md5
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****** bashlyk/testmd5/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/libmd5.sh" ] && . "${_bashlyk_pathLib}/libmd5.sh"
#******
#****u* bashlyk/testmd5/udfTestMd5
#  SYNOPSIS
#    udfTestMd5
# DESCRIPTION
#   bashlyk MD5 library test unit
#   Запуск проверочных операций модуля
#  SOURCE
udfTestMd5() {
 local fn s b=1
 printf "\n- libmd5.sh tests: "
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
 echo "--"
 return 0
}
#******
#****** bashlyk/testmd5/Main section
# DESCRIPTION
#   Running MD5 library test unit
#  SOURCE
udfTestMd5
#******
