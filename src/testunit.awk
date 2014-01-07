#
# $Id$
#

BEGIN {
 FS = "\n"
 b = 2
}


/^#\*\*\*\*f\* .*$/ {
 b = 0
 i=split($0, a, "/")
 f=a[i]"_test"
 print f"() {"
 print "echo -- "f" testing start: >> $_bashlyk_TestUnit_fnLog 2>&1"
}

/^#  EXAMPLE/ {
 b = b+1
 next
}

/^#  SOURCE/ {
 if ( b != 1 ) next
 print "echo -- "f" testing  done. >> $_bashlyk_TestUnit_fnLog 2>&1" 
 print "}"
 print f
 b = 2
}

$1=$1 {
 if ( b == 1 ) { 
  sub(/^# *?/, "")
  if (match($0, /#\?/)) { 
   sub(/#\?/, " >> $_bashlyk_TestUnit_fnLog 2>\&1; udfTestUnitMsg")
  } else {
   if (match($0, /#=/)) { 
    sub(/#=/, "; udfTestUnitMsg")
   } else {
    if (match($0, /#-/)) {
     sub(/#-/, "")
     gsub(/[ \t]+$/, "")
    } else {
     $0 = $0">> $_bashlyk_TestUnit_fnLog 2>&1"      
    }
   }
  }
  print $0 
 }
}

END   {  }
