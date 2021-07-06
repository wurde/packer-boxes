#!/bin/sh

# Ubuntu instances use the apt-get package manager. It can
# install, remove, and update software.
updatePackages() {
  echo "Updating packages"
  apt-get update -y
}

# `date` => UTC
setTimezone() {
  echo "Setting timezone to UTC"
  DEBIAN_FRONTEND=noninteractive apt-get install -yq tzdata
  rm --force /etc/localtime
  cp /usr/share/zoneinfo/UTC /etc/localtime
  echo "UTC" > /etc/timezone
}

# dumb-init is a simple process supervisor that
# forwards signals to children. It is designed
# to run as PID1 in minimal container environments.
installDumbInit() {
  echo "Installing dumb-init"
  apt-get install -y dumb-init
}

moveNomad() {
  echo "Moving the Nomad binary"
  chown root:root /tmp/nomad
  mv /tmp/nomad /usr/bin/nomad
}

moveDockerEntrypoint() {
  echo "Moving the Docker ENTRYPOINT"
  chmod 755 /tmp/docker-entrypoint
  mv /tmp/docker-entrypoint /bin/docker-entrypoint
}

adduserNomad() {
  echo "Creating a non-privileged user to run Nomad"
  useradd --system --user-group  --home /etc/nomad.d --shell /bin/false nomad
}

mkdirNomadConfig() {
  echo "Creating Nomad's configuration directory"
  mkdir --parents /etc/nomad.d
  touch /etc/nomad.d/nomad.hcl
  chmod 640 /etc/nomad.d/nomad.hcl
  chown --recursive nomad:nomad /etc/nomad.d
}

mkdirNomadData() {
  echo "Creating Nomad's data directory"
  mkdir --parents /nomad/data
  chown --recursive nomad:nomad /nomad/data
}

configureNomad() {
  echo "Configuring Nomad"

  cat << EOF | tee /etc/nomad.d/nomad.hcl
datacenter = "${DOCKER_DATACENTER}"
region     = "${NOMAD_REGION}"

data_dir = "/nomad/data"

bind_addr = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
  raft_multiplier  = ${NOMAD_RAFT_MULTIPLIER}
}

ports {
  http = ${NOMAD_PORT_HTTP}
  rpc  = ${NOMAD_PORT_RPC}
  serf = ${NOMAD_PORT_SERF}
}
EOF
  chown nomad:nomad /etc/nomad.d/nomad.hcl
}

main() {
  echo "Running"

  updatePackages
  setTimezone
  installDumbInit
  moveNomad
  moveDockerEntrypoint
  adduserNomad
  mkdirNomadConfig
  mkdirNomadData
  configureNomad

  echo "Complete"
}

main
