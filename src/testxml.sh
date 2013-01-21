#
# $Id$
#
#****h* bashlyk/testxml
#  DESCRIPTION
#    bashlyk XML test unit
#    Тестовый модуль библиотеки XML
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****** bashlyk/testxml/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/libxml.sh" ] && . "${_bashlyk_pathLib}/libxml.sh"
#******
#****u* bashlyk/testxml/udfTestXml
#  SYNOPSIS
#    udfTestXml
# DESCRIPTION
#   bashlyk XML library test unit
#   Запуск проверочных операций модуля
#  SOURCE
udfTestXml() {
 local s='<entry><input>echo test</input><variable>sTest</variable></entry>' 
 local b=1
 printf "\n- libxml.sh tests: "
 [ "$s" = "$(udfXml entry $(udfXml input echo test)$(udfXml variable sTest))" ] \
  && echo -n '.' || { echo -n 'fail.'; b=0; }
 [ "$s" = "$(_ entry $(_ input echo test)$(_ variable sTest))" ] \
  && echo -n '.' || { echo -n 'fail.'; b=0; }
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 echo "--"
 return 0
}
#******
#****** bashlyk/testxml/Main section
# DESCRIPTION
#   Running XML library test unit
#  SOURCE
udfTestXml
#******
