BEGIN {
 b = 0
 FS = "/"
}


/^#\*\*\*\*f\* .*$/ {
 print "# "$NF
}

/^#  EXAMPLE/ {
 b = 1
 next
}

/^#  SOURCE/ {
 b = 0
}

$1=$1 {
 if ( b == 1 ) { 
  sub(/^# *?/, "")
  sub(/##.* \?/, "; udfTestUnitMsg")
  print $0 
 }
}

END   {  }
