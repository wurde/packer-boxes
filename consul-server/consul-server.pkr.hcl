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
  default     = ""
}

# The locals block, also called the local-variable
# block, defines locals within your Packer config.
# https://www.packer.io/docs/templates/hcl_templates/blocks/locals
locals {
  # The version of the Consul Server image.
  version = "v1"

  # The size of the disk in GB.
  disk_size = 10

  # The AWS Region used for the EC2 instance.
  aws_region = "us-east-2"

  # The GCP Zone used to launch the instance.
  gcp_zone = "us-central1-a"

  # The GCP Source Image
  gcp_source_image_family = "ubuntu-minimal-2104"

  # The GCP machine type.
  gcp_machine_type = "n1-standard-1"

  # The EC2 instance type.
  ec2_instance_type = "t3a.nano"

  # The Docker image.
  docker_image = "amd64/alpine:3.13"

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

  # Each instance has an associated root device volume, which is
  # either an Amazon EBS volume or an instance store volume. You
  # can use block device mapping to specify additional EBS volumes
  # or instance store volumes.
  launch_block_device_mappings {
    device_name = "/dev/xvda"

    # The size in GiB. gp2 = $0.10 per GB-month.
    # https://aws.amazon.com/ebs/pricing
    volume_size = local.disk_size

    # Amazon EBS provides the following volume types:
    # - General Purpose SSD (gp2 and gp3)
    # - Provisioned IOPS SSD (io1 and io2)
    # - Throughput Optimized HDD (st1)
    # - Cold HDD (sc1)
    # - Magnetic (standard)
    volume_type = "gp2"

    delete_on_termination = true
  }

  tags = {
    name = "consul_server"
    os   = "amazon_linux_2"

    # Consul auto-join functionality enables bootstrapping
    # and auto-scaling Consul clusters via metadata.
    # https://www.consul.io/docs/install/cloud-auto-join
    consul_auto_join = "main"
  }
}

# Create images for use with Google Compute Engine (GCE).
# https://www.packer.io/docs/builders/googlecompute
source "googlecompute" "consul-server" {
  # The project ID that will be used to launch instances and store images.
  project_id = var.googlecompute_project_id

  # The unique name of the image.
  image_name        = "consul-server-${local.version}-googlecompute-${local.timestamp}"
  image_description = "A Minimal Ubuntu Image for deploying a Consul server."

  # The source image to use to create the new image from.
  # gcloud compute images list
  source_image_family = local.gcp_source_image_family

  # The zone in which to launch the instance used to create the image.
  zone = local.gcp_zone

  # The GCP machine type.
  machine_type = local.gcp_machine_type

  # The username to connect to SSH with.
  ssh_username = "ubuntu"

  # The size of the disk in GB. Defaults to 10GB (min 10GB).
  disk_size = local.disk_size

  # Type of disk used to back your instance, like pd-ssd,
  # pd-balanced, or pd-standard. Defaults to pd-standard.
  disk_type = "pd-ssd"

  # Create a Shielded VM image with Secure Boot enabled. It helps
  # ensure that the system only runs authentic software by verifying
  # the digital signature of all boot components, and halting the
  # boot process if signature verification fails.
  enable_secure_boot = true

  # Sets Host Maintenance Option. Choices are MIGRATE or TERMINATE.
  on_host_maintenance = "MIGRATE"

  labels = {
    name = "consul_server"
    os   = "minimal_ubuntu_2104"

    # Consul auto-join functionality enables bootstrapping
    # and auto-scaling Consul clusters via metadata.
    # https://www.consul.io/docs/install/cloud-auto-join
    consul_auto_join = "main"
  }
}

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
    "sources.amazon-ebs.consul-server",
    "sources.googlecompute.consul-server",
    "sources.docker.consul-server",
  ]

  # Copy setup files. The "file" Packer provisioner uploads
  # files to machines built by Packer.
  #
  # Warning: You can only upload files to locations that the
  # provisioning user (generally not root) has permission to
  # access. Creating files in /tmp and using a shell
  # provisioner to move them into the final location is the
  # only way to upload files to root owned locations.
  #
  # The existence of a trailing slash on the source path will
  # determine whether the directory name will be embedded
  # within the destination, or whether the destination will
  # be created. If the source is /foo (no trailing slash),
  # and the destination is /tmp, then the contents of /foo on
  # the local machine will be uploaded to /tmp/foo on the
  # remote machine. The foo directory on the remote machine
  # will be created by Packer. If the source, however, is
  # /foo/ (a trailing slash is present), and the destination
  # is /tmp, then the contents of /foo will be uploaded into
  # /tmp directly.
  provisioner "file" {
    source      = "./consul-server/scripts/"
    destination = "/tmp"
  }

  # Run the local setup script.
  provisioner "shell-local" {
    inline = ["sh ./consul-server/scripts/setup-local.sh"]
  }

  # Copy the consul binary.
  provisioner "file" {
    source      = "./tmp/"
    destination = "/tmp"
    generated   = true
  }

  # Run the Amazon EBS script.
  provisioner "shell" {
    only   = ["amazon-ebs.consul-server"]
    inline = ["sh /tmp/setup-amazon-ebs.sh"]
  }

  # Run the Google Compute script.
  provisioner "shell" {
    only   = ["googlecompute.consul-server"]
    inline = ["sh /tmp/setup-googlecompute.sh"]
  }

  # Run the Docker script.
  provisioner "shell" {
    only   = ["docker.consul-server"]
    inline = ["sh /tmp/setup-docker.sh"]
  }

  # Run the remote setup script.
  provisioner "shell" {
    inline = ["sh /tmp/setup-remote.sh"]
  }
}
