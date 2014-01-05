BEGIN {
 b = 0
 FS = "/"
}


/^#\*\*\*\*f\* .*$/ {
 f=$NF"_test"
 print f"() {"
}

/^#  EXAMPLE/ {
 b = 1
 next
}

/^#  SOURCE/ {
 b = 0
 print "}"
 print f
}

$1=$1 {
 if ( b == 1 ) { 
  sub(/^# *?/, "")
  sub(/##.* \?/, " >>$_bashlyk_TestUnit_fnLog 2>\&1; udfTestUnitMsg")
  print $0 
 }
}

END   {  }
