# Andy Bettisworth's Packer Builds

A set of Packer templates to simplify deploying a
multi-cloud HashiStack.

## Requirements

- Linux x86-64 (operating system, architecture)

## Usage

```bash
# Initiate all builds
make build
```

Required configuration:

**./main.pkvars.hcl**

```bash
# If using googlecompute then you must specify
# a Google Cloud Project ID.
googlecompute_project_id = "<unique_project_name>"
```

Optional configuration:

**./.env**

```bash
# Configure which builds run
# Default: 
#   amazon-ebs.consul-server, googlecompute.consul-server, docker.consul-server,
#   amazon-ebs.nomad-client,  googlecompute.nomad-client,  docker.nomad-client,
#   amazon-ebs.nomad-server,  googlecompute.nomad-server,  docker.nomad-server,
#   amazon-ebs.vault-server,  googlecompute.vault-server,  docker.vault-server
BUILDS = amazon-ebs.consul-server, docker.consul-server
```

## Builders

### Amazon EBS

The `amazon-ebs` Packer builder is able to create images for
use with Amazon Elastic Compute Cloud (EC2).

### Google Compute

The `googlecompute` Packer builder is able to create images for
use with Google Compute Engine (GCE).

### Docker

The `docker` Packer builder is able to create images for
use with Docker.

## License

This project is __FREE__ to use, reuse, remix, and resell.
This is made possible by the [MIT license](/LICENSE).
