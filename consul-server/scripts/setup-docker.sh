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

# dumb-init is a simple process supervisor that
# forwards signals to children. It is designed
# to run as PID1 in minimal container environments.
installDumbInit() {
  echo "Installing dumb-init"
  apk add --no-cache dumb-init
}

# su-exec allows you to switch user and group id
# before executing a command
installSuExec() {
  echo "Installing su-exec"
  apk add --no-cache su-exec
}

# Set up nsswitch.conf for Go's "netgo" implementation
# which is used by Consul, otherwise DNS supercedes the
# container's hosts file, which we don't want.
setupNameServiceSwitch() {
  test -e /etc/nsswitch.conf || echo 'hosts: files dns' > /etc/nsswitch.conf
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
  encryption_key=$(consul keygen)
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
encrypt = "${encryption_key}"
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

moveDockerEntrypoint() {
  echo "Moving the Docker image entrypoint"
  chown root:root /tmp/docker-entrypoint.sh
  mv /tmp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
}

main() {
  echo "Running"

  setTimezone
  updatePackages
  installDumbInit
  installSuExec
  setupNameServiceSwitch
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
  moveDockerEntrypoint

  echo "Complete"
}

main
