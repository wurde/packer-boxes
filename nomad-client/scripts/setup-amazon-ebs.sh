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

moveNomad() {
  echo "Moving the Nomad binary"
  sudo chown root:root /tmp/nomad
  sudo mv /tmp/nomad /usr/bin/nomad
}

adduserNomad() {
  echo "Creating a non-privileged user to run Nomad"
  sudo useradd --system --user-group  --home /etc/nomad.d --shell /bin/false nomad
}

mkdirNomadConfig() {
  echo "Creating Nomad's configuration directory"
  sudo mkdir --parents /etc/nomad.d
  sudo touch /etc/nomad.d/nomad.hcl
  sudo chmod 640 /etc/nomad.d/nomad.hcl
  sudo chown --recursive nomad:nomad /etc/nomad.d
}

mkdirNomadData() {
  echo "Creating Nomad's data directory"
  sudo mkdir --parents /nomad/data
  sudo chown --recursive nomad:nomad /nomad/data
}

configureNomad() {
  echo "Configuring Nomad"

  cat << EOF | sudo tee /etc/nomad.d/nomad.hcl
datacenter = "${AWS_DATACENTER}"
region     = "${NOMAD_REGION}"

data_dir = "/nomad/data"

bind_addr = "0.0.0.0"

server {
  enabled = true
}

ports {
  http = ${NOMAD_PORT_HTTP}
  rpc  = ${NOMAD_PORT_RPC}
  serf = ${NOMAD_PORT_SERF}
}
EOF
  sudo chown nomad:nomad /etc/nomad.d/nomad.hcl
}

configureSystemd() {
  echo "Configuring the Nomad process"

  cat << EOF | sudo tee /usr/lib/systemd/system/nomad.service
[Unit]
Description="HashiCorp Nomad - A workload orchestration service"
Documentation=https://www.nomadproject.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/nomad.d/nomad.hcl

[Service]
Type=notify
User=nomad
Group=nomad
ExecStart=/usr/bin/nomad agent -client -config=/etc/nomad.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
}

startNomad() {
  echo "Starting the Nomad service"
  sudo systemctl daemon-reload
  sudo systemctl enable nomad
  sudo systemctl restart nomad && sleep 5
  sudo systemctl status nomad
}

main() {
  echo "Running"

  setTimezone
  updatePackages
  moveNomad
  adduserNomad
  mkdirNomadConfig
  mkdirNomadData
  configureNomad
  configureSystemd
  startNomad

  echo "Complete"
}

main
