#!/usr/bin/env sh

echo '===> Running post setup...'

sed -i 's/^#PermitRootLogin\(.*[^ ]\)/PermitRootLogin without-password/g' /etc/ssh/sshd_config
sed -i 's/^#GSSAPIAuthentication\(.*[^ ]\)/GSSAPIAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#GSSAPICleanupCredentials\(.*[^ ]\)/GSSAPICleanupCredentials yes/g' /etc/ssh/sshd_config
sed -i 's/^#GSSAPIKeyExchange\(.*[^ ]\)/GSSAPIKeyExchange yes/g' /etc/ssh/sshd_config

cat << 'EOF' >> /etc/ssh/ssh_config
Host *
  GSSAPIAuthentication yes
  GSSAPIKeyExchange yes
  GSSAPIRenewalForcesRekey yes
  GSSAPITrustDns yes
Host "*.$(hostname -d)"
  GSSAPIDelegateCredentials yes
EOF

cat << 'EOF' >> /etc/sudoers
Defaults env_keep += "HTTP_PROXY HTTPS_PROXY FTP_PROXY RSYNC_PROXY NO_PROXY"
EOF

echo '===> Provisionning...'

yum update -y
yum remove docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-engine \
  docker-engine-selinux \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux

yum install -y realmd storaged python2 socat cockpit \
  cockpit-packagekit \
  cockpit-pcp \
  cockpit-storaged \
  device-mapper-persistent-data \
  lvm2 \
  yum-utils \
  policycoreutils-python \
  nfs-utils

mv /etc/dbus-1/system.d/com.redhat.SubscriptionManager.conf{,.back}

sudo systemctl enable --now firewalld
sudo systemctl enable --now cockpit.socket

sudo firewall-cmd --permanent --zone=public --add-service=cockpit
sudo firewall-cmd --reaload

curl https://get.acme.sh | sh
mkdir -p /root/.ssh
