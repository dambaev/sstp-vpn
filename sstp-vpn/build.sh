#!/bin/bash -ex

SSTP_VERSION=1.0.12

cd /usr/src/app

apt update
apt upgrade -y && apt dist-upgrade -y

# save packages db state
dpkg --get-selections > clean
dpkg -l > clean_versions

# building package

apt install -y pkg-config dh-make build-essential libevent-dev libssl-dev ppp-dev autotools-dev
cd /usr/src/app/sstp-client-$SSTP_VERSION
USER=build dh_make --createorig -s -y
# we need DEB_BUILD_OPTIONS=nocheck because build environment will not allow
# us to modify routing table
DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc

# now remove all leftovers from building
cd /usr/src/app

rm -rf ./sstp-client-$SSTP_VERSION
dpkg --clear-selections
dpkg --set-selections < clean
# mark them to remove config files as well
dpkg --get-selections | grep deinstall | awk '{print $1 " purge"}' | dpkg --set-selections
apt-get -y --force-yes dselect-upgrade
dpkg --get-selections > after
dpkg -l > after_versions
diff clean after
diff clean_versions after_versions

# now install deps and sstp-client itself
apt install -y ppp nmap tcpdump 
# this will fail due to missing deps, which we will install on the next step
dpkg -i sstp-client_${SSTP_VERSION}*.deb || true
apt install -y -f 
# we need to be sure, that plugin is available at search path for pppd
PLUGIN_PATH=$(find /usr -name sstp-pppd-plugin.so)
ln -s $PLUGIN_PATH /usr/lib/pppd/$(pppd --version 2>&1 | awk '{print $3}')/ || true # maybe it is the same path?



