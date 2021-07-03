#!/bin/sh

check_git() {
  echo "Verifying git is installed"
  git version
}

check_golang() {
  echo "Verifying golang is installed"
  go version
}

install_nomad() {
  echo "Installing the Nomad binary"
  if [ ! -d /tmp/nomad ]; then
    rm -rf /tmp/nomad ~/go/bin/nomad
    git clone https://github.com/hashicorp/nomad.git /tmp/nomad
    cd /tmp/nomad
    git checkout $NOMAD_VERSION
    sed --in-place s/'VersionPrerelease = "dev"'/'VersionPrerelease = ""'/g /tmp/nomad/version/version.go
    make bootstrap
    make release ALL_TARGETS=linux_amd64
    cd -
    mkdir -p ./tmp
    cp --force /tmp/nomad/pkg/linux_amd64/nomad ./tmp/nomad
  fi
}

main() {
  echo "Running"

  check_git
  check_golang
  install_nomad

  echo "Complete"
}

main
