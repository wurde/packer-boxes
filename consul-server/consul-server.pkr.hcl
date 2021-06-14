# Builders are responsible for creating machines and
# generating images from them for various platforms.

# https://github.com/hashicorp/consul
# export PKR_VAR_consul_version=$CONSUL_VERSION
variable "consul_version" {
  type    = string
  default = "1.9.5"
}

variable "googlecompute_project_id" {
  type        = string
  description = "The Google Cloud project ID used to launch instances and store images."
}

# The locals block, also called the local-variable
# block, defines locals within your Packer config.
# https://www.packer.io/docs/templates/hcl_templates/blocks/locals
locals {
  # The version of the Consul Server image.
  version = "v1"

  # The AWS Region used for the EC2 instance.
  aws_region = "us-east-2"

  # The GCP Zone used to launch the instance.
  gcp_zone = "us-central1-a"

  # The GCP Source Image
  gcp_source_image_family = "ubuntu-minimal-2104"

  # The GCP machine type.
  gcp_machine_type = "f1-micro"

  # The EC2 instance type.
  ec2_instance_type = "t3a.nano"

  # The Docker image.
  docker_image = "amd64/alpine:3.13"

  # The Docker repository to use.
  docker_hub_user = "wurde"

  # The timestamp when the build ran.
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# The top-level source block defines reusable
# builder configuration blocks.
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
#
# All AMIs are categorized as either backed by Amazon EBS
# or backed by instance store.
#
# Source:       amazon-ebs - or - amazon-instance
# Boot time:     < 1 min          < 5 min
# Root Size Max: 16 TiB           10 GiB
# Persistence:   yes              no
#
# Create Amazon AMIs backed by EBS volumes for use in EC2.
# Builds an AMI by launching an EC2 instance from a source
# AMI, provisioning that running machine, and then creating
# an AMI from that machine. This is done in your AWS account.
# The builder will create temporary keypairs, security group
# rules, etc. that provide it temporary access to the
# instance while the image is being created.
#
# The builder does not manage AMIs. Once it creates an AMI
# and stores it in your account, it is up to you to use,
# delete, etc. the AMI.
#
# https://www.packer.io/docs/builders/amazon/ebs
source "amazon-ebs" "consul-server" {
  # Name of the AMI. Required. Must be unique.
  ami_name        = "consul-server-${local.version}-amazon-ebs-${local.timestamp}"
  ami_description = "An Amazon Linux 2 AMI for deploying a Consul server."

  # The type of virtualization for the AMI you are building.
  # This option is required to register HVM images. Can be
  # paravirtual (default) or hvm.
  ami_virtualization_type = "hvm"

  # The profile to use in the shared credentials file for AWS.
  profile = "default"

  # The EC2 instance type. Required.
  instance_type = local.ec2_instance_type
  region        = local.aws_region

  # Default Linux system user account.
  ssh_username = "ec2-user"
  ssh_timeout  = "5m"

  # Force deregister an existing AMI if one with the same
  # name already exists. Default false.
  force_deregister      = true
  force_delete_snapshot = true

  # Lookup the source AMI whose root volume will be copied
  # and provisioned on the instance.
  #
  # Amazon Linux 2 is a Linux server operating system from AWS.
  # It provides a secure, stable, and high performance environment.
  #
  # - Long-term support for 5 years.
  # - Includes the systemd init system.
  # - Kernel tuned for Amazon EC2.
  # - Disables remote root login.
  # - Includes the AWS CLI.
  # - Includes the cloud-init.
  #
  # https://aws.amazon.com/amazon-linux-2
  # https://aws.amazon.com/amazon-linux-2/release-notes
  source_ami_filter {
    filters = {
      name                               = "*amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type                   = "ebs"
      architecture                       = "x86_64"
      "block-device-mapping.volume-type" = "gp2"
      virtualization-type                = "hvm"
      state                              = "available"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  # Lookup the vpc_id field.
  vpc_filter {
    filters = {
      "isDefault" : "true"
    }
  }

  # Temporary IAM instance profile to launch the instance with.
  temporary_iam_instance_profile_policy_document {
    Statement {
      Action = [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "autoscaling:DescribeAutoScalingGroups"
      ]
      Effect   = "Allow"
      Resource = ["*"]
    }
    Version = "2012-10-17"
  }
}

# Create images for use with Azure Virtual Machines.
# https://www.packer.io/docs/builders/azure
source "azure-arm" "consul-server" {}

# Create images for use with Docker.
# https://www.packer.io/docs/builders/docker
source "docker" "consul-server" {
  # The base image for the Docker container that will be started.
  # This image will be pulled from the Docker registry if it
  # doesn't already exist.
  image = local.docker_image

  # The container will be committed to an image rather than exported.
  commit = true

  # Set a message for the commit.
  message = "Build consul-server-${local.version}-docker-${local.timestamp}."
}

# Create images for use with Google Compute Engine (GCE).
# https://www.packer.io/docs/builders/googlecompute
source "googlecompute" "consul-server" {
  # The project ID that will be used to launch instances and store images.
  project_id = var.googlecompute_project_id

  # The source image to use to create the new image from.
  # gcloud compute images list
  source_image_family = local.gcp_source_image_family

  # The zone in which to launch the instance used to create the image.
  zone = local.gcp_zone

  # The GCP machine type.
  machine_type = local.gcp_machine_type

  # The username to connect to SSH with.
  ssh_username = "ubuntu"
}

# Create images for use with Linode.
# https://www.packer.io/docs/builders/linode
source "linode" "consul-server" {}

# Create images for use with OpenStack.
# https://www.packer.io/docs/builders/openstack
source "openstack" "consul-server" {}

# The build block defines what builders are
# started, how to provision them and if
# necessary what to do with their artifacts
# using post-process.
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  # Use the singular `source` block set specific fields.
  # Note that fields cannot be overwritten, in other words, you cannot
  # set the 'image' field from the top-level source block in here, as well as
  # the 'name' and 'output_image' fields cannot be set in the top-level source block.
  sources = [
    #"sources.amazon-ebs.consul-server",
    #"sources.azure-arm.consul-server",
    #"sources.docker.consul-server",
    #"sources.googlecompute.consul-server",
    #"sources.linode.consul-server",
    #"sources.openstack.consul-server",
  ]

  post-processor "docker-tag" {
    only       = ["docker.consul-server"]
    repository = "${local.docker_hub_user}/consul-server-${local.version}-docker-${local.timestamp}"
    tags       = [local.version, "latest"]
  }
}
