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
: ${_bashlyk_aRequiredCmd_xml:="echo grep"}
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
#    udfLibXml --bashlyk-test xml
# DESCRIPTION
#   bashlyk XML library test unit
#  INPUTS
#    --bashlyk-test - command for use test unit
#    xml            - enable test for this library
#  SOURCE
udfLibXml() {
 [ -z "$(echo "${_bashlyk_sArg}" \
  | grep -e "--bashlyk-test" | grep -w "xml")" ] \
  && return 0
 echo "--- libxml.sh tests --- start"
 echo "Check udfXml for XML code generating generating:"
 echo 'Code:   $(udfXml entry $(udfXml input echo test)'\
'$(udfXml variable sTest))'
 echo "Result: $(udfXml entry $(udfXml input echo test)\
$(udfXml variable sTest))"
 echo "Check _ for XML code generating generating:"
 echo 'Code:   $(_ entry $(_ input echo test)$(_ variable sTest))'
 echo "Result: $(_ entry $(_ input echo test)$(_ variable sTest))"
 echo "--- libxml.sh tests ---  done"
 return 0
}
#******
#****** bashlyk/libxml/Main section
# DESCRIPTION
#   Running XML library test unit if $_bashlyk_sArg ($*) contain
#   substring "--bashlyk-test xml" - command for test using
#  SOURCE
udfLibXml
#******
