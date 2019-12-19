#!/bin/bash

set -x

DEBIAN_FRONTEND=noninteractive
apt-get install -qq -y unzip curl

USER="vault"
COMMENT="Hashicorp vault user"
GROUP="vault"
HOME="/srv/vault"

user_ubuntu() {
  # UBUNTU user setup
  if ! getent group $GROUP >/dev/null
  then
     addgroup --system $GROUP >/dev/null
  fi

  if ! getent passwd $USER >/dev/null
  then
     adduser \
      --system \
      --disabled-login \
      --ingroup $GROUP \
      --home $HOME \
      --no-create-home \
      --gecos "$COMMENT" \
      --shell /bin/false \
      $USER  >/dev/null
  fi
}

user_ubuntu

logger "User setup complete"


VAULT_ZIP="vault_1.2.4_linux_amd64.zip"
VAULT_URL="https://releases.hashicorp.com/vault/1.2.4/vault_1.2.4_linux_amd64.zip"
curl --silent --output /tmp/$VAULT_ZIP $VAULT_URL
unzip -o /tmp/$VAULT_ZIP -d /usr/local/bin/
chmod 0755 /usr/local/bin/vault
chown vault:vault /usr/local/bin/vault
mkdir -pm 0755 /etc/vault.d
mkdir -pm 0755 /opt/vault
chown vault:vault /opt/vault


cat << EOF |  tee /lib/systemd/system/vault.service
[Unit]
Description=Vault Agent
Requires=network-online.target
After=network-online.target
[Service]
Restart=on-failure
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/local/bin/vault
ExecStart=/usr/local/bin/vault server -config /etc/vault.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=vault
Group=vault
[Install]
WantedBy=multi-user.target
EOF


cat << EOF |  tee /etc/vault.d/vault.hcl
storage "file" {
  path = "/opt/vault"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

ui=true
EOF

chmod 0664 /lib/systemd/system/vault.service
systemctl daemon-reload
chown -R vault:vault /etc/vault.d
chmod -R 0644 /etc/vault.d/*

systemctl enable vault