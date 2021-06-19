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

main() {
  echo "Running"

  setTimezone
  updatePackages

  echo "Complete"
}

main
