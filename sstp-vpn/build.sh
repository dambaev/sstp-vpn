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
DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc || {
	cat src/test-suite.log
	exit 1
}

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

