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

Below includes optional configurations.

**./.env**

```bash
# Configure which images are created
# Default: consul-server, nomad-client, nomad-server, vault-server
IMAGES = consul-server

# Configure which builds run
# Default: amazon-ebs, googlecompute, docker
BUILDERS = amazon-ebs, docker
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
