#
# $Id$
#
#****h* bashlyk/testXXX
#  DESCRIPTION
#    bashlyk XXX test unit
#    Тестовый модуль библиотеки XXX
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****** bashlyk/testXXX/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
: ${_bashlyk_TestUnit_iCount=0}
: ${_bashlyk_TestUnit_fnLog=/tmp/testunit.log}
#: ${_bashlyk_TestUnit_fnLog=/var/log/bashlyk/testunit.log}
: ${_bashlyk_TestUnit_fnTmp=$(mktemp 2>/dev/null || tempfile)}
#******
#****u* bashlyk/testunit/udfTestUnitMsg
#  SYNOPSIS
#    udfTestUnitMsg
# DESCRIPTION
#   bashlyk library test unit stdout
#  SOURCE
udfTestUnitMsg() {
 local rc0=$? rc1 rc2=''
 case "$1" in
   true) rc1=0;;
  false) rc1=1;;
      *) rc1=$1;;
     '') return 255
 esac
 [ "$rc0" = "$rc1" ] && rc2='.' || rc2='?'
 echo -n $rc2
 if [ "$rc2" = "?" ]; then
  {
   _bashlyk_TestUnit_iCount=$((_bashlyk_TestUnit_iCount+1))
   echo "? rc: [ $rc0 != $rc1 ] - ${BASH_SOURCE[1]} (line ${BASH_LINENO[0]}):"
   head -n ${BASH_LINENO[0]} ${BASH_SOURCE[1]} | tail -n 1
  } >> $_bashlyk_TestUnit_fnLog
 fi
 return 0
} 
#******
#****u* bashlyk/testunit/udfMain
# DESCRIPTION
#   Running libraries test unit
#  SOURCE
udfMain() {
 [ -n "$1" ] || return 255
# local a s fn=${_bashlyk_pathLib}/lib${1}.sh
 local a s fn
 fn=${_bashlyk_pathLib}/lib${1}.sh
 [ -s $fn ] && . $fn || return 254
 _bashlyk_TestUnit_fnLog=/tmp/${1}.testunit.log
 a=$(eval echo '$_bashlyk_aExport_'"${1}")
 {
  for s in $a; do
   echo 'echo "-- testing '"${s}"':" >>$_bashlyk_TestUnit_fnLog'
   grep "^#.*#.${s}" $fn | grep -w "#.${s}" | sed -e "s/^#//" | sed -e "s/##${s}/>>\$_bashlyk_TestUnit_fnLog 2>\&1/" -e "s/#-${s}//"  -e "s/\? \(.*\)/; udfTestUnitMsg \1/" -e "s/[ ]\+$//"
   echo 'echo "--" >>$_bashlyk_TestUnit_fnLog'
   done
 } >> $_bashlyk_TestUnit_fnTmp
 echo "testunit for $fn library" > $_bashlyk_TestUnit_fnLog
 echo -n "${fn}: "
 . $_bashlyk_TestUnit_fnTmp
 if [ $_bashlyk_TestUnit_iCount -eq 0 ]; then
  echo " ok."
  rm -f $_bashlyk_TestUnit_fnTmp
 else
  echo " fail.."
  echo "found $_bashlyk_TestUnit_iCount errors. See \"[?] - test unit error -\" lines from $_bashlyk_TestUnit_fnLog"
 fi
}
#******
udfMain $*
