#
# $Id: libmsg.sh 658 2017-01-20 16:16:05+04:00 toor $
#
#****h* BASHLYK/libmsg
#  DESCRIPTION
#    стандартный набор функций, включает автоматически управляемые функции вывода сообщений
#  USES
#    libstd
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* liberr/BASH Compability
#  DESCRIPTION
#    BASH version 4.xx or more required for this script
#  SOURCE
[ -n "$BASH_VERSION" ] && (( ${BASH_VERSINFO[0]} >= 4 )) || eval '             \
                                                                               \
    echo "[!] BASH shell version 4.xx required for ${0}, abort.."; exit 255    \
                                                                               \
'
#******
#  $_BASHLYK_LIBMSG provides protection against re-using of this module
[[ $_BASHLYK_LIBMSG ]] && return 0 || _BASHLYK_LIBMSG=1
#****L* libmsg/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****G* libmsg/Global variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_envXSession:=}

declare -rg _bashlyk_externals_msg="                                           \
                                                                               \
    cat cut echo grep head hostname logname mail printf ps rm sort             \
    stat tee uniq which write notify-send|kdialog|zenity|xmessage              \
                                                                               \
"
declare -rg _bashlyk_exports_msg="                                             \
                                                                               \
    udfEcho udfGetXSessionProperties udfMail udfMessage udfNotify2X            \
    udfNotifyCommand udfWarn                                                   \
                                                                               \
"
#******
#****f* libmsg/udfEcho
#  SYNOPSIS
#    udfEcho [-] args
#  DESCRIPTION
#    Сборка сообщения из аргументов и стандартного ввода
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то эта строка выводится заголовком для данных
#           из стандартного ввода
#  OUTPUT
#   Зависит от параметров вывода
#  EXAMPLE
#    udfEcho 'test' >| grep -w 'test'                                           #? true
#    echo body | udfEcho - subject | tr -d '\n' >| grep -w "^subject----body$"  #? true
#  SOURCE
udfEcho() {

  if [[ "$1" == "-" ]]; then

    shift
    [[ $1 ]] && printf -- "%s\n----\n" "$*"
    ## TODO alarm required...
    cat

  else

    [[ $1 ]] && echo $*

  fi

}
#******
#****f* libmsg/udfWarn
#  SYNOPSIS
#    udfWarn [-] args
#  DESCRIPTION
#    Show input message or data from special variable. In the case of
#    non-interactive execution  message is sent notification system.
#  INPUTS
#    -    - read message from stdin
#    args - message string. With stdin data ("-" option required) used as header
#           By default ${_bashlyk_sLastError[$BASHPID]}
#  OUTPUT
#   show input message or value of ${_bashlyk_sLastError[$BASHPID]}
#  EXAMPLE
#    # TODO требуется более точная проверка
#    _bashlyk_sLastError[$BASHPID]="udfWarn testing .."
#    local bNotUseLog=$_bashlyk_bNotUseLog
#    _bashlyk_bNotUseLog=1
#    udfWarn                                                                    #? true
#    _bashlyk_bNotUseLog=0
#    date | udfWarn - "bashlyk::libmsg::udfWarn testing (non-interactive mode)" #? true
#    _bashlyk_bNotUseLog=1
#    date | udfWarn - "udfWarn test int"                                        #? true
#    _bashlyk_bNotUseLog=$bNotUseLog
#  SOURCE
udfWarn() {

  local s IFS=$' \t\n'

  [[ $* ]] && s="$*" || s="${_bashlyk_sLastError[$BASHPID]}"

  [[ "$_bashlyk_bNotUseLog" != "0" ]] && udfEcho $s || udfMessage $s

}
#******
#****f* libmsg/udfMail
#  SYNOPSIS
#    udfMail [[-] arg]
#  DESCRIPTION
#    Передача сообщения по почте
#  INPUTS
#    arg -  Если это имя непустого существующего файла, то выполняется попытка
#           чтения из него, иначе строка аргументов воспринимается как текст
#           сообщения
#    -   -  данные читаются из стандартного ввода
#  ERRORS
#    MissingArgument - аргумент не задан
#    CommandNotFound - команда не найдена
#  EXAMPLE
##  TODO уточнить по каждому варианту
#    ##local emailOptions=$(_ emailOptions)
#    ##_ emailOptions '-v'
#    echo "notification testing" | udfMail - "bashlyk::libmsg::udfMail"
#    [ $? -eq $(_ iErrorCommandNotFound) -o $? -eq 0 ] && true                  #? true
#    ##_ emailOptions "$emailOptions"
#  SOURCE
udfMail() {

  udfOn MissingArgument $1 || return $?

  local sTo=$_bashlyk_sLogin IFS=$' \t\n'

  which mail >/dev/null 2>&1 || eval $(udfOnError return CommandNotFound 'mail')

  [[ $sTo ]] || sTo=$_bashlyk_sUser
  [[ $sTo ]] || sTo=postmaster

  {

    case "$1" in

      -)
         udfEcho $*
       ;;

      *)
         [[ -s "$*" ]] && cat "$*" || echo "$*"
       ;;

    esac

  } | mail -e -s "${_bashlyk_emailSubj}" $_bashlyk_emailOptions $sTo

  return $?

}
#******
#****f* libmsg/udfMessage
#  SYNOPSIS
#    udfMessage [-] [args]
#  DESCRIPTION
#    Передача сообщения владельцу процесса по одному из доступных способов:
#    службы уведомлений рабочего стола X-Window, почты, утилитой write или
#    стандартный вывод сценария
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то эта строка выводится заголовком для данных
#           из стандартного ввода
#  ERRORS
#    MissingArgument - аргумент не задан
#    CommandNotFound - команда не найдена
#  EXAMPLE
#    local sBody="notification testing" sSubj="bashlyk::libmsg::udfMessage"
#    echo "$sBody" | udfMessage - "$sSubj"                                      #? true
#    [[ $? -eq 0 ]] && sleep 2
#  SOURCE
udfMessage() {

  local fnTmp i=$(_ iMaxOutputLines) IFS=$' \t\n'

  udfIsNumber $i || i=9999

  udfMakeTemp fnTmp
  udfEcho $* | tee -a $fnTmp | head -n $i

  udfNotify2X $fnTmp || udfMail $fnTmp || {

    [[ $_bashlyk_sLogin ]] && write $_bashlyk_sLogin < $fnTmp

  } || cat $fnTmp

  i=$?
  rm -f $fnTmp

  return $i

}
#******
#****f* libmsg/udfNotify2X
#  SYNOPSIS
#    udfNotify2X arg
#  DESCRIPTION
#    Передача сообщения через службы уведомления, основанные на X-Window
#  INPUTS
#    arg -  Если это имя непустого существующего файла, то выполняется попытка
#           чтения из него, иначе строка аргументов воспринимается как текст
#           сообщения
#  ERRORS
#    MissingArgument  - аргумент не задан
#    CommandNotFound  - команда не найдена
#    XsessionNotFound - X-сессия не обнаружена
#    NotPermitted     - не разрешено
#  EXAMPLE
#    local sBody="notification testing" sSubj="bashlyk::libmsg::udfNotify2X" rc
#    udfNotify2X "${sSubj}\n----\n${sBody}\n"
#    rc=$?
#    echo "$?" >| grep "$(_ iErrorNotPermitted)\|$(_ iErrorXsessionNotFound)\|0" #? true
#    [[ $rc -eq 0 ]] && sleep 2
#  SOURCE
udfNotify2X() {

  udfOn MissingArgument $1 || return $?

  local iTimeout=8 s IFS=$' \t\n'

  [[ -s "$*" ]] && s="$(< "$*")" || s="$(echo -e "$*")"

  for cmd in notify-send kdialog zenity xmessage; do

    udfNotifyCommand $cmd "$(_ emailSubj)" "$s" "$iTimeout" && break

  done

  (( $? == 0 )) || eval $( udfOnError return CommandNotFound '$cmd' )

  return 0

}
#******
#****f* libmsg/udfGetXSessionProperties
#  SYNOPSIS
#    udfGetXSessionProperties
#  DESCRIPTION
#    установить некоторые переменные среды первой локальной X-сессии
#  ERRORS
#    CommandNotFound  - команда не найдена
#    XsessionNotFound - X-сессия не обнаружена
#    NotPermitted     - не разрешено
#    ## TODO улучшить тест
#  EXAMPLE
#    udfGetXSessionProperties || echo "X-Session error ($?)"
#  SOURCE
udfGetXSessionProperties() {

  local a pid s sB sD sX sudo user userX IFS=$' \t\n'

  a="x-session-manager gnome-session gnome-session-flashback lxsession mate-session-manager openbox razorqt-session xfce4-session kwin twin"
  user=$(_ sUser)

  [[ "$user" == "root" && $SUDO_USER ]] && user=$SUDO_USER

  a+=" $(grep "Exec=.*" /usr/share/xsessions/*.desktop 2>/dev/null | cut -f 2 -d"=" | sort | uniq )"

  for s in $a; do

    for pid in $(pgrep -f "${s##*/}"); do

      userX=$(stat -c %U /proc/$pid)
      [[ -n "$userX" ]] || continue
      [[ "$user" == "$userX" || "$user" == "root" ]] || continue

      ## TODO many X-Sessions ?
      sB="$(grep -az DBUS_SESSION_BUS_ADDRESS= /proc/${pid}/environ)"
      sD="$(grep -az DISPLAY= /proc/${pid}/environ)"
      sX="$(grep -az XAUTHORITY= /proc/${pid}/environ)"

      [[ $sB && $sD && $sX ]] && break 2

   done

  done 2>/dev/null

  [[ $userX ]] || eval $(udfOnError return XsessionNotFound)

  [[ "$user" == "$userX" || "$user" == "root" ]] \
    || eval $(udfOnError return NotPermitted)

  [[ $sB && $sD && $sX ]] || eval $( udfOnError return MissingArgument )

  [[ "$(_ sUser)" == "root" ]] && sudo="sudo -u $userX" || sudo=''

  _ sXSessionProp "$sudo $sD $sX $sB"

  return 0

}
#******
#****f* libmsg/udfNotifyCommand
#  SYNOPSIS
#    udfNotifyCommand command title text timeout
#  DESCRIPTION
#    Передача сообщения через службы уведомления, основанные на X-Window
#  INPUTS
#    command - утилита для выдачи уведомления, в данной версии это одно из
#              notify-send kdialog zenity xmessage
#      title - заголовок сообщения
#       text - текст сообщения
#    timeout - время показа окна сообщения
#       user - получатель сообщения
#  ERRORS
#    MissingArgument - аргументы не заданы
#    CommandNotFound - команда не найдена
#  EXAMPLE
#    local title="bashlyk::libmsg::udfNotifyCommand" body="notification testing"
#    local rc
#    udfNotifyCommand notify-send $title "$body" 8
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    [[ $rc -eq 0 ]] && sleep 2
#    udfNotifyCommand kdialog     $title "$body" 8
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    [[ $rc -eq 0 ]] && sleep 2
#    udfNotifyCommand zenity      $title "$body" 2
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    [[ $rc -eq 0 ]] && sleep 2
#    udfNotifyCommand xmessage    $title "$body" 4
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#  SOURCE
udfNotifyCommand() {

  udfOn MissingArgument $4 || return $?

  local h t rc X IFS=$' \t\n'

  udfIsNumber $4 && t=$4 || t=8

  [[ $(_ sXSessionProp) ]] || udfGetXSessionProperties || return $?

  X=$(_ sXSessionProp)
  #
  declare -A h=(                                                                                                   \
    [notify-send]="$X $1 -t $t \"$2 via $1\" \"$(printf -- "%s" "$3")\""                                           \
    [kdialog]="$X $1 --title \"$2 via $1\" --passivepopup \"$(printf -- "%s" "$3")\" $t"                           \
    [zenity]="$X $1 --notification --timeout $(($t/2)) --text \"$(printf -- "%s via %s\n\n%s\n" "$2" "$1" "$3")\"" \
    [xmessage]="$X $1 -center -timeout $t \"$(printf -- "%s via %s\n\n%s\n" "$2" "$1" "$3")\" 2>/dev/null"         \
  )

  if [[ -x "$(which "$1")" ]]; then

    eval "${h[$1]}"
    rc=$?
    [[ "$1" == "zenity" && "$rc" == "5" ]] && rc=0

  else

    rc=$( _ iErrorCommandNotFound )
    udfSetLastError $rc "$1"

  fi

  return $rc

}
#******
