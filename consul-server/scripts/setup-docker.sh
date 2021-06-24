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

installOpenRCInit() {
  echo "Installing OpenRC init system"
  apk add openrc
}

moveConsul() {
  echo "Moving the Consul binary"
  chown root:root /tmp/consul
  mv /tmp/consul /usr/bin/consul
}

adduserConsul() {
  echo "Creating a non-privileged user to run Consul"
  addgroup -S consul
  adduser -S -h /etc/consul.d -s /bin/false -G consul consul
}

mkdirConsulConfig() {
  echo "Creating Consul's configuration directory"
  mkdir --parents /etc/consul.d
  touch /etc/consul.d/consul.hcl
  chmod 640 /etc/consul.d/consul.hcl
  touch /etc/consul.d/server.hcl
  chmod 640 /etc/consul.d/server.hcl
  chown --recursive consul:consul /etc/consul.d
}

mkdirConsulData() {
  echo "Creating Consul's data directory"
  mkdir --parents /opt/consul
  chown --recursive consul:consul /opt/consul
}

createEncryptionKey() {
  echo "Generating a new 32-byte encryption key"
  consul keygen | tee /etc/consul.d/key
  chown consul:consul /etc/consul.d/key
}

createCertificateAuthority() {
  echo "Creating a Consul Certificate Authority"
  cd /etc/consul.d
  consul tls ca create
  chown --recursive consul:consul /etc/consul.d
}

createTlsCertificates() {
  echo "Generating TLS certificates for RPC encryption"
  consul tls cert create -server -dc docker-dc1
  consul tls cert create -server -dc docker-dc1
  consul tls cert create -server -dc docker-dc1
  chown --recursive consul:consul /etc/consul.d
}

configureConsul() {
  echo "Configuring Consul"

  cat << EOF | tee /etc/consul.d/consul.hcl
datacenter = "docker-dc1"
data_dir = "/opt/consul"
encrypt = "qDOPBEr+/oUVeOFQOnVypxwDaHzLrD+lvjo5vCEBbZ0="
ca_file = "/etc/consul.d/consul-agent-ca.pem"
cert_file = "/etc/consul.d/docker-dc1-server-consul-0.pem"
key_file = "/etc/consul.d/docker-dc1-server-consul-0-key.pem"
verify_incoming = true
verify_outgoing = true
verify_server_hostname = true

#acl = {
#  enabled = true
#  default_policy = "allow"
#  enable_token_persistence = true
#}

#advertise_addr = "{{ GetInterfaceIP \"eth0\" }}"

performance {
  raft_multiplier = 5
}
EOF
  chown consul:consul /etc/consul.d/consul.hcl
}

configureServer() {
  echo "Configuring Consul server"

  cat << EOF | tee /etc/consul.d/server.hcl
server = true
client_addr = "0.0.0.0"
bootstrap_expect = 1

#ui_config {
#  enabled = true
#  metrics_provider = "prometheus"
#}
EOF
  chown consul:consul /etc/consul.d/server.hcl
}

validateConfig() {
  echo "Validating the Consul configuration"
  consul validate /etc/consul.d/consul.hcl
}

configureInit() {
  echo "Configuring the Consul process"
  cat << EOF | tee /etc/init.d/consul.service
#!/sbin/openrc-run

# https://github.com/OpenRC/openrc/blob/master/service-script-guide.md

# Declare a hard dependency on network and
# local filesystem access.
depend() {
  need net
  need localmount
}

reload() {
  ebegin "Reloading Consul"
  start-stop-daemon --signal HUP --pidfile "/run/consul.service.pid"
  eend $?
}

command=/usr/bin/consul
command_args="agent -config-dir=/etc/consul.d/"
command_background=true
pidfile="/run/consul.service.pid"
extra_started_commands="reload"

name="Consul Server"
description="HashiCorp Consul - A service mesh solution"
EOF
  chmod +x /etc/init.d/consul.service
}

startConsul() {
  echo "Starting the Consul service"
  # In Alpine, runlevels work like they do in Gentoo:
  #   /etc/runlevels/boot
  #   /etc/runlevels/default
  #   /etc/runlevels/nonetwork
  #   /etc/runlevels/shutdown
  #   /etc/runlevels/sysinit
  # rc-update add consul.service default
  # rc-service consul.service describe
  # rc-status
}

main() {
  echo "Running"

  setTimezone
  updatePackages
  installOpenRCInit
  moveConsul
  adduserConsul
  mkdirConsulConfig
  mkdirConsulData
  createEncryptionKey
  createCertificateAuthority
  createTlsCertificates
  configureConsul
  configureServer
  validateConfig
  configureInit
  startConsul

  echo "Complete"
}

main
