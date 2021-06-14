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

.PHONY: build
packer-init:
	@echo "Installing packer plugins"
ifeq ($(TF_VAR_BACKEND_S3_BUCKET),)
	@packer init -upgrade ./consul-server/consul-server.pkr.hcl
endif

.PHONY: build
build: dependencies packer-init ## Build machine images.
	@echo "Building machine images:"
# @cd ./consul-server && packer build ./consul-server.pkr.hcl

HELP_FORMAT="    \033[36m%-25s\033[0m %s\n"
.PHONY: help
help: ## Display this usage information.
	@echo "Valid targets:"
	@grep -E '^[^ ]+:.*?## .*$$' Makefile | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; \
			{printf $(HELP_FORMAT), $$1, $$2}'
