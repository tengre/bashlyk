csv='[lime];a=b;[test];sTxt=foo;b=false;_bashlyk_ini_test_autoKey_0="iXo Xo=19";iYo=80;_bashlyk_ini_test_autoKey_1="simple line";;;[lime];a=c;[test];sTxt="foo bar";b=true;iXo=1921;iYo=1080;;'

aTag=$(echo $csv | tr ';' '\n' | grep -oE '\[.*\]' | sort | uniq | tr -d '[]' | tr '\n' ' ')
sR=''
for s in "" $aTag; do
 sT=''
 sS='\['${s}'\]'
 while [ true ]; do
  [ -n "$(echo $csv | grep -oE $sS)" ] || break
  sF=$(echo "${csv#*${sS};}" | cut -f1 -d'[')
  csv=$(echo ${csv/${sS};${sF}/})
  sT+=";"${sF}
 done
 sR+="[${s}];${sT};"
done
echo ${sR} | sed -e "s/;\+/;/g"

