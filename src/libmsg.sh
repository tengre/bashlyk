#
# $Id: libmsg.sh 543 2016-08-19 14:43:43+04:00 toor $
#
#****h* BASHLYK/libmsg
#  DESCRIPTION
#    стандартный набор функций, включает автоматически управляемые функции вывода сообщений
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#****d* libmsg/Once required
#  DESCRIPTION
#    Эта глобальная переменная обеспечивает защиту от повторного использования данного модуля
#    Отсутствие значения $BASH_VERSION предполагает несовместимость c текущим командным интерпретатором
#  SOURCE
[ -n "$BASH_VERSION" ] || eval 'echo "bash interpreter for this script ($0) required ..."; exit 255'

[[ -n "$_BASHLYK_LIBMSG" ]] && return 0 || _BASHLYK_LIBMSG=1
#******
#****** libmsg/External Modules
# DESCRIPTION
#   Using modules section
#   Здесь указываются модули, код которых используется данной библиотекой
# SOURCE
: ${_bashlyk_pathLib:=/usr/share/bashlyk}
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
#******
#****v* libmsg/Init section
#  DESCRIPTION
: ${_bashlyk_sUser:=$USER}
: ${_bashlyk_sLogin:=$(logname 2>/dev/null)}
: ${HOSTNAME:=$(hostname 2>/dev/null)}
: ${_bashlyk_bNotUseLog:=1}
: ${_bashlyk_emailRcpt:=postmaster}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${_bashlyk_s0}"}
: ${_bashlyk_envXSession:=}
: ${_bashlyk_aRequiredCmd_msg:="cat cut echo grep head mail printf ps rm sort  \
  stat tee uniq which write notify-send|kdialog|zenity|xmessage"}
: ${_bashlyk_aExport_msg:="udfEcho udfGetXSessionProperties udfMail udfMessage \
  udfNotify2X udfNotifyCommand udfWarn"}
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
  [[ -n "$1" ]] && printf -- "%s\n----\n" "$*"
  ## TODO alarm required...
  cat
 else
  [[ -n "$1" ]] && echo $*
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

	[[ -n "$*" ]] && s="$*" || s="${_bashlyk_sLastError[$BASHPID]}"

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
#  RETURN VALUE
#    0                            - сообщение успешно отправлено
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorCommandNotFound        - команда не найдена
#  EXAMPLE
##  TODO уточнить по каждому варианту
#    local emailOptions=$(_ emailOptions)
#    _ emailOptions '-v'
#    echo "notification testing" | udfMail - "bashlyk::libmsg::udfMail"
#    [ $? -eq $(_ iErrorCommandNotFound) -o $? -eq 0 ] && true                  #? true
#    _ emailOptions "$emailOptions"
#  SOURCE
udfMail() {
 local sTo=$_bashlyk_sLogin IFS=$' \t\n'
 #
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 which mail >/dev/null 2>&1 || eval $(udfOnError return iErrorCommandNotFound 'mail')

 [[ -n "$sTo" ]] || sTo=$_bashlyk_sUser
 [[ -n "$sTo" ]] || sTo=postmaster

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
#  RETURN VALUE
#    0   - сообщение успешно отправлено (передано выбранному транспорту)
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorCommandNotFound        - команда не найдена
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
  [[ -n "$_bashlyk_sLogin" ]] && write $_bashlyk_sLogin < $fnTmp
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
#  RETURN VALUE
#    0                            - сообщение успешно отправлено
#    iErrorEmptyOrMissingArgument - аргумент не задан
#    iErrorCommandNotFound        - команда не найдена
#    iErrorXsessionNotFound       - X-сессия не обнаружена
#    iErrorNotPermitted           - не разрешено
#  EXAMPLE
#    local sBody="notification testing" sSubj="bashlyk::libmsg::udfNotify2X" rc
#    udfNotify2X "${sSubj}\n----\n${sBody}\n"
#    rc=$?
#    echo "$?" >| grep "$(_ iErrorNotPermitted)\|$(_ iErrorXsessionNotFound)\|0" #? true
#    [[ $rc -eq 0 ]] && sleep 2
#  SOURCE
udfNotify2X() {
 local iTimeout=8 s IFS=$' \t\n'
 #
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 [[ -s "$*" ]] && s="$(< "$*")" || s="$(echo -e "$*")"

 for cmd in notify-send kdialog zenity xmessage; do
  udfNotifyCommand $cmd "$(_ emailSubj)" "$s" "$iTimeout" && break
 done
 (( $? == 0 )) || eval $(udfOnError return iErrorCommandNotFound '$cmd')
 return 0
}
#******
#****f* libmsg/udfGetXSessionProperties
#  SYNOPSIS
#    udfGetXSessionProperties
#  DESCRIPTION
#    установить некоторые переменные среды первой локальной X-сессии
#  RETURN VALUE
#    0                            - сообщение успешно отправлено
#    iErrorCommandNotFound        - команда не найдена
#    iErrorXsessionNotFound       - X-сессия не обнаружена
#    iErrorNotPermitted           - не разрешено
#    ## TODO улучшить тест
#  EXAMPLE
#    udfGetXSessionProperties || echo "X-Session error ($?)"
#  SOURCE
udfGetXSessionProperties() {
 local a pid s sB sD sX sudo user userX IFS=$' \t\n'
 #
 a="x-session-manager gnome-session gnome-session-flashback lxsession mate-session-manager openbox razorqt-session xfce4-session kwin twin"
 user=$(_ sUser)
 #
 [[ "$user" == "root" && -n "$SUDO_USER" ]] && user=$SUDO_USER

 a+=" $(grep "Exec=.*" /usr/share/xsessions/*.desktop 2>/dev/null | cut -f 2 -d"=" | sort | uniq )"

 for s in $a; do
  for pid in $(ps -C ${s##*/} -o pid=); do
   userX=$(stat -c %U /proc/$pid)
   [[ -n "$userX" ]] || continue
   [[ "$user" == "$userX" || "$user" == "root" ]] || continue
   ## TODO если много X-сессий - позволить rootу выбирать оптимальный
   sB="$(grep -az DBUS_SESSION_BUS_ADDRESS= /proc/${pid}/environ)"
   sD="$(grep -az DISPLAY= /proc/${pid}/environ)"
   sX="$(grep -az XAUTHORITY= /proc/${pid}/environ)"
   [[ -n "$sB" && -n "$sD" && -n "$sX" ]] && break 2
  done
 done

 [[ -n "$userX" ]] || eval $(udfOnError return iErrorXsessionNotFound)
 [[ "$user" == "$userX" || "$user" == "root" ]] || eval $(udfOnError return iErrorNotPermitted)
 [[ -n "$sB" && -n "$sD" && -n "$sX" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
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
#  RETURN VALUE
#    0                            - сообщение успешно отправлено
#    iErrorEmptyOrMissingArgument - аргументы не заданы
#    iErrorCommandNotFound        - команда не найдена
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
 local h t rc X IFS=$' \t\n'
 #
 [[ -n "$4" ]] || eval $(udfOnError iErrorEmptyOrMissingArgument)
 #
 udfIsNumber "$4" && t=$4 || t=8
 [[ -n "$(_ sXSessionProp)" ]] || udfGetXSessionProperties || return $?
 X=$(_ sXSessionProp)
 #
 declare -A h=(                                                                                                  \
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
  rc=$(_ iErrorCommandNotFound)
  udfSetLastError $rc "$1"
 fi

 return $rc
}
#******
