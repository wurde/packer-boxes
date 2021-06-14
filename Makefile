IMAGES = consul-server nomad-client nomad-server vault-server
BUILDERS = amazon-ebs, azure-arm, docker, googlecompute, linode, openstack

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
ifneq (,$(findstring consul-server, $(IMAGES)))
	@packer init -upgrade ./consul-server/consul-server.pkr.hcl
endif
ifneq (,$(findstring nomad-client, $(IMAGES)))
	@packer init -upgrade ./nomad-client/nomad-client.pkr.hcl
endif
ifneq (,$(findstring nomad-server, $(IMAGES)))
	@packer init -upgrade ./nomad-server/nomad-server.pkr.hcl
endif
ifneq (,$(findstring vault-server, $(IMAGES)))
	@packer init -upgrade ./vault-server/vault-server.pkr.hcl
endif

.PHONY: build
build: dependencies packer-init ## Build machine images.
	@echo "Building machine images:"
	@echo $(PKR_VAR_googlecompute_project_id)
# ifneq (,$(findstring consul-server, $(IMAGES)))
# 	@cd ./consul-server && packer build ./consul-server.pkr.hcl
# endif
# ifneq (,$(findstring nomad-client, $(IMAGES)))
# 	@cd ./nomad-client && packer build ./nomad-client.pkr.hcl
# endif
# ifneq (,$(findstring nomad-server, $(IMAGES)))
# 	@cd ./nomad-server && packer build ./nomad-server.pkr.hcl
# endif
# ifneq (,$(findstring vault-server, $(IMAGES)))
# 	@cd ./vault-server && packer build ./vault-server.pkr.hcl
# endif

HELP_FORMAT="    \033[36m%-25s\033[0m %s\n"
.PHONY: help
help: ## Display this usage information.
	@echo "Valid targets:"
	@grep -E '^[^ ]+:.*?## .*$$' Makefile | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; \
			{printf $(HELP_FORMAT), $$1, $$2}'
