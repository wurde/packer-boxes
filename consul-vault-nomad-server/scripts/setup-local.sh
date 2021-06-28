#!/bin/sh

check_git() {
  echo "Verifying git is installed"
  git version
}

check_golang() {
  echo "Verifying golang is installed"
  go version
}

install_consul() {
  echo "Installing the Consul binary"
  if [ ! -d /tmp/consul ] || [ ! -f /tmp/consul/bin/consul ]; then
    rm -rf /tmp/consul
    git clone https://github.com/hashicorp/consul.git /tmp/consul
    cd /tmp/consul
    git checkout $CONSUL_VERSION
    make tools
    make linux
    cd -
    mkdir -p ./tmp
    cp /tmp/consul/bin/consul ./tmp/consul
  fi
}

main() {
  echo "Running"

  # check_git
  # check_golang
  # install_consul

  echo $RAFT_MULTIPLIER

  echo "Complete"
}

main
