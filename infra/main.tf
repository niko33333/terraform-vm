locals {
  projectName = var.project_name
  environment = var.env
  prefix      = "${local.projectName}-${local.environment}"
  common_tags = {
      projectName = local.projectName
      environment = local.environment
  }
}

terraform {
  backend "s3" {
    bucket         = "vmex-prod-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    acl            = "private"
    dynamodb_table = "terraform-state-locking"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region  = var.region
}


######################################
# Resources
######################################
resource "aws_ecr_repository" "web_server_repo" {
  name = "${local.prefix}-web-server-repo"
  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-web-server-repo"
    }
  )
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-vpc"
    }
  )
}

module "networking" {
  source           = "./networking"
  vpc_id           = aws_vpc.vpc.id
  cidr_block       = aws_vpc.vpc.cidr_block
  env              = var.env
  project_name     = var.project_name
  number_of_subnet = 3
  number_of_nat    = 1
}

module "alb" {
  source              = "./alb"
  vpc_id              = aws_vpc.vpc.id
  env                 = var.env
  project_name        = var.project_name
  alb_subnet_list     = module.networking.public_subnet_list
}

module "asg" {
  source                     = "./asg"
  vpc_id                     = aws_vpc.vpc.id
  env                        = var.env
  region                     = var.region
  project_name               = var.project_name
  security_group_alb_id      = module.alb.alb_security_group_id
  ec2_natted_subnet_list     = module.networking.natted_subnet_list
  volume_size                = 30
  instance_type              = "t3a.micro"
  image_id                   = "ami-0faab6bdbac9486fb"
  target_group_arn           = module.alb.target_group_arn
  docker_image               = aws_ecr_repository.web_server_repo.repository_url
}