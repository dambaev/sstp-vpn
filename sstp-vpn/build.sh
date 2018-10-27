#!/bin/bash -ex

SSTP_VERSION=1.0.12

cd /usr/src/app

apt update
apt upgrade -y && apt dist-upgrade -y

# save packages db state
dpkg --get-selections > clean
dpkg -l > clean_versions

# building package

apt install -y pkg-config dh-make build-essential libevent-dev libssl-dev ppp-dev
cd /usr/src/app/sstp-client-$SSTP_VERSION
dh_make --createorig -s -y
dpkg-buildpackage -us -uc

# now remove all leftovers from building
cd /usr/src/app

dpkg --set-selections < clean
apt-get -y --force-yes dselect-upgrade
dpkg --get-selections > after
dpkg -l > after_versions
diff clean after
diff clean_versions after_versions

# now install deps and sstp-client itself
apt install -y ppp
dpkg -i sstp-client_$SSTP_VERSION-1_amd64.deb
apt install -y -f 

