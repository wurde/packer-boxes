#!/bin/sh

setTimezone() {
  echo "Setting timezone to UTC"
  sudo timedatectl set-timezone UTC
}

# Ubuntu instances use the apt-get package manager. It can
# install, remove, and update software.
updatePackages() {
  echo "Updating packages"
  sudo apt update -y
}

main() {
  echo "Running"

  setTimezone
  updatePackages

  echo "Complete"
}

main
