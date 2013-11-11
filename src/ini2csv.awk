BEGIN {
 b = 0; i = 0; csv="[];"; s="_bashlyk_ini_void_autoKey_"
}

/^#|^$/ { next }

/\[/ { 
 sTag = $0; sub(/\]/, "", sTag); 
 sub(/\[/, "", sTag); csv = csv""$0";"; s="_bashlyk_ini_"sTag"_autoKey_"
 next 
}

$1=$1 {
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
