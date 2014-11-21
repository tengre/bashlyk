#
# $Id$
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
: ${_bashlyk_aRequiredCmd_msg:="[ "}
: ${_bashlyk_aExport_msg:="udfEcho udfWarn udfThrow udfOnEmptyVariable udfThrowOnEmptyVariable udfWarnOnEmptyVariable udfMail \
    udfMessage udfNotify2X udfNotifyCommand udfGetXSessionProperties"}
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
  [[ -n "$1" ]] && printf "%s\n----\n" "$*"
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
#    Вывод предупреждающего сообщения. Если терминал отсутствует, то сообщение
#    передается функции udfMessage.
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то строка выводится заголовком для данных
#           из стандартного ввода, при отсутствии аргументов выдаётся содержимое
#           глобальной переменной $_bashlyk_sLastError
#  OUTPUT
#   Зависит от параметров вывода
#  EXAMPLE
#    # TODO требуется более точная проверка
#    local bNotUseLog=$_bashlyk_bNotUseLog
#    _bashlyk_bNotUseLog=0 date | udfWarn - "udfWarn test log"                  #? true
#    _bashlyk_bNotUseLog=1 date | udfWarn - "udfWarn test int"                  #? true
#    _bashlyk_bNotUseLog=$bNotUseLog
#  SOURCE
udfWarn() {
 local s
 [[ -n "$*" ]] && s="$*" || s="$(_ sLastError)"
 [[ "$_bashlyk_bNotUseLog" != "0" ]] && udfEcho $s || udfMessage $s
}
#******
#****f* libmsg/udfThrow
#  SYNOPSIS
#    udfThrow [-] errNo errMessage
#  DESCRIPTION
#    Вывод аварийного сообщения с завершением работы. Если терминал отсутствует,
#    то сообщение передается системе уведомлений.
#  INPUTS
#    -    - данные читаются из стандартного ввода
#    args - строка для вывода. Если имеется в качестве первого аргумента
#           "-", то строка выводится заголовком для данных
#           из стандартного ввода
#  OUTPUT
#   Зависит от параметров вывода
#  ## TODO добавить секцию RETURN VALUE
#  EXAMPLE
#    $(udfThrow test; true)                                                     #? false
#  SOURCE
udfThrow() {
 udfWarn $*
 (( $(_ iLastError) != 0 )) && exit $(_ iLastError) || exit 255
}
#******
#****f* libmsg/udfOnEmptyVariable
#  SYNOPSIS
#    udfOnEmptyVariable [echo|exit|return|warn|throw] <args>
#  DESCRIPTION
#    В зависимости от команды (первый аргумент) вызывает завершение сценария или выдает уведомление,
#    если последующие аргументы - имена переменных - содержат пустые значения.
#    Командой по умолчанию является завершение текущей функции с кодом ошибки
#    $(_ iErrorEmptyOrMissingArgument)
#  INPUTS
#    echo   - вывод предупреждения о пустых переменных на STDOUT
#    warn   - передача предупреждения о пустых переменных системе уведомлений со стеком вызовов
#    return - только возврат кода результата проверки имен переменных (по умолчанию, можно не указывать)
#    exit   - безусловное завершения сценария в случае пустых переменных
#    throw  - тоже самое что exit, но c выводом сообщения и стека вызовов системе уведомлений
#    args   - имена переменных
#  OUTPUT
#    Сообщение об ошибке с перечислением имен переменных, которые содержат пустые значения
#  RETURN VALUE
#    0                            - переменные не содержат пустые значения
#    iErrorEmptyOrMissingArgument - есть не инициализированные переменные
#  EXAMPLE
#    local sNoEmpty='test' sEmpty='' sEmptyMore=''
#    udfOnEmptyVariable                                       #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfOnEmptyVariable sEmpty                                #? $_bashlyk_iErrorEmptyOrMissingArgument
#    $(udfOnEmptyVariable sEmpty || exit 111)                 #? 111
#    udfOnEmptyVariable WARN sEmpty sNoEmpty sEmptyMore       #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfOnEmptyVariable Echo sEmpty sNoEmpty                  #? $_bashlyk_iErrorEmptyOrMissingArgument
#    $(udfOnEmptyVariable  Exit sEmpty >/dev/null 2>&1; true) #? $_bashlyk_iErrorEmptyOrMissingArgument
#    $(udfOnEmptyVariable Throw sEmpty >/dev/null 2>&1; true) #? $_bashlyk_iErrorEmptyOrMissingArgument
#    udfOnEmptyVariable sNoEmpty                              #? true
#  SOURCE
udfOnEmptyVariable() {
 local bashlyk_udfOnEmptyVariable_csv bashlyk_udfOnEmptyVariable_s
 local bashlyk_udfOnEmptyVariable_cmd="return" bashlyk_udfOnEmptyVariable_i=0
 case "$1" in
          [Ee][Cc][Hh][Oo]) bashlyk_udfOnEmptyVariable_cmd='retecho'; shift;;
          [Ee][Xx][Ii][Tt]) bashlyk_udfOnEmptyVariable_cmd='exit';    shift;;
          [Ww][Aa][Rr][Nn]) bashlyk_udfOnEmptyVariable_cmd='retwarn'; shift;;
      [Tt][Hh][Rr][Oo][Ww]) bashlyk_udfOnEmptyVariable_cmd='throw';   shift;;
  [Rr][Ee][Tt][Uu][Rr][Nn]) bashlyk_udfOnEmptyVariable_cmd='return';  shift;;
 esac
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument "Variable\(s\) list empty")
 for bashlyk_udfOnEmptyVariable_s in $*; do
  [[ -z "${!bashlyk_udfOnEmptyVariable_s}" ]] && {
   (( bashlyk_udfOnEmptyVariable_i == 0 )) && bashlyk_udfOnEmptyVariable_csv+="\'${bashlyk_udfOnEmptyVariable_s}\'"
   (( bashlyk_udfOnEmptyVariable_i == 1 )) && bashlyk_udfOnEmptyVariable_csv+=", \'${bashlyk_udfOnEmptyVariable_s}\'"
   bashlyk_udfOnEmptyVariable_i=1
  }
 done
 [[ -n "$bashlyk_udfOnEmptyVariable_csv" ]] && {
  eval $(udfOnError $bashlyk_udfOnEmptyVariable_cmd iErrorEmptyOrMissingArgument "Variable\(s\) $bashlyk_udfOnEmptyVariable_csv is empty...")
 }
 return 0
}
#******
#****f* libmsg/udfThrowOnEmptyVariable
#  SYNOPSIS
#    udfThrowOnEmptyVariable args
#  DESCRIPTION
#    Вызывает останов сценария, если аргументы, как имена переменных, содержат
#    пустые значения
#  INPUTS
#    args - имена переменных
#  OUTPUT
#    Сообщение об ошибке с перечислением имен переменных, которые содержат
#    пустые значения
#  RETURN VALUE
#    0                            - переменные не содержат пустые значения
#    iErrorEmptyOrMissingArgument - есть не инициализированные переменные
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''
#    udfThrowOnEmptyVariable sNoEmpty                                           #? true
#    $(udfThrowOnEmptyVariable sEmpty >/dev/null 2>&1)                          #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
udfThrowOnEmptyVariable() {
 udfOnEmptyVariable Throw $*
}
#******
#****f* libmsg/udfWarnOnEmptyVariable
#  SYNOPSIS
#    udfWarnOnEmptyVariable args
#  DESCRIPTION
#    Выдаёт предупреждение, если аргументы - имена переменных - содержат пустые
#    значения
#  INPUTS
#    args - имена переменных
#  OUTPUT
#    Сообщение об ошибке с перечислением имен переменных, которые содержат
#    пустые значения
#  RETURN VALUE
#    0                            - переменные не содержат пустые значения
#    iErrorEmptyOrMissingArgument - есть не инициализированные переменные
#  EXAMPLE
#    local sNoEmpty='test' sEmpty=''
#    udfWarnOnEmptyVariable sNoEmpty                                            #? true
#    udfWarnOnEmptyVariable sEmpty                                              #? $_bashlyk_iErrorEmptyOrMissingArgument
#  SOURCE
udfWarnOnEmptyVariable() {
 udfOnEmptyVariable Warn $*
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
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 local sTo=$_bashlyk_sLogin

 which mail >/dev/null 2>&1 || eval $(udfOnError return iErrorCommandNotFound mail)

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
#    службы уведомлений рабочего стола X-Window, почты или утилитой write
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
 local fnTmp i=$(_ iMaxOutputLines)

 udfIsNumber $i || i=9999

 udfMakeTemp fnTmp
 udfEcho $* | tee -a $fnTmp | head -n $i

 udfNotify2X $fnTmp || udfMail $fnTmp || {
  [[ -n "$_bashlyk_sLogin" ]] && cat $fnTmp | write $_bashlyk_sLogin
 }
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
 [[ -n "$1" ]] || eval $(udfOnError return iErrorEmptyOrMissingArgument)
 #
 local iTimeout=8 s

 [[ -s "$*" ]] && s="$(cat "$*")" || s="$(echo -e "$*")"

 for cmd in notify-send kdialog zenity xmessage; do
  udfNotifyCommand $cmd "$(_ emailSubj)" "$s" "$iTimeout" && break
 done
 (( $? == 0 )) || eval $(udfOnError return iErrorCommandNotFound $cmd)
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
#  EXAMPLE
#    udfGetXSessionProperties
#  SOURCE
udfGetXSessionProperties() {
 local a pid s sB sD sX sudo user userX
 #
 a="x-session-manager gnome-session gnome-session-flashback lxsession mate-session-manager openbox razorqt-session xfce4-session"
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
 [[ -n "$4" ]] || eval $(udfOnError iErrorEmptyOrMissingArgument)
 #
 local h t rc X
 udfIsNumber "$4" && t=$4 || t=8
 [[ -n "$(_ sXSessionProp)" ]] || udfGetXSessionProperties || return $?
 X=$(_ sXSessionProp)
 #
 declare -A h=(                                                                                \
  [notify-send]="$X $1 -t $t \"$2 via $1\" \"$(printf "$3")\""                                 \
  [kdialog]="$X $1 --title \"$2 via $1\" --passivepopup \"$(printf "$3")\" $t"                 \
  [zenity]="$X $1 --notification --timeout $(($t/2)) --text \"$(printf "$2 via $1\n\n$3\n")\"" \
  [xmessage]="$X $1 -center -timeout $t \"$(printf "$2 via $1\n\n$3\n")\" 2>/dev/null"         \
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
