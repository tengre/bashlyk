#
# $Id$
#
#****h* bashlyk/libxml
#  DESCRIPTION
#    bashlyk XML library
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* bashlyk/libxml/Required Once
#  DESCRIPTION
#    If this global variable defined then library already linked
#  SOURCE
[ -n "$_BASHLYK_LIBXML" ] && return 0 || _BASHLYK_LIBXML=1
#******
#****v* bashlyk/libxml/Init section
#  DESCRIPTION
#    Global variable for store arguments
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_aRequiredCmd_xml:="echo grep ["}
#******
#****f* bashlyk/libxml/udfXML
#  SYNOPSIS
#    udfXml tag [property] data
#  DESCRIPTION
#    Generate XML code to stdout
#  INPUTS
#    tag      - XML tag name (without <>)
#    property - XML tag property
#    data     - XML tag content
#  OUTPUT
#    Show compiled XML code
#  EXAMPLE
#    udfXML 'date TO="+0500" TZ="SAMST"' "Sun, 21 Jun 2009 03:43:11 +0500"
#    Show "<date TO="+0500" TZ="SAMST">Sun, 21 Jun 2009 03:43:11 +0500</date>
#  SOURCE
udfXml() {
 [ -n "$1" ] || return 1
 local s=($1)
 shift
 echo "<${s[*]}>${*}</${s[0]}>"
}
#******
#****f* bashlyk/libxml/_
#  SYNOPSIS
#    _ tag [property] data
#  DESCRIPTION
#    Generate XML code to stdout
#    Short alias for udfXML
#******
_() {
 [ -n "$1" ] || return 1
 local s=($1)
 shift
 echo "<${s[*]}>${*}</${s[0]}>"
}
#****u* bashlyk/libxml/udfLibXml
#  SYNOPSIS
#    udfLibXml
# DESCRIPTION
#   bashlyk XML library test unit
#   Запуск проверочных операций модуля выполняется если только аргументы 
#   командной строки cодержат строку вида "--bashlyk-test=[.*,]xml[,.*]",
#   где * - ярлыки на другие тестируемые библиотеки
#  SOURCE
udfLibXml() {
 [ -z "$(echo "${_bashlyk_sArg}" | grep -E -e "--bashlyk-test=.*xml")" ] \
  && return 0
 local s='<entry><input>echo test</input><variable>sTest</variable></entry>' 
 local b=1
 printf "\n- libxml.sh tests:\n\n"
 printf "\nCheck function udfXml and his alias '_' for XML code generating: "
 [ "$s" = "$(udfXml entry $(udfXml input echo test)$(udfXml variable sTest))" ] \
  && echo -n '.' || { echo -n 'fail.'; b=0; }
 [ "$s" = "$(_ entry $(_ input echo test)$(_ variable sTest))" ] \
  && echo -n '.' || { echo -n 'fail.'; b=0; }
 [ $b -eq 1 ] && echo 'ok.' || echo 'fail.'
 printf "\n--\n\n"
 return 0
}
#******
#****** bashlyk/libxml/Main section
# DESCRIPTION
#   Running XML library test unit if $_bashlyk_sArg ($*) contain
#   substrings "--bashlyk-test" and "xml" - command for test using
#  SOURCE
udfLibXml
#******
