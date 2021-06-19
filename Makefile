BUILDS = amazon-ebs.consul-server, googlecompute.consul-server, docker.consul-server, amazon-ebs.nomad-client,  googlecompute.nomad-client, docker.nomad-client, amazon-ebs.nomad-server, googlecompute.nomad-server, docker.nomad-server, amazon-ebs.vault-server, googlecompute.vault-server, docker.vault-server

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
	@echo "Building machine images:"
	@packer build -only=$(BUILDS) -var-file=main.pkrvars.hcl ./consul-server/consul-server.pkr.hcl
	@packer build -only=$(BUILDS) -var-file=main.pkrvars.hcl ./nomad-client/nomad-client.pkr.hcl
	@packer build -only=$(BUILDS) -var-file=main.pkrvars.hcl ./nomad-server/nomad-server.pkr.hcl
	@packer build -only=$(BUILDS) -var-file=main.pkrvars.hcl ./vault-server/vault-server.pkr.hcl

HELP_FORMAT="    \033[36m%-25s\033[0m %s\n"
.PHONY: help
help: ## Display this usage information.
	@echo "Valid targets:"
	@grep -E '^[^ ]+:.*?## .*$$' Makefile | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; \
			{printf $(HELP_FORMAT), $$1, $$2}'
