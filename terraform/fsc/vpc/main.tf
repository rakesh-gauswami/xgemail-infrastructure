##################################################################################
# Modules
##################################################################################

module "terraform_version_pin" {
 source = "git::ssh://git.cloud.sophos/msg/terraform-version-pin.git?ref=v4.0.0"
}

module "env_helper" {
 source = "git::ssh://git.cloud.sophos/msg/msg-ecs-helper.git?ref=v2.0"
}

##################################################################################
# Backend
##################################################################################

terraform {
  backend "s3" {
    encrypt        = true
    key            = "terraform/vpc"
    region         = "us-west-2"
    dynamodb_table = "terraform_locks"
  }
}

##################################################################################
# Data Sources
##################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
}

locals {
  domain_names = {
    "us-east-1"    = "ec2.internal"
    "us-east-2"    = "us-east-2.compute.internal"
    "us-west-2"    = "us-west-2.compute.internal"
    "eu-west-1"    = "eu-west-1.compute.internal"
    "eu-central-1" = "eu-central-1.compute.internal"
  }

  vpc_full_name       = format("%s-VPC/vpc", var.vpc_name)
  public_subnet_tags  = merge(var.tags, map("Type", "public"))
  private_subnet_tags = merge(var.tags, map("Type", "private"))
}
##################################################################################
# Resources
##################################################################################

resource "aws_eip" "nat" {
  count = 3
  vpc = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> v2.62.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  dhcp_options_domain_name = lookup(local.domain_names, var.region, "ec2.internal")
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]

  create_vpc = true
  create_igw = true
  enable_dhcp_options = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_s3_endpoint   = true
  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true
  reuse_nat_ips       = true
  external_nat_ip_ids = aws_eip.nat.*.id
  manage_default_network_acl = true

  tags = var.tags

  vpc_tags = {
    Name  = local.vpc_full_name
  }
   dhcp_options_tags = {
    Name  = "${var.vpc_name}-VPC/dhcp"
  }
  igw_tags = {
    Name  = "${var.vpc_name}-VPC/igw"
  }
  nat_eip_tags = {
    Name  = "${var.vpc_name}-VPC/eip"
  }
  nat_gateway_tags = {
    Name  = "${var.vpc_name}-VPC/nat"
  }
  default_security_group_tags = {
    Name  = "${var.vpc_name}-VPC/sg"
  }
  private_acl_tags = {
    Name  = "${var.vpc_name}-VPC/nat"
  }
  public_acl_tags = {
    Name  = "${var.vpc_name}-VPC/acl"
  }
  private_subnet_tags = {
    Type  = "private"
  }
  public_subnet_tags = {
    Type  = "public"
  }
}
