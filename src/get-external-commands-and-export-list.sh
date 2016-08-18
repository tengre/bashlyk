#!/bin/bash
#
#$Id: get-external-commands-and-export-list.sh 539 2016-08-18 14:51:40+04:00 toor $
#
. bashlyk
#
#
#
_get_external_binaries_list_a="$(grep -oP '(/usr)?/s?bin/\S+' /var/lib/dpkg/info/*.list | sed -re "s/.*bin\///" | xargs)"
_get_external_binaries_list_a+=" awk mkfifo"
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
	for s in ${a//[/\\\[}; do

		grep -w $s $fn | grep -P "(^\s*?|[&|]\s*?|\044\(\s*?)$s" | grep -v "^#\|_bashlyk_aRequiredCmd" | grep -o "$s"

	done | sort | uniq | xargs


	printf -- "\n\nexport list:\n------------\n"
	grep -P '^(udf|_).*\(\)' $fn | cut -f 1 -d'(' | sort | uniq | xargs
	printf -- "\n\n"
}
#
#
#
udfMain
#
