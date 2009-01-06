#
# $Id$
#
[ -n "$_BASHLYK_LIBXML" ] && return 0 || _BASHLYK_LIBXML=1
#
# link section
#
#
# global variables
#
_bashlyk_aBin+=" basename date echo hostname false printf logger mail mkfifo sleep tee true jobs "
#
udfXml() {
 [ -n "$1" ] || return 1
 local s=($1)
 shift
 echo "<${s[*]}>${*}</${s[0]}>"
}
#
#
#
udfLibXml() {
 #[ -z "$(echo "${_bashlyk_sArg}" | grep -e "--bashlyk-test" | grep -w "xml")" ] && return 0
 echo "--- libxml.sh tests --- start"
 echo "Check udfXml for xml generating"
 echo 'Code:   $(udfXml entry $(udfXml input echo test)$(udfXml variable sTest))'
 echo "Result: $(udfXml entry $(udfXml input echo test)$(udfXml variable sTest))"
 echo "--- libpid.sh tests ---  done"
 return 0
}
#
#
#
udfLibXml
