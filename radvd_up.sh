#!/bin/sh
if test $PPP_IPPRARM != pptpd ;then
        exit 0
fi

ADDR=$(echo $PPP_REMOTE | cut -d : -f 3,4,5,6)

if test x$ADDR == x ; then
        echo "Unable to generate IPv6 Address"
        exit 0
fi
ADDR=2001:470:8192:BEEF:$ADDR

#add route
route -6 add $ADDR/128 dev $PPP_IFACE

#generate radvd config
RAP=/etc/ppp/ipv6-radvd/$PPP_IFACE
RA=$RAP.conf

cat <<EOF >$RA
interface $PPP_IFACE{
        AdvManagedFlag off;
        AdvOtherConfigFlag on;
        AdvSendAdvert on;
        MinRtrAdvInterval 5;
        MaxRtrAdvInterval 100;
        UnicastOnly on;
        AdvSourceLLAddress on;
        prefix 2001:470:8192:BEEF::/64 {};
};
EOF

#start radvd
/usr/sbin/radvd -C $RA -p $RAP.pid

#start tchdpd
/usr/sbin/tdhcpd \
 --dns-server=2001:470:20::2 \
 --dns-name=$PPP_IFACE.tunnel.ipv6.icybear.net \
 --pid-file=$RAP.dhcp.pid \
 --local-id=tunnel.ipv6.icybear.net -L debug\
 $PPP_IFACE

#update dns
ARPA=$(ipv6_rev $ADDR)
nsupdate << EOF
update delete $ARPA
update add $ARPA 10 ptr $PPP_IFACE.tunnel.ipv6.icybear.net
send
update delete $PPP_IFACE.tunnel.ipv6.icybear.net
update add $PPP_IFACE.tunnel.ipv6.icybear.net 10 aaaa $ADDR
send
EOF

exit 0