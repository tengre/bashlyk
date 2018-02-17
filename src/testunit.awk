#
# $Id: testunit.awk 790 2018-02-17 21:59:26+04:00 toor $
#

BEGIN {

  FS = "\n"
  b = 2
  f = ""
  bEmbed = 0
}


/^#\*\*\*\*[fepm]\* .*$/ {

  if (b == 0) {

    print "echo -- "f" testing  done. >> $_bashlyk_TestUnit_fnLog 2>&1"
    print "}"

  }

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

/\| {{{$/ {

  bEmbed = 1
  sub(/\| {{{$/, "")
  sub(/^#/, "")
  print $0" > $testunitEmbedB"
  print "cat << '--EOF--' > $testunitEmbedA"
  next

}

/^#}}}$/ {

  bEmbed = 0
  print "--EOF--"
  print "cat $testunitEmbedB >> $_bashlyk_TestUnit_fnLog 2>&1"
  print "diff -wu $testunitEmbedA $testunitEmbedB >> $_bashlyk_TestUnit_fnLog 2>&1; udfTestUnitMsg true"
  next

}


$1=$1 {

  if ( b == 1 ) {

    sub(/^# *?/, "")

    if (match($0, /{{.*}}[1!]/)) {
      sub(/{{.*}}[1!]/, "tee -a $_bashlyk_TestUnit_fnLog | grep & #? false")
      gsub(/{{|}}[1!]/, "")
    }

    if (match($0, /{{.*}}0?/)) {
      sub(/{{.*}}0?/, "tee -a $_bashlyk_TestUnit_fnLog | grep & #? true")
      gsub(/{{|}}0?/, "")
    }

    sub(/>\|/, " | tee -a $_bashlyk_TestUnit_fnLog | ")

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

          if ( bEmbed == 0 ) {

            $0 = $0" >> $_bashlyk_TestUnit_fnLog 2>&1"

          }

        }

      }

    }

    print $0

  }

}

END   {

  if (b == 0) {

   print "echo -- "f" testing  done. >> $_bashlyk_TestUnit_fnLog 2>&1"
   print "}"

  }

}
