#!/bin/sh

function check_git() {
  echo "Verifying git is installed"
  git version
}

function check_golang() {
  echo "Verifying golang is installed"
  go version
}

function install_consul() {
  echo "Installing the Consul binary"
  # TODO check if local binary exists
  if [ ! -d /tmp/consul ]; then
    rm -rf /tmp/consul && cd /tmp
    git clone https://github.com/hashicorp/consul.git && cd consul
    git checkout v1.9.6
    make tools
    make linux
    # TODO copy binary to local ./tmp/consul
  fi
}

function main() {
  echo "Running"

  check_git
  check_golang
  install_consul

  echo "Complete"
}

main
