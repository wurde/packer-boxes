#!/bin/sh

setTimezone() {
  echo "Setting timezone to UTC"
  sudo timedatectl set-timezone UTC
}

# Amazon Linux instances use the yum package manager. It can
# install, remove, and update software.
updatePackages() {
  echo "Updating packages"
  sudo yum update -y
}

moveVault() {
  echo "Moving the Vault binary"
  sudo chown root:root /tmp/vault
  sudo mv /tmp/vault /usr/bin/vault
}

adduserVault() {
  echo "Creating a non-privileged user to run Vault"
  sudo useradd --system --user-group  --home /etc/vault.d --shell /bin/false vault
}

mkdirVaultConfig() {
  echo "Creating Vault's configuration directory"
  sudo mkdir --parents /etc/vault.d
  sudo touch /etc/vault.d/vault.hcl
  sudo chmod 640 /etc/vault.d/vault.hcl
  sudo chown --recursive vault:vault /etc/vault.d
}

configureVault() {
  echo "Configuring Vault"

  cat << EOF | tee /etc/vault.d/vault.hcl
cluster_name = ${VAULT_CLUSTER_NAME}

storage "inmem" {}

#storage "consul" {
#  # Specifies the address of the Consul agent to communicate with.
#  address = "127.0.0.1:8500"
#  path    = "vault"
#
#  check_timeout = ${VAULT_CHECK_TIMEOUT}
#  scheme        = "https"
#  tls_ca_file   = "/etc/pki/tls/certs/vault-agent-ca.pem"
#  tls_cert_file = "/etc/pki/tls/certs/${DOCKER_DATACENTER}-server-vault-0.pem"
#  tls_key_file  = "/etc/pki/tls/private/${DOCKER_DATACENTER}-server-vault-0-key.pem"
#}

ui = ${VAULT_UI_ENABLED}

default_lease_ttl = "1h"
max_lease_ttl     = "720h"
EOF
  chown vault:vault /etc/vault.d/vault.hcl
}

configureSystemd() {
  echo "Configuring the Vault process"

  cat << EOF | sudo tee /usr/lib/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A secrets management solution"
Documentation=https://www.vaultproject.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
Type=notify
User=vault
Group=vault
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
}

startVault() {
  echo "Starting the Vault service"
  sudo systemctl daemon-reload
  sudo systemctl enable vault
  sudo systemctl restart vault && sleep 5
  sudo systemctl status vault
}

main() {
  echo "Running"

  setTimezone
  updatePackages
  moveVault
  adduserVault
  mkdirVaultConfig
  configureVault
  configureSystemd
  startVault

  echo "Complete"
}

main
