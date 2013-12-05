BEGIN {
 b = 0; i = 0; csv="[];"; s="_bashlyk_ini_void_autoKey_"
}

/^#|^$/ { next }

/\[/ {
 if ( b == 0 ) {
  if (match($0, /:\[.*\]:/)) { b = 1; gsub(":", "") } 
  sTag = $0; sub(/\]/, "", sTag); sub(/\[/, "", sTag); csv = csv""$0";";
  s="_bashlyk_ini_"sTag"_autoKey_"
  next 
 } else {
  if (match($0, /:\[\/.*\]:/)) { b = 0; next }   
 }
}

$1=$1 {
 gsub(";", "_bashlyk_semicolon_")
 if ( b == 1 ) { 
  gsub("\[", "_bashlyk_lsqb_")
  gsub("\]", "_bashlyk_rsqb_")
 }  
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
