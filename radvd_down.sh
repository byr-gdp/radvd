#!/bin/sh
RAP=/etc/ppp/ipv6-radvd/$PPP_IFACE
kill `cat $RAP.pid` || true
kill `cat $RAP.dhcp.pid` || true
rm -f $RAP.*
ADDR=$(echo $PPP_REMOTE | cut -d : -f 3,4,5,6)
ADDR=2001:470:8192:BEEF:$ADDR
ARPA=$(ipv6_rev $ADDR)
nsupdate << EOF
update delete $ARPA
send
update delete $PPP_IFACE.tunnel.ipv6.icybear.net
send
EOF
exit 0