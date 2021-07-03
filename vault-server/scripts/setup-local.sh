#!/bin/sh

check_git() {
  echo "Verifying git is installed"
  git version
}

check_golang() {
  echo "Verifying golang is installed"
  go version
}

install_vault() {
  echo "Installing the Vault binary"
  if [ ! -d /tmp/vault ]; then
    rm -rf /tmp/vault ~/go/bin/vault
    git clone https://github.com/hashicorp/vault.git /tmp/vault
    cd /tmp/vault
    git checkout $VAULT_VERSION
    sed --in-place s/'VersionPrerelease = "dev"'/'VersionPrerelease = ""'/g /tmp/vault/sdk/version/version_base.go
    make bootstrap
    go install
    cd -
    mkdir -p ./tmp
    cp --force ~/go/bin/vault ./tmp/vault
  fi
}

main() {
  echo "Running"

  check_git
  check_golang
  install_vault

  echo "Complete"
}

main
