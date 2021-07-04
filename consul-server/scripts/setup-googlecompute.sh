#!/bin/sh

setTimezone() {
  echo "Setting timezone to UTC"
  sudo timedatectl set-timezone UTC
}

# Ubuntu instances use the apt-get package manager. It can
# install, remove, and update software.
updatePackages() {
  echo "Updating packages"
  sudo apt-get update -y
}

moveConsul() {
  echo "Moving the Consul binary"
  sudo chown root:root /tmp/consul
  sudo mv /tmp/consul /usr/bin/consul
}

adduserConsul() {
  echo "Creating a non-privileged user to run Consul"
  sudo useradd --system --user-group  --home /etc/consul.d --shell /bin/false consul
}

mkdirConsulConfig() {
  echo "Creating Consul's configuration directory"
  sudo mkdir --parents /etc/consul.d
  sudo touch /etc/consul.d/consul.hcl
  sudo chmod 640 /etc/consul.d/consul.hcl
  sudo touch /etc/consul.d/server.hcl
  sudo chmod 640 /etc/consul.d/server.hcl
  sudo chown --recursive consul:consul /etc/consul.d
}

mkdirConsulData() {
  echo "Creating Consul's data directory"
  sudo mkdir --parents /opt/consul
  sudo chown --recursive consul:consul /opt/consul
}

createEncryptionKey() {
  echo "Generating a new 32-byte encryption key"
  encryption_key=$(consul keygen)
}

setupTlsCertificates() {
  echo "Creating a Consul Certificate Authority"
  cd /consul/config
  sudo mkdir -p /etc/pki/tls/certs && cd /etc/pki/tls/certs
  sudo consul tls ca create

  echo "Generating TLS certificates for RPC encryption"
  sudo mkdir -p /etc/pki/tls/private
  sudo consul tls cert create -server -dc $GCP_DATACENTER

  sudo mv *-key.pem /etc/pki/tls/private
}

configureConsul() {
  echo "Configuring Consul"

  cat << EOF | sudo tee /etc/consul.d/consul.hcl
node_name  = "gcp-${CONSUL_NODE_NAME}"
datacenter = "${GCP_DATACENTER}"
data_dir   = "/opt/consul"
encrypt    = "${encryption_key}"
ca_file    = "/etc/pki/tls/certs/consul-agent-ca.pem"
cert_file  = "/etc/pki/tls/certs/${GCP_DATACENTER}-server-consul-0.pem"
key_file   = "/etc/pki/tls/private/${GCP_DATACENTER}-server-consul-0-key.pem"

verify_incoming        = true
verify_outgoing        = true
verify_server_hostname = true

retry_join = ["provider=gce tag_value=consul_auto_join"]

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
  sudo chown consul:consul /etc/consul.d/consul.hcl
}

configureServer() {
  echo "Configuring Consul server"

  cat << EOF | sudo tee /etc/consul.d/server.hcl
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
  sudo chown consul:consul /etc/consul.d/server.hcl
}

configureSystemd() {
  echo "Configuring the Consul process"

  cat << EOF | sudo tee /usr/lib/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
}

validateConfig() {
  echo "Validating the Consul configuration"
  sudo consul validate /etc/consul.d/consul.hcl
}

startConsul() {
  echo "Starting the Consul service"
  sudo systemctl daemon-reload
  sudo systemctl enable consul
  sudo systemctl restart consul && sleep 5
  sudo systemctl status consul
}

main() {
  echo "Running"

  setTimezone
  updatePackages
  moveConsul
  adduserConsul
  mkdirConsulConfig
  mkdirConsulData
  createEncryptionKey
  setupTlsCertificates
  configureConsul
  configureServer
  configureSystemd
  validateConfig
  startConsul

  echo "Complete"
}

main
