#!/bin/bash -ex
PWD="$1"
GW_IP="$2"
FWD_IP="$3"

function usage(){
	echo "$0 <SSTP_PASSWORD> <GW_IP> <FORWARD_IP>"
}

if [ "$PWD" == "" ] || [ "$GW_IP" == "" ] || [ "$FWD_IP" == "" ]; then
       usage
       exit 1
fi

# stop already running client
sstp-vpn-stop.sh

#run new one
nohup sstpc --log-level 5 --log-stderr --cert-warn --user "resindevice" --password "$PWD" "$GW_IP" \
	require-mppe \
	require-mschap-v2 \
	refuse-eap \
	refuse-pap \
	refuse-chap \
	refuse-mschap \
	noauth \
	noccp \
	noaccomp \
	noipdefault \
	nomagic \
	novj \
	user "resindevice" \
	password "$PWD" &

# wait while ppp0 will be availabe
TIMEOUT_CNT=60 # timeout seconds
IFACE=""

while [ "$IFACE" == ""]; do
	ip li show dev ppp0 2>/dev/null >/dev/null && {
		IFACE=ppp0
	} || sleep 1s
done

# setup forwardings
iptables -t nat -N VPNFWDDNAT || true
iptables -t nat -A VPNFWDDNAT -i ppp0 -p tcp -m tcp -j DNAT --to-destination $FWD_IP
iptables -t nat -A VPNFWDDNAT -i ppp0 -p udp -m udp -j DNAT --to-destination $FWD_IP

iptables -t nat -N VPNFWDSNAT || true
iptables -t nat -A VPNFWDSNAT -i ppp0 -j MASQUERADE
iptables -t nat -A VPNFWDSNAT -o ppp0 -j MASQUERADE

# now setup jumps to our chains
iptables -t nat -A POSTROUTING -j VPNFWDSNAT
iptables -t nat -A PREROUTING  -j VPNFWDDNAT

#now tell gateway which device had been connected, so we can track it
GATEWAY=$(ip addr show dev ppp0 | grep inet | awk '{print $4}' | awk 'BEGIN{FS="/"}{print $1}')
wget http://$GATEWAY/sstp-vpn/?uuid="$RESIN_DEVICE_UUID" || true

