#!/bin/sh

check_package()
{
  dpkg -l $1 >/dev/null 2>&1 
  if [ $? -ne 0 ]
  then
    echo "Package $1 not installed"
    exit 1
  fi
}

make_chroot_php()
{
  CHROOT=$1
  USER=$2
  GROUP=$3
  UID=$4
  GID=$5
  ZONEINFO=$6

  install -m 755 -o root -g root -d $CHROOT/
  install -m 755 -o root -g root -d $CHROOT/etc/
  install -m 755 -o root -g root -d $CHROOT/dev/
  install -m 755 -o root -g root -d $CHROOT/lib/
  install -m 755 -o root -g root -d $CHROOT/lib64/
  install -m 750 -o $USER -g $GROUP -d $CHROOT/site/
  install -m 777 -o root -g root -d $CHROOT/tmp/
  install -m 755 -o root -g root -d $CHROOT/usr/
  install -m 755 -o root -g root -d $CHROOT/var/
  install -m 755 -o root -g root -d $CHROOT/var/log/
  install -m 755 -o root -g root -d $CHROOT/var/lib/
  install -m 755 -o root -g root -d $CHROOT/var/lib/php5/
  install -m 755 -o $USER -g $GROUP -d $CHROOT/var/lib/php5/sessions/
  mknod -m 644 $CHROOT/dev/urandom c 1 9

  check_package libc6:amd64
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libresolv.so.2 $CHROOT/lib/
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libnss_compat.so.2 $CHROOT/lib/
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libnss_files.so.2 $CHROOT/lib/
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libnss_dns.so.2 $CHROOT/lib/

  cat > $CHROOT/etc/nsswitch.conf <<END
passwd:         compat
group:          compat
shadow:         compat

hosts:          files dns
networks:       files

protocols:      files
services:       files
ethers:         files
rpc:            files
END
  chown root:root $CHROOT/etc/nsswitch.conf
  chmod 644 $CHROOT/etc/nsswitch.conf

  cat > $CHROOT/etc/passwd <<END
root:x:0:0:root:/:/bin/sh
$USER:x:$UID:$GID:$USER:/:/bin/sh
END
  chown root:root $CHROOT/etc/passwd
  chmod 644 $CHROOT/etc/passwd

  cat > $CHROOT/etc/shadow <<END
root:!:0:0:99999:7:::
$USER:!:0:0:99999:7:::
END
  chown root:root $CHROOT/etc/shadow
  chmod 600 $CHROOT/etc/shadow

  cat > $CHROOT/etc/group <<END
root:x:0:
$GROUP:x:$GID:
END
  chown root:root $CHROOT/etc/group
  chmod 644 $CHROOT/etc/group

  cat > $CHROOT/etc/hosts <<END
127.0.0.1       localhost
END
  chown root:root $CHROOT/etc/hosts
  chmod 644 $CHROOT/etc/hosts

  cat > $CHROOT/etc/networks <<END
default         0.0.0.0
loopback        127.0.0.0
link-local      169.254.0.0
END
  chown root:root $CHROOT/etc/networks
  chmod 644 $CHROOT/etc/networks

  cat > $CHROOT/etc/resolv.conf <<END
nameserver      127.0.0.1
END
  chown root:root $CHROOT/etc/resolv.conf
  chmod 644 $CHROOT/etc/resolv.conf

  install -m 644 -o root -g root /etc/protocols $CHROOT/etc/
  install -m 644 -o root -g root /etc/services $CHROOT/etc/
  install -m 644 -o root -g root /etc/rpc $CHROOT/etc/

  dir=`dirname $ZONEINFO`
  install -m 755 -o root -g root -d $CHROOT/usr/share/
  install -m 755 -o root -g root -d $CHROOT/usr/share/zoneinfo/
  install -m 644 -o root -g root /usr/share/zoneinfo/UTC $CHROOT/usr/share/zoneinfo/
  install -m 755 -o root -g root -d $CHROOT/usr/share/zoneinfo/$dir/
  install -m 644 -o root -g root /usr/share/zoneinfo/$ZONEINFO $CHROOT/usr/share/zoneinfo/$dir
  install -m 644 -o root -g root /usr/share/zoneinfo/$ZONEINFO $CHROOT/etc/localtime

  touch $CHROOT/var/log/php5-fpm.access.log
  chown $USER:$GROUP $CHROOT/var/log/php5-fpm.access.log
  chmod 644 $CHROOT/var/log/php5-fpm.access.log

  touch $CHROOT/var/log/php5-fpm.error.log
  chown $USER:$GROUP $CHROOT/var/log/php5-fpm.error.log
  chmod 644 $CHROOT/var/log/php5-fpm.error.log
}

make_chroot_esmtp()
{
  CHROOT=$1
  MAIL_SERVER=$2
  MAIL_PORT=$3
  MAIL_USER=$4
  MAIL_PASSWORD=$5

  install -m 755 -o root -g root -d $CHROOT/bin/
  install -m 755 -o root -g root -d $CHROOT/lib/
  install -m 755 -o root -g root -d $CHROOT/lib64/
  install -m 755 -o root -g root -d $CHROOT/usr/
  install -m 755 -o root -g root -d $CHROOT/usr/bin/
  install -m 755 -o root -g root -d $CHROOT/usr/lib/
  install -m 755 -o root -g root -d $CHROOT/usr/lib/esmtp/

  check_package libc6:amd64
  install -m 755 -o root -g root /lib64/ld-linux-x86-64.so.2 $CHROOT/lib64/
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libc.so.6 $CHROOT/lib/
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libdl.so.2 $CHROOT/lib/
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libnsl.so.1 $CHROOT/lib/
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libpthread.so.0 $CHROOT/lib/

  check_package libssl1.0.0:amd64
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libssl.so.1.0.0 $CHROOT/lib/
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0 $CHROOT/lib/

  check_package libesmtp6
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libesmtp.so.6 $CHROOT/lib/
  install -m 644 -o root -g root /usr/lib/esmtp/sasl-login.so $CHROOT/usr/lib/esmtp/
  install -m 644 -o root -g root /usr/lib/esmtp/sasl-plain.so $CHROOT/usr/lib/esmtp/
  install -m 644 -o root -g root /usr/lib/esmtp/sasl-cram-md5.so $CHROOT/usr/lib/esmtp/

  check_package dash
  install -m 755 -o root -g root /bin/sh $CHROOT/bin/

  check_package esmtp
  install -m 755 -o root -g root /usr/bin/esmtp $CHROOT/usr/bin/

  cat > $CHROOT/etc/esmtprc <<END
hostname=$MAIL_SERVER:$MAIL_PORT
username=$MAIL_USER
password=$MAIL_PASSWORD
starttls=disabled
force sender=$MAIL_USER
force reverse_path=$MAIL_USER
END
  chown root:root $CHROOT/etc/esmtprc
  chmod 644 $CHROOT/etc/esmtprc
}

make_chroot_msmtp()
{
  CHROOT=$1
  MAIL_SERVER=$2
  MAIL_PORT=$3
  MAIL_USER=$4
  MAIL_PASSWORD=$5

  install -m 755 -o root -g root -d $CHROOT/bin/
  install -m 755 -o root -g root -d $CHROOT/etc/
  install -m 755 -o root -g root -d $CHROOT/lib64/
  install -m 755 -o root -g root -d $CHROOT/lib/
  install -m 755 -o root -g root -d $CHROOT/usr/
  install -m 755 -o root -g root -d $CHROOT/usr/bin/
  install -m 755 -o root -g root -d $CHROOT/var/
  install -m 755 -o root -g root -d $CHROOT/var/log/

  check_package libc6:amd64
  install -m 755 -o root -g root /lib64/ld-linux-x86-64.so.2 $CHROOT/lib64/
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libc.so.6 $CHROOT/lib/
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libdl.so.2 $CHROOT/lib/
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libpthread.so.0 $CHROOT/lib/

  check_package libgnutls-deb0-28:amd64
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libgnutls-deb0.so.28 $CHROOT/lib/

  check_package libgsasl7
  install -m 644 -o root -g root /usr/lib/libgsasl.so.7 $CHROOT/lib/

  check_package libidn11:amd64
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libidn.so.11 $CHROOT/lib/

  check_package zlib1g:amd64
  install -m 644 -o root -g root /lib/x86_64-linux-gnu/libz.so.1 $CHROOT/lib/

  check_package libp11-kit0:amd64
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libp11-kit.so.0 $CHROOT/lib/

  check_package libtasn1-6:amd64
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libtasn1.so.6 $CHROOT/lib/

  check_package libnettle4:amd64
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libnettle.so.4 $CHROOT/lib/

  check_package libhogweed2:amd64
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libhogweed.so.2 $CHROOT/lib/

  check_package libgmp10:amd64
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libgmp.so.10 $CHROOT/lib/

  check_package libntlm0:amd64
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libntlm.so.0 $CHROOT/lib/

  check_package libffi6:amd64
  install -m 644 -o root -g root /usr/lib/x86_64-linux-gnu/libffi.so.6 $CHROOT/lib/

  check_package dash
  install -m 755 -o root -g root -d $CHROOT/bin/
  install -m 755 -o root -g root /bin/sh $CHROOT/bin/

  check_package msmtp
  install -m 755 -o root -g root /usr/bin/msmtp $CHROOT/usr/bin/

  cat > $CHROOT/etc/msmtprc <<END
account default

host $MAIL_SERVER
port $MAIL_PORT
protocol smtp
timeout 5

auto_from off
from $MAIL_USER

tls off
auth plain
user $MAIL_USER
password $MAIL_PASSWORD

logfile /var/log/msmtp.log
END
  chown root:root $CHROOT/etc/msmtprc
  chmod 644 $CHROOT/etc/msmtprc

  touch $CHROOT/var/log/msmtp.log
  chown $USER:$GROUP $CHROOT/var/log/msmtp.log
  chmod 644 $CHROOT/var/log/msmtp.log
}

destroy_chroot()
{
  CHROOT=$1

  rm -fR $CHROOT/bin/
  rm -fR $CHROOT/etc/
  rm -fR $CHROOT/dev/
  rm -fR $CHROOT/lib/
  rm -fR $CHROOT/lib64/
  rm -fR $CHROOT/tmp/
  rm -fR $CHROOT/usr/
  rm -fR $CHROOT/var/
}


USER=www01
GROUP=www-data
UID=10001
GID=33

ZONEINFO=Asia/Yekaterinburg

# no, esmtp, msmtp
MAILER=esmtp
MAIL_SERVER=mail.domain.tld
MAIL_PORT=587
MAIL_USER=mailbox@domain.tld
MAIL_PASSWORD=mailbox_password

destroy_chroot $CHROOT

make_chroot_php $CHROOT $USER $GROUP $UID $GID $ZONEINFO

case $MAILER in
  esmtp) 
    make_chroot_esmtp $CHROOT $MAIL_SERVER $MAIL_PORT $MAIL_USER $MAIL_PASSWORD $MAIL_TLS
    ;;
  msmtp) 
    make_chroot_msmtp $CHROOT $MAIL_SERVER $MAIL_PORT $MAIL_USER $MAIL_PASSWORD $MAIL_TLS
    ;;
esac
