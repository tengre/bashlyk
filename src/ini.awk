BEGIN {
 reSection = "\["sSection"\]"
 bBeginSection = 0; bEndSection = 0; i = 0; csv=""
 
 print "dbg "sSection
 #sSection = "\[test\]"
}

 /^#/ { next }
 /^$/ { next }

 $0 ~ reSection {
  print "Begin Section " $0
  bBeginSection = 1
  next
 }

 /\[/ {
  print "End Section " $0
  if (bBeginSection == 1) {
   bEndSection = 1
   exit
  }
 }

 $1=$1 {
  if ( bBeginSection == 0 ) { next }
  match($0, /= *.*$/)
  sValue = substr($0, RSTART+1, RLENGTH)
  sub("="sValue, "")
  sub(/ *$/, "")
  sKey = $0
  sub(/^ */, "", sValue)
  csv = csv""sKey"="sValue";"
 }


END   { print "Begin="bBeginSection" End="bEndSection" csv:"csv }
