#!/bin/sh

setTimezone() {
  echo "Setting timezone to UTC"
  apk add tzdata
  cp /usr/share/zoneinfo/UTC /etc/localtime
  echo "UTC" > /etc/timezone
}

# Alpine instances use the apk package manager. It can
# install, remove, and update software.
updatePackages() {
  echo "Updating packages"
  apk -U upgrade
}

configureVault() {
  echo "Configuring Vault"

  cat << EOF | tee /vault/config/vault.hcl
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

default_lease_ttl = 1h
max_lease_ttl     = 720h
EOF
  chown vault:vault /vault/config/vault.hcl
}

main() {
  echo "Running"

  setTimezone
  updatePackages
  configureVault

  echo "Complete"
}

main
