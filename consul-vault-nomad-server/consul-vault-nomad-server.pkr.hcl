# Builders are responsible for creating machines and
# generating images from them for various platforms.

variable "consul_version" {
  type        = string
  description = "Consul version to install. See latest releases here: https://github.com/hashicorp/consul/releases"
}

variable "vault_version" {
  type        = string
  description = "Vault version to install. See latest releases here: https://github.com/hashicorp/vault/releases"
}

variable "nomad_version" {
  type        = string
  description = "Nomad version to install. See latest releases here: https://github.com/hashicorp/nomad/releases"
}

source "amazon-ebs" "consul-vault-nomad-server" { }
source "googlecompute" "consul-vault-nomad-server" { }
source "docker" "consul-vault-nomad-server" { }

source "null" "example" {
  communicator = "none"
}

build {
  sources = [
    "source.null.example"
  ]
  provisioner "shell-local" {
    environment_vars = ["HELLO_USER=packeruser", "UUID=${build.PackerRunUUID}"]
    inline           = [
      "echo the Packer run uuid is $UUID",
      "echo Consul version ${var.consul_version}",
    ]
  }
}
