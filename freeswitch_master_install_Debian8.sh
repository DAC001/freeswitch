#!/bin/bash

echo '########## This script prepares a Debian 8(Jessie) x64 system for the ######'
echo '########## Freeswitch requirements and install ######'
echo '########## By: Sylvester Mitchell ###### June 13, 2015 #####################'

echo
echo
sleep 3
echo 'Enable non free repository'
sleep 2
echo "" >> /etc/apt/sources.list
echo "#nonfree" >> /etc/apt/sources.list
echo "deb http://ftp.us.debian.org/debian/ jessie main contrib non-free" >> /etc/apt/sources.list
echo "deb-src http://ftp.us.debian.org/debian/ jessie main contrib non-free" >> /etc/apt/sources.list
sleep 2

echo 'Adding freeswitch video repository'
sleep 2
echo "" >> /etc/apt/sources.list
echo "#freeswitch video" >> /etc/apt/sources.list
echo "deb http://files.freeswitch.org/repo/deb/debian/ jessie main" >> /etc/apt/sources.list
wget -O - http://files.freeswitch.org/repo/deb/debian/key.gpg |apt-key add -


echo 'Updating operating system'
sleep 2

apt-get -y update
apt-get -y upgrade

sleep 3

echo 'Lets update the time'
apt-get -y install ntp ntpdate
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
ntpdate time-a.nist.gov

DEBIAN_FRONTEND=none APT_LISTCHANGES_FRONTEND=none apt-get install -y --force-yes freeswitch-video-deps-most

sleep 3

apt-get -y install gcc g++ automake wget make git subversion chkconfig nano
apt-get -y install libtool autoconf cmake pkg-config nasm bzip2 libtool
apt-get -y install openjdk-7-jdk lua5.2 lua5.2-dev libmad0-dev libavcodec-dev 
apt-get -y install libspeexdsp1 libspeexdsp-dev libltdl-dev

sleep 2 
echo 'Installing Freeswitch'
sleep 2

cd /usr/src
git clone https://freeswitch.org/stash/scm/fs/freeswitch.git freeswitch.git
cd freeswitch.git
./bootstrap.sh
./configure -C

perl -i -pe 's/#formats\/mod_vlc/formats\/mod_vlc/g' modules.conf
perl  -i -pe 's/#applications\/mod_av/applications\/mod_av/g' modules.conf

make
make install
make cd-sounds-install cd-moh-install samples

sleep 2
echo 'Adjusting kernel settings'
sleep 2 
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.d/vid.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.d/vid.conf
echo 'kernel.core_pattern = core.%p' >> /etc/sysctl.d/vid.conf

sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216
sysctl -w kernel.core_pattern=core.%p

cp /usr/local/freeswitch/bin/fs_cli /usr/bin

cd /usr/src
wget https://github.com/DAC001/freeswitch/raw/master/freeswitch.txt
cp freeswitch.txt /etc/init.d/freeswitch
chmod +x /etc/init.d/freeswitch
chkconfig --add freeswitch

sleep 2 
echo 'Fixing permissions and adding freeswitch user'
sleep 2 
/bin/echo "adding freeswitch user"
	/usr/sbin/adduser --disabled-password  --quiet --system \
		--home /usr/local/freeswitch \
		--gecos "FreeSWITCH Voice Platform" --ingroup daemon \
		freeswitch
		
if [ $? -ne 0 ]; then
		#previous had an error
		/bin/echo "ERROR: Failed adding freeswitch user."
		exit 1
	fi
	#fi

	/usr/sbin/adduser freeswitch audio
	/usr/sbin/groupadd freeswitch

	/bin/chown -R freeswitch:daemon /usr/local/freeswitch/

	/bin/echo "removing 'other' permissions on freeswitch"
	/bin/chmod -R o-rwx /usr/local/freeswitch/
	/bin/echo
	cd /usr/local/
	/bin/chown -R freeswitch:daemon /usr/local/freeswitch
	/bin/echo "FreeSWITCH directories now owned by freeswitch.daemon"
	/usr/bin/find freeswitch -type d -exec /bin/chmod u=rwx,g=srx,o= {} \;
	/bin/echo "FreeSWITCH directories now sticky group. This will cause any files created"
	/bin/echo "  to default to the daemon group so FreeSWITCH can read them"
	/bin/echo




echo 'Freeswitch Installation complete....'





