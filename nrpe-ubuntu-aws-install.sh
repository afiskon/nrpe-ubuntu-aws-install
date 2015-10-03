#!/bin/sh

set -e

#sudo useradd nagios

sudo apt-get update
sudo apt-get install -y build-essential openssl libssl-dev xinetd

mkdir /tmp/nrpe-buid
cd /tmp/nrpe-buid
wget http://iweb.dl.sourceforge.net/project/nagios/nrpe-2.x/nrpe-2.15/nrpe-2.15.tar.gz
tar -xvzf nrpe-2.15.tar.gz
cd nrpe-2.15/

./configure --enable-command-args --with-nagios-user=nagios \
  --with-nagios-group=nagios --with-ssl=/usr/bin/openssl \
  --with-ssl-lib=/usr/lib/x86_64-linux-gnu
 
make all
sudo make install
sudo make install-xinetd
sudo make install-daemon-config

cat > nrpe.diff << EOF
15c15
< 	only_from       = 127.0.0.1
---
> 	only_from       = 127.0.0.1 172.16.0.0/12
EOF

sudo patch /etc/xinetd.d/nrpe nrpe.diff

sudo service xinetd restart

cd /tmp/nrpe-buid
mkdir nagios-plugins
cd nagios-plugins
wget http://nagios-plugins.org/download/nagios-plugins-2.1.1.tar.gz
tar -xvzf nagios-plugins-2.1.1.tar.gz
cd nagios-plugins-2.1.1
./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl
make
sudo make install

sudo sh -c 'wget https://raw.githubusercontent.com/justintime/nagios-plugins/master/check_mem/check_mem.pl -O /usr/local/nagios/libexec/check_mem'
sudo chmod a+x /usr/local/nagios/libexec/check_mem

cat > nrpe.cfg.diff << EOF
221c221,222
< command[check_hda1]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /dev/hda1
---
> command[check_mem]=/usr/local/nagios/libexec/check_mem -u -C -w 80 -c 90
> command[check_disk]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /
224d224
< 
EOF

sudo patch /usr/local/nagios/etc/nrpe.cfg nrpe.cfg.diff

