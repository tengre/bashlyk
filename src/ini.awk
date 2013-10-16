BEGIN {
 b = 0; i = 0; csv="";
 if (s == "") s="_"sId"_Key_"
 if ( sId == "" ) { re = "\[\]"; b = 1 }
           else { re = "\["sId"\]" }
}

$0 ~ re { b = 1; next }
/\[/ { if (b == 1) exit }

$1=$1 {
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

END   { print "["sId"];"csv }
