#!/usr/bin/env bash
#
# $Git: bashlyk-robodoc.sh 1.96-7-941 2023-05-10 08:56:51+00:00 yds $
#
bashlyk-robodoc::usage() {

  local rc=$? dt="$(stat -c %y $0)" S="$(exec -c printf -- '\044')"
  local -a a=( $(grep -o "${S}Git: .*${S}" $0 | head -n 1) )

  printf -- "\n  %s %s %s, (c) %s\n\n"                                         \
            "${a[1]:=${0##*/}}"                                                \
            "${a[2]:=?}"                                                       \
            "${a[3]:=${dt%% *}}"                                               \
            "2016-$(std::date %Y)"

	cat <<-EOF | tr -d '#'
#  DESCRIPTION
#    This tool is designed to generate RoboDoc files  outside  of the process of
#    building packages from source due to the lack of a robodoc package in  some
#    modern distributions. Need to run before automake
#  USAGE
#    bashlyk-robodoc.sh [ -h|--help ] | [[ --path <path>] [ --name <name> ]]
#  ARGUMENTS
#    -h, --help        - show this usage and exit
#    -p, --path <path> - path to the configuration file robodoc.rc, by default
#                        used current folder
#    -n, --name <name> - project name, by default used short name of current
#                        folder
#  USES
#    basename bash date head grep patch pwd robodoc sed stat
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#  EXAMPLE
#    bashlyk-robodoc
	EOF
  exit $rc
}
bashlyk-robodoc::main() {

  local name path sNotFound timestamp

  for s in basename date head grep pwd stat; do
    hash $s 2>/dev/null || sNotFound+="\"$s\" "
  done
  if [[ $sNotFound ]]; then
    echo "error: required external tool(s) - ${sNotFound}.." >&2
    return 1
  fi

  [[ $@ =~ (-h|--help)[[:space:]]*?([^-]*?)([[:space:]]-.*|$) ]] && help="${BASH_REMATCH[1]}"
  [[ $help ]] && bashlyk-robodoc::usage

  [[ $* =~ (-n|--name)[[:space:]]*?([^-]*?)([[:space:]]-.*|$) ]] && name="${BASH_REMATCH[2]}"
  [[ $name ]] || name=$(basename $(pwd))

  [[ $* =~ (-p|--path)[[:space:]]*?([^-]*?)([[:space:]]-.*|$) ]] && path="${BASH_REMATCH[2]}"
  [[ $path ]] || path=.

  if [[ -s ${path}/VERSION ]]; then
    timestamp="$(head -n 1 ${path}/VERSION | grep -Po '\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}')"
    [[ $timestamp ]] || timestamp="$(exec -c date --rfc-3339=s -u)"
  fi

  if [[ ! -f ${path}/robodoc.rc ]]; then
    echo "RoboDoc configuration file ${path}/robodoc.rc not found, exit.." >&2
    return 1
  fi

  if ! hash robodoc 2>/dev/null; then
    echo "error: required external tool robodoc not found, exit.." >&2
    return 2
  fi
  if ! robodoc; then
    return $?
  fi

  if [[ ! -d ${path}/doc ]]; then
    echo "target folder ${path}/doc not found, exit.." >&2
    return 1
  fi

  if ! cd ${path}/doc; then
    echo "Change to target folder ${path}/doc failed, exit.." >&2
    return 1
  fi

  if [[ -f ${name}.html.patch ]]; then
    if ! hash patch 2>/dev/null; then
      echo "error: required external tool patch not found, exit.." >&2
      return 2
    fi
    patch < ${name}.html.patch
  fi

  [[ $timestamp ]] || return 1

  if [[ ! -f ${name}.html ]]; then
    echo "target file ${name}.html not found, patching cancelled.." >&2
    return 1
  fi
  if ! hash sed 2>/dev/null; then
    echo "error: required external tool sed not found, exit.." >&2
    return 2
  fi
  sed -i -re "s/^(<p>Generated.from.*V.*on).*/\1 ${timestamp}/ig" ${name}.html
  return $?
}
#
#
#
bashlyk-robodoc::main "$@"
#
