# Builders are responsible for creating machines and
# generating images from them for various platforms.

variable "nomad_version" {
  type        = string
  description = "Nomad version to install. See latest releases here: https://github.com/hashicorp/nomad/releases"
}

source "amazon-ebs" "nomad-server" { }
source "googlecompute" "nomad-server" { }
source "docker" "nomad-server" { }
