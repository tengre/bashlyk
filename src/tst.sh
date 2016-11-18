#!/bin/bash

. bashlyk

udfShellExec "declare -g -A _h"

ini.selectsection() {

local s

if [[ ! ${_h[$1]} ]]; then

  s=$(md5sum <<< "$1")
  s="_ini${s:0:32}"
  _h[$1]="$s"

  eval "declare -g -A -- $s"

  declare -p _h

fi

#echo "ini.section() { case "\$1" in get) echo "\${$s[\$2]}";; set) $s[\$2]="\$3";; esac; }"
#eval "ini.section() { case "\$1" in get) echo "\${$s[\$2]}";; set) $s[\$2]="\$3";; esac; }"
eval "ini.section.set() { $s[\$1]="\$2"; }; ini.section.get() { echo "\${$s[\$1]}"; };"

}

ini.selectsection test

ini.section.set bobrock "abramov abramovich"
ini.section.set bobrock1 "abramov abramovich1"

ini.section.get bobrock

ini.selectsection test2

ini.section.set bobrock "abramov abramovich lala"

ini.section.get bobrock


declare -p _h

for s in "${!_h[@]}"; do

    declare -p ${_h[$s]}

done



