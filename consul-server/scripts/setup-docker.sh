#!/bin/bash
set -x

function setTimezone() {
  echo "Setting timezone to UTC"
  sudo timedatectl set-timezone UTC
}

# Alpine instances use the apk package manager. It can
# install, remove, and update software.
function updatePackages() {
  echo "Updating packages"
  sudo apk -U upgrade
}

function main() {
  echo "Running"

  setTimezone
  updatePackages

  echo "Complete"
}

main
