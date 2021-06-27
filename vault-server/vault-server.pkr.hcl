# Builders are responsible for creating machines and
# generating images from them for various platforms.

variable "vault_version" {
  type        = string
  description = "Vault version to install. See latest releases here: https://github.com/hashicorp/vault/releases"
}

source "amazon-ebs" "vault-server" { }
source "googlecompute" "vault-server" { }
source "docker" "vault-server" { }
