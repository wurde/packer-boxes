#!/bin/sh

function setTimezone() {
  echo "Setting timezone to UTC"
  sudo timedatectl set-timezone UTC
}

# Ubuntu instances use the apt-get package manager. It can
# install, remove, and update software.
function updatePackages() {
  echo "Updating packages"
  sudo apt update -y
}

function main() {
  echo "Running"

  setTimezone
  updatePackages

  echo "Complete"
}

main
