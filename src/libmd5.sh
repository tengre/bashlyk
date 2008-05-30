#
# $Id$
#
[ -n "$_BASHLYK_LIBMD5" ] && return 0 || _BASHLYK_LIBMD5=1
#
# global variables
#
_bashlyk_aBin+=" cut echo md5sum sleep true"
#
# function section
#
udfGetMd5() {
 {
  case "$1" in
       "-")
          local s
          while read s; do echo "$s"; done | md5sum
         ;;
  "--file")
          [ -f "$2" ] && md5sum $2
         ;;
         *)
          [ -n "$1" ] && echo "$*" | md5sum
         ;;
  esac
 } | cut -f 1 -d ' '
 return 0
}
#
udfGetPathMd5() {
 [ -n "$1" -a -d "$1" ] || return 1
 local pathSrc=$(pwd)
 cd $1 2>/dev/null
 local pathDst=$(pwd)
 local       a=$(ls)
 for s in $a
 do
  [ -d "$s" ] && udfGetPathMd5 $s
 done
 md5sum $pathDst/*
 cd $pathSrc
 return 0
} 
#
# main section
#
# Test Block
if [ -n "$(echo "${_bashlyk_aTest}" | grep -w md5)" ]; then
 echo "--- libmd5.sh tests --- start"
 echo "Check udfGetMd5 with string $(uname -a):"
 echo -n "from argument: " && udfGetMd5 $(uname -a)
 sleep 1
 echo -n "from stdin   : " && echo $(uname -a) | udfGetMd5 -
 sleep 1
 echo $(uname -a) > /tmp/$1.$$.tmp
 echo -n "from file    : " && udfGetMd5 --file /tmp/$1.$$.tmp
 rm -f /tmp/$1.$$.tmp
 sleep 1
 echo "Check udfGetPathMd5 with path .:"
 udfGetPathMd5 .
 echo "--- libmd5.sh tests ---  done"
fi
#
# main section
#
true
