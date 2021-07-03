#!/bin/sh

# `date` => UTC
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

createEncryptionKey() {
  echo "Generating a new 32-byte encryption key"
  encryption_key=$(consul keygen)
}

createCertificateAuthority() {
  echo "Creating a Consul Certificate Authority"
  cd /consul/config
  consul tls ca create
  chown --recursive consul:consul /consul/config
  # TODO move to /etc/pki/tls/...
}

createTlsCertificates() {
  echo "Generating TLS certificates for RPC encryption"
  consul tls cert create -server -dc $DOCKER_DATACENTER
  consul tls cert create -server -dc $DOCKER_DATACENTER
  consul tls cert create -server -dc $DOCKER_DATACENTER
  chown --recursive consul:consul /consul/config
  # TODO move to /etc/pki/tls/...
}

configureConsul() {
  echo "Configuring Consul"

  cat << EOF | tee /consul/config/consul.hcl
datacenter = "docker-${DOCKER_DATACENTER}"
data_dir   = "/consul/data"
encrypt    = "${encryption_key}"
ca_file    = "/etc/pki/tls/certs/consul-agent-ca.pem"
cert_file  = "/etc/pki/tls/certs/${DOCKER_DATACENTER}-server-consul-0.pem"
key_file   = "/etc/pki/tls/private/${DOCKER_DATACENTER}-server-consul-0-key.pem"

verify_incoming        = true
verify_outgoing        = true
verify_server_hostname = true

performance {
  raft_multiplier = ${RAFT_MULTIPLIER}
}

ports {
  dns      = ${CONSUL_PORT_DNS}
  http     = ${CONSUL_PORT_HTTP}
  https    = ${CONSUL_PORT_HTTPS}
  grpc     = ${CONSUL_PORT_GRPC}
  serf_lan = ${CONSUL_PORT_SERF_LAN}

  sidecar_min_port = ${CONSUL_PORT_SIDECAR_MIN_PORT}
  sidecar_max_port = ${CONSUL_PORT_SIDECAR_MAX_PORT}
  expose_min_port  = ${CONSUL_PORT_EXPOSE_MIN_PORT}
  expose_max_port  = ${CONSUL_PORT_EXPOSE_MAX_PORT}
}
EOF
  chown consul:consul /consul/config/consul.hcl
}

configureServer() {
  echo "Configuring Consul server"

  cat << EOF | tee /consul/config/server.hcl
server = true
client_addr = "${CLIENT_ADDR}"
bootstrap_expect = ${BOOTSTRAP_EXPECT}

ports {
  serf_wan = ${CONSUL_PORT_SERF_WAN}
  server   = ${CONSUL_PORT_SERVER}
}

ui_config {
  enabled = ${CONSUL_UI_ENABLED}
}
EOF
  chown consul:consul /consul/config/server.hcl
}

validateConfig() {
  echo "Validating the Consul configuration"
  consul validate /consul/config/consul.hcl
}

main() {
  echo "Running"

  # setTimezone
  # updatePackages
  # createEncryptionKey
  # createCertificateAuthority
  # createTlsCertificates
  # configureConsul
  # configureServer
  # validateConfig

  echo "Complete"
}

main
