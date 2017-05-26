#
# $Id: libmsg.sh 766 2017-05-26 16:33:11+04:00 toor $
#
#****h* BASHLYK/libmsg
#  DESCRIPTION
#    A set of functions for delivering messages from the script using various
#    transports:
#    - X Window System Notification System
#    - e-mail
#    - write utility
#  USES
#    libstd
#  AUTHOR
#    Damir Sh. Yakupov <yds@bk.ru>
#******
#***iV* libmsg/BASH compatibility
#  DESCRIPTION
#    Compatibility checked by bashlyk (BASH version 4.xx or more required)
#    $_BASHLYK_LIBMSG provides protection against re-using of this module
#  SOURCE
[ -n "$_BASHLYK_LIBMSG" ] && return 0 || _BASHLYK_LIBMSG=1
[ -n "$_BASHLYK" ] || . ${_bashlyk_pathLib}/bashlyk || eval '                  \
                                                                               \
    echo "[!] bashlyk loader required for ${0}, abort.."; exit 255             \
                                                                               \
'
#******
#****L* libmsg/Used libraries
# DESCRIPTION
#   Loading external libraries
# SOURCE
[[ -s ${_bashlyk_pathLib}/liberr.sh ]] && . "${_bashlyk_pathLib}/liberr.sh"
[[ -s ${_bashlyk_pathLib}/libstd.sh ]] && . "${_bashlyk_pathLib}/libstd.sh"
#******
#****G* libmsg/Global variables
#  DESCRIPTION
#    Global variables of the library
#  SOURCE
: ${HOSTNAME:=localhost}
#: ${_bashlyk_envXSession:=}
: ${_bashlyk_sLogin:=$( exec -c logname 2>/dev/null )}
: ${_bashlyk_emailSubj:="${_bashlyk_sUser}@${HOSTNAME}::${0##*/}"}

declare -rg _bashlyk_externals_msg="                                           \
                                                                               \
    grep logname mail pgrep rm stat write notify-send|kdialog|zenity|xmessage  \
                                                                               \
"

declare -rg _bashlyk_exports_msg="                                             \
                                                                               \
    msg::{echo,getXsessionProperties,mail,notify,notify2x,notifyTool,warn}     \
                                                                               \
"
#******
#****f* libmsg/msg::echo
#  SYNOPSIS
#    msg::echo [-] <text>
#  DESCRIPTION
#    Build a message from arguments and standard input
#  INPUTS
#    -      - data is read from standard input
#    <text> - is used as a header for a stream from standard input
#  EXAMPLE
#    msg::echo 'test'                >| grep -w 'test'                          #? true
#    echo body | msg::echo - subject >| md5sum | grep ^472002e8a20e4cf6d78e.*-$ #? true
#  SOURCE
msg::echo() {

  if [[ "$1" == "-" ]]; then

    shift
    [[ $1 ]] && printf -- "%s\n----\n" "$*"

    std::cat

  else

    [[ $* ]] && echo $*

  fi

}
#******
#****f* libmsg/msg::warn
#  SYNOPSIS
#    msg::warn [-] <text>
#  DESCRIPTION
#    Show input message or data from special variable. In the case of
#    non-interactive execution  message is sent notification system.
#  INPUTS
#    -      - read message from stdin
#    <text> - message string. With stdin data ("-" option required) used as
#             header. By default ${_bashlyk_sLastError[$BASHPID]}
#  OUTPUT
#   show input message or value of ${_bashlyk_sLastError[$BASHPID]}
#  EXAMPLE
#    # TODO требуется более точная проверка
#    _bashlyk_sLastError[$BASHPID]="msg::warn testing .."
#    local bNotUseLog=$_bashlyk_bNotUseLog
#    _bashlyk_bNotUseLog=1
#    msg::warn                                                                  #? true
#    _bashlyk_bNotUseLog=0
#    date | msg::warn - "bashlyk::msg::warn testing (non-interactive mode)"     #? true
#    _bashlyk_bNotUseLog=1
#    date | msg::warn - "msg::warn test int"                                    #? true
#    _bashlyk_bNotUseLog=$bNotUseLog
#  SOURCE
msg::warn() {

  local s IFS=$' \t\n'

  [[ $* ]] && s="$*" || s="${_bashlyk_sLastError[$BASHPID]}"

  [[ "$_bashlyk_bNotUseLog" != "0" ]] && msg::echo $s || msg::notify $s

}
#******
#****f* libmsg/msg::mail
#  SYNOPSIS
#    msg::mail [[-] <arg>]
#  DESCRIPTION
#    Send <text> as email
#  INPUTS
#    <arg> - if this is the name of a non-empty existing file, the data is read
#            from it, otherwise the argument string is treated as the message
#            text
#    -     - data is read from standard input
#  ERRORS
#    MissingArgument - no arguments
#    CommandNotFound - 'mail' command not found
#  EXAMPLE
#    echo "notification testing" | msg::mail - "bashlyk::msg::mail"
#    [ $? -eq $(_ iErrorCommandNotFound) -o $? -eq 0 ] && true                  #? true
#    msg::mail -
#    [ $? -eq $(_ iErrorCommandNotFound) -o $? -eq 0 ] && true                  #? true
##   see user (or aliased) mailbox for result checking
#  SOURCE
msg::mail() {

  errorify on MissingArgument $* || return
  errorify on CommandNotFound mail || return

  local sTo=$_bashlyk_sLogin IFS=$' \t\n'


  : ${sTo:=$_bashlyk_sUser}
  : ${sTo:=postmaster}

  {

    case "$1" in

      -)

         shift && msg::echo ${*:-empty message}

       ;;

      *)

         [[ -s "$*" ]] && std::cat < "$*" || echo "$*"

       ;;

    esac

  } | mail -s "${_bashlyk_emailSubj}" $_bashlyk_emailOptions $sTo

  return $?

}
#******
#****f* libmsg/msg::notify
#  SYNOPSIS
#    msg::notify [-] <text>
#  DESCRIPTION
#    Send the message to the active user of the local X-Window desktop or the
#    process owner using one of the available methods:
#    - X-Window desktop notification service
#    - e-mail
#    - 'write' utility or show to the standard output of the script
#  INPUTS
#    -      - data is read from standard input
#    <text> - is used as a header for a stream from standard input
#  ERRORS
#    MissingArgument - no input data
#  EXAMPLE
#    local sBody="notification testing" sSubj="bashlyk::msg::notify"
#    echo "$sBody" | msg::notify - "$sSubj"                                     #? true
#    [[ $rc -eq 0 ]] && sleep 1.5
#  SOURCE
msg::notify() {

  local fnTmp

  std::temp fnTmp

  ## TODO limit input data for safety
  msg::echo $* > $fnTmp

  [[ -s $fnTmp ]] || return $_bashlyk_MissingArgument

  msg::notify2x $fnTmp || msg::mail $fnTmp || {

    [[ $_bashlyk_sLogin ]] && write $_bashlyk_sLogin < $fnTmp

  } || std::cat - < $fnTmp

  rm -f $fnTmp

  return $i

}
#******
#****f* libmsg/msg::notify2x
#  SYNOPSIS
#    msg::notify2x <arg>
#  DESCRIPTION
#    Sending message through notification services based on X-Window
#  INPUTS
#    <arg> - if this is the name of a non-empty existing file, the data is read
#            from it, otherwise the argument string is treated as the message
#            text
#  ERRORS
#    MissingArgument  - no input data
#    CommandNotFound  - clients  for sending not found
#    XsessionNotFound - X-Session not found
#    NotPermitted     - not permitted
#  EXAMPLE
#    local sBody="notification testing" sSubj="bashlyk::msg::notify2x" rc
#    msg::notify2x "${sSubj}\n----\n${sBody}\n"
#    rc=$?
#    echo $rc >| grep "$(_ iErrorNotPermitted)\|$(_ iErrorXsessionNotFound)\|0" #? true
#    [[ $rc -eq 0 ]] && sleep 1.5
#  SOURCE
msg::notify2x() {

  errorify on MissingArgument $* || return

  local iTimeout=8 s IFS=$' \t\n'

  [[ -s "$*" ]] && s="$( std::cat - < "$*" )" || s="$( printf -- "$*" )"

  for cmd in notify-send kdialog zenity xmessage; do

    msg::notifyTool $cmd "$(_ emailSubj)" "$s" "$iTimeout" && break

  done

  return $?

}
#******
#****f* libmsg/msg::getXsessionProperties
#  SYNOPSIS
#    msg::getXsessionProperties
#  DESCRIPTION
#    Get some environment global variables from first local X-Window session
#  ERRORS
#    CommandNotFound  - no commands were found to send the message to the active
#                       X-Window session
#    XsessionNotFound - X-Session not found
#    NotPermitted     - not permitted
#    ## TODO improve test
#  EXAMPLE
#    msg::getXsessionProperties || echo "X-Session error ($?)"
#  SOURCE
msg::getXsessionProperties() {

  local a pid s sB sD sX sudo user userX IFS=$' \t\n'
  local -A h

  a="                                                                          \
                                                                               \
      x-session-manager gnome-session gnome-session-flashback lxsession        \
      mate-session-manager openbox razorqt-session xfce4-session kwin twin     \
                                                                               \
  "

  user=$(_ sUser)

  [[ "$user" == "root" && $SUDO_USER ]] && user=$SUDO_USER

  for s in $a; do h[$s]=1; done

  while read -t 4; do

    h[${REPLY#*Exec=}]=1

  done< <( exec -c grep '^Exec=.*' /usr/share/xsessions/*.desktop 2>/dev/null )

  for s in $a ${!h[@]}; do

    for pid in $( exec -c pgrep -f "${s##*/}" ); do

      userX=$( exec -c stat -c %U /proc/$pid )
      [[ $userX ]] || continue
      [[ "$user" == "$userX" || "$user" == "root" ]] || continue

      ## TODO many X-Sessions ?
      sB="$(exec -c grep -az DBUS_SESSION_BUS_ADDRESS= /proc/${pid}/environ)"
      sD="$(exec -c grep -az DISPLAY= /proc/${pid}/environ)"
      sX="$(exec -c grep -az XAUTHORITY= /proc/${pid}/environ)"

      [[ $sB && $sD && $sX ]] && break 2

   done

  done 2>/dev/null

  [[ $userX ]] || return $_bashlyk_iErrorXsessionNotFound

  [[ $user == $userX || $user == root ]] || return $_bashlyk_iErrorNotPermitted

  [[ $sB && $sD && $sX ]] || return $_bashlyk_iErrorMissingArgument

  [[ $(_ sUser) == root ]] && sudo="sudo -u $userX" || sudo=''

  _ sXSessionProp "$sudo $sD $sX $sB"

  return 0

}
#******
#****f* libmsg/msg::notifyTool
#  SYNOPSIS
#    msg::notifyTool <command> <title> <text> <timeout>
#  DESCRIPTION
#    Sending messages through notification services based on X-Window
#  INPUTS
#    <command> - The notification utility, in this version this is one of:
#                notify-send
#                kdialog
#                zenity
#                xmessage
#      <title> - Message header
#       <text> - Message body
#    <timeout> - Message window time
#       <user> - recipient of the message
#  ERRORS
#    MissingArgument - no arguments
#    CommandNotFound - no commands were found to send the message to the active
#                      X-Window session
#  EXAMPLE
#    local title="bashlyk::msg::notifyTool" body="notification testing"
#    local rc
#    DEBUGLEVEL=$(( DEBUGLEVEL + 1 ))
#    msg::notifyTool notify-send $title "$body" 8
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    [[ $rc -eq 0 ]] && sleep 2
#    msg::notifyTool kdialog     $title "$body" 8
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    [[ $rc -eq 0 ]] && sleep 2
#    msg::notifyTool zenity      $title "$body" 2
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    [[ $rc -eq 0 ]] && sleep 2
#    msg::notifyTool xmessage    $title "$body" 4
#    rc=$?
#    echo $? >| grep "$(_ iErrorCommandNotFound)\|0"                            #? true
#    DEBUGLEVEL=$(( DEBUGLEVEL - 1 ))
#  SOURCE
msg::notifyTool() {

  errorify on MissingArgument $* || return

  local h t rc X IFS=$' \t\n'

  std::isNumber $4 && t=$4 || t=8

  [[ $( _ sXSessionProp ) ]] || msg::getXsessionProperties || return $?

  X=$( _ sXSessionProp )
  #
  declare -A h=(                                                                                                   \
    [notify-send]="$X $1 -t $t \"$2 via $1\" \"$(printf -- "%s" "$3")\""                                           \
    [kdialog]="$X $1 --title \"$2 via $1\" --passivepopup \"$(printf -- "%s" "$3")\" $t"                           \
    [zenity]="$X $1 --notification --timeout $(($t/2)) --text \"$(printf -- "%s via %s\n\n%s\n" "$2" "$1" "$3")\"" \
    [xmessage]="$X $1 -center -timeout $t \"$(printf -- "%s via %s\n\n%s\n" "$2" "$1" "$3")\""                     \
  )

  if hash "$1" 2>/dev/null; then

    if (( DEBUGLEVEL > 0 )); then

      ## save stderr for debugging
      std::temp t keep=true prefix='msg.' suffix=".notify_command.${1}.err"

      eval "${h[$1]}" 2>$t
      rc=$?

      [[ -s $t ]] && printf -- "\n%s status: %s\n" "$1" "$rc" >> $t || rm -f $t

    else

      eval "${h[$1]}"
      rc=$?

    fi

    ## TODO workaround for zenity
    [[ "$1" == "zenity" && "$rc" == "5" ]] && rc=0

  else

    err::status CommandNotFound "$1"
    rc=$?

  fi

  return $rc

}
#******
