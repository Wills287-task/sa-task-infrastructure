locals {
  account = "333907587704"
}

/* ---------------------------------------------------------------------------------------------------------------------
  METADATA
--------------------------------------------------------------------------------------------------------------------- */

module "metadata" {
  source = "git::https://github.com/Wills287/terraform-modules//aws/general/metadata?ref=v0.0.11"

  enabled     = var.enabled
  namespace   = var.namespace
  environment = var.environment
  name        = var.name
  service     = var.service
  delimiter   = var.delimiter
  attributes  = var.attributes
  tags        = var.tags
}

/* ---------------------------------------------------------------------------------------------------------------------
  NETWORKING
--------------------------------------------------------------------------------------------------------------------- */

module "vpc" {
  source = "git::https://github.com/Wills287/terraform-modules//aws/networking/vpc?ref=v0.0.12"

  enabled     = var.enabled
  namespace   = module.metadata.namespace
  environment = module.metadata.environment
  name        = module.metadata.name
  service     = module.metadata.service
  delimiter   = module.metadata.delimiter
  attributes  = module.metadata.attributes
  tags        = module.metadata.tags

  cidr_block = var.cidr_block
}

module "subnets" {
  source = "git::https://github.com/Wills287/terraform-modules//aws/networking/subnet?ref=v0.0.29"

  enabled     = var.enabled
  namespace   = module.metadata.namespace
  environment = module.metadata.environment
  name        = module.metadata.name
  service     = module.metadata.service
  delimiter   = module.metadata.delimiter
  attributes  = module.metadata.attributes
  tags        = module.metadata.tags

  availability_zones = var.availability_zones
  cidr_block         = module.vpc.vpc_cidr_block
  vpc_id             = module.vpc.vpc_id
  igw_id             = module.vpc.igw_id
}

/* ---------------------------------------------------------------------------------------------------------------------
  ECS
--------------------------------------------------------------------------------------------------------------------- */

module "ecs_cluster" {
  source = "git::https://github.com/Wills287/terraform-modules//aws/ecs/cluster?ref=v0.0.16"

  enabled     = var.enabled
  namespace   = module.metadata.namespace
  environment = module.metadata.environment
  name        = module.metadata.name
  service     = module.metadata.service
  delimiter   = module.metadata.delimiter
  attributes  = module.metadata.attributes
  tags        = module.metadata.tags
}

module "ecs_service" {
  source = "git::https://github.com/Wills287/terraform-modules//aws/ecs/service?ref=v0.0.27"

  enabled     = var.enabled
  namespace   = module.metadata.namespace
  environment = module.metadata.environment
  name        = module.metadata.name
  service     = module.metadata.service
  delimiter   = module.metadata.delimiter
  attributes  = module.metadata.attributes
  tags        = module.metadata.tags

  ecs_cluster_id = module.ecs_cluster.ecs_cluster_id

  container_image  = var.container_image
  container_memory = var.container_memory
}

/* ---------------------------------------------------------------------------------------------------------------------
  ALB
--------------------------------------------------------------------------------------------------------------------- */

module "alb" {
  source = "git::https://github.com/Wills287/terraform-modules//aws/alb?ref=v0.0.30"

  enabled     = var.enabled
  namespace   = module.metadata.namespace
  environment = module.metadata.environment
  name        = module.metadata.name
  service     = module.metadata.service
  delimiter   = module.metadata.delimiter
  attributes  = module.metadata.attributes
  tags        = module.metadata.tags

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.subnets.public_subnet_ids

  asg_id = module.autoscaling_group.autoscaling_group_id
}

/* ---------------------------------------------------------------------------------------------------------------------
  ASG
--------------------------------------------------------------------------------------------------------------------- */

locals {
  userdata = <<-USERDATA
    #!/bin/bash
    echo "ECS_CLUSTER=${module.metadata.id}" >> /etc/ecs/ecs.config
  USERDATA
}

data "aws_ami" "latest_ecs_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "${module.metadata.id}-ecs-agent-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "${module.metadata.id}-ecs-agent-instance-profile"
  role = aws_iam_role.ecs_agent.name
}

module "autoscaling_group" {
  source = "git::https://github.com/Wills287/terraform-modules//aws/asg?ref=v0.0.23"

  enabled     = var.enabled
  namespace   = module.metadata.namespace
  environment = module.metadata.environment
  name        = module.metadata.name
  service     = module.metadata.service
  delimiter   = module.metadata.delimiter
  attributes  = module.metadata.attributes

  image_id                    = data.aws_ami.latest_ecs_ami.id
  instance_type               = var.instance_type
  subnet_ids                  = module.subnets.public_subnet_ids
  min_size                    = var.min_size
  max_size                    = var.max_size
  desired_capacity            = var.desired_capacity
  associate_public_ip_address = true
  iam_instance_profile_name   = aws_iam_instance_profile.ecs_agent.name
  user_data_base64            = base64encode(local.userdata)
  key_name                    = var.key_name

  security_group_ids = [module.alb.alb_security_group_id]

  tags = {
    Cluster = module.ecs_cluster.ecs_cluster_id
  }

  autoscaling_policies_enabled = true
}
