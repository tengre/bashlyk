#
# $Id$
#
#****h* BASHLYK/testunit
#  DESCRIPTION
#    компилятор сценария для запуска тестирования библиотеки, зависит от
#    awk-сценария testunit.awk
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****** testunit/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
: ${_bashlyk_pathLog:=/tmp}
: ${_bashlyk_TestUnit_iCount=0}
: ${_bashlyk_TestUnit_fnTmp=$(mktemp 2>/dev/null || tempfile)}
#******
#****f* testunit/udfTestUnitMsg
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
 [[ "$rc0" == "$rc1" ]] && rc2='.' || rc2='?'
 echo -n "$rc2"
 {
  if [[ "$rc2" == '?' ]]; then
   _bashlyk_TestUnit_iCount=$((_bashlyk_TestUnit_iCount+1))
   echo "--[?]: status $rc0 ( must have $rc1 )"
   echo "--[?]: file: ${BASH_SOURCE[1]} function: ${FUNCNAME[1]}"
   echo -n "--[?]: line: ${BASH_LINENO[0]}: "
   head -n ${BASH_LINENO[0]} ${BASH_SOURCE[1]} | tail -n 1
  else
   echo "-- ok"
  fi
 } >> $_bashlyk_TestUnit_fnLog
 return 0
}
#******
#****f* testunit/udfError
#  SYNOPSIS
#   udfError <сообщение об ошибке>
# DESCRIPTION
#   Вывод указанного сообщения об ошибке c последующим завершением сценария
#  SOURCE
udfError() {
 local rc=$?
 echo "$*"
 exit $rc
}
#******
#****f* testunit/udfMain
# DESCRIPTION
#   main function libraries test unit
#  SOURCE
udfMain() {
 [[ -n "$1" ]] || return 255
 local a s fn
 fn=${_bashlyk_pathLib}/lib${1}.sh
 [[ -s "$fn" ]] && . $fn || return 254
 mkdir -p $_bashlyk_pathLog || udfError "path $_bashlyk_pathLog not exist..."
 _bashlyk_TestUnit_fnLog=${_bashlyk_pathLog}/${1}.testunit.log
 mawk -f ${_bashlyk_pathLib}/testunit.awk -- $fn > $_bashlyk_TestUnit_fnTmp
 echo "testunit for $fn library" > $_bashlyk_TestUnit_fnLog
 echo -n "${fn}: "
 . $_bashlyk_TestUnit_fnTmp
 if [[ $? == "0" && "$_bashlyk_TestUnit_iCount" == "0" ]]; then
  echo " ok."
  rm -f $_bashlyk_TestUnit_fnTmp
 else
  echo " fail.."
  echo "found $_bashlyk_TestUnit_iCount errors. See \"[?]: status\" lines from $_bashlyk_TestUnit_fnLog"
 fi
}
#******
udfMain $*
