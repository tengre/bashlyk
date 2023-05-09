#!/usr/bin/env bash
#
# $Git: bashlyk-robodoc.sh 1.96-3-941 2023-05-09 14:14:13+00:00 yds $
#
_bashlyk=bashlyk . bashlyk
#
#
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
#                        current folder
#    -n, --name <name> - project name, by default short name of current folder
#  USES
#    bashlyk >= 1.96
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#  EXAMPLE
#    bashlyk-robodoc
	EOF
  exit $rc
}
bashlyk-robodoc::main() {
  exit+echo on CommandNotFound basename date head grep patch pwd robodoc sed

  local name path timestamp

  CFG cfg
  cfg.bind.cli help{h} path{p}: name{n}:

  [[ $(cfg.getopt help) ]] && kolchan-robodoc::usage

  name=$(cfg.getopt name) || name=$(basename $(pwd))
  path=$(cfg.getopt path) || path=.

  if [[ -s ${path}/VERSION ]]; then
    timestamp="$(head -n 1 ${path}/VERSION | grep -Po '\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}')"
    [[ $timestamp ]] || timestamp="$(exec -c date --rfc-3339=s -u)"
  fi

  exit+echo on NoSuchFile ${path}/robodoc.rc

  if ! robodoc; then
    return $?
  fi

  exit+echo on NoSuchDir ${path}/doc
  cd ${path}/doc || error NotPermitted throw -- ${path}/doc
  exit+echo on NoSuchFile ${name}.html.patch
  patch < ${name}.html.patch
  exit+echo on EmptyVariable timestamp
  exit+echo on NoSuchFile ${name}.html
  sed -i -re "s/^(<p>Generated.from.*V.*on).*/\1 ${timestamp}/ig" ${name}.html
  return $?
}
#
#
#
bashlyk-robodoc::main
#
