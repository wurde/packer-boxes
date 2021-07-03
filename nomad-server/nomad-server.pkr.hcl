# Builders are responsible for creating machines and
# generating images from them for various platforms.

variable "nomad_version" {
  type        = string
  description = "Nomad version to install. See latest releases here: https://github.com/hashicorp/nomad/releases"
}

variable "aws_region" {
  description = "The AWS Region used for the EC2 instance."
  type        = string
}

variable "ec2_instance_type" {
  description = "The EC2 instance type."
  type        = string
}

variable "googlecompute_project_id" {
  description = "The Google Cloud project ID used to launch instances and store images."
  type        = string
  default     = ""
}

variable "gcp_zone" {
  description = "The GCP Zone used to launch the instance."
  type        = string
}

variable "gcp_machine_type" {
  description = "The GCP machine type."
  type        = string
}

variable "gcp_source_image_family" {
  description = "The GCP Source Image."
  type        = string
}

variable "docker_image" {
  description = "The Docker image."
  type        = string
}

variable "disk_size" {
  description = "The size of the disk in GB."
  type        = number
}

variable "aws_datacenter" {
  description = "The AWS datacenter in which the agent is running."
  type        = string
}

variable "gcp_datacenter" {
  description = "The GCP datacenter in which the agent is running."
  type        = string
}

variable "docker_datacenter" {
  description = "The Docker datacenter in which the agent is running."
  type        = string
}

# The locals block, also called the local-variable
# block, defines locals within your Packer config.
# https://www.packer.io/docs/templates/hcl_templates/blocks/locals
locals {
  # The timestamp when the build ran.
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")

  environment_vars = [
    "NOMAD_VERSION=${var.nomad_version}",
    "AWS_REGION=${var.aws_region}",
    "AWS_DATACENTER=${var.aws_datacenter}",
    "GCP_DATACENTER=${var.gcp_datacenter}",
    "DOCKER_DATACENTER=${var.docker_datacenter}",
  ]
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
source "amazon-ebs" "nomad-server" {
  # Name of the AMI. Required. Must be unique.
  ami_name        = "nomad-server-amazon-ebs-${local.timestamp}"
  ami_description = "An Amazon Linux 2 AMI for deploying a Nomad server."

  # The type of virtualization for the AMI you are building.
  # This option is required to register HVM images. Can be
  # paravirtual (default) or hvm.
  ami_virtualization_type = "hvm"

  # The profile to use in the shared credentials file for AWS.
  profile = "default"

  # The EC2 instance type. Required.
  instance_type = var.ec2_instance_type
  region        = var.aws_region

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
  # https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpcs.html
  vpc_filter {
    filters = {
      "isDefault" : "true"
      "state" : "available"
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
    volume_size = var.disk_size

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
    "name" : "nomad_server"
  }
}

# Create images for use with Google Compute Engine (GCE).
# https://www.packer.io/docs/builders/googlecompute
source "googlecompute" "nomad-server" {
  # The project ID that will be used to launch instances and store images.
  project_id = var.googlecompute_project_id

  # The unique name of the image.
  image_name        = "nomad-server-googlecompute-${local.timestamp}"
  image_description = "A Minimal Ubuntu Image for deploying a Nomad server."

  # The source image to use to create the new image from.
  # gcloud compute images list
  source_image_family = var.gcp_source_image_family

  # The zone in which to launch the instance used to create the image.
  zone = var.gcp_zone

  # The GCP machine type.
  machine_type = var.gcp_machine_type

  # The username to connect to SSH with.
  ssh_username = "ubuntu"

  # The size of the disk in GB. Defaults to 10GB (min 10GB).
  disk_size = var.disk_size

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
    "name" : "nomad_server"
  }
}

# Create images for use with Docker.
# https://www.packer.io/docs/builders/docker
source "docker" "nomad-server" {
  # The base image for the Docker container that will be started.
  # This image will be pulled from the Docker registry if it
  # doesn't already exist.
  image = var.docker_image

  # The container will be committed to an image rather than exported.
  commit = true

  # Set a message for the commit.
  message = "Build nomad-server-docker-${local.timestamp}."
}

# The build block defines what builders are  started, how
# to provision them and if necessary what to do with their
# artifacts using post-process.
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  # Use the singular `source` block set specific fields.
  # Note that fields cannot be overwritten, in other words, you cannot
  # set the 'image' field from the top-level source block in here, as well as
  # the 'name' and 'output_image' fields cannot be set in the top-level source block.
  sources = [
    "source.amazon-ebs.nomad-server",
    "source.googlecompute.nomad-server",
    "source.docker.nomad-server",
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
    source      = "./nomad-server/scripts/"
    destination = "/tmp"
  }

  # Run the local setup script.
  provisioner "shell-local" {
    inline           = ["sh ./nomad-server/scripts/setup-local.sh"]
    environment_vars = local.environment_vars
  }

  # Copy the binary.
  provisioner "file" {
    source      = "./tmp/"
    destination = "/tmp"
    generated   = true
  }

  #  # Run the Amazon EBS script.
  #  provisioner "shell" {
  #    only   = ["amazon-ebs.nomad-server"]
  #    inline = ["sh /tmp/setup-amazon-ebs.sh"]
  #
  #    environment_vars = local.environment_vars
  #  }
  #
  #  # Run the Google Compute script.
  #  provisioner "shell" {
  #    only   = ["googlecompute.nomad-server"]
  #    inline = ["sh /tmp/setup-googlecompute.sh"]
  #
  #    environment_vars = local.environment_vars
  #  }
  #
  #  # Run the Docker script.
  #  provisioner "shell" {
  #    only   = ["docker.nomad-server"]
  #    inline = ["sh /tmp/setup-docker.sh"]
  #
  #    environment_vars = local.environment_vars
  #  }
}
