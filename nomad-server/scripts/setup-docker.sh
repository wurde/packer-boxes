#!/bin/sh

setTimezone() {
  echo "Setting timezone to UTC"
  timedatectl set-timezone UTC
}

# Ubuntu instances use the apt-get package manager. It can
# install, remove, and update software.
updatePackages() {
  echo "Updating packages"
  apt-get update -y
}

moveNomad() {
  echo "Moving the Nomad binary"
  chown root:root /tmp/nomad
  mv /tmp/nomad /usr/bin/nomad
}

adduserNomad() {
  echo "Creating a non-privileged user to run Nomad"
  useradd --system --user-group  --home /etc/nomad.d --shell /bin/false nomad
}

mkdirNomadConfig() {
  echo "Creating Nomad's configuration directory"
  mkdir --parents /etc/nomad.d
  touch /etc/nomad.d/nomad.hcl
  chmod 640 /etc/nomad.d/nomad.hcl
  chown --recursive nomad:nomad /etc/nomad.d
}

mkdirNomadData() {
  echo "Creating Nomad's data directory"
  mkdir --parents /nomad/data
  chown --recursive nomad:nomad /nomad/data
}

configureNomad() {
  echo "Configuring Nomad"

  cat << EOF | tee /etc/nomad.d/nomad.hcl
datacenter = "${DOCKER_DATACENTER}"
region     = "${NOMAD_REGION}"

data_dir = "/nomad/data"

bind_addr = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
}

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}
EOF
  chown nomad:nomad /etc/nomad.d/nomad.hcl
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

  echo "Complete"
}

main
