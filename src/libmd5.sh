#
# $Id: libmd5.sh 2 2007-07-30 08:34:41Z yds $
#
udfMD5(){
 /usr/bin/md5sum "$1" | /usr/bin/awk '{print $1}'
}
#
udfDirMD5(){
 [ -n "$1" -a -d "$1" ] || return 1
 cd $1
 local    a=$(/bin/ls)
 local path=$(/bin/pwd)
 for s in $a
 do
  [ -d "$s" ] && udfDirMD5 $s
 done
 /usr/bin/md5sum -v $path/*
 cd ..
 return 0
} 2>/dev/null
#

