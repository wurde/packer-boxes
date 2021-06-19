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
  if [ ! -d /tmp/consul ] || [ ! -f /tmp/consul/bin/consull ]; then
    rm -rf /tmp/consul
    git clone https://github.com/hashicorp/consul.git /tmp/consul
    cd consul
    git checkout v1.9.6
    make tools
    make linux
    cd -
    mkdir ./tmp
    cp /tmp/consul/bin/consul ./tmp/consul
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
