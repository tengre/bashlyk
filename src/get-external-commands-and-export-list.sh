#!/bin/bash
#
#$Id: get-external-commands-and-export-list.sh 808 2018-03-10 19:30:25+04:00 toor $
#
. bashlyk
#
#
#
get-external-commands-and-export-list::main() {

  eval set -- $(_ sArg)

  exit+warn on MissingArgument $1
  exit+warn on NoSuchFileOrDir $1

  local a s fn fnDat re

  fn=$1
  fnDat="${TMPDIR}/get-external-commands-and-export-list.dat"

  shift

  if [[ $* ]]; then

    a="$*"

  else

    if [[ -s $fnDat ]]; then

      a="$(< $fnDat)"

    else

      a="$(grep -oP '(/usr)?/s?bin/\S+' /var/lib/dpkg/info/*.list | sed -re "s/.*bin\///" | xargs)"
      echo "$a" > $fnDat

    fi

  fi

  printf -- "\nused external commands:\n-----------------------\n"
  for s in ${a//[/\\\[}; do

    grep -P "[^\"\'][&|(]?\s+${s}\s+" $fn | grep -v "^#\|_bashlyk_externals_" | grep -o "$s"

  done | sort | uniq | xargs

  printf -- "\n\nexport list:\n------------\n"

  grep -P '^(\S+).?\(\)' $fn | cut -f 1 -d'(' | sort | uniq | xargs
  printf -- "\n\n"

}
#
#
#
get-external-commands-and-export-list::main
#
