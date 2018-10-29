#!/bin/bash -ex

killall sstpc || true

# flush iptables chains
iptables -t nat -F VPNFWDSNAT || true
iptables -t nat -F VPNFWDDNAT || true

# remove POSTROUTING and PREROUTING jumps
SNAT_LIST=$(iptables -t nat -vnL POSTROUTING --line-numbers | grep VPNFWDSNAT || echo "")
DNAT_LIST=$(iptables -t nat -vnL PREROUTING --line-numbers | grep VPNFWDDNAT || echo "")

while [ "$SNAT_LIST" != "" ]; do
	LINENUM=$(echo $SNAT_LIST | awk '{print $1}')
	iptables -t nat -D POSTROUTING $LINENUM
	SNAT_LIST=$(iptables -t nat -vnL POSTROUTING --line-numbers | grep VPNFWDSNAT || echo "")
done

while [ "$DNAT_LIST" != "" ]; do
	LINENUM=$(echo $DNAT_LIST | awk '{print $1}')
	iptables -t nat -D PREROUTING $LINENUM
	DNAT_LIST=$(iptables -t nat -vnL PREROUTING --line-numbers | grep VPNFWDDNAT || echo "")
done


