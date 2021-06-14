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
# Configure which builds run
# Default: amazon-ebs, azure-arm, docker, googlecompute, linode, openstack
BUILDERS = amazon-ebs, googlecompute
```

## Builders

### Amazon EBS

The `amazon-ebs` Packer builder is able to create images for
use with Amazon Elastic Compute Cloud (EC2).

### Azure ARM

The `azure-arm` Packer builder is able to create images for
use with Azure Virtual Machines.

### Docker

The `docker` Packer builder is able to create images for
use with Docker.

### Google Compute

The `googlecompute` Packer builder is able to create images for
use with Google Compute Engine (GCE).

### Linode

The `linode` Packer builder is able to create images for
use with Linode.

### OpenStack

The `openstack` Packer builder is able to create images for
use with OpenStack.

## License

This project is __FREE__ to use, reuse, remix, and resell.
This is made possible by the [MIT license](/LICENSE).
