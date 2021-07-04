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
