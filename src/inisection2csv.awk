#
# $Id$
#

BEGIN {
 b = 0; i = 0; csv="";
 if ( sTag == "" ) { re = "\[\]"; sTag = "void"; b = 1 }
 else { re = "\["sTag"\]" }
 s="_bashlyk_ini_"sTag"_autoKey_"
}

/^#|^$/ { next }

$0 ~ re { b = 1; next }
/\[/ { if (b == 1) exit }

$1=$1 {

 gsub(";",  "_bashlyk_\&#59_")
 gsub("\[", "_bashlyk_\&#91_")
 gsub("\\", "_bashlyk_\&#92_")
 gsub("\]", "_bashlyk_\&#93_")

 if ( b == 0 ) { next }
 s0 = $0
 if ( match(s0, /= *.*$/) < 2 ) {
  if ( match(s0, /[ =]/) ) { s0 = "\""s0"\"" }
  csv = csv""s""i++"="s0";"
 } else {
  v = substr($0, RSTART+1, RLENGTH)
  sub("="v, "")
  sub(/ *$/, "")
  k = $0
  if ( match(k, /[ ]/) ) {
   if ( match(s0, /[ =]/) ) { s0 = "\""s0"\"" }
   csv = csv""s""i++"="s0";"
  } else {
   sub(/^ */, "", v)
   if ( match(v, /[ =]/) ) { v = "\""v"\"" }
   csv = csv""k"="v";"
  }
 }
}

END   { print csv }
