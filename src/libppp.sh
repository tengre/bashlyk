#
# $Id$
#
[ -n "$1" ] &&  ipPeerC=$1
[ -n "$2" ] && sPeerISP=$2
[ -n "$3" ] &&  ipPeerO=$3

udfExitIfNoTrustRemotePeer(){
 [ -n "$1" ] && ipPeerO=$1
 [ -n "$ipPeerO" ] || return -1 
 [ -n "$PPP_REMOTE" ] && local ipPeerC=$PPP_REMOTE
 [ "$ipPeerC" != "$ipPeerO" ] && exit 0
 return 0
}

udfExitIfNoTrustLocalPeer(){
 [ -n "$1" ] && ipPeerO=$1
 [ -n "$ipPeerO" ] || return -1
 [ -n "$PPP_LOCAL" ] && local ipPeerC=$PPP_LOCAL
 [ "$ipPeerC" != "$ipPeerO" ] && exit 0
 return 0
}

udfExitIfTrustLocalPeer(){
 [ -n "$1" ] && ipPeerO=$1
 [ -n "$ipPeerO" ] || return -1
 [ -n "$PPP_LOCAL" ] && local ipPeerC=$PPP_LOCAL
 [ "$ipPeerC" = "$ipPeerO" ] && exit 0
 return 0
}
#
 ipPeerLocal=$PPP_LOCAL
ipPeerRemote=$PPP_REMOTE
#