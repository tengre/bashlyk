#!/bin/bash
#
#$Id: get-external-commands-and-export-list.sh 534 2016-06-30 14:27:40+04:00 toor $
#
. bashlyk
#
#
#
_get_external_binaries_list_a="awk basename cat chgrp chmod chown cut date dir \
 dirname echo exit false file grep head kdialog kill ls mail md5sum mkdir      \
 mktemp notify-send printf ps pwd rm rmdir sed sleep sort tee tempfile touch   \
 true uniq w which write xargs xmessage zenity"
#
#
#
udfMain() {

    eval set -- $(_ sArg)

	[[ -f $1 ]] || eval $( udfOnError exitecho EmptyOrMissingArgument )

	local a s fn
	fn=$1
	shift
	[[ -n "$*" ]] && a="$*" || a=$_get_external_binaries_list_a

	printf -- "\nused external commands:\n-----------------------\n"
	for s in $a; do

		grep -w $s $fn | grep -P "(^\s*?|[&|]\s*?|\044\(\s*?)$s" | grep -v "^#\|_bashlyk_aRequiredCmd" | grep -o "$s"

	done | sort | uniq | xargs


	printf -- "\n\nexport list:\n------------\n"
	grep -P '^(udf|_).*\(\)' libmsg.sh | cut -f 1 -d'(' | sort | uniq | xargs
	printf -- "\n\n"
}
#
#
#
udfMain
#
