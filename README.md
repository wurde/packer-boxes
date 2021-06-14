# Andy Bettisworth's Packer Builds

A set of Packer templates to simplify deploying a HashiStack.

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



## License

This project is __FREE__ to use, reuse, remix, and resell.
This is made possible by the [MIT license](/LICENSE).
