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


move_consul() {
  echo "Moving the Consul binary"
  sudo chown root:root /tmp/consul
  sudo mv /tmp/consul /usr/bin/consul
}

adduser_consul() {
  echo "Creating a non-privileged user to run Consul"
  sudo useradd --system --home /etc/consul.d --shell /bin/false consul
}

mkdir_consul_config() {
  echo "Creating Consul's configuration directory"
  sudo mkdir --parents /etc/consul.d
  sudo touch /etc/consul.d/consul.hcl
  sudo chmod 640 /etc/consul.d/consul.hcl
  sudo touch /etc/consul.d/server.hcl
  sudo chmod 640 /etc/consul.d/server.hcl
  sudo chown --recursive consul:consul /etc/consul.d
}

mkdir_consul_data() {
  echo "Creating Consul's data directory"
  sudo mkdir --parents /opt/consul
  sudo chown --recursive consul:consul /opt/consul
}

create_encryption_key() {
  echo "Generating a new 32-byte encryption key"
  consul keygen | sudo tee /etc/consul.d/key
  sudo chown consul:consul /etc/consul.d/key
}

create_certificate_authority() {
  echo "Creating a Consul Certificate Authority"
  cd /etc/consul.d
  sudo consul tls ca create
  sudo chown --recursive consul:consul /etc/consul.d
}

create_tls_certificates() {
  echo "Generating TLS certificates for RPC encryption"
  sudo consul tls cert create -server -dc aws-us-east-2
  sudo consul tls cert create -server -dc aws-us-east-2
  sudo consul tls cert create -server -dc aws-us-east-2
  sudo chown --recursive consul:consul /etc/consul.d
}

configure_consul() {
  echo "Configuring Consul"

  cat << EOF | sudo tee /etc/consul.d/consul.hcl
node = consul-node-one
datacenter = "aws-us-east-2"
data_dir = "/opt/consul"
encrypt = "qDOPBEr+/oUVeOFQOnVypxwDaHzLrD+lvjo5vCEBbZ0="
ca_file = "/etc/consul.d/consul-agent-ca.pem"
cert_file = "/etc/consul.d/aws-us-east-2-server-consul-0.pem"
key_file = "/etc/consul.d/aws-us-east-2-server-consul-0-key.pem"
verify_incoming = true
verify_outgoing = true
verify_server_hostname = true
retry_join = ["provider=aws tag_key=Consul-Auto-Join tag_value=main region=us-east-2"]

#acl = {
#  enabled = true
#  default_policy = "allow"
#  enable_token_persistence = true
#}

performance {
  raft_multiplier = 5
}
EOF
  sudo chown consul:consul /etc/consul.d/consul.hcl
}

configure_server() {
  echo "Configuring Consul server"

  cat << EOF | sudo tee /etc/consul.d/server.hcl
server = true
client_addr = "0.0.0.0"
#bootstrap_expect = 1

#ui_config {
#  enabled = true
#  metrics_provider = "prometheus"
#}
EOF
  sudo chown consul:consul /etc/consul.d/server.hcl
}

configure_systemd() {
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

validate_config() {
  echo "Validating the Consul configuration"
  sudo consul validate /etc/consul.d/consul.hcl
}

start_consul() {
  echo "Starting the Consul service"
  # TODO alpine doesn't have systemd!
  sudo systemctl enable consul
  sudo systemctl start consul
  sudo systemctl status consul
}

main() {
  echo "Running"

  setTimezone
  updatePackages
  # move_consul
  # adduser_consul
  # mkdir_consul_config
  # mkdir_consul_data
  # create_encryption_key
  # create_certificate_authority
  # create_tls_certificates
  # configure_consul
  # configure_server
  # configure_systemd
  # validate_config
  # start_consul

  echo "Complete"
}

main
