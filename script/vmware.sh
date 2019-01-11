#!/usr/bin/env sh

SSH_USER=${SSH_USERNAME:-root}
SSH_USER_HOME=${SSH_USER_HOME:/root}

if [[ $PACKER_BUILDER_TYPE =~ vmware ]]; then
  echo '===> Installing VMware Tools'

  yum install -y open-vm-tools perl net-tools
  systemctl restart vmtoolsd

  # rm -f /etc/redhat-release
  # touch /etc/redhat-release
  # echo 'Red Hat Enterprise Linux Server release 7.0 (Maipo)' /etc/redhat-release

  # systemctl disable NetworkManager.service
  # chkconfig network on
fi
