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
#    Отсутствие значения $BASH_VERSION предполагает несовместимость с
#    c текущим командным интерпретатором
#  SOURCE
[ -n "$_BASHLYK_LIBXML" ] && return 0 || _BASHLYK_LIBXML=1
[ -n "$BASH_VERSION" ] \
 || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'
#******
#****v* bashlyk/libxml/Init section
#  DESCRIPTION
#    Global variable for store arguments
#  SOURCE
: ${_bashlyk_sArg:=$*}
: ${_bashlyk_aRequiredCmd_xml:="[ echo"}
: ${_bashlyk_aExport_xml:="udfXml _"}
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
#  SOURCE
_() {
 [ -n "$1" ] || return 1
 local s=($1)
 shift
 echo "<${s[*]}>${*}</${s[0]}>"
}
#******
