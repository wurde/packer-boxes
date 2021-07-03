# Andy Bettisworth's Packer Builds

A set of Packer templates to simplify deploying a
multi-cloud [HashiStack](https://hashicorp.com).

## Requirements

- Linux x86-64 (operating system, architecture)

_Note I'm open to contributors who'd like to extend OS support. It's just not a concern/focus of mine._

## Usage

```bash
make build
```

All configuration happens via environment variables.
By default a local `.env` file will be imported.

**./.env**

```bash
# Configure which builds run
# Default: 
#   amazon-ebs.consul-server, googlecompute.consul-server, docker.consul-server,
#   amazon-ebs.nomad-client,  googlecompute.nomad-client,  docker.nomad-client,
#   amazon-ebs.nomad-server,  googlecompute.nomad-server,  docker.nomad-server,
#   amazon-ebs.vault-server,  googlecompute.vault-server,  docker.vault-server
BUILDS = amazon-ebs.consul-server, docker.consul-server

# Configure which Consul version to install.
PKR_VAR_consul_version = v1.10
# Configure which Vault version to install.
PKR_VAR_vault_version = v1.7
# Configure which Nomad version to install.
PKR_VAR_nomad_version = v1.1
```

## Builders

### Amazon EBS

The `amazon-ebs` Packer builder is able to create images for
use with Amazon Elastic Compute Cloud (EC2).

### Google Compute

The `googlecompute` Packer builder is able to create images for
use with Google Compute Engine (GCE).

**./.env**

```bash
# REQUIRED. You must specif a Google Cloud Project ID.
PKR_VAR_googlecompute_project_id = "<unique_project_name>"
```

### Docker

The `docker` Packer builder is able to create images for
use with Docker.

```bash
# Run your image as a container
docker run -it [image-id]

# Enter a running Docker container with a new TTY
docker exec -it [container-id] bash
```

The following images are used:

- [consul:latest](https://hub.docker.com/_/consul/)
- [vault:latest](https://hub.docker.com/_/vault/)
- [ubuntu:latest](https://hub.docker.com/_/ubuntu/)

## License

This project is __FREE__ to use, reuse, remix, and resell.
This is made possible by the [MIT license](/LICENSE).
