#!/usr/bin/env sh

if [[ $UPDATE =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
  echo '===> Applying Updates'
  yum -y update

  # reboot
  echo 'Rebooting...'
  reboot
  sleep 60
fi
