#
# $Id: testunit.sh 868 2018-08-17 17:54:10+04:00 toor $
#
#****h* BASHLYK/testunit
#  DESCRIPTION
#    script compiler to run a library test
#  USES
#    testunit.awk
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****v* testunit/Global Variables
#  DESCRIPTION
#    Global variables
#  SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
: ${_bashlyk_pathLog:=/tmp}
: ${_bashlyk_TestUnit_iCount:=0}
: ${_bashlyk_TestUnit_fnTmp:=$( mktemp 2>/dev/null || tempfile || echo "/tmp/${RANDOM}${RANDOM}" )}
#******
#****f* testunit/testunit::msg
#  SYNOPSIS
#    testunit::msg
# DESCRIPTION
#   bashlyk library test unit stdout
#  SOURCE
testunit::msg() {

  local rc0=$? rc1 rc2='' IFS=$' \t\n'

  case "$1" in

     true) rc1=0;;
    false) rc1=1;;
        *) rc1=$1;;
       '') return 255;;

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
#****f* testunit/testunit::error
#  SYNOPSIS
#   testunit::error <error message>
# DESCRIPTION
#   output error message and exit
#  SOURCE
testunit::error() {

  local rc=$?
  echo "$*"
  exit $rc

}
#******
#****f* testunit/testunit::main
# DESCRIPTION
#   main function libraries test unit
#  SOURCE
testunit::main() {

  [[ $1 ]] || return 254

  if   [[ -w /dev/shm ]]; then

    TMPDIR=/dev/shm

  elif [[ -w /run/shm ]]; then

    TMPDIR=/run/shm

  else

    TMPDIR=/tmp

  fi
  export TMPDIR

  local a s fn fnErr="${_bashlyk_TestUnit_fnTmp}.${1}.err" IFS=$' \t\n'
  local testunitEmbedA testunitEmbedB

  testunitEmbedA="${TMPDIR}/testunit.embedded.a.${RANDOM}${RANDOM}"
  testunitEmbedB="${TMPDIR}/testunit.embedded.b.${RANDOM}${RANDOM}"

  fn=${_bashlyk_pathLib}/lib${1}.sh

  [[ -s "$fn" ]] && . $fn || return 254

  mkdir -p $_bashlyk_pathLog || testunit::error "path $_bashlyk_pathLog not exist..."

  _bashlyk_TestUnit_fnLog=${_bashlyk_pathLog}/${1}.testunit.log

  mawk -f ${_bashlyk_pathLib}/testunit.awk -- $fn > $_bashlyk_TestUnit_fnTmp

  echo "testunit for $fn library" > $_bashlyk_TestUnit_fnLog
  echo -n "${fn}: "

  . $_bashlyk_TestUnit_fnTmp 2>$fnErr

  if [[ $? == "0" && "$_bashlyk_TestUnit_iCount" == "0" ]]; then

    echo " ok."
    rm -f $_bashlyk_TestUnit_fnTmp $fnErr

  else

    echo " fail.."
    echo "found $_bashlyk_TestUnit_iCount errors. See \"[?]: status\" lines from $_bashlyk_TestUnit_fnLog"

  fi

  rm -f $testunitEmbedA $testunitEmbedB
}
#******

testunit::main $*
