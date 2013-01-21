#
# $Id$
#
#****h* bashlyk/testini
#  DESCRIPTION
#    bashlyk INI test unit
#    Тестовый модуль библиотеки INI
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****** bashlyk/testini/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[ -s "${_bashlyk_pathLib}/libini.sh" ] && . "${_bashlyk_pathLib}/libini.sh"
#******
#****u* bashlyk/testini/udfTestIni
#  SYNOPSIS
#    udfTestIni
# DESCRIPTION
#   bashlyk INI library test unit
#   Запуск проверочных операций модуля
#  SOURCE
udfTestIni() {
 local b=true c ini fn s csv csv0 csv1 csv2 path csv20930903
 local aLetter0=a,b,c,d,e bResult0=true iX0=1921 iY0=1080 sText0="foo bar"
 #
 fn=$(mktemp -t "XXXXXXXX" 2>/dev/null) && ini=${fn}.ini || ini=~/${ini}
 path=$(dirname ${ini})
 ini=$(basename ${ini})
 #
 csv0="aLetter=${aLetter0};bResult=${bResult0};iX=${iX0};${iX0};iY=${iY0};sText=${sText0};${sText0}"
 csvQ='aLetter=a,b,c,d,e;bResult=true;iX=1921;_zzz_bashlyk_ini_line_0=1921;iY=1080;sText="foo bar";_zzz_bashlyk_ini_line_1="foo bar";'
 #
 printf "\n- libini.sh tests: "
 [ "$(udfCheckCsv "$csv0")" = "$csvQ" ] && echo -n "." || { b=false; echo -n "?"; }
 udfCheckCsv "$csv0" csv
 [ "$csv" = "$csvQ" ] && echo -n "." || { b=false; echo -n "?"; }
 #
 [ "$(udfCsvOrder "$csv")" = "$(udfCsvOrder "$csv0")" ]  && echo -n "." || { b=false; echo -n "?"; }
 #
 udfIniChange ${path}/${ini} "$csv0;iY=12;iX=34;bResult=false" "settings" && echo -n "." || { b=false; echo -n "?"; }
 csv='iY=1080;iX=1921;bResult=true;$(uname -a)'
 udfIniChange ${path}/a.${ini} "$csv" "settings" && echo -n "." || { b=false; echo -n "?"; }
 #udfReadIniSection ${path}/a.${ini} "settings" csv
 udfGetIniSection ${path}/a.${ini} "settings" csv2 && echo -n "." || { b=false; echo -n "?"; }
 #[ "$csvQ" = "$(udfCheckCsv "$csv2")" ] && echo -n "." || { b=false; echo -n "?"; }
 udfSetVarFromIni ${path}/a.${ini} "settings" aLetter bResult iX iY sText
 [ "$aLetter" = "$aLetter0" ] && echo -n "." || { b=false; echo -n "?"; }
 [ "$bResult" = "$bResult0" ] && echo -n "." || { b=false; echo -n "?"; }
 [ "$iX"      = "$iX0"      ] && echo -n "." || { b=false; echo -n "?"; }
 [ "$iY"      = "$iY0"      ] && echo -n "." || { b=false; echo -n "?"; }
 [ "$sText"   = "$sText0"   ] && echo -n "." || { b=false; echo -n "?"; }
 $b && echo "ok" || echo "fail"
 rm -f ${path}/a.${ini}
 rm -f ${path}/${ini}
 echo "--"
 return 0
}
#******
#****** bashlyk/testini/Main section
# DESCRIPTION
#   Running INI library test unit
#  SOURCE
udfTestIni
#******
