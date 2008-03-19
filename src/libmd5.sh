#
# $Id$
#
[ -n "$_BASHLYK_LIBMD5" ] && return 0
_BASHLYK_LIBMD5=1
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
 cd $1
 local pathDst=$(pwd)
 local       a=$(ls)
 for s in $a
 do
  [ -d "$s" ] && udfGetPathMd5 $s
 done
 md5sum $pathDst/*
 cd $pathSrc
 return 0
} 2>/dev/null
#
################################################
################################################
###### Test Block ##############################
################################################
################################################
#
if [ "$1" = "test.libmd5.bashlyk" ]; then
  echo "Check udfGetMd5 with string $*:"
  echo -n "from argument: " && udfGetMd5 $*
  sleep 1
  echo -n "from stdin   : " && echo $* | udfGetMd5 -
  sleep 1
  echo $* > /tmp/$1.$$.tmp
  echo -n "from file    : " && udfGetMd5 --file /tmp/$1.$$.tmp
  rm -f /tmp/$1.$$.tmp
  sleep 1
  echo "Check udfGetPathMd5 with path .:"
  udfGetPathMd5 .
fi

true