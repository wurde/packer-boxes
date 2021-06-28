# Builders are responsible for creating machines and
# generating images from them for various platforms.

variable "consul_version" {
  description = "Consul version to install. See latest releases here: https://github.com/hashicorp/consul/releases"
  type        = string
}

variable "vault_version" {
  description = "Vault version to install. See latest releases here: https://github.com/hashicorp/vault/releases"
  type        = string
}

variable "nomad_version" {
  description = "Nomad version to install. See latest releases here: https://github.com/hashicorp/nomad/releases"
  type        = string
}

variable "raft_multiplier" {
  description = "An integer multiplier used by Consul servers to scale key Raft timing parameters."
  type        = number
}

locals {
  environment_vars = [
    "RAFT_MULTIPLIER=${var.raft_multiplier}"
  ]
}

source "amazon-ebs" "consul-vault-nomad-server" { }
source "googlecompute" "consul-vault-nomad-server" { }
source "docker" "consul-vault-nomad-server" { }
