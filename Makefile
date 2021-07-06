BUILDS = amazon-ebs.consul-server, googlecompute.consul-server, docker.consul-server, amazon-ebs.nomad-client,  googlecompute.nomad-client, docker.nomad-client, amazon-ebs.nomad-server, googlecompute.nomad-server, docker.nomad-server, amazon-ebs.vault-server, googlecompute.vault-server, docker.vault-server

# Pass through the Google Cloud project ID.
export PKR_VAR_googlecompute_project_id

# Set default versions of Consul, Vault, and Nomad.
export PKR_VAR_consul_version = v1.10.0
export PKR_VAR_vault_version = v1.7.3
export PKR_VAR_nomad_version = v1.1.2

# Set default root device size in GB.
export PKR_VAR_disk_size = 10

# Set defaults for the Amazon AMI Builder.
export PKR_VAR_aws_region = us-east-2
export PKR_VAR_ec2_instance_type = t3a.nano

# Set defaults for the Google Compute Builder.
export PKR_VAR_gcp_zone = us-central1-a
export PKR_VAR_gcp_machine_type = e2-micro
export PKR_VAR_gcp_source_image_family = ubuntu-minimal-2104

# Set defaults for the Docker Builder.
# https://hub.docker.com/_/consul/
export PKR_VAR_consul_docker_image = consul:latest
# https://hub.docker.com/_/vault/
export PKR_VAR_vault_docker_image = vault:latest
# https://hub.docker.com/_/ubuntu/
export PKR_VAR_nomad_docker_image = ubuntu:latest

# Set default datacenter names.
export PKR_VAR_aws_datacenter = aws-dc1
export PKR_VAR_gcp_datacenter = gcp-dc1
export PKR_VAR_docker_datacenter = docker-dc1

# Consul variables
export PKR_VAR_consul_node_name = consul-server-node-one
export PKR_VAR_raft_multiplier = 5
export PKR_VAR_bootstrap_expect = 1
export PKR_VAR_client_addr = 0.0.0.0
export PKR_VAR_consul_ui_enabled = false
export PKR_VAR_consul_port_dns = 8600
export PKR_VAR_consul_port_http = 8500
export PKR_VAR_consul_port_https = -1
export PKR_VAR_consul_port_grpc = -1
export PKR_VAR_consul_port_serf_lan = 8301
export PKR_VAR_consul_port_serf_wan = 8302
export PKR_VAR_consul_port_server = 8300
export PKR_VAR_consul_port_sidecar_min_port = 21000
export PKR_VAR_consul_port_sidecar_max_port = 21255
export PKR_VAR_consul_port_expose_min_port = 21500
export PKR_VAR_consul_port_expose_max_port = 21755

# Vault variables
export PKR_VAR_vault_cluster_name = vault-cluster-one
export PKR_VAR_vault_ui_enabled = false
export PKR_VAR_vault_check_timeout = 5m

# Nomad variables
export PKR_VAR_nomad_region = global
export PKR_VAR_nomad_port_http = 4646
export PKR_VAR_nomad_port_rpc = 4647
export PKR_VAR_nomad_port_serf = 4648

# Source environment variables
-include .env

default: help

.PHONY: dependencies
dependencies:
ifeq ($(shell which packer),)
# Install packer
	@rm -rf /tmp/packer
	@git clone https://github.com/hashicorp/packer.git /tmp/packer
	@sed -i s/'const VersionPrerelease = "dev"'/'const VersionPrerelease = ""'/g /tmp/packer/version/version.go
	@sed -i s/'ALL_XC_ARCH="386 amd64 arm arm64 ppc64le mips mips64 mipsle mipsle64 s390x"'/'ALL_XC_ARCH="amd64"'/g /tmp/packer/scripts/build.sh
	@sed -i s/'ALL_XC_OS="linux darwin windows freebsd openbsd solaris"'/'ALL_XC_OS="linux"'/g /tmp/packer/scripts/build.sh
	@cd /tmp/packer && make releasebin
	@sudo mv -f /tmp/packer/bin/packer /usr/local/bin/packer
endif

.PHONY: packer-init
packer-init:
	@echo "Installing packer plugins"
	@packer init -upgrade ./consul-server/consul-server.pkr.hcl
	@packer init -upgrade ./nomad-client/nomad-client.pkr.hcl
	@packer init -upgrade ./nomad-server/nomad-server.pkr.hcl
	@packer init -upgrade ./vault-server/vault-server.pkr.hcl

.PHONY: build
build: dependencies packer-init ## Build machine images.
	@echo "Building machine images"
ifneq (,$(findstring consul-server, $(BUILDS)))
	@packer build -timestamp-ui -only=$(BUILDS) ./consul-server/consul-server.pkr.hcl
endif
ifneq (,$(findstring nomad-client, $(BUILDS)))
	@packer build -timestamp-ui -only=$(BUILDS) ./nomad-client/nomad-client.pkr.hcl
endif
ifneq (,$(findstring nomad-server, $(BUILDS)))
	@packer build -timestamp-ui -only=$(BUILDS) ./nomad-server/nomad-server.pkr.hcl
endif
ifneq (,$(findstring vault-server, $(BUILDS)))
	@packer build -timestamp-ui -only=$(BUILDS) ./vault-server/vault-server.pkr.hcl
endif
ifneq (,$(findstring consul-vault-nomad-server, $(BUILDS)))
	@packer build -timestamp-ui -only=$(BUILDS) ./consul-vault-nomad-server/consul-vault-nomad-server.pkr.hcl
endif

HELP_FORMAT="    \033[36m%-25s\033[0m %s\n"
.PHONY: help
help: ## Display this usage information.
	@echo "Valid targets:"
	@grep -E '^[^ ]+:.*?## .*$$' Makefile | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; \
			{printf $(HELP_FORMAT), $$1, $$2}'
