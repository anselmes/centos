#!/usr/bin/env sh

echo '===> Force logs to rotate'
/usr/sbin/logrotate -f /etc/logrotate.conf
/bin/rm -f /var/log/*-???????? /var/log/*.gz

echo '===> Clear audit log and wtmp'
/bin/cat /dev/null > /var/log/audit/audit.log
/bin/cat/ dev/null > /var/log/wtmp

echo '===> Cleaning up tmp'
/bin/rm -rf /tmp/*
/bin/rm -rf /var/tmp/*

echo '===> Remove the SSH host keys'
/bin/rm -f /etc/ssh/*key*

echo '===> Cleaning up udev rules'
/bin/rm -f /etc/udev/rules.d/70*

echo '===> Cleaning up temporary network address'
rm -rf /dev/.udev/
if [ -f /etc/sysconfig/network-scripts/ifcfg-eth0 ]; then
  sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth0
  sed -i '/^UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth0
fi

nmcli radio all off
/bin/systemctl stop NetworkManager.service
for ifcfg in `ls /etc/sysconfig/network-scripts/ifcfg-* | grep -v ifcfg-lo`; do
  rm -f $ifcfg
done
rm -f /var/lib/NetworkManager/*

echo '===> Setup /etc/rc.d/rc.local for CentOS7'
cat << __EOF__ >> /etc/rc.d/rc.local
#BOXCUTTER-BEGIN
LANG=C

# delete all connection
for con in \`nmcli -t -f uuid con\`; do
  if [ "\$con" != "" ]; then
    nmcli con del \$con
  fi
done

# add gateway interface connection
gwdev=\`nmcli dev | grep ethernet | egrep -v 'unmanaged' | head -n 1 | awk '{ print \$1 }'\`
if [ "\$gwdev" != "" ]; then
  nmcli c add type eth ifname \$gwdev con-name \$gwdev
fi

sed -i -e '/^#BOXCUTTER-BEGIN/,/^#BOXCUTTER-END/{s/^/# /}' /etc/rd.d/rc.local
chmod -x /etc/rc.d/rc.local
#BOXCUTTER-END
__EOF__
chmod +x /etc/rc.d/rc.local

echo '===> Remove unused man page locales'
DISK_USAGE_BEFORE_CLEANUP=$(df -h)
KEEP_LANGUAGE="en"
KEEP_LOCALE="en_CA"
pushd /usr/share/man
if [ $(ls | wc -w) -gt 16 ]; then
  mkdir ../tmp_dir
  mv man* $KEEP_LANGUAGE $SECONDARY_LANGUAGE ../tmp_dir
  rm -rf *
  mv ../tmp_dir/* .
  rm -rf ../tmp_dir
  sync
fi
popd

echo '===> Remove packages needed for building guest tools'
yum remove -y gcc cpp libmpc mpfr kernel-devel kernel-headers

echo '===> Clean up YUM cache of metadata and packages'
yum -y --enablerepo='*' clean all

echo '===> Clear core files'
rm -f /core*

echo '===> Removing temporary files'
rm -rf /tmp/*

echo '===> Rebuild RPM DB'
rpmdb --rebuilddb
rm -f /var/lib/rpm/__db*

# echo '===> Clear out swap and disable until reboot'
# set +e
# swapuuid=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
# case "$?" in
#   2|0) ;;
#   *) exit 1 ;;
# esac

# set -e
# if [ "x${swapuuid}" != "x" ]; then
#   swappart=$(readlink -f /dev/disk/by-uuid/$swapuuid)
#   /sbin/swapoff "${swappart}"
#   dd if=/dev/zero of="${swappart}" bs=1M
#   /sbin/mkswap -U "${swapuuid}" "${swappart}"
# fi

yum install -y cockpit-storaged

echo '===> Zeroing out empty area'
dd if=/dev/zero of=/EMPTY bs=1M || echo 'dd exit code $? is suppressed'
rm -f /EMPTY
sync

echo '===> Disk usage before cleanup'
echo ${DISK_USAGE_BEFORE_CLEANUP}

echo '===> Disk usage after cleanup'
df -h

echo '===> Remove the root user shell history'
/bin/rm -f ~root/.bash_history
unset HISTFILE
