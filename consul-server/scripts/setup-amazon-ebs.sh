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

main() {
  echo "Running"

  setTimezone
  updatePackages

  echo "Complete"
}

main
