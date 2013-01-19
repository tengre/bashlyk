#
# $Id$
#
#****h* bashlyk/testcnf
#  DESCRIPTION
#    bashlyk CNF test unit
#    Тестовый модуль библиотеки cnf
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****** bashlyk/testcnf/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
#[ -s "${_bashlyk_pathLib}/libcnf.sh" ] && . "${_bashlyk_pathLib}/libcnf.sh"
. ./libcnf.sh
#******
#****u* bashlyk/testcnf/udfTestCnf
#  SYNOPSIS
#    udfTestCnf
# DESCRIPTION
#   bashlyk CNF library test unit
#   Запуск проверочных операций модуля
#  SOURCE
udfTestCnf() {
 local a b=1 c conf="$$.testlib.conf" fn s
 printf "\n- libcnf.sh tests: "
#
# Проверка файла конфигурации без полного пути
#
 udfSetConfig $conf "a=\"$0\";c=\"$(uname -a)\"" >/dev/null 2>&1
 echo -n '.'
 . ${_bashlyk_pathCnf}/${conf} >/dev/null 2>&1
 echo -n '.'
 [ "$a" = "$0" -a "$c" = "$(uname -a)" ] \
  && echo -n  '.' || { echo -n '?'; b=0; }
 a=;c=
 echo -n '.'
 udfGetConfig $conf 2>/dev/null
 echo -n '.'
 [ "$a" = "$0" -a "$c" = "$(uname -a)" ] \
  && echo -n '.' || { echo -n '?'; b=0; }
 rm -f "${_bashlyk_pathCnf}/${conf}"
 a=;c=
#
# Проверка файла конфигурации с полным путем
#
 fn=$(mktemp -t "XXXXXXXX.${conf}" 2>/dev/null) && conf=$fn || conf=~/${conf}
 udfSetConfig $conf "a=\"$0\";c=\"$(uname -a)\"" >/dev/null 2>&1
 echo -n '.'
 . $conf >/dev/null 2>&1
 echo -n '.'
 [ "$a" = "$0" -a "$c" = "$(uname -a)" ] \
  && echo -n '.' || { echo -n '?'; b=0; }
 a=;c=
 echo -n '.'
 udfGetConfig $conf 2>/dev/null
 echo -n '.'
 [ "$a" = "$0" -a "$c" = "$(uname -a)" ] \
  && echo -n '.' || { echo -n '?'; b=0; }
 a=;c=
 rm -f $conf
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 echo "--"
 return 0
}
#******
#****** bashlyk/testcnf/Main section
# DESCRIPTION
#   Running CNF library test unit
#  SOURCE
udfTestCnf
#******
